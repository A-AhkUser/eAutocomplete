Class eAutocomplete {
	/*
		Enables users to quickly find and select from a dynamic pre-populated list of suggestions based on both earlier
		typed letters and the content of a custom list as they type in an AHK Edit control.
		https://github.com/A-AhkUser/eAutocomplete
	*/
	; ===============================================================================================================
	; ============================ PRIVATE PROPERTIES /===================================================
	; ===============================================================================================================
	_parent := "0x0"
	_szHwnd := "0x0"
	_menuWindow := {HWND: "0x0", AHKID: "", _lbListHeight: ""}
	_fnIf := ""

	_enabled := true
	_source := "Default"
	_startAt := 2
	_onEvent := ""
	_onSelect := ""
	_onSize := ""
	; ===============================================================================================================
	; ============================/ PRIVATE PROPERTIES ===================================================
	; ===============================================================================================================
	; ============================ PUBLIC PROPERTIES /=====================================================
	; ===============================================================================================================
	static sources := {"Default": {list: "", path: "", delimiter: "`n", _delimiter: "\n"}}

	editOptions := "w150 h35 Multi",
	menuOptions := "",
	HWND := ""
	AHKID := ""
	menu := {HWND: "", AHKID: "", _selectedItem: "", _selectedItemIndex: 0, _count: 0}

	disabled {
		set {
			if (this._enabled:=!value) {
				_fn := this._suggestWordList.bind(this)
				GuiControl +g, % this.HWND, % _fn ; set the function object which handles the edit control's events
				_fn := this._endWord.bind(this, 1)
				GuiControl +g, % this.menu.HWND, % _fn ; set the function object which handles the combobox control's events
			} else {
				GuiControl -g, % this.menu.HWND, ; removes the function object bound to the control
				GuiControl -g, % this.HWND,
			}
		return value
		}
		get {
		return !this._enabled
		}
	}
	startAt {
		set {
		return this._startAt := (value > 0) ? value : this._startAt
		}
		get {
		return this._startAt
		}
	}
	matchModeRegEx := true
	onEvent {
		set {
			this._setCallback("_onEvent", value)
		return this._onEvent
		}
		get {
		return this._onEvent
		}
	}
	maxSuggestions := 7
	onSelect {
		set {
			this._setCallback("_onSelect", value)
		return this._onSelect
		}
		get {
		return this._onSelect
		}
	}
	_minSize := {w: 51, h: 21}
	_maxSize := {w: A_ScreenWidth, h: A_ScreenHeight}
	onSize {
		set {
			this._setCallback("_onSize", value)
		return this._onSize
		}
		get {
		return this._onSize
		}
	}
	; ===============================================================================================================
	; ============================/ PUBLIC PROPERTIES ====================================================
	; ===============================================================================================================
	; ============================ PUBLIC METHODS /=====================================================
	; ===============================================================================================================
	__New(_GUIID, _options:="") {

		(IsObject(_options) || _options:={})
		_options.remove("disabled")
		for _option, _value in _options
			this[_option] := _value

		_GUI := A_DefaultGUI, _lastFoundWindow := WinExist()

		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		if not (WinExist("ahk_id " . _GUIID))
			return !ErrorLevel:=1
		DetectHiddenWindows % _detectHiddenWindows
		; --------------------------------------------------------------------------------------------------------------------------------------------------------- edit control
		GUI, % (this._parent:=_GUIID) . ":Add", Edit, % this.editOptions . " hwnd_eHwnd +Multi",
		this.AHKID := "ahk_id " . this.HWND:=_eHwnd
		RegExMatch(this.editOptions, "Pi)(^|\s)\K\+?[^-]?Resize(?=\s|$)", _resize) ; matchs if the 'Resize' option is specified
		if (_resize) {
			GuiControlGet, _pos, Pos, % _eHwnd
			GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 " . Format("x{1} y{2}", _posx + _posw - 7, _posy + _posh - 7) . " hwnd_szHwnd"
			; , % Chr(9698) ; https://unicode-table.com/fr/25E2/
			this._szHwnd := _szHwnd, _fn := this.__resize.bind(this)
			GuiControl +g, % _szHwnd, % _fn ; set the function object which handles the static control's events
		}
		; --------------------------------------------------------------------------------------------------------------------------------------------------------- menu
		GUI, New, +ToolWindow -Caption +Owner%_GUIID% +hwnd_menuWindowHwnd +E0x20 +LastFound
		GUI, Color,, % this.menuBackgroundColor
		GUI, Font, % this.menuFontOptions, this.menFontName
		WinSet, Transparent, 255
		this._menuWindow.AHKID := "ahk_id " . this._menuWindow.HWND:=_menuWindowHwnd
		GUI, Margin, 0, 0
		GUI, Add, ListBox, x0 y0 -HScroll +VScroll Choose0 -Multi -Sort 0x100 hwnd_lbHwnd,
		SendMessage, 0x1A1, 0, 0,, % this.menu.AHKID:="ahk_id " . this.menu.HWND:=_lbHwnd ; LB_GETITEMHEIGHT
		this._menuWindow._lbListHeight := ErrorLevel
		_fn := this._endWord.bind(this, 1)
		GuiControl +g, % _lbHwnd, % _fn ; set the function object which handles the combobox control's events
		; --------------------------------------------------------------------------------------------------------------------------------------------------------- hotkeys
		_fn := this._fnIf := this._hotkeysShouldFire.bind("", "ahk_id " . _GUIID, _menuWindowHwnd)
		Hotkey, If, % _fn
			_fn1 := this._menuSetSelection.bind(this, -1), _fn2 := this._menuSetSelection.bind(this, +1)
			Hotkey, Up, % _fn1
			Hotkey, Down, % _fn2
			_fn1 := this._menuSetPsSz.bind(this, -1), _fn2 := this._menuSetPsSz.bind(this, 1)
			Hotkey, !Left, % _fn1
			Hotkey, !Right, % _fn2
			_fn := this._autocomplete.bind(this, this.AHKID)
			Hotkey, Tab, % _fn
			_fn := this._menuReset.bind(this)
			Hotkey, Escape, % _fn
		Hotkey, If,
		OnMessage(0x03, this._menuHide.bind("", _menuWindowHwnd)) ; WM_MOVE
		OnMessage(0x05, this._menuHide.bind("", _menuWindowHwnd)) ; WM_SIZE

		this.disabled := this.disabled ; both the 'onEvent' and the 'onSize' properties must be set prior to set the 'disabled' one

		GUI, %_GUI%:Default
		WinExist(_lastFoundWindow)

	}
	addSource(_source, _list, _delimiter:="`n", _fileFullPath:="") {

		if _delimiter in `n,`r
			_d := "\n"
		else if (_delimiter = A_Tab)
			_d := "\t"
		else if _delimiter in \,.,*,?,+,[,],{,},|,(,),^,$ ; the characters \.*?+[{|()^$ must be preceded by a backslash to be seen as literal in regex
			_d := "\" . _delimiter
		else if not (StrLen(_delimiter) = 1)
			return !ErrorLevel:=1
		else _d := _delimiter
		_sources := eAutocomplete.sources
		, _source := _sources[_source] := {path: _fileFullPath, delimiter: _delimiter, _delimiter: _d}
		_list := _delimiter . _list . _delimiter
		Sort, _list, D%_delimiter% U
		ErrorLevel := 0
		_list := _delimiter . (_source.list := LTrim(_list, _delimiter))
		while ((_letter:=SubStr(_list, 2, 1))
		&& _pos:=RegExMatch(_list, "Psi)" . _d . "\Q" . _letter . "\E[^" . _d . "]+(.*" . _d . "\Q" . _letter . "\E.+?(?=" . _d . "))?", _length)) {
			_source[_letter] := SubStr(_list, 1, _pos + _length - 1) . _delimiter
			_list := SubStr(_list, _pos + _length)
		} ; builds a dictionary from the list

	return true
	}
	addSourceFromFile(_source, _fileFullPath, _delimiter:="`n") {
	_list := (_f:=FileOpen(_fileFullPath, 4+0, "UTF-8")).read() ; EOL: 4 > replace `r`n with `n when reading
	if (A_LastError)
		return !ErrorLevel:=1, _f.close()
		this.addSource(_source, _list, _delimiter, _fileFullPath)
	return !ErrorLevel:=0, _f.close()
	}
	setSource(_source) {
		if (eAutocomplete.sources.hasKey(_source)) {
			GUI, % this._menuWindow.HWND . ":+Delimiter" . this.sources[_source].delimiter
			this._menuReset()
			GuiControl,, % this.HWND,
		return !ErrorLevel:=0, this._source := _source
		}
		return !ErrorLevel:=1
	}
		setDimensions(_minW:="", _minH:="", _maxW:="", _maxH:="") {
		_minSz := this._minSize, ((_minW+0 <> "") && _minSz.w:=Abs(_minW)), ((_minH+0 <> "") && _minSz.h:=Abs(_minH))
		_maxSz := this._maxSize, ((_maxW+0 <> "") && _maxSz.w:=Abs(_maxW)), ((_maxH+0 <> "") && _maxSz.h:=Abs(_maxH))
		}
		dispose() {
			this.disabled := true
			this._onEvent := ""
			this._onSelect := ""
			if (this.hasKey("_szHwnd"))
				GuiControl -g, % this._szHwnd ; removes the function object bound to the control
			this._onSize := ""
			_fn := this._fnIf, _f := Func("WinActive")
			Hotkey, If, % _fn
				for _, _keyName in ["Up", "Down", "Tab", "!Left", "!Right", "Escape"]
					Hotkey, % _keyName, % _f
			Hotkey, If,
		}
	; ===============================================================================================================
	; ============================/ PUBLIC METHODS =====================================================
	; ===============================================================================================================
	; ============================ PRIVATE METHODS /=====================================================
	; ===============================================================================================================
	_setCallback(_eventName, _fn) {
	if not (IsFunc(_fn))
		return !ErrorLevel:=1
		((_fn.minParams = "") && _fn:=Func(_fn)) ; handles function references as well as function names
	return !ErrorLevel:=0, this[_eventName]:=_fn
	}
	_hotkeysShouldFire(_ahkid, _menuWindowHwnd) {
	return (DllCall("IsWindowVisible", "Ptr", _menuWindowHwnd) && WinActive(_ahkid))
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; cf. https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage 0xB0, &_startPos, &_endPos,, % this.AHKID ; EM_GETSEL
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_menuHide(_menuWindowHwnd) {
	if (DllCall("IsWindowVisible", "Ptr", _menuWindowHwnd))
		GUI % _menuWindowHwnd . ":Show", Hide
	}
	_menuSetSelection(_prm) {
		_menu := this.menu, _count := _menu._count
		if (_prm > 0) {
			Control, Choose, % (_menu._selectedItemIndex >= _count)
			? _menu._selectedItemIndex:=1 : ++_menu._selectedItemIndex,, % _menu.AHKID
		} else Control, Choose, % (_menu._selectedItemIndex <= 1)
			? (_menu._selectedItemIndex:=_count) : --_menu._selectedItemIndex,, % _menu.AHKID
		this._endWord()
	}
	_menuReset() {
	_menu := this.menu
	SendMessage, 0x0184, 0, 0,, % _menu.AHKID ; LB_RESETCONTENT
	_menu._selectedItem := "", _menu._count := _menu._selectedItemIndex := 0
	GUI % this._menuWindow.HWND . ":Show", Hide
	}
	_suggestWordList(_eHwnd) {

		_menu := this.menu, _source := eAutocomplete.sources[ this._source ]
		_match := "", _letter := ""
		ControlGetText, _input,, % this.AHKID
		_caretPos := this._getSelection()
		_vicinity := SubStr(_input, _caretPos, 2) ; the two characters in the vicinity of the current caret/insert position
		if ((StrLen(RegExReplace(_vicinity, "\s$")) <= 1)
			&& (RegExMatch(SubStr(_input, 1, _caretPos), "\S+(?P<IsWord>\s?)$", _m))
			&& (StrLen(_m) >= this.startAt)) {
				if (_mIsWord) { ; if the word is completed...
					if (this.appendHapax && !InStr(_m, "*")) {
						ControlGet, _choice, Choice,,, % _menu.AHKID
						if not ((_m:=RTrim(_m, A_Space)) = _choice) ; if it is not suggested...
							this.__hapax(SubStr(_m, 1, 1), _m) ; append it to the dictionary
					}
				} else if (_letter:=SubStr(_m, 1, 1)) {
					if (_str:=_source[_letter]) {
						_d := _source._delimiter
						if (InStr(_m, "*") && this.matchModeRegEx && (_parts:=StrSplit(_m, "*")).length() = 2) {
							_match := RegExReplace(_str
							, "`ni)" . _d . "(?!\Q" . _parts.1 . "\E[^" . _d . "]+\Q" . _parts.2 . "\E).+?(?=" . _d . ")")
							; I am particularly indebted to AlphaBravo for this regex
						} else {
							_m := "\Q" . _m . "\E"
							RegExMatch(_str, "`nsi)" . _d . _m . "[^" . _d . "]+(.*" . _d . _m . ".+?(?=" . _d . "))?", _match)
						}
					}
				}
		}
		GuiControl,, % _menu.HWND, % _match
		; SendMessage, 0x18b, 0, 0,, % _menu.AHKID ; LB_GETCOUNT
		StrReplace(_match, _source.delimiter,, _count)
		if (LTrim(_match, _source.delimiter) <> "")
			_menu._count := _count, _menu._selectedItem := "", _menu._selectedItemIndex := 0, this._menuSetPsSz()
		else this._menuReset()

		(this._onEvent && this._onEvent.call(this, _eHwnd, _input))

	}
	_menuSetPsSz(_w:=0) {

		_mHwnd := this.menu.HWND
		if (_w) {
			GuiControlGet, _pos, Pos, % _mHwnd
			GuiControl, Move, % _mHwnd, % "w" . _posw + _w * 10
		}
		_coordModeCaret := A_CoordModeCaret
			CoordMode, Caret, Screen
			if not ((A_CaretX+0 <> "") && (A_CaretY+0 <> ""))
				return
			_x := A_CaretX + 220, _y := A_CaretY + 235
			_x := (_x > A_ScreenWidth) ? A_ScreenWidth - 220 : A_CaretX + 20 ; /MonitorWorkArea
			_y :=(_y > A_ScreenHeight) ? A_ScreenHeight - 235 : A_CaretY + 35 ; /MonitorWorkArea
			(((_count:=this.menu._count) > this.maxSuggestions) && _count:=this.maxSuggestions)
			GuiControl, Move, % _mHwnd, % " h" . ++_count * this._menuWindow._lbListHeight
			GUI % this._menuWindow.HWND . ":Show", % "NA AutoSize" . Format("x{1} y{2}", _x, _y)
		CoordMode, Caret, % _coordModeCaret

	}
	_endWord(_param:=false) {

		ControlGet, _item, Choice,,, % this.menu.AHKID ; we use ControlGet instead of GuiControlGet to prevent AltSubmit from interfering
		if ((this.menu._selectedItem:=_item:=Trim(_item)) && _param)
			return
		ControlGetText, _input,, % _ahkid := this.AHKID
		_caretPos := this._getSelection(), _leftSide := SubStr(_input, 1, _caretPos), _rightSide := SubStr(_input, _caretPos + 1)
		_pos := RegExMatch(_leftSide, "P)\S+$", _length)
		StringTrimRight, _leftSide, % _leftSide, % _length ; arabic alphabets should also be considered (StringTrimLeft?)
		ControlSetText,, % _leftSide . _item . _rightSide, % _ahkid
		SendMessage, 0xB1, % _pos + 1, % _caretPos + StrLen(_item) - _length,, % _ahkid ; EM_SETSEL
		this._menuSetPsSz()

	}
	_autocomplete(_eAhkid) {
	SendMessage, 0xB1, -1,,, % _eAhkid ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
	GUI % this._menuWindow.HWND . ":Show", Hide
	ControlSend,, {Space}, % _eAhkid
	if (this.menu._selectedItemIndex)
		(this._onSelect && this._onSelect.call(this, this.menu._selectedItem))
	}
	__hapax(_letter, _value) {

		if ((_source:=eAutocomplete.sources[ this._source ]).hasKey(_letter))
			_source.list := StrReplace(_source.list, Trim(_source[_letter], _delimiter:=_source.delimiter), "")
		else _source[_letter] := ""
		_v := _source[_letter] . _value . _delimiter
		Sort, _v, D%_delimiter% U
		_source.list .= (_source[_letter]:=_v)
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, 4+1, "UTF-8")).write(LTrim(_source.list, _delimiter)), _f.close() ; EOL: 4 > replace `n with `r`n when writing
		}

	}
		__resize(_szHwnd) {

			_coordModeMouse := A_CoordModeMouse
			CoordMode, Mouse, Client

			GuiControlGet, _pos, Pos, % _eHwnd:=this.HWND
			_xStart := _posx, _yStart := _posy, _minSz := this._minSize, _maxSz := this._maxSize
			while (GetKeyState("LButton", "P")) {
				MouseGetPos, _mousex, _mousey
				_w := _mousex - _xStart, _h := _mousey - _yStart
				if (_w <= _minSz.w)
					_w := _minSz.w
				else if (_w >= _maxSz.w)
					_w := _maxSz.w
				if (_h <= _minSz.h)
					_h := _minSz.h
				else if (_h >= _maxSz.h)
					_h := _maxSz.h
				GuiControl, Move, % _eHwnd, % "w" . _w . " h" . _h
				(this._onSize && this._onSize.call(A_GUI, this, _w, _h, _mousex, _mousey))
				GuiControlGet, _pos, Pos, % _eHwnd
				GuiControl, MoveDraw, % _szHwnd, % "x" . (_posx + _posw - 7) . " y" . _posy + _posh - 7
			sleep, 15
			}
			CoordMode, Mouse, % _coordModeMouse

		}
	; ===============================================================================================================
	; ============================/ PRIVATE METHODS =====================================================
	; ===============================================================================================================
}
