Class eAutocomplete {
	/*
		Enables users to quickly find and select from a dynamic pre-populated list of suggestions, based on both earlier
		typed letters and the content of a custom word list, as they type in an AHK Edit control.
		https://github.com/A-AhkUser/eAutocomplete
	*/
	; ===============================================================================================================
	; ============================ PRIVATE PROPERTIES /===================================================
	; ===============================================================================================================
	static _instances := [] ; keep track of instances
	_parent := "0x0" ; intended to contain the HWND of the host GUI itself
	_szHwnd := "0x0" ; intended to contain, when necessary, the HWND of the static control which allows users to resize the edit control
	_fnIf := "" ; intended to contain the function object with which are associated instance's hotkeys

	_lastSource := ""
	_lastMatch := ""
	_lastCaretPos := ""
	_lastInput := ""

	_source := "Default"
	_startAt := 2
	_regexSymbol := "*"
	_onEvent := ""
	_onSize := ""
	_minSize := {w: 51, h: 21}
	_maxSize := {w: A_ScreenWidth, h: A_ScreenHeight}
	; ===============================================================================================================
	; ============================/ PRIVATE PROPERTIES ===================================================
	; ===============================================================================================================
	; ============================ PUBLIC PROPERTIES /=====================================================
	; ===============================================================================================================
	static sources := {"Default": {list: "", path: "", delimiter: "`n", _delimiter: "\n"}}
	disabled {
		set {
			((this._enabled:=!value) || this.menu._reset())
		return value
		}
		get {
		return !this._enabled
		}
	}
	startAt {
		set {
		return (ErrorLevel:=not (value > 0)) ? this["_startAt"] : this["_startAt"]:=value
		}
		get {
		return this._startAt
		}
	}
	regexSymbol {
		set {
		return (ErrorLevel:=not (StrLen(value) = 1)) ? this["_regexSymbol"] : this["_regexSymbol"]:=value
		}
		get {
		return this._regexSymbol
		}
	}
	onEvent {
		set {
			this._setCallback(this, "_onEvent", value)
		return this._onEvent
		}
		get {
		return this._onEvent
		}
	}
	onSize {
		set {
			this._setCallback(this, "_onSize", value)
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
	create(_GUIID, _opt:="") {
	return new eAutocomplete(_GUIID, _opt)
	}
	attach(_GUIID, _eHwnd, _opt:="") {
	return new eAutocomplete(_GUIID, _opt, _eHwnd)
	}
	__New(_GUIID, _opt:="", _eHwnd:="0x0") {

		_GUI := A_DefaultGUI, _lastFoundWindow := WinExist() ; get both the default and the 'last found' GUI windows in order to restore them later
		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		if not (WinExist("ahk_id " . this._parent:=_GUIID)) {
			GUI, %_GUI%:Default
			WinExist(_lastFoundWindow)
			DetectHiddenWindows % _detectHiddenWindows
		return !ErrorLevel:=1
		}
		DetectHiddenWindows % _detectHiddenWindows

		WinGet, _PID, PID, % this.AHKID := "ahk_id " . (this.HWND:=_eHwnd)
		this._hWinEventHook := SetWinEventHook("0x800B", "0x800B", 0, RegisterCallback("eAutocomplete_EventMonitor"), _PID, 0, 0) ;EVENT_OBJECT_LOCATIONCHANGE

		if not (_eHwnd) { ; create
			GUI, % _GUIID . ":Add", Edit, % _opt.editOptions . " hwnd_eHwnd",
			this.AHKID := "ahk_id " . (this.HWND:=_eHwnd)
			RegExMatch(_opt.editOptions, "Pi)(^|\s)\K\+?[^-]?Resize(?=\s|$)", _resize) ; matchs if the '(+)Resize' option is specified
			if (_resize) {
				GuiControlGet, _pos, Pos, % _eHwnd
				GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 " . Format("x{1} y{2}", _posx + _posw - 7, _posy + _posh - 7) . " hwnd_szHwnd"
				; , % Chr(9698) ; https://unicode-table.com/fr/25E2/
				this._szHwnd := _szHwnd, _fn := this.__resize.bind(this)
				GuiControl +g, % _szHwnd, % _fn ; set the function object which handles the static control's events
			}
		}
		if (IsObject(_opt)) {
			this.autoAppend := _opt.hasKey("autoAppend") ? !!_opt.autoAppend : false
			this.matchModeRegEx := _opt.hasKey("matchModeRegEx") ? !!_opt.matchModeRegEx : true
			this.appendHapax := _opt.hasKey("appendHapax") ? !!_opt.appendHapax : false
			(_opt.hasKey("startAt") && this.startAt:=_opt.startAt)
			(_opt.hasKey("regexSymbol") && this.regexSymbol:=_opt.regexSymbol)
			(_opt.hasKey("onEvent") && this.onEvent:=_opt.onEvent)
			(_opt.hasKey("onSize") && this.onSize:=_opt.onSize)
		} else _opt:={}

		_menu := this.menu
		:= new eAutocomplete.Menu(this,_opt.maxSuggestions,_opt.menuBackgroundColor,_opt.menuFontName,_opt.menuFontOptions)
		(_opt.hasKey("onSelect") && _menu.onSelect:=_opt.onSelect)

		_fn := this._fnIf := this._hotkeysShouldFire.bind("", "ahk_id " . _GUIID, _menu._parent)
		; once passed to the Hotkey command, an object is never deleted, hence the empty string
		Hotkey, If, % _fn
			_fn1 := _menu._setSelection.bind(_menu, -1), _fn2 := _menu._setSelection.bind(_menu, +1)
			Hotkey, Up, % _fn1
			Hotkey, Down, % _fn2 ; use both the Down and Up arrow keys to select from the list of available suggestions
			_fn1 := _menu._setSz.bind(_menu, _multiplier:=-1), _fn2 := _menu._setSz.bind(_menu, _multiplier:=1)
			Hotkey, !Left, % _fn1
			Hotkey, !Right, % _fn2 ; use Alt+Left and Alt+Right keyboard shortcuts to respectively shrink/expand the menu
			_fn := _menu._reset.bind(_menu, _autocomplete:=true)
			Hotkey, Tab, % _fn ; press Tab key to select an item from the drop-down list
			_fn := _menu._reset.bind(_menu)
			Hotkey, Escape, % _fn ; the drop-down list can be closed by pressing the ESC key
			_fn := this._sendEnter.bind(this)
			Hotkey, Enter, % _fn
			_fn := this._sendBackspace.bind(this)
			Hotkey, BackSpace, % _fn
		Hotkey, If,

		this.disabled := _opt.hasKey("disabled") ? !!_opt.disabled : false
		this.setSource("Default")

		GUI, %_GUI%:Default
		WinExist(_lastFoundWindow)

	return eAutocomplete._instances[_eHwnd] := this
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
		, _source := _sources[_source] := {list: "", path: _fileFullPath, delimiter: _delimiter, _delimiter: _d}
		_list := _delimiter . _list . _delimiter
		Sort, _list, D%_delimiter% U
		ErrorLevel := 0
		_list := _delimiter . (_source.list .= LTrim(_list, _delimiter))

		while (_letter:=SubStr(_list, 2, 1)) { ; a new letter in the sorted list
			if not (_pos:=RegExMatch(_list, "Psi)" _d "\Q" _letter "\E[^" _d "]+(.*" _d "\Q" _letter "\E.+?(?=" _d "))?", _length))
				break
			_source[_letter] := SubStr(_list, 1, _pos + _length - 1) . _delimiter
			_list := SubStr(_list, _pos + _length)
		} ; builds a dictionary (subsections) from the list

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
			GUI, % this.menu._parent . ":+Delimiter" . this.sources[_source].delimiter
			this.menu._reset()
		return !ErrorLevel:=0, this._source := _source, this._lastSource := eAutocomplete.sources[_source]
		}
		return !ErrorLevel:=1
	}
		dispose() { ; only useful if a __Delete meta-function is defined
			this._onEvent := ""
			this.menu._onSelect := ""
			if (this.hasKey("_szHwnd"))
				GuiControl -g, % this._szHwnd ; removes the function object bound to the control
			this._onSize := ""
			_fn := this._fnIf, _f := Func("WinActive")
			Hotkey, If, % _fn
				for _, _keyName in ["Up", "Down", "Tab", "!Left", "!Right", "Escape", "BackSpace", "Enter"]
					Hotkey, % _keyName, % _f
			Hotkey, If,
			this.menu := ""
			eAutocomplete._instances[ this.HWND ] := ""
			UnhookWinEvent(this._hWinEventHook)
		}
	; ===============================================================================================================
	; ============================/ PUBLIC METHODS =====================================================
	; ===============================================================================================================
	; ============================ PRIVATE METHODS /=====================================================
	; ===============================================================================================================
	_setCallback(_source, _eventName, _fn) {
	if not (IsFunc(_fn))
		return !ErrorLevel:=1
		((_fn.minParams = "") && _fn:=Func(_fn)) ; handles function references as well as function names
	return !ErrorLevel:=0, _source[_eventName]:=_fn
	}
	_hotkeysShouldFire(_ahkid, _menuParentHwnd) {
	return (DllCall("IsWindowVisible", "Ptr", _menuParentHwnd) && WinActive(_ahkid))
	}
	_sendBackspace() {
		if not (this.autoAppend) {
			ControlSend,, {BackSpace}, % this.AHKID
		return
		}
		this.menu._reset()
		ControlSetText,, % this._lastInput, % this.AHKID
		_pos := this._lastCaretPos
		SendMessage, 0xB1, % _pos, % _pos,, % this.AHKID ; EM_SETSEL
	}
	_sendEnter() {
	this.menu._reset()
	ControlSend,, {Enter}, % this.AHKID
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; cf. https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage 0xB0, &_startPos, &_endPos,, % this.AHKID ; EM_GETSEL
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_suggestWordList(_eHwnd) {

		static _shouldAvoidRecursion := false ; used to avoid a g-label recursion

		if (_shouldAvoidRecursion)
			return
		_shouldAvoidRecursion := true
		ControlGet, _column, CurrentCol,,, % this.AHKID
		if not (_column - 1)
			return "", _shouldAvoidRecursion := false
		_menu := this.menu, _source := this._lastSource, _match := ""

		ControlGetText, _input,, % this.AHKID
		_caretPos := this._getSelection()

		if ((StrLen(RegExReplace(SubStr(_input, _caretPos, 2), "\s$")) <= 1)
			&& (RegExMatch(SubStr(_input, 1, _caretPos), "\S+(?P<IsWord>" A_Space "?)$", _m))
			&& (StrLen(this._lastMatch:=_m) >= this.startAt))
			{
			_regExMode := (this.matchModeRegEx && (_wildcard:=InStr(_m, this._regexSymbol)))
				if (_mIsWord) { ; if the word is completed...
					if (this.appendHapax && !_wildcard) {
						ControlGet, _choice, Choice,,, % _menu.AHKID
						if not ((_m:=Trim(_m, A_Space)) = _choice) ; if it is not suggested...
							this.__hapax(SubStr(_m, 1, 1), _m) ; append it to the dictionary
					}
				} else if (_letter:=SubStr(_m, 1, 1)) {
					if (_str:=_source[_letter]) {
						_d := _source._delimiter
						if (_regExMode && (_p:=StrSplit(_m, this._regexSymbol)).length() = 2) {
							_match := RegExReplace(_str, "`ni)" . _d . "(?!\Q" . _p.1 . "\E[^" . _d . "]+\Q" . _p.2 . "\E).+?(?=" . _d . ")")
							; remove all irreleavant lines from the subsection of the dictionary. I am particularly indebted to AlphaBravo for this regex
						} else {
							_q := "\Q" . _m . "\E"
							RegExMatch(_str, "`nsi)" . _d . _q . "[^" . _d . "]+(.*" . _d . _q . ".+?(?=" . _d . "))?", _match)
						}
					}
				}
			}

		if (LTrim(_match, _d:=_source.delimiter) <> "") {
			StrReplace(_match, _d,, _count)
			((_count > 132 && _count:=132) && _match:=SubStr(_match, 1, InStr(_match, _d,,, 132))) ; 133 - 1
			GuiControl,, % _menu.HWND, % _match
			_menu._lbCount := _count
			_menu._selectedItemIndex:= 0, _menu._setSelection((this.autoAppend && !_regExMode), _update:=true)
			_menu._setSz(), _menu._setPos() ; update the size and the position of the menu
		} else _menu._reset()
		(this._onEvent && this._onEvent.call(this, _eHwnd, _input))

		return "", _shouldAvoidRecursion := false

	}
	__hapax(_letter, _value) {

		_source := this._lastSource, _delimiter:=_source.delimiter
		if (_source.hasKey(_letter))
			_source.list := StrReplace(_source.list, Trim(_source[_letter], _delimiter), "")
		else _source[_letter] := _delimiter
		_v := _source[_letter] . _value . _delimiter ; append the hapax legomenon to the dictionary's subsection
		Sort, _v, D%_delimiter% U
		_source.list .= (_source[_letter]:=_v), _source.list := LTrim(_source.list, _delimiter)
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, 4+1, "UTF-8")).write(_source.list), _f.close() ; EOL: 4 > replace `n with `r`n when writing
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

	; ===============================================================================================================

		Class Menu {

			_parent := "0x0" ; intended to contain the HWND of the GUI itself
			_lastWidth := 0
			_lastHeight := 0

			__New(_owner, _maxSuggestions:=7, _bkColor:="", _ftName:="", _ftOptions:="") {

				this._owner := _owner
				this._selectedItem := "", this._selectedItemIndex := 0 := this._lbCount := 0
				this.maxSuggestions := _maxSuggestions
				GUI, New, % "+hwnd_menuParentHwnd +LastFound +ToolWindow -Caption +E0x20 +Owner" . _owner._parent
				GUI, Color,, % _bkColor
				GUI, Font, % _ftOptions, % _ftName
				WinSet, Transparent, 255 ; in order to actually apply the +E0x20 extended style
				this._parent := _menuParentHwnd
				GUI, Margin, 0, 0
				GUI, Add, ListBox, x0 y0 -HScroll +VScroll Choose0 -Multi +Sort hwnd_lbHwnd,
				SendMessage, 0x1A1, 0, 0,, % this.AHKID := "ahk_id " . (this.HWND:=_lbHwnd) ; LB_GETITEMHEIGHT
				this._lbListHeight := ErrorLevel

			}
			onSelect {
				set {
					this._owner._setCallback(this, "_onSelect", value)
				return this._onSelect
				}
				get {
				return this._onSelect
				}
			}
			; ==========================================================================================================
			_setSelection(_prm:=0, _update:=false) {

				_owner := this._owner
				ControlGetText, _input,, % _ahkid := _owner.AHKID
				_caretPos := _owner._getSelection()
				_rightSide := SubStr(_input, _caretPos + 1), _leftSide := SubStr(_input, 1, _caretPos)
				if (_update) {
					_owner._lastCaretPos := _caretPos
					_owner._lastInput := _input
				}

				_count := this._lbCount
				if not (_prm) {
					this._selectedItem := "", this._selectedItemIndex := 0
				return
				} else if (_prm > 0) {
					Control, Choose, % (this._selectedItemIndex >= _count)
					? this._selectedItemIndex:=1 : ++this._selectedItemIndex,, % this.AHKID
				} else Control, Choose, % (this._selectedItemIndex <= 1)
					? (this._selectedItemIndex:=_count) : --this._selectedItemIndex,, % this.AHKID
				ControlGet, _item, Choice,,, % this.AHKID ; we use ControlGet instead of GuiControlGet to prevent AltSubmit from interfering
				this._selectedItem := _item

				_pos := RegExMatch(_leftSide, "P)\S+$", _length) ; matches the last entered word starting from the left-hand side of the caret/insert current position
				StringTrimRight, _leftSide, % _leftSide, % _length ; arabic alphabets should also be considered (StringTrimLeft?)
				ControlSetText,, % _leftSide . _item . _rightSide, % _ahkid ; inserts the selected item in the string
				SendMessage, 0xB1, % _pos + StrLen(_owner._lastMatch) - 1, % _caretPos + StrLen(_item) - _length,, % _ahkid ; EM_SETSEL
				this._setPos()

			}
			_setSz(_multiplier:=0) {
				_mHwnd := this.HWND
				GuiControlGet, _pos, Pos, % _mHwnd
				GuiControl, Move, % _mHwnd, % "w" . this._lastWidth:=_posw + _multiplier * 10
				(((_count:=this._lbCount) > this.maxSuggestions) && _count:=this.maxSuggestions)
				GuiControl, Move, % _mHwnd, % " h" . this._lastHeight:=++_count * this._lbListHeight
				GUI % this._parent . ":Show", NA AutoSize
			}
			_setPos(_coerce:=1) {

				_hwnd := this._parent
				if not (_coerce || DllCall("IsWindowVisible", "Ptr", _hwnd))
					return
				_coordModeCaret := A_CoordModeCaret
				CoordMode, Caret, Screen
					if not ((A_CaretX+0 <> "") && (A_CaretY+0 <> "")) {
						CoordMode, Caret, % _coordModeCaret
					return
					}
					_x1 := A_CaretX + 20, _y1 := A_CaretY + 35
					_x2 := _x1 + this._lastWidth, _y2 := _y1 + this._lastHeight
					_x := (_x2 > A_ScreenWidth) ? A_ScreenWidth - this._lastWidth : _x1
					_y :=(_y2 > A_ScreenHeight) ? A_ScreenHeight - this._lastHeight : _y1
					GUI % _hwnd . ":Show", % "NA AutoSize" . Format("x{1} y{2}", _x, _y)
				CoordMode, Caret, % _coordModeCaret

			}
			_reset(_autocomplete:=false) {

				_ahkid := this._owner.AHKID
				SendMessage, 0xB1, -1,,, % _ahkid ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
				if (_autocomplete) {
					_selectedItemIndex := this._selectedItemIndex, _selectedItem := this._selectedItem
					if not (_selectedItemIndex)
						return this._setSelection(+1, true)
					ControlSend,, {Space}, % _ahkid
					if (_selectedItemIndex)
						((_fn:=this._onSelect) && _fn.call(this, _selectedItem))
				} else SendMessage, 0x0184, 0, 0,, % _ahkid ; LB_RESETCONTENT
				this._selectedItem := "", this._selectedItemIndex := this._lbCount := 0
				GUI % this._parent . ":Show", Hide

			}

		}

}
eAutocomplete_EventMonitor(_hWinEventHook, _event, _hwnd) {
_listLines := A_ListLines
ListLines, Off
	static _menu := "", _parent := "", _input := ""
	if (_i:=eAutocomplete._instances[_hwnd]) { ; if the event source is the edit control...
		_menu := _i.menu, _parent := "ahk_id " . _i._parent
		ControlGetText, _text,, % _i.AHKID
		if (_text <> _input) {
			if not (_i.disabled) {
				_i._suggestWordList(_hwnd)
			}
			_input := _text
		}
	} else if (_parent) ; if the event source is the GUI itself...
		(_menu && _menu._setPos(false))
ListLines % _listLines ? "On" : "Off"
}
SetWinEventHook(_eventMin, _eventMax, _hmodWinEventProc, _lpfnWinEventProc, _idProcess, _idThread, _dwFlags) {
   DllCall("CoInitialize", "Uint", 0)
   return DllCall("SetWinEventHook"
			, "Uint", _eventMin
			, "Uint", _eventMax
			, "Ptr", _hmodWinEventProc
			, "Ptr", _lpfnWinEventProc
			, "Uint", _idProcess
			, "Uint", _idThread
			, "Uint", _dwFlags)
} ; cf. https://autohotkey.com/boards/viewtopic.php?t=830
UnhookWinEvent(_hWinEventHook) {
    _v := DllCall("UnhookWinEvent", "Ptr", _hWinEventHook)
    DllCall("CoUninitialize")
return _v
} ;  cf. https://autohotkey.com/boards/viewtopic.php?t=830
