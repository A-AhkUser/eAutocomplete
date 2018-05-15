Class eAutocomplete {

	/*
		Enables users to quickly find and select from a dynamic pre-populated list of suggestions based on both earlier typed
		letters and the content of a custom list as they type in an AHK Edit control.
		https://github.com/A-AhkUser/eAutocomplete
	*/
	; ===================================================================================================
	; ============================ PRIVATE PROPERTIES /===================================================
	; ===================================================================================================
	_source := "Default"
	_onEvent := ""
	_enabled := true
	_startAt := 2
	_parent := "0x0"
	_szHwnd := "0x0"
	_onSize := ""
	_cbListHwnd := "0x0"
	_fnIf := ""
	; ===================================================================================================
	; ============================/ PRIVATE PROPERTIES ===================================================
	; ===================================================================================================

	; ===================================================================================================
	; ============================ PUBLIC PROPERTIES /=====================================================
	; ===================================================================================================
	static sources := {"Default": {list: "", path: "", delimiter: "`n", _delimiter: "\n"}} ; _delimiter > used with regex

	editOptions := "w150 h35 Multi",
	menuOptions := "-VScroll r7",
	HWND := ""
	AHKID := ""
	menu :=
	(LTrim Join C
		{
			HWND: "",
			AHKID: "",
			_selectedItem: "",
			_selectedItemIndex: 0
		}
	)
	onEvent {
		set {
			this._setCallback("_onEvent", value)
		return this._onEvent
		}
		get {
		return this._onEvent
		}
	}
	useTab := false
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
	; ===================================================================================================
	; ============================/ PUBLIC PROPERTIES ====================================================
	; ===================================================================================================

	; ===================================================================================================
	; ============================ PUBLIC METHODS /=====================================================
	; ===================================================================================================
	__New(_GUIID, _options:="") {

		(_options || _options:={})
		_options.remove("disabled")
		for _option, _value in _options
			this[_option] := _value

		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		if not (WinExist("ahk_id " . _GUIID))
			return !ErrorLevel:=1
		DetectHiddenWindows % _detectHiddenWindows

		; --------------------------------------------------------------------------------------------------------------------------------------------------------- edit control
		RegExMatch(this.editOptions, "Pi)(^|\s)\K\+?[^-]?Resize(?=\s|$)", _resize) ; _resize contains 'true' if the 'Resize' option is specified
		GUI, % (this._parent:=_GUIID) . ":Add", Edit, % this.editOptions . " hwnd_eHwnd +Multi",
		this.AHKID := "ahk_id " . this.HWND:=_eHwnd
		GuiControlGet, _pos, Pos, % _eHwnd
		if (_resize) {
			GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 " . Format("x{1} y{2}", _posx + _posw - 7, _posy + _posh - 7) . " hwnd_szHwnd", % Chr(9698) ; https://unicode-table.com/fr/25E2/
			this._szHwnd := _szHwnd, _fn := this.__resize.bind(this)
			GuiControl +g, % _szHwnd, % _fn ; set the function object which handles the static control's events
		}
		; --------------------------------------------------------------------------------------------------------------------------------------------------------- combobox control
		RegExReplace(this.menuOptions, "(^|\s)\K(x|y|w|h)(\d+)", "") ; remove dimensions and/or coordinates if any - we want our own stuff happening
		GUI, % _GUIID . ":Add", ComboBox, % this.menuOptions . " +Hidden -Sort -0x800 hwnd_cbHwnd " . Format("x{1} y{2} w{3}", _posx, _posy + _posh - 7, _posw) ; CBS_DISABLENOSCROLL
		PostMessage, 0x153, -1, 0,, % this.menu.AHKID := "ahk_id " . (this.menu.HWND:=_cbHwnd) ; CB_SETITEMHEIGHT
		_fn := this._endWord.bind(this, 1)
		GuiControl +g, % _cbHwnd, % _fn ; set the function object which handles the combobox control's events
		VarSetCapacity(COMBOBOXINFO, (_cbCOMBOBOXINFO:=(A_PtrSize == 8) ? 64 : 52), 0), NumPut(_cbCOMBOBOXINFO, COMBOBOXINFO, 0, "UInt")
		this._cbListHwnd := (DllCall("GetComboBoxInfo", "Ptr", _cbHwnd, "Ptr", &COMBOBOXINFO)) ? NumGet(COMBOBOXINFO, _cbCOMBOBOXINFO - A_PtrSize, "Ptr") : ""
		; thanks much to qwerty12 > https://autohotkey.com/boards/viewtopic.php?f=5&p=187310#post_content187289
		; --------------------------------------------------------------------------------------------------------------------------------------------------------- hotkeys
		_fn := this._fnIf := this._isMenuVisible.bind("", this._cbListHwnd)
		Hotkey, If, % _fn
			_fn1 := this._menuSetSelection.bind(this, -1), _fn2 := this._menuSetSelection.bind(this, +1)
			if (this.useTab) {
				Hotkey, +Tab, % _fn1
				Hotkey, Tab, % _fn2
			} else {
				Hotkey, Up, % _fn1
				Hotkey, Down, % _fn2
			}
			_fn := this._autocomplete.bind(this, this.AHKID)
			Hotkey, Enter, % _fn
		Hotkey, If,

		this.disabled := this.disabled ; both the 'onEvent' and the 'onSize' properties must be set prior to set the 'disabled' one

	}
	addSourceFromFile(_source, _fileFullPath:="", _delimiter:="`n") {
		_list := (_f:=FileOpen(_fileFullPath, 4+0, "UTF-8")).read() ; EOL: 4 > replace `r`n with `n when reading
		if (A_LastError)
			return !ErrorLevel:=1, _f.close()
			this.addSource(_source, _list, _delimiter, _fileFullPath)
		return !ErrorLevel:=0, _f.close()
	}
	addSource(_source, _list, _delimiter:="`n", _fileFullPath:="") {

		if _delimiter in `n,`r
			_d := "\n"
		else if (_delimiter = A_Tab)
			_d := "\t"
		else if _delimiter in \,.,*,?,+,[,],{,},|,(,),^,$
			_d := "\" . _delimiter
		else if not (StrLen(_delimiter) = 1)
			return !ErrorLevel:=1
		_sources := eAutocomplete.sources, _source := _sources[_source] := {path: _fileFullPath, delimiter: _delimiter, _delimiter: _d}
		_list := _delimiter . _list . _delimiter
		Sort, _list, D%_delimiter% U
		ErrorLevel := 0
		_list := _source.list := LTrim(_list, _delimiter)
		while ((_letter:=SubStr(_list, 1, 1)) && _pos:=RegExMatch(_list, "Psi)\Q" . _letter . "\E.*" . _d . "\Q" . _letter . "\E.+?" . _d, _length)) {
			_source[_letter] := _delimiter . SubStr(_list, 1, _pos + _length - 1), _list := SubStr(_list, _pos + _length)
		} ; builds a dictionary from the list

	return true
	}
	setSource(_source) {
		if (eAutocomplete.sources.hasKey(_source)) {
			GuiControl,, % this.menu.HWND, % this.sources[ this._source ].delimiter
			GuiControl,, % this.HWND,
		return !ErrorLevel:=0, this._source := _source
		}
		return !ErrorLevel:=1
	}
	setDimensions(_minW:="", _minH:="", _maxW:="", _maxH:="") {
	_minSz := this._minSize, ((_minW+0 <> "") && _minSz.w := _minW), ((_minH+0 <> "") && _minSz.h := _minH)
	_maxSz := this._maxSize, ((_maxW+0 <> "") && _maxSz.w := _maxW), ((_maxH+0 <> "") && _maxSz.h := _maxH)
	}
	dispose() {
		this.disabled := true
		this._onEvent := ""
		if (this.hasKey("_szHwnd"))
			GuiControl -g, % this._szHwnd ; removes the function object bound to the control
		this._onSize := ""
		_fn := this._fnIf, _f := Func("WinActive")
		Hotkey, If, % _fn
			for _, _keyName in this.useTab ? ["+Tab", "Tab", "Enter"] : ["Up", "Down", "Enter"]
				Hotkey, % _keyName, % _f
		Hotkey, If,
	}
	; ===================================================================================================
	; ============================/ PUBLIC METHODS =====================================================
	; ===================================================================================================

	; ===================================================================================================
	; ============================ PRIVATE METHODS /=====================================================
	; ===================================================================================================
	_setCallback(_eventName, _fn) {
	if not (IsFunc(_fn))
		return !ErrorLevel:=1
		((_fn.minParams = "") && _fn:=Func(_fn)) ; handles function references as well as function names
	return !ErrorLevel:=0, this[_eventName]:=_fn
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; cf. https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage 0xB0, &_startPos, &_endPos,, % this.AHKID ; EM_GETSEL
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_isMenuVisible(_cbListHwnd) {
	return DllCall("IsWindowVisible", "Ptr", _cbListHwnd)
	}
	_menuSetSelection(_prm) {
		_menu := this.menu
		if (_prm > 0) {
			SendMessage, 0x0146, 0, 0,, % _menu.AHKID ; CB_GETCOUNT
			Control, Choose, % (_menu._selectedItemIndex < ErrorLevel) ? ++_menu._selectedItemIndex : ErrorLevel,, % _menu.AHKID
		} else Control, Choose, % (_menu._selectedItemIndex - 1 > 0) ? --_menu._selectedItemIndex : 1,, % _menu.AHKID
		this._endWord()
	}
	_suggestWordList(_eHwnd) {

		_menu := this.menu, _source := eAutocomplete.sources[ this._source ]
		_match := _source.delimiter
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
						if (InStr(_m, "*") && this.matchModeRegEx && (_parts:=StrSplit(_m, "*")).length() = 2) { ; if 'matchModeRegEx' is set to true, an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (dot-star pattern)
							_match := RegExReplace(_str, "`nmi)" . _d . "(?!\Q" . _parts.1 . "\E[^" . _d . "]+\Q" . _parts.2 . "\E).+?(?=" . _d . ")") ; I am particularly indebted to AlphaBravo for this regex
						} else {
							RegExMatch(_str, "`nsmi)" . _d . _m . "[^" . _d . "]+(.*" . _d . _m . ".+?(?=" . _d . "))?", _match)
						}
					}
				}
		}
		GuiControl,, % _menu.HWND, % _match
		(this._onEvent && this._onEvent.call(this, _eHwnd, _input))
		if (_match <> _source.delimiter) {
			Control, ShowDropDown,,, % _menu.AHKID
		} else Control, HideDropDown,,, % _menu.AHKID
		_menu._selectedItemIndex := 0

	}
	_endWord(_param:=false) {

		GuiControlGet, _item,, % this.menu.HWND
		if ((this.menu._selectedItem:=_item:=Trim(_item)) && _param)
			return
		_ahkid := this.AHKID
		ControlGetText, _input,, % _ahkid
		_caretPos := this._getSelection(), _leftSide := SubStr(_input, 1, _caretPos), _rightSide := SubStr(_input, _caretPos + 1)
		_pos := RegExMatch(_leftSide, "P)\S+$", _length)
		StringTrimRight, _leftSide, % _leftSide, % _length ; arabic alphabets should also be considered (StringTrimLeft?)
		ControlSetText,, % _leftSide . _item . _rightSide, % _ahkid
		SendMessage, 0xB1, % _pos + 1, % _caretPos + StrLen(_item) - _length,, % _ahkid ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)

	}
	_autocomplete(_eAhkid) {
	SendMessage, 0xB1, -1,,, % _eAhkid ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
	Control, HideDropDown,,, % this.menu.AHKID
	ControlSend,, {Space}, % _eAhkid
	if (this.menu._selectedItemIndex)
		(this._onSelect && this._onSelect.call(this, this.menu._selectedItem))
	}
	__hapax(_letter, _value) {

		if ((_source:=eAutocomplete.sources[ this._source ]).hasKey(_letter))
			_source.list := StrReplace(_source.list, _source[_letter], "")
		else _source[_letter] := ""
		_v := _source[_letter] . _value . _delimiter:=_source.delimiter
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
			(this.onSize && this.onSize.call(A_GUI, this, _w, _h, _mousex, _mousey))
			GuiControlGet, _pos, Pos, % _eHwnd
			GuiControl, MoveDraw, % _szHwnd, % "x" . (_posx + _posw - 7) . " y" . _y:=(_posy + _posh - 7)
		sleep, 15
		}
		GuiControl, Move, % this.menu.HWND, % "w" . _posw . " y" . _y - 27

		CoordMode, Mouse, % _coordModeMouse

	}
	; ===================================================================================================
	; ============================/ PRIVATE METHODS =====================================================
	; ===================================================================================================

}
