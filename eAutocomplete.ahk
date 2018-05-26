Class eAutocomplete {
	/*
		see also: https://github.com/A-AhkUser/eAutocomplete#eautocomplete
		; --------------- description ---------------
			The script enables users, as typing in an Edit control, to quickly find and select from a dynamic pre-populated list of suggestions
			and, by this means, to expand partially entered strings into complete strings. When a user starts to type in the edit control, a
			listbox should display suggestions to complete the word, based both on earlier typed letters and the content of a custom list.
		; --------------- links ---------------
			SetWinEventHook function: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373640(v=vs.85).aspx
				- WinEventProc callback function: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373885(v=vs.85).aspx
				- Event Constants: https://msdn.microsoft.com/en-us/library/windows/desktop/dd318066(v=vs.85).aspx
				- Object Identifiers: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373606(v=vs.85).aspx
				- [LIB] EWinHook - SetWinEventHook implementation: https://autohotkey.com/boards/viewtopic.php?t=830
			Edit control messages: https://msdn.microsoft.com/en-us/library/windows/desktop/ff485923(v=vs.85).aspx
			Edit.ahk: https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
			ListBox control messages: https://msdn.microsoft.com/en-us/library/windows/desktop/ff485967(v=vs.85).aspx
		; --------------- AutoHotkey version ---------------
			1.1.28.00 unicode x32
		; --------------- OS version ---------------
			Windows 8.1
		; --------------- version ---------------
			1.0.00
		; --------------- revision history ---------------
			1.0.00 *initial release* (2018/12/21)
		; --------------- acknowledgements ---------------
			. Thanks to brutus_skywalker for his valuable suggestions on how to make more ergonomic and user-friendly the common
				features provided by the script via the use of keyboard shortcuts.
			. Thanks to jeeswg for sharing its knowlegde.
			. Thanks to AlphaBravo for its decisive help on regular expressions.
	*/
	; ===============================================================================================================
	; ============================ PRIVATE PROPERTIES /===================================================
	; ===============================================================================================================
	static _CID := {}
	static _GUIID := {}
	_parent := "0x0" ; intended to contain the HWND of the host GUI itself
	_szHwnd := "0x0" ; intended to contain, when necessary, the HWND of the static control which allows users to resize the edit control
	_fnIf := "" ; intended to contain the function object with which are associated instance's hotkeys

	_lastSourceAsObject := ""
	; --------------------------------------------------------
	_lastUncompleteWord := ""
	_lastInterimEditContent := ""
	_lastCaretPos := ""
	; --------------------------------------------------------

	_startAt := 2 ; used as default value
	_regexSymbol := "*" ; used as default value
	_onEvent := "" ; used as default value
	_onSize := "" ; used as default value
	_minSize := {w: 51, h: 21} ; default values used internally by __resize
	_maxSize := {w: A_ScreenWidth, h: A_ScreenHeight} ; default values used internally by __resize
	; ===============================================================================================================
	; ============================/ PRIVATE PROPERTIES ===================================================
	; ===============================================================================================================
	; ============================ PUBLIC PROPERTIES /=====================================================
	; ===============================================================================================================
	static sources := {"Default": {list: "", path: "", delimiter: "`n", _delimiterRegExSymbol: "\n"}}
	disabled {
		set {
			((this._enabled:=!this._shouldAvoidRecursion:=value) || this.menu._submit())
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
	autoAppend := false
	regexSymbol {
		set {
		return (ErrorLevel:=not (StrLen(value) = 1)) ? this["_regexSymbol"] : this["_regexSymbol"]:=value
		}
		get {
		return this._regexSymbol
		}
	}
	matchModeRegEx := true
	appendHapax := false
	onEvent {
		set {
			eAutocomplete._setCallback(this, "_onEvent", value)
		return this._onEvent
		}
		get {
		return this._onEvent
		}
	}
	onSize {
		set {
			eAutocomplete._setCallback(this, "_onSize", value)
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
		_hLastFoundWindow := WinExist()
		try Gui % _GUIID ":+LastFoundExist"
		IfWinNotExist
			throw ErrorLevel:=2
		WinExist("ahk_id " . _hLastFoundWindow)
	return new eAutocomplete(_GUIID, _opt)
	}
	attach(_hEdit, _opt:="") {
		VarSetCapacity(_class, 256, 0)
		DllCall("GetClassName", "Ptr", _hEdit, "Str", _class, "Int", 255) ; https://autohotkey.com/board/topic/45627-function-control-getclassnn-get-a-control-classnn/
		if not (_class ~= "^Edit") ; should be sufficient
			throw ErrorLevel:=1
		if not (_GUIID:=DllCall("user32\GetAncestor", "Ptr", _hEdit, "UInt", 2, "Ptr")) ; GA_ROOT since it may be the child of a combobox
		; thanks to jeeswg here: https://autohotkey.com/boards/viewtopic.php?f=5&t=49374
			throw ErrorLevel:=2
	return new eAutocomplete(_GUIID, _opt, "Edit", _hEdit)
	}
	__New(_GUIID, _opt:="", _class:="Edit", _hEdit:="0x0") {

		this._parent := _GUIID, this.class := _class

		_PID := "", DllCall("User32.dll\GetWindowThreadProcessId", "Ptr", _GUIID, "UIntP", _PID, "UInt") ; DllCall also works with hidden windows, as the case may be
		; https://github.com/flipeador/AutoHotkey/blob/master/Lib/window/GetWindowThreadProcessId.ahk
		this._winEventObjectLocationChangeEventHook
			:= SetWinEventHook(0x800B, 0x800B, 0, RegisterCallback("eAutocomplete._locationChangeEventMonitor"), _PID, 0, 0) ; EVENT_OBJECT_LOCATIONCHANGE
		this._winEventObjectDestroyEventHook
			:= SetWinEventHook(0x8001, 0x8001, 0, RegisterCallback("eAutocomplete._objectDestroyEventMonitor"), _PID, 0, 0) ; EVENT_OBJECT_DESTROY
		this._winEventObjectTextSelectionChangedEventHook
			:= SetWinEventHook(0x8014, 0x8014, 0, RegisterCallback("eAutocomplete._objectTextSelectionChangedEventMonitor"), _PID, 0, 0) ; EVENT_OBJECT_TEXTSELECTIONCHANGED

		if not (_hEdit) { ; create ?
			GUI, % _GUIID . ":Add", Edit, % _opt.editOptions . " hwnd_hEdit",
			this.AHKID := "ahk_id " . (this.HWND:=_hEdit)
			if (_opt.editOptions ~= "i)(^|\s)\K\+?[^-]?Resize(?=\s|$)") { ; matchs if the '(+)Resize' option is specified
				GuiControlGet, _pos, Pos, % _hEdit
				GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 " . Format("x{1} y{2}", _posx + _posw - 7, _posy + _posh - 7) . " hwnd_hSz",
				this._hSz := _hSz, _fn := this.__resize.bind(this)
				GuiControl +g, % _hSz, % _fn ; set the function object which handles the static control's events
			}
		} else ; otherwise, attach
			this.AHKID := "ahk_id " . (this.HWND:=_hEdit)

		if (IsObject(_opt)) {
			this.matchModeRegEx := _opt.hasKey("matchModeRegEx") ? !!_opt.matchModeRegEx : true
			this.autoAppend := _opt.hasKey("autoAppend") ? !!_opt.autoAppend : false
			this.appendHapax := _opt.hasKey("appendHapax") ? !!_opt.appendHapax : false
			; setters >>>>>>>>>>
			(_opt.hasKey("startAt") && this.startAt:=_opt.startAt)
			(_opt.hasKey("regexSymbol") && this.regexSymbol:=_opt.regexSymbol)
			(_opt.hasKey("onEvent") && this.onEvent:=_opt.onEvent)
			(_opt.hasKey("onSize") && this.onSize:=_opt.onSize)
			; <<<<<<<<<< setters
		}

		_menu
			:= this.menu
			:= new eAutocomplete.Menu(this,_opt.maxSuggestions,_opt.menuBackgroundColor,_opt.menuFontName,_opt.menuFontOptions)
			(_opt.hasKey("onSelect") && _menu.onSelect:=_opt.onSelect) ; set the function object which handles the menu control's events

		_fn := this._fnIf := this._hotkeysShouldFire.bind("", "ahk_id " . _GUIID, _menu._parent)
		; once passed to the Hotkey command, an object is never deleted, hence the empty string
		Hotkey, If, % _fn
			_fn1 := ObjBindMethod(_menu, "_setChoice", -1), _fn2 := ObjBindMethod(_menu, "_setChoice", +1)
			Hotkey, Up, % _fn1
			Hotkey, Down, % _fn2 ; use both the Down and Up arrow keys to select from the list of available suggestions
			; _fn1 := ObjBindMethod(_menu, "_setSz" _multiplier:=-1), _fn2 := ObjBindMethod(_menu, "_setSz", _multiplier:=1) ; doesn't work...
			_fn1 := _menu._setSz.bind(_menu, _multiplier:=-1), _fn2 := _menu._setSz.bind(_menu, _multiplier:=1)
			Hotkey, !Left, % _fn1
			Hotkey, !Right, % _fn2 ; use Alt+Left and Alt+Right keyboard shortcuts to respectively shrink/expand the menu
			_fn := ObjBindMethod(_menu, "_submit", _autocomplete:=true)
			Hotkey, Tab, % _fn ; press Tab key to select an item from the drop-down list
			_fn := ObjBindMethod(_menu, "_submit", _autocomplete:=false)
			Hotkey, Escape, % _fn ; the drop-down list can be closed by pressing the ESC key
			_fn := ObjBindMethod(this, "_sendEnter")
			Hotkey, Enter, % _fn
			_fn := ObjBindMethod(this, "_sendBackspace")
			Hotkey, BackSpace, % _fn
		Hotkey, If,

		this.disabled := _opt.hasKey("disabled") ? !!_opt.disabled : false
		this.setSource("Default")

	return eAutocomplete._GUIID[_GUIID] := eAutocomplete._CID[_hEdit] := this ; return the instance having beforehand storing it in the base object
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

		_source := eAutocomplete.sources[_source] := {list: "", path: _fileFullPath, delimiter: _delimiter, _delimiterRegExSymbol: _d}
		_list := _delimiter . _list . _delimiter
		Sort, _list, D%_delimiter% U ; CL
		ErrorLevel := 0 ; ErrorLevel is changed by Sort when the U option is in effect
		_list := _delimiter . (_source.list .= LTrim(_list, _delimiter))

		while (_letter:=SubStr(_list, 2, 1)) { ; for each initial letter in the sorted list...
			if not (_pos:=RegExMatch(_list, "Psi)" _d "\Q" _letter "\E[^" _d "]+(.*" _d "\Q" _letter "\E.+?(?=" _d "))?", _length))
				break
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
			GUI, % this.menu._parent . ":+Delimiter" . this.sources[_source].delimiter
			this.menu._submit()
		return !ErrorLevel:=0, this._source := _source, this._lastSourceAsObject := eAutocomplete.sources[_source]
		}
		return !ErrorLevel:=1
	}
		dispose() {
			if not (this.menu) ; ~= if the method has already been called...
				return
			_fn := this._fnIf, _f := Func("WinActive")
			Hotkey, If, % _fn
			for _, _keyName in ["Up", "Down", "Tab", "!Left", "!Right", "Escape", "BackSpace", "Enter"]
				Hotkey, % _keyName, % _f ; release circular references so that the object can be freed
			Hotkey, If,
			this.menu := this.menu._onSelect := ""
			this._onEvent := ""
			if (this.hasKey("_hSz")) {
				GuiControl -g, % this._hSz ; removes the function object bound to the control
				this._onSize := ""
			}
			eAutocomplete._GUIID.delete(this._parent), eAutocomplete._CID.delete(this.HWND)
			UnhookWinEvent(this._winEventObjectLocationChangeEventHook)
			UnhookWinEvent(this._winEventObjectDestroyEventHook)
			UnhookWinEvent(this._winEventObjectTextSelectionChangedEventHook)
			MsgBox % A_ThisFunc
		}
		__Delete() {
		MsgBox % A_ThisFunc
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

	_hotkeysShouldFire(_ahkid, _menuParent) {
	return (DllCall("IsWindowVisible", "Ptr", _menuParent) && WinActive(_ahkid))
	}
	_sendBackspace() {
		if not (this.autoAppend) {
			ControlSend,, {BackSpace}, % this.AHKID
		return
		}
		this.menu._submit()
		this._setText(this._lastInterimEditContent)
		sleep, 0
		_pos := this._lastCaretPos, this._setSelection(_pos, _pos)

	}
	_sendEnter() {
	this.menu._submit()
	ControlSend,, {Enter}, % this.AHKID
	}

	_getText(ByRef _text) {
	ControlGetText, _text,, % this.AHKID
	}
	_setText(_text) {
		static WM_SETTEXT := 0xC
		SendMessage % WM_SETTEXT, 0, &_text,, % this.AHKID
	return ErrorLevel
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		static EM_GETSEL := 0xB0
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage, % EM_GETSEL, &_startPos, &_endPos,, % this.AHKID
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_setSelection(_startSel:=-1, _endSel:="") {
		static EM_SETSEL := 0xB1
		SendMessage % EM_SETSEL, % _startSel, % _endSel,, % this.AHKID
	}

	_suggestWordList(_hEdit) {

		this._shouldAvoidRecursion := true
		ControlGet, _column, CurrentCol,,, % this.AHKID
		if not (_column - 1)
			return "", this._shouldAvoidRecursion := false

		_source := this._lastSourceAsObject, _menu := this.menu
		this._getText(_input), _caretPos := this._getSelection()
		this._lastUncompleteWord := _match := ""

		if ((StrLen(RegExReplace(SubStr(_input, _caretPos, 2), "\s$")) <= 1)
			&& (RegExMatch(SubStr(_input, 1, _caretPos), "\S+(?P<IsWord>" A_Space "?)$", _m))
			&& (StrLen(this._lastUncompleteWord:=_m) >= this.startAt))
			{
			_regExMode := (this.matchModeRegEx && (_wildcard:=InStr(_m, this._regexSymbol)))
				if (_mIsWord) { ; if the word is completed...
					if (this.appendHapax && !_wildcard) {
						ControlGet, _choice, Choice,,, % _menu.AHKID
						if not ((_m:=Trim(_m, A_Space)) = _choice) ; if it is not suggested...
							this.__hapax(SubStr(_m, 1, 1), _m) ; append it to the dictionary
					}
				} else if (_str:=_source[ SubStr(_m, 1, 1) ]) {
					_d := _source._delimiterRegExSymbol
					if (_regExMode && (_p:=StrSplit(_m, this._regexSymbol)).length() = 2) {
						this._lastUncompleteWord := [ _p.1, _p.2 ]
						_match := RegExReplace(_str, "`ni)" . _d . "(?!\Q" . _p.1 . "\E[^" . _d . "]+\Q" . _p.2 . "\E).+?(?=" . _d . ")")
						; remove all irreleavant lines from the subsection of the dictionary. I am particularly indebted to AlphaBravo for this regex
					} else {
						_q := "\Q" . _m . "\E"
						RegExMatch(_str, "`nsi)" . _d . _q . "[^" . _d . "]+(.*" . _d . _q . ".+?(?=" . _d . "))?", _match)
					}
				}
			}
			if (LTrim(_match, _d:=_source.delimiter) <> "") {
				StrReplace(RTrim(_match, _d), _d,, _count)
				((_count > 132 && _count:=132) && _match:=SubStr(_match, 1, InStr(_match, _d,,, 132)))
				_menu._lbCount := _count, _menu._setSz() ; update the size of the menu according to the new item count
				GuiControl,, % _menu.HWND, % _match
				_menu._selectedItemIndex:= 0, _menu._setChoice((this.autoAppend && !_regExMode), _update:=true)
			} else _menu._submit()
			(this._onEvent && this._onEvent.call(this, _hEdit, _input))

	return "", this._shouldAvoidRecursion := false
	}
	__hapax(_letter, _value) {
		_source := this._lastSourceAsObject, _delimiter := _source.delimiter
		if (_source.hasKey(_letter))
			_source.list := StrReplace(_source.list, Trim(_source[_letter], _delimiter), "")
		else _source[_letter] := _delimiter
		_v := _source[_letter] . _value . _delimiter ; append the hapax legomenon to the dictionary's subsection
		Sort, _v, D%_delimiter% U ; CL
		_source.list .= (_source[_letter]:=_v), _source.list := LTrim(_source.list, _delimiter)
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, 4+1, "UTF-8")).write(_source.list), _f.close() ; EOL: 4 > replace `n with `r`n when writing
		}
	}
		__resize(_szHwnd) {

			_coordModeMouse := A_CoordModeMouse
			CoordMode, Mouse, Client

			GuiControlGet, _pos, Pos, % _hEdit:=this.HWND
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
				GuiControl, Move, % _hEdit, % "w" . _w . " h" . _h
				(this._onSize && this._onSize.call(A_GUI, this, _w, _h, _mousex, _mousey))
				GuiControlGet, _pos, Pos, % _hEdit
				GuiControl, MoveDraw, % _szHwnd, % "x" . (_posx + _posw - 7) . " y" . _posy + _posh - 7
			sleep, 15
			}
			CoordMode, Mouse, % _coordModeMouse

		}
	; ===============================================================================================================
	; ============================/ PRIVATE METHODS =====================================================
	; ===============================================================================================================

		Class Menu {

			_parent := "0x0" ; intended to contain the HWND of the GUI itself
			_lastWidth := 0
			_lastHeight := 0

			__New(_owner, _maxSuggestions:=7, _bkColor:="", _ftName:="", _ftOptions:="") {

				_GUI := A_DefaultGUI
				this._owner := _owner
				this._selectedItem := "", this._selectedItemIndex := 0 := this._lbCount := 0
				((_maxSuggestions = "") && _maxSuggestions:=7), this.maxSuggestions := _maxSuggestions
				GUI, New, % "+hwnd_menuParent +LastFound +ToolWindow -Caption +E0x20 +Owner" . _owner._parent
				this._parent := _menuParent
				WinSet, Transparent, 255 ; in order to actually apply the +E0x20 extended style
				GUI, Color,, % _bkColor
				GUI, Font, % _ftOptions, % _ftName
				GUI, Margin, 0, 0
				GUI, Add, ListBox, x0 y0 -HScroll +VScroll Choose0 -Multi +Sort hwnd_lbHwnd,
				SendMessage, 0x1A1, 0, 0,, % this.AHKID := "ahk_id " . (this.HWND:=_lbHwnd) ; LB_GETITEMHEIGHT
				this._lbListHeight := ErrorLevel
				GUI, %_GUI%:Default

			}
			onSelect {
				set {
					eAutocomplete._setCallback(this, "_onSelect", value)
				return this._onSelect
				}
				get {
				return this._onSelect
				}
			}
			; ==========================================================================================================
			_setChoice(_prm:=0, _update:=false) {

				_owner := this._owner
				_owner._getText(_input), _caretPos := _owner._getSelection(_start, _end)
				if (_update) {
					_owner._lastInterimEditContent := _input, _owner._lastCaretPos := _caretPos
				}
				if not (_prm) {
					this._selectedItem := "", this._selectedItemIndex := 0
					this._setPos()
				return
				} else if (_prm > 0) {
					Control, Choose, % (this._selectedItemIndex >= this._lbCount)
								? this._selectedItemIndex:=1 : ++this._selectedItemIndex,, % this.AHKID
				} else {
					Control, Choose, % (this._selectedItemIndex <= 1)
								? (this._selectedItemIndex:=this._lbCount) : --this._selectedItemIndex,, % this.AHKID
				}
				ControlGet, _item, Choice,,, % this.AHKID ; we use ControlGet instead of GuiControlGet to prevent AltSubmit from interfering here
				this._selectedItem := _item

				_owner._shouldAvoidRecursion := true
					if (_owner._lastUncompleteWord.length()) { ; regular expression ?
						StringTrimLeft, _item, % _item, % StrLen(_owner._lastUncompleteWord.1)
						_start := _start - StrLen(_owner._lastUncompleteWord.2) - 1
						_owner._setSelection(_start, _start + StrLen(_owner._lastUncompleteWord.2) + 1)
						sleep, 0
						_owner._lastUncompleteWord := _owner._lastUncompleteWord.1
					}
					else StringTrimLeft, _item, % _item, % StrLen(_owner._lastUncompleteWord)
					Control, EditPaste, % _item,, % _owner.AHKID
					_owner._setSelection(_start, _start + StrLen(_item))
					sleep, 0
				_owner._shouldAvoidRecursion := false

				this._setPos()

			}
			_setSz(_multiplier:=0) {
				_mHwnd := this.HWND
				GuiControlGet, _pos, Pos, % _mHwnd
				(((_count:=this._lbCount) > this.maxSuggestions) && _count:=this.maxSuggestions)
				_w := this._lastWidth:=_posw + _multiplier * 10, _h := this._lastHeight:=++_count * this._lbListHeight
				GuiControl, Move, % _mHwnd, % Format("w{1} h{2}", _w, _h)
				this._show(true)
			}
			_setPos(_coerce:=1) {
				if not (_coerce || DllCall("IsWindowVisible", "Ptr", this._parent))
					return
				_coordModeCaret := A_CoordModeCaret
				CoordMode, Caret, Screen
					if not ((A_CaretX+0 <> "") && (A_CaretY+0 <> "")) {
						CoordMode, Caret, % _coordModeCaret
					return
					}
					_x1 := A_CaretX + 20, _y1 := A_CaretY + 35, _x2 := _x1 + this._lastWidth, _y2 := _y1 + this._lastHeight
					_x := (_x2 > A_ScreenWidth) ? A_ScreenWidth - this._lastWidth : _x1
					_y :=(_y2 > A_ScreenHeight) ? A_ScreenHeight - this._lastHeight : _y1
					this._show(true, Format("x{1} y{2}", _x, _y))
				CoordMode, Caret, % _coordModeCaret
			}
			_submit(_autocomplete:=false) {
				SendMessage, 0xB1, -1,,, % this._owner.AHKID ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
				if (_autocomplete) {
					_selectedItemIndex := this._selectedItemIndex, _selectedItem := this._selectedItem
					if not (_selectedItemIndex)
						return this._setChoice(+1, true)
					ControlSend,, {Space}, % this._owner.AHKID
					if (_selectedItemIndex)
						((_fn:=this._onSelect) && _fn.call(this, _selectedItem))
				}
				this._reset(), this._show(false)
			}
			_reset() {
			SendMessage, 0x0184, 0, 0,, % this._owner.AHKID ; LB_RESETCONTENT
			this._selectedItem := "", this._selectedItemIndex := this._lbCount := 0
			}
			_show(_boolean:=true, _params:="") {
				GUI % this._parent . ":Show", % (_boolean ? "NA AutoSize " : "Hide ") . _params
			}

		}
		; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		_locationChangeEventMonitor(_event, _hwnd, _idObject) {
			static OBJID_CARET := 0xFFFFFFF8 ; https://www.logsoku.com/r/2ch.net/software/1265518996/
			static _txt := ""
			if ((_idObject = OBJID_CARET) && eAutocomplete._CID.hasKey(_hwnd)) { ; if the event source is the caret in the edit control...
				_inst := eAutocomplete._CID[_hwnd]
				_inst._getText(_text)
				if (_text <> _txt) {
					if not (_inst._shouldAvoidRecursion) ; returns also false if the instance is disabled
						_inst._suggestWordList(_hwnd)
					_txt := _text
				}
			} else if (eAutocomplete._GUIID.hasKey(_hwnd)) { ; if the event source is the GUI itself...
				eAutocomplete._GUIID[_hwnd].menu._setPos(false)
			}
		}
		_objectDestroyEventMonitor(_event, _hwnd, _idObject) {
			static OBJID_WINDOW := 0x0 ; https://autohotkey.com/board/topic/45781-changing-a-windows-title-permanently/
			if (eAutocomplete._CID.hasKey(_hwnd)) {
				_inst := eAutocomplete._CID[_hwnd]
				sleep, 0
				if not (DllCall("User32.dll\IsWindow", "Ptr", _inst._parent)) { ; https://github.com/flipeador/AutoHotkey/blob/master/Lib/window/IsWindow.ahk
					eAutocomplete._CID[_hwnd].dispose()
				}
			} else if ((_idObject = OBJID_WINDOW) && eAutocomplete._GUIID.hasKey(_hwnd)) {
				_inst := eAutocomplete._GUIID[_hwnd]
				sleep, 0
				if not (DllCall("User32.dll\IsWindow", "Ptr", _inst._parent)) {
					eAutocomplete._GUIID[_hwnd].dispose()
				}
			}
		}
		_objectTextSelectionChangedEventMonitor(_event, _hwnd) {
			if (eAutocomplete._CID.hasKey(_hwnd)) {
				_inst := eAutocomplete._CID[_hwnd]
				if not (_inst._shouldAvoidRecursion) ; = if it's an user-generated event...
					_inst.menu._reset(), _inst.menu._show(false)
			}
		}

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
