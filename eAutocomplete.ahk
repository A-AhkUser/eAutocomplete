Class eAutocomplete {
	/*
		; ~~~~~~~~~~~~~~ description ~~~~~~~~~~~~~~
			The script enables users, as typing in an Edit control, to quickly find and select from a dynamic pre-populated list of suggestions
			and, by this means, to expand partially entered strings into complete strings. When a user starts to type in the edit control, a
			listbox should display suggestions to complete the word, based both on earlier typed letters and the content of a custom list.
			see also: https://github.com/A-AhkUser/eAutocomplete#eautocomplete
		; ~~~~~~~~~~~~~~ some links ~~~~~~~~~~~~~~
			SetWinEventHook function: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373640(v=vs.85).aspx
				- WinEventProc callback function: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373885(v=vs.85).aspx
				- Event Constants: https://msdn.microsoft.com/en-us/library/windows/desktop/dd318066(v=vs.85).aspx
				- Object Identifiers: https://msdn.microsoft.com/en-us/library/windows/desktop/dd373606(v=vs.85).aspx
				- [LIB] EWinHook - SetWinEventHook implementation: https://autohotkey.com/boards/viewtopic.php?t=830
			Edit control messages: https://msdn.microsoft.com/en-us/library/windows/desktop/ff485923(v=vs.85).aspx
			Edit.ahk: https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
			ListBox control messages: https://msdn.microsoft.com/en-us/library/windows/desktop/ff485967(v=vs.85).aspx
		; ~~~~~~~~~~~~~~ AutoHotkey version ~~~~~~~~~~~~~~
			1.1.28.00 unicode x32
		; ~~~~~~~~~~~~~~ OS version ~~~~~~~~~~~~~~
			Windows 8.1
		; ~~~~~~~~~~~~~~ version ~~~~~~~~~~~~~~
			1.0.20
		; ~~~~~~~~~~~~~~ author(s) ~~~~~~~~~~~~~~
			. yet another AutoHotkey enthusiast aka A_AhkUser <A_AhkUser@hotmail.com>
		; ~~~~~~~~~~~~~~ revision history ~~~~~~~~~~~~~~
			; --------------------------------------------------------------- 1.0.20 (2018/05/30) - A_AhkUser
				- the property specific to each instance and now indeed used internally *_focused* has been made available via the read-only property *focused*
				- the class was further reworked to properly handle INSTANCES sharing the same process and/or the same parent
				- if the source's list is a file, its content is overwritten by the updated list only at the time the *setSource* or the *dispose* method is called
				- fixed *Enter* not triggering the *__hapax* method upon the first onset of a word
			; --------------------------------------------------------------- 1.0.10 (2018/05/28) - A_AhkUser
				- fixed unwanted scroll up upon a backspace key press if the first visible line of the edit control is not the very first one (due
				to the use of *ControlSetText*)
				- removed the *_objectTextSelectionChangedEventMonitor* callback function, which was intended to prevent autocompletion
					if the selection in the edit control had been changed as a result of an user-generated event
				- added *_caretLifeCycleEventMonitor* callback function which handles host edit control's focus/defocus events.
				- added a *_GUIDelimiter* property for each source (word list) object since it has actually to be distinguished from the *delimiter*
					one in cases where a space or tab is use as field separator for the GUI (*Gui +DelimiterSpace* or *Gui +DelimiterTab*)
				- make the *_suggestWordList* method remove any trailing ?!,;.:(){}[]'""<> before actually appending a hapax legomena to the current word list
			; --------------------------------------------------------------- 1.0.00 (2018/05/26) - A_AhkUser
				*initial release*
		; ~~~~~~~~~~~~~~ acknowledgements ~~~~~~~~~~~~~~
			. Thanks to brutus_skywalker for his valuable suggestions on how to make more ergonomic and user-friendly the common
				features provided by the script via the use of keyboard shortcuts.
			. Thanks to jeeswg for sharing its knowlegde.
			. Thanks to AlphaBravo for its decisive help on regular expressions.
		; ~~~~~~~~~~~~~~ notes ~~~~~~~~~~~~~~
			. all local variables are prepended with a _ (e.g. *_myVar*) - just an idiosyncratic way to visually distinguish local variables from the global ones.
			. all internal methods and properties are prepended with a _ (e.g. *eAutocomplete._caretLifeCycleEventMonitor*).

		This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
	*/
	; ===============================================================================================================
	; ============================ PRIVATE PROPERTIES /===================================================
	; ===============================================================================================================
	static _CID := {} ; intended to keep track of each instance, added to the collection upon instantiation (keys: control IDs)
	static _lastFoundControl := ""
	static _winEventHookTable := {} ; intended to keep track of *HWINEVENTHOOK* values
	_idProcess := "" ; intended to contain the PID of the host GUI itself
	_parent := "0x0" ; intended to contain the HWND of the host GUI itself
	_szHwnd := "0x0" ; intended to contain the HWND of the static control which allows users to resize the edit control, when applicable

	_fnIf := "" ; intended to contain the function object with which are associated instance's hotkeys (*Hotkey, If, % functionObject*)

	_lastSourceAsObject := ""
	_lastUncompleteWord := ""

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
	static sources := {"Default": {list: "", path: "", _GUIDelimiter: "`n", delimiter: "`n", _delimiterRegExSymbol: "\n"}}
	static HAPAX_MINLENGTH := 4 ;  the minimum number of characters a hapax legomenon must contain to be appended to the current source's list, if applicable
	focused {
		set {
		return this._focused
		}
		get {
		return this._focused
		}
	}
	content {
		set {
		return this._content
		}
		get {
		return this._content
		}
	}
	disabled {
		set {
			((this._enabled:=!this._shouldNotSuggest:=value) || this.menu._submit(false))
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
		_hLastFoundWindow := WinExist() ; get the current last found window in order to restore it later
		try {
			Gui % _GUIID ":+LastFoundExist"
			IfWinNotExist ; if the host window is an existing GUI window...
				throw ErrorLevel:=2
		} finally WinExist("ahk_id " . _hLastFoundWindow)
	return new eAutocomplete(_GUIID, _opt)
	}
	attach(_hEdit, _opt:="") {
		VarSetCapacity(_class, 256, 0)
		DllCall("GetClassName", "Ptr", _hEdit, "Str", _class, "Int", 255) ; https://autohotkey.com/board/topic/45627-function-control-getclassnn-get-a-control-classnn/
		if not (_class = "Edit")
			throw ErrorLevel:=1
		if not (_GUIID:=DllCall("user32\GetAncestor", "Ptr", _hEdit, "UInt", 2, "Ptr")) ; GA_ROOT since it may be the child of a combobox
		; thanks to jeeswg here: https://autohotkey.com/boards/viewtopic.php?f=5&t=49374
			throw ErrorLevel:=2
	return new eAutocomplete(_GUIID, _opt, _hEdit)
	}
	__New(_GUIID, _opt:="", _hEdit:="0x0") {

		this._parent := _GUIID ; a hwndle to the host window

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
			(_opt.hasKey("matchModeRegEx") && this.matchModeRegEx :=!!_opt.matchModeRegEx)
			(_opt.hasKey("autoAppend") && this.autoAppend:=!!_opt.autoAppend)
			(_opt.hasKey("appendHapax") && this.appendHapax:=!!_opt.appendHapax)
			; setters >>>>>>>>>>
			(_opt.hasKey("startAt") && this.startAt:=_opt.startAt)
			(_opt.hasKey("regexSymbol") && this.regexSymbol:=_opt.regexSymbol)
			(_opt.hasKey("onEvent") && this.onEvent:=_opt.onEvent)
			(_opt.hasKey("onSize") && this.onSize:=_opt.onSize)
			; <<<<<<<<<< setters
		} else _opt := {}

		_menu ; create the menu
			:= this.menu
			:= new eAutocomplete.Menu(this,_opt.maxSuggestions,_opt.menuBackgroundColor,_opt.menuFontName,_opt.menuFontOptions)
			(_opt.hasKey("onSelect") && _menu.onSelect:=_opt.onSelect) ; set the function object which handles the menu control's events

		_fn := this._fnIf := this._hotkeysShouldFire.bind("", "ahk_id " . _GUIID, _hEdit, _menu._parent)
		; once passed to the Hotkey command, an object is never deleted, hence the empty string
		Hotkey, If, % _fn
			_fn1 := ObjBindMethod(_menu, "_setChoice", -1), _fn2 := ObjBindMethod(_menu, "_setChoice", +1)
			Hotkey, Up, % _fn1
			Hotkey, Down, % _fn2 ; use both the Down and Up arrow keys to select from the list of available suggestions
			_fn1 := ObjBindMethod(_menu, "_setSz", _multiplier:=-1), _fn2 := ObjBindMethod(_menu, "_setSz", _multiplier:=1)
			Hotkey, !Left, % _fn1
			Hotkey, !Right, % _fn2 ; use Alt+Left and Alt+Right keyboard shortcuts to respectively shrink/expand the menu
			_fn := ObjBindMethod(_menu, "_submit", true)
			Hotkey, Tab, % _fn ; press Tab key to select an item from the drop-down list
			_fn := ObjBindMethod(_menu, "_submit", false)
			Hotkey, Escape, % _fn ; the drop-down list can be closed by pressing the ESC key
			_fn := ObjBindMethod(this, "_sendEnter")
			Hotkey, Enter, % _fn
			_fn := ObjBindMethod(this, "_sendBackspace")
			Hotkey, BackSpace, % _fn
		Hotkey, If,

		this.disabled := _opt.hasKey("disabled") ? !!_opt.disabled : false
		this.setSource("Default")

		_PID := "", DllCall("User32.dll\GetWindowThreadProcessId", "Ptr", _GUIID, "UIntP", _PID, "UInt") ; DllCall also works with hidden windows, as the case may be
		; https://github.com/flipeador/AutoHotkey/blob/master/Lib/window/GetWindowThreadProcessId.ahk
		this._setWinEventHook(_PID, true)

	return eAutocomplete._CID[_hEdit] := this ; return the instance having beforehand storing it in the base object
	}
	addSource(_sourceName, _list, _delimiter:="`n", _fileFullPath:="") {
	; creates a new autocomplete dictionary from an input string or a file's content, storing it directly in the base object

		if _delimiter in `n,`r
			_GUIDelimiter := _delimiter, _d := "\n"
		else if (_delimiter = A_Tab)
			_GUIDelimiter := "Tab", _d := "\t" ; the *_GUIDelimiter* property has to be distinguished from the *delimiter* one in cases where a space or tab is use as field separator for the GUI
		else if (_delimiter = A_Space)
			_GUIDelimiter := "Space", _d := _delimiter
		else if _delimiter in \,.,*,?,+,[,],{,},|,(,),^,$ ; the characters \.*?+[{|()^$ must be preceded by a backslash to be seen as literal in regex
			_GUIDelimiter := _delimiter, _d := "\" . _delimiter
		else if not (StrLen(_delimiter) = 1)
			return !ErrorLevel:=1
		else _GUIDelimiter := _d := _delimiter

		_source := eAutocomplete.sources[_sourceName]
			:= {list: "", path: _fileFullPath, _GUIDelimiter: _GUIDelimiter, delimiter: _delimiter, _delimiterRegExSymbol: _d}
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
	addSourceFromFile(_sourceName, _fileFullPath, _delimiter:="`n") {
	_list := (_f:=FileOpen(_fileFullPath, 4+0, "UTF-8")).read() ; EOL: 4 > replace `r`n with `n when reading
	if (A_LastError)
		return !ErrorLevel:=1, _f.close()
		this.addSource(_sourceName, _list, _delimiter, _fileFullPath)
	return !ErrorLevel:=0, _f.close()
	}
	setSource(_sourceName) {
	; specifies the autocomplete list to use
		if (eAutocomplete.sources.hasKey(_sourceName)) {
			this._updateSource() ; if the current source's list is a file, update its content
			GUI, % this.menu._parent . ":+Delimiter" . this.sources[_sourceName]._GUIDelimiter
			this.menu.delimiter := this.sources[_sourceName].delimiter
			this.menu._submit(false)
		return !ErrorLevel:=0, this._source := _sourceName, this._lastSourceAsObject := eAutocomplete.sources[_sourceName]
		}
		return !ErrorLevel:=1
	}
		dispose() {
		; release all circular references and removes instance's own event hook functions
			this._updateSource() ; if the current source's list is a file, update its content
			if not (this.menu) ; ~= if the method has already been called...
				return
			_fn := this._fnIf, _f := Func("WinActive")
			Hotkey, If, % _fn
			for _, _keyName in ["Up", "Down", "Tab", "!Left", "!Right", "Escape", "BackSpace", "Enter"]
				Hotkey, % _keyName, % _f, Off ; release circular references so that the object can be freed
				; specify *Off* is not only better here but rather necessary since *_hotkeysShouldFire* could otherwise still trigger *__hapax*
			Hotkey, If,
			this.menu := this.menu._onSelect := ""
			this._onEvent := ""
			if (this.hasKey("_hSz")) {
				GuiControl -g, % this._hSz ; removes the function object bound to the control
				this._onSize := ""
			}
			eAutocomplete._CID.delete(this.HWND)
			this._setWinEventHook(this._idProcess, false)
		}
	; ===============================================================================================================
	; ============================/ PUBLIC METHODS =====================================================
	; ===============================================================================================================
	; ============================ PRIVATE METHODS /=====================================================
	; ===============================================================================================================
	_setWinEventHook(_idProcess, _hook) {
		; static EVENT_OBJECT_LOCATIONCHANGE := 0x800B, EVENT_OBJECT_CREATE := 0x8000, EVENT_OBJECT_DESTROY := 0x8001
		(_hook && this._idProcess:=_idProcess)
		Loop, 1 {
			for _, _instance in eAutocomplete._CID {
				if (_instance._idProcess = _idProcess)
					break, 2 ; cancel the operation if an instance already has (hook) or still has (unhook) the same PID
			}
			if (_hook) {
				_handles := eAutocomplete._winEventHookTable[_idProcess] := {}
				_handles["_objectLocationChangeEvent"]
					:= SetWinEventHook(0x800B, 0x800B, 0, RegisterCallback("eAutocomplete._objectLocationChangeEventMonitor"), _idProcess, 0, 0)
					; handles location change events from both the caret and the host window
				_handles["_caretLifeCycleEvent"]
					:= SetWinEventHook(0x8000, 0x8001, 0, RegisterCallback("eAutocomplete._caretLifeCycleEventMonitor"), _idProcess, 0, 0)
					; handles host edit control's focus/defocus events
			} else { ; unhook
				_handles := eAutocomplete._winEventHookTable[_idProcess]
				UnhookWinEvent(_handles["_objectLocationChangeEvent"])
				UnhookWinEvent(_handles["_caretLifeCycleEvent"])
				eAutocomplete._winEventHookTable.delete(_idProcess)
			}
		}
	}
	_setCallback(_source, _eventName, _fn) { ; called via base object
	if not (IsFunc(_fn))
		return !ErrorLevel:=1
		((_fn.minParams = "") && _fn:=Func(_fn)) ; handles function references as well as function names
	return !ErrorLevel:=0, _source[_eventName]:=_fn
	}

	_hotkeysShouldFire(_editParent, _hEdit, _menuParent, _thisHotkey) { ; *_thisHotkey* is automatically passed to the caller
		if (DllCall("IsWindowVisible", "Ptr", _menuParent)) {
			return WinActive(_editParent)
		} ; the menu is not visible: the word is not suggested
		else if ((_inst:=eAutocomplete._CID[_hEdit])._focused && (_thisHotkey = "Enter") && _inst.appendHapax) {
			_inst.__hapax(Trim(_inst._lastUncompleteWord, A_Space)) ; ...append the word to the current source's list
		}
		return false
	}
	_sendBackspace() {
		_state := this._shouldNotSuggest
		this._shouldNotSuggest := this.autoAppend ; if *true*, do not suggest: the selection in the edit control will not change as a result of an user-generated event
		ControlSend,, {BackSpace}, % this.AHKID
		this._shouldNotSuggest := _state
		this.menu._submit(false)
	}
	_sendEnter() {
	this.menu._submit(false)
	ControlSend,, {Enter}, % this.AHKID
	}

	_getText(ByRef _text) {
	ControlGetText, _text,, % this.AHKID
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		static EM_GETSEL := 0xB0
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage, % EM_GETSEL, &_startPos, &_endPos,, % this.AHKID
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_setSelection(_startSel:=-1, _endSel:=0) {
		static EM_SETSEL := 0xB1
		SendMessage % EM_SETSEL, % _startSel, % _endSel,, % this.AHKID
	}

	_suggestWordList(_hEdit) { ; Autocomplete Search Engine

		this._shouldNotSuggest := true
		; prevent the script from suggesting recursively: indicates to the *_objectLocationChangeEventMonitor* event hook function
		; that the selection in the edit control will not change as a result of an user-generated event
		ControlGet, _column, CurrentCol,,, % this.AHKID
		if not (_column - 1) ; the edit control is mapped starting from the second column
			return "", this._shouldNotSuggest := false

		_source := this._lastSourceAsObject, _menu := this.menu
		_input := this._content, _caretPos := this._getSelection()
		this._lastUncompleteWord := _match := "", _regExMode := false

		if ((StrLen(RegExReplace(SubStr(_input, _caretPos, 2), "\s$")) <= 1) ; if the caret is well placed to perform a search...
			&& (RegExMatch(SubStr(_input, 1, _caretPos), "\S+(?P<IsWord>" A_Space "?)$", _m)) ; match the last word that have been partially entered
			&& (StrLen(this._lastUncompleteWord:=_m) >= this.startAt))
			{
				if (_mIsWord) { ; if the word is completed...
					if (this.appendHapax) {
						if not ((_m:=Trim(_m, A_Space)) = _menu._selectedItem) { ; if it is not suggested...
							this.__hapax(_m) ; append it to the dictionary
						}
					}
				} else if (_str:=_source[ SubStr(_m, 1, 1) ]) { ; perform a search only if the subsection of the dictionary is not empty
					_d := _source._delimiterRegExSymbol
					_regExMode := (this.matchModeRegEx && InStr(_m, this._regexSymbol))
					if (_regExMode && (_p:=StrSplit(_m, this._regexSymbol)).length() = 2) { ; split the string in two parts using the *regexSymbol* as delimiter
						this._lastUncompleteWord := [ _p.1, _p.2 ]
						_match := RegExReplace(_str, "`ni)" . _d . "(?!\Q" . _p.1 . "\E[^" . _d . "]+\Q" . _p.2 . "\E).+?(?=" . _d . ")")
						; remove all irreleavant lines from the subsection of the dictionary. I am particularly indebted to AlphaBravo for this regex
					} else {
						_q := "\Q" . _m . "\E"
						RegExMatch(_str, "`nsi)" . _d . _q . "[^" . _d . "]+(.*" . _d . _q . ".+?(?=" . _d . "))?", _match)
					}
				}
			}
			_match := LTrim(_match, _d:=_source.delimiter)
			if (_match <> "") {
				_menu._updateList(_match)
				_menu._setChoice((this.autoAppend && !_regExMode)) ; preselect the first item if *autoAppend* is enabled
			} else _menu._submit(false)
			(this._onEvent && this._onEvent.call(this, _hEdit, _input))

	return "", this._shouldNotSuggest := false
	}
	_fillInSuggestion(_item) {
		this._shouldNotSuggest := true ; do not suggest: the selection in the edit control will not change as a result of an user-generated event
			this._getSelection(_start)
			if (this._lastUncompleteWord.length()) { ; is it a regular expression splitted in two parts using the *regexSymbol* as delimiter ?
				StringTrimLeft, _missingPart, % _item, % StrLen(this._lastUncompleteWord.1)
				_start := _start - StrLen(this._lastUncompleteWord.2) - 1
				this._setSelection(_start, _start + StrLen(this._lastUncompleteWord.2) + 1)
				sleep, 0
				this._lastUncompleteWord := this._lastUncompleteWord.1
			} else ; otherwise...
				StringTrimLeft, _missingPart, % _item, % StrLen(this._lastUncompleteWord)
			Control, EditPaste, % _missingPart,, % this.AHKID ; complete the word with its missing part
			this._setSelection(_start, _start + StrLen(_missingPart))
			sleep, 0
		this._shouldNotSuggest := false
	}
	__hapax(_value) { ;  called at the first onset of a word (assuming *appendHapax* is set to *true*)
		; _startTime := A_TickCount
		_value := Trim(_value, "?!,;.:(){}[]'""<>") ; remove any trailing ?!,;.:(){}[]'""<> before actually appending a hapax legomenon to the current source's list
		if not (StrLen(_value) >= eAutocomplete.HAPAX_MINLENGTH)
			return
		_source := this._lastSourceAsObject, _delimiter := _source.delimiter
		if (_source.hasKey(_letter:=SubStr(_value, 1, 1)))
			_source.list := StrReplace(_source.list, Trim(_source[_letter], _delimiter), "")
		else _source[_letter] := _delimiter
		_v := _source[_letter] . _value . _delimiter ; append the hapax legomenon to the dictionary's subsection
		Sort, _v, D%_delimiter% U ; CL
		ErrorLevel := 0
		_source.list .= LTrim(_source[_letter]:=_v, _delimiter) ; append the updated subsection to the list
		; ToolTip % A_TickCount - _startTime
	}
	_updateSource() {
		_source := this._lastSourceAsObject
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, 4+1, "UTF-8")).write(_source.list), _f.close() ; EOL: 4 > replace `n with `r`n when writing
		}
	}
		__resize(_szHwnd) { ; called when the edit control is resized

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
					_h := _maxSz.h ; prevent the control from exceeding the limits imposed
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
			_selectedItem := ""
			_selectedItemIndex := 0
			_itemCount := 0
			_lastWidth := 0
			_lastHeight := 0
			visible := false
			delimiter := ""

			__New(_owner, _maxSuggestions:=7, _bkColor:="", _ftName:="", _ftOptions:="") {

				_GUI := A_DefaultGUI, _hLastFoundWindow := WinExist() ; get both the current last found window and the current default GUI in order to restore them later
				this._owner := _owner
				((_maxSuggestions = "") && _maxSuggestions:=7), this.maxSuggestions := _maxSuggestions
				GUI, New, % "+hwnd_menuParent +LastFound +ToolWindow -Caption +E0x20 +Owner" . _owner._parent
				this._parent := _menuParent
				WinSet, Transparent, 255 ; in order to actually apply the +E0x20 extended style
				GUI, Color,, % _bkColor
				GUI, Font, % _ftOptions, % _ftName
				GUI, Margin, 0, 0
				GUI, Add, ListBox, x0 y0 -HScroll +VScroll Choose0 -Multi +Sort hwnd_lbHwnd,
				SendMessage, 0x1A1, 0, 0,, % this.AHKID := "ahk_id " . (this.HWND:=_lbHwnd) ; LB_GETITEMHEIGHT
				this._lbListHeight := ErrorLevel ; get the height of the menu for further use
				WinExist("ahk_id " . _hLastFoundWindow)
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
			_updateList(_list) {
				this._reset()
				_delimiter := this.delimiter
				StrReplace(_list:=RTrim(_list, _delimiter), _delimiter,, _count)
				((_count > 132 && _count:=132) && _list:=SubStr(_list, 1, InStr(_list, _delimiter,,, 133))) ; load up to 132 items in the menu
				this._itemCount := _count + 1, this._setSz() ; update the size of the menu according to the new item count
				GuiControl,, % this.HWND, % _delimiter . _list
			}
			_setChoice(_prm:=0) {
				if not (_prm) {
					this._selectedItem := _item := "", this._selectedItemIndex := 0
					this._setPos()
				return
				} else if (_prm > 0) {
					Control, Choose, % (this._selectedItemIndex >= this._itemCount)
								? this._selectedItemIndex:=1 : ++this._selectedItemIndex,, % this.AHKID
				} else {
					Control, Choose, % (this._selectedItemIndex <= 1)
								? (this._selectedItemIndex:=this._itemCount) : --this._selectedItemIndex,, % this.AHKID
				}
				ControlGet, _item, Choice,,, % this.AHKID ; we use ControlGet instead of GuiControlGet to prevent AltSubmit from interfering here
				this._selectedItem := _item
				this._owner._fillInSuggestion(_item) ; fill in the field with the selected item
				this._setPos()
			}
			_setSz(_multiplier:=0) {
				GuiControlGet, _pos, Pos, % _mHwnd:=this.HWND
				(((_count:=this._itemCount) > this.maxSuggestions) && _count:=this.maxSuggestions) ; display up to *maxSuggestions* item(s)
				_w := ((this._lastWidth:=_posw + _multiplier * 10) > 30) ? this._lastWidth : 30
				_h := this._lastHeight := ++_count * this._lbListHeight
				GuiControl, Move, % _mHwnd, % Format("w{1} h{2}", _w, _h)
				this._show(true)
			}
			_setPos(_coerce:=1) {
				if not (_coerce || this.visible)
					return
				_coordModeCaret := A_CoordModeCaret
				CoordMode, Caret, Screen
					if not (A_CaretX+0 <> "") { ; if no caret...
						CoordMode, Caret, % _coordModeCaret
					return
					}
					_x1 := A_CaretX + 20, _y1 := A_CaretY + 35 ; move the menu to caret position, with an offset
					_x2 := _x1 + this._lastWidth, _y2 := _y1 + this._lastHeight
					_x := (_x2 > A_ScreenWidth) ? A_ScreenWidth - this._lastWidth : _x1
					_y :=(_y2 > A_ScreenHeight) ? A_ScreenHeight - this._lastHeight : _y1 ; prevent the menu from being displayed outside screen
					this._show(true, Format("x{1} y{2}", _x, _y))
				CoordMode, Caret, % _coordModeCaret
			}
			_submit(_autocomplete:=false) {
				this._owner._setSelection() ; both *_wParam* and *_lParam* default to -1 and 0 respectively when omitted, values which deselects any current selection
				if (_autocomplete) {
					_selectedItemIndex := this._selectedItemIndex, _selectedItem := this._selectedItem
					; we store these values right now since, as the case may be, the *ControlSend* command below will inevitably update them by updating the content of the Edit control
					if not (_selectedItemIndex)
						return this._setChoice(+1) ; the return value of the method is meaningless - just a shortcut
					ControlSend,, {Space}, % this._owner.AHKID ; autocomplete!
					((_fn:=this._onSelect) && _fn.call(this, _selectedItem))
				}
				this._reset(), this._show(false)
			}
			_reset() {
			SendMessage, 0x0184, 0, 0,, % this._owner.AHKID ; *LB_RESETCONTENT* removes all items from a list box
			this._selectedItem := "", this._selectedItemIndex := this._itemCount := 0
			}
			_show(_boolean:=true, _params:="") {
				GUI % this._parent . ":Show", % ((this.visible:=_boolean) ? "NA AutoSize " : "Hide ") . _params
			}
			__Delete() {
				GUI % this._parent . ":Destroy"
			}

		}
		; -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- WinEventProc callback functions
		_objectLocationChangeEventMonitor(_event, _hwnd, _idObject) { ; handles location change events from both the caret and the host window
			static OBJID_CARET := 0xFFFFFFF8 ; https://www.logsoku.com/r/2ch.net/software/1265518996/
			static OBJID_WINDOW := 0x0 ; https://autohotkey.com/board/topic/45781-changing-a-windows-title-permanently/
			if (_idObject = OBJID_CARET) {
				if not (eAutocomplete._CID.hasKey(_hwnd))
					return
				; if the event source is the caret in an autocomplete control...
				_inst := eAutocomplete._CID[_hwnd]
				_inst._getText(_text)
				if (_text <> _inst._content) { ; if the contents of the edit control has been altered...
					_inst._content := _text
					if not (_inst._shouldNotSuggest) ; returns also false if the instance is disabled
						_inst._suggestWordList(_hwnd)
				}
			} else if (_idObject = OBJID_WINDOW) {
				_inst := eAutocomplete._CID[eAutocomplete._lastFoundControl]
				if (_hwnd = _inst._parent)
					_inst.menu._setPos(false) ; change the position of the menu window if it is currently visible
			}
		}
		_caretLifeCycleEventMonitor(_event, _hwnd, _idObject) { ; handles host edit control's focus/defocus events
			if ((_idObject = 0xFFFFFFF8) && eAutocomplete._CID.hasKey(_hwnd)) { ; if the event source is the caret in an autocomplete control...
				_inst := eAutocomplete._CID[_hwnd]
				_hasLostFocus := !(_inst._focused:=!!(_event - 0x8001))
				eAutocomplete._lastFoundControl := _inst.HWND
				if (_hasLostFocus) { ;  if the caret has been destroyed...
					_inst.menu._show(false)
				} else {
					if (_inst._shouldNotSuggest)
						return
					_inst._suggestWordList(_hwnd)
				}
			}
		}

}
SetWinEventHook(_eventMin, _eventMax, _hmodWinEventProc, _lpfnWinEventProc, _idProcess, _idThread, _dwFlags) {
   DllCall("CoInitialize", "Uint", 0)
   return DllCall("SetWinEventHook"
			, "Uint", _eventMin, "Uint", _eventMax
			, "Ptr", _hmodWinEventProc, "Ptr", _lpfnWinEventProc
			, "Uint", _idProcess, "Uint", _idThread
			, "Uint", _dwFlags)
} ; cf. https://autohotkey.com/boards/viewtopic.php?t=830
UnhookWinEvent(_hWinEventHook) {
    _v := DllCall("UnhookWinEvent", "Ptr", _hWinEventHook)
    DllCall("CoUninitialize")
return _v
} ;  cf. https://autohotkey.com/boards/viewtopic.php?t=830
