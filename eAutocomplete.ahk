Class eAutocomplete {
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PRIVATE BASE OBJECT PROPERTIES ■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	static _instances := {}
	static _winEventHookFunctions := new eAutocomplete._EventHandling("_setWinEventHook", "_unhookWinEvent")
	static _hotkeys := new eAutocomplete._EventHandling("_setHotkey", "_unregisterHotkey")
	static _eventObjects := new eAutocomplete._EventHandling("_setEventObject", "_unregisterEventObject")
	static _bypassToggle := false
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PRIVATE NESTED CLASSES ■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	Class _EventHandling {

		static table := {}

		__New(__push:="", __remove:="") {
		ObjRawSet(this, "__push", __push), ObjRawSet(this, "__remove", __remove)
		}
		__Get(_params*) {
		return eAutocomplete._EventHandling.table[_params*]
		}
		__Set(_k, _params*) {
			if (this.__push) {
				if (eAutocomplete._EventHandling.table.hasKey(_k)) {
					if ((_params.length() = 1) && (_params.1 = "")) {
						eAutocomplete._EventHandling.table.delete(_k)
					return
					}
				} else {
					_inst := new eAutocomplete._EventHandling(, this.__remove), ObjRawSet(_inst, "_k", _k)
					eAutocomplete._EventHandling.table[_k] := _inst
				}
				_param := _params.removeAt(1), eAutocomplete[ this.__push ].call("", _k, _param, _params*)
				eAutocomplete._EventHandling.table[_k].push(_param)
			return _params.pop()
			}
			return
		}
		__Delete() {
			if (this._k && this.__remove) {
				for _key, _value in this {
					if _key is integer
						eAutocomplete[ this.__remove ].call("", this._k, _value)
				}
			}
		}

	}
		; ====================================================================================
		_setEventObject(_source, ByRef _eventName, _callback) {
			if (_callback = "") {
				return eAutocomplete._unregisterEventObject(_source, _eventName)
			} if (IsFunc(_callback)) {
				((_callback.minParams = "") && _callback:=Func(_callback))
				return _source[_eventName] := _callback
			} else if (IsObject(_callback)) {
				return _source[_eventName] := _callback
			} else return _source[_eventName]
		}
		_setHotkey(_ifFuncObj, ByRef _keyName, _func) {
			Hotkey, If, % _ifFuncObj
				Hotkey % _keyName, % _func, On
			Hotkey, If
		}
		_setWinEventHook(_idProcess, ByRef _HWINEVENTHOOK, _eventMin, _eventMax, _lpfnWinEventProc) {
			_HWINEVENTHOOK := DllCall("SetWinEventHook"
									, "Uint", _eventMin, "Uint", _eventMax
									, "Ptr", 0, "Ptr", _lpfnWinEventProc
									, "Uint", LTrim(_idProcess, "DWORD")
									, "Uint", 0, "Uint", 0)
		return _HWINEVENTHOOK
		}
		_unregisterEventObject(_source, _eventName) {
			return _source[_eventName] := ""
		}
		_unregisterHotkey(_ifFuncObj, _keyName) {
			_f := Func("WinActive")
			Hotkey, If, % _ifFuncObj
				Hotkey % _keyName, % _f, Off
			Hotkey, If
		}
		_unhookWinEvent(_idProcess, _HWINEVENTHOOK) {
			_v := DllCall("UnhookWinEvent", "Ptr", _HWINEVENTHOOK)
		return _v
		}
		; ====================================================================================

	Class _Resource {

		static table := []

		path := ""
		subsections := []
		hapaxLegomena := {}

		_set(_sourceName, _fileFullPath:="", _resource:="") {
			if not (StrLen(_sourceName))
				throw Exception("Invalid source name.")
			if (_fileFullPath) {
				if not (FileExist(_fileFullPath))
					throw Exception("The resource could not be found.")
				try _f:=FileOpen(_fileFullPath, 4+8+0, "UTF-8")
				catch
					throw Exception("Failed attempt to open the file.")
				_resource := _f.read(), _f.close()
			}
			_source := new eAutocomplete._Resource(_sourceName)
			_source.path := _fileFullPath
			_resource .= "`n"
			_batchLines := A_BatchLines
			SetBatchLines, -1
			Sort, _resource, D`n U
			ErrorLevel := 0
			_resource := "`n" . LTrim(_resource, "`n")
			while (_letter:=SubStr(_resource, 2, 1)) {
				_position := RegExMatch(_resource, "Psi)\n\Q" . _letter . "\E[^\n]+(.*\n\Q" . _letter . "\E.+?(?=\n))?", _length) + _length
				if _letter is not space
					_source.subsections[_letter] := SubStr(_resource, 1, _position)
				_resource := SubStr(_resource, _position)
			}
			SetBatchLines % _batchLines
		}

		__New(_sourceName) {
			static _ := new eAutocomplete._Resource("Default")
			this.name := _sourceName
		return eAutocomplete._Resource.table[_sourceName] := this
		}
		appendValue(_value) {
			_subsections := this.subsections, _letter := SubStr(_value, 1, 1)
			(_subsections.hasKey(_letter) || _subsections[_letter]:="`n")
			_v := _subsections[_letter] . _value . "`n"
			Sort, _v, D`n U
			ErrorLevel := 0
			_subsections[_letter] := "`n" . LTrim(_subsections[_letter]:=_v, "`n")
		}
		update() {
			static _substr := "■■■■■■■■■■■■■■■■■■■■"
			if (this.path <> "") {
				try _f:=FileOpen(this.path, 4+1, "UTF-8")
				catch
					return
				for _letter, _subsection in this.subsections {
					_f.writeLine("`t`t`t" . _substr . A_Tab . Format("{:U}", _letter) . A_Tab . _substr)
					_f.write(_subsection)
				}
				_f.close()
			}
		}

	}
	Class _pendingWordMatchObjectWrapper {
		match := {value:"", pos:0, len:0}
		leftPart := {value:"", pos:0, len:0}
		isRegEx := {value:"", pos:0, len:0}
		rightPart := {value:"", pos:0, len:0}
		isComplete := {value:"", pos:0, len:0}
	}
	Class _DropDownList {

		static _COUNTUPPERTHRESHOLD := 52
		_parent := ""
		_lastX := 0
		_lastY := 0
		_lastWidth := 0
		_visible := false
		_itemCount := 0

		_onSelectionChanged := ""

		__New(_owner, _opt) {

			for _key, _defaultValue in _clone:=eAutocomplete._properties.dropDownList.clone()
				ObjRawSet(this, "_" . _key, _defaultValue)

			_GUI := A_DefaultGUI, _hLastFoundWindow := WinExist()
			GUI, New, +Owner%_owner% +hwnd_parent +LastFound +ToolWindow -Caption +E0x20 +Delimiter`n
			this._parent := _parent
			GUI, Margin, 0, 0
			try GUI, Color,, % _clone.remove("bkColor")
			try GUI, Font, % Format("s{1} c{2}", _clone.remove("fontSize"), _clone.remove("fontColor")), % _clone.remove("fontName")
			GUI, Add, ListBox, x0 y0 -HScroll +VScroll hwnd_hListBox t512,
			this._AHKID := "ahk_id " . (this._HWND:=_hListBox)
			SysGet, _virtualScreenWidth, 78
			this._overallWidthAlloc := _virtualScreenWidth
			this._hDC := DllCall("GetDC", "UPtr", _hListBox, "UPtr")
			SendMessage, 0x31, 0, 0,, % this._AHKID
			this._hFont := DllCall("SelectObject", "UPtr", this._hDC, "UPtr", ErrorLevel, "UPtr")
			SendMessage, 0x1A1, 0, 0,, % this._AHKID
			this._itemHeight := ErrorLevel
			WinExist("ahk_id " . _hLastFoundWindow)
			GUI, %_GUI%:Default

			for _key in _clone {
				this[_key] := _opt[_key]
			}

			this._setData("")

		}
		__Set(_k, _v) {
			if (_k = "maxSuggestions") {
				_COUNTUPPERTHRESHOLD := eAutocomplete._DropDownList._COUNTUPPERTHRESHOLD
				if _v between 1 and %_COUNTUPPERTHRESHOLD%
					return this._rows:=this._maxSuggestions:=Floor(_v)
				else return this._rows:=this._maxSuggestions
			}
			else if (_k = "transparency") {
				if _v between 1 and 255
				{
					_hLastFoundWindow := WinExist()
					GUI % this._parent ":+LastFound"
					WinSet, Transparent, % this._transparency:=_v
					WinExist("ahk_id " . _hLastFoundWindow)
				}
			return this._transparency
			}
			else if ((_k = "AHKID") || (_k = "HWND"))
				return this["_" . _k]
		}
		__Get(_k) {
			if ((_k = "AHKID") || (_k = "HWND") || (_k = "maxSuggestions") || (_k = "transparency"))
				return this["_" . _k]
		}

		_setData(_list) {
			_list := Trim(_list, "`n")
			StrReplace(_list, "`n",, _count)
			if (_list <> "") {
				_upperThreshold := eAutocomplete._DropDownList._COUNTUPPERTHRESHOLD
				if (++_count > _upperThreshold) {
					_count := _upperThreshold, _list := SubStr(_list, 1, InStr(_list, "`n",,, ++_upperThreshold) - 1)
				}
			}
			this._itemCount := _count
			GuiControl,, % this._HWND, % "`n" . _list
			this._autoSize(_list)
			this._selection := new eAutocomplete._DropDownList._Selection(this._HWND)
		}
		_getWidth(_list) {
			static SM_CXVSCROLL := DllCall("GetSystemMetrics", "UInt", 2)
			_size := "", _w := 0
			_listLines := A_ListLines
			ListLines, Off
			Loop, Parse, % _list, `n
			{
				_substr := SubStr(A_LoopField, 1, ((_l:=InStr(A_LoopField, A_Tab) - 1) > 0) ? _l : _l:=StrLen(A_LoopField))
				DllCall("GetTextExtentPoint32", "UPtr", this._hDC, "Str", _substr, "Int", _l, "Int64*", _size)
				_size &= 0xFFFFFFFF
				((_size > _w) && _w:=_size)
			}
			ListLines % _listLines ? "On" : "Off"
			(_w && _w += 10 + (this._itemCount > this._rows) * SM_CXVSCROLL)
			return _w
		}
		_getHeight() {
			_rows := (this._itemCount < this._rows) ? this._itemCount : this._rows
		return (_rows + 1) * this._itemHeight
		}
		_autoSize(_list) {
			_w := this._lastWidth := this._getWidth(_list), _h := this._getHeight()
			GuiControl, Move, % this._HWND, % "w" . _w . " h" . _h
			this._show(this._visible)
		}

		Class _Selection {

			_index := 0
			_text := ""

			__New(_parent) {
			this._parent := _parent
			}

			index {
				set {
					Control, Choose, % this._index:=value,, % "ahk_id " . this._parent
				return value
				}
				get {
				return this._index
				}
			}
			text {
				get {
					ControlGet, _item, Choice,,, % "ahk_id " . this._parent
				return this._text:=_item ; /LB_GETITEMDATA/LB_SETITEMDATA
				}
				set {
				return this.text
				}
			}
			offsetTop {
				get {
					SendMessage, 0x018E, 0, 0,, % "ahk_id " . this._parent
					return this._offsetTop := this._index - ErrorLevel
				}
				set {
				return this.offsetTop
				}
			}

		}
		_getItemData(_suggestion, _dataMaxIndex:=3) {
			(_item:=[])[_dataMaxIndex] := ""
			for _index, _element in StrSplit(_suggestion, A_Tab, A_Tab . A_Space, _dataMaxIndex)
				_item[_index] := _element
		return _item
		}

		_setPosition() {
			_coordModeCaret := A_CoordModeCaret
			CoordMode, Caret, Screen
				if not (A_CaretX+0 <> "") {
					CoordMode, Caret, % _coordModeCaret
				return
				}
				_x1 := A_CaretX + 5, _y := A_CaretY + 30
				_x2 := _x1 + this._lastWidth
				_x := (_x2 > this._overallWidthAlloc) ? this._overallWidthAlloc - this._lastWidth : _x1
				this._show(this._visible, "x" . (this._lastX:=_x) . " y" . (this._lastY:=_y))
			CoordMode, Caret, % _coordModeCaret
		}
		_show(_boolean:=true, _params:="") {
			GUI % this._parent . ":Show", % ((this._visible:=_boolean) ? "NA AutoSize" : "Hide") . A_Space . _params
		}
		_showDropDown() {
		this._setPosition(), this._show()
		}
		_hideDropDown() {
		this._show(false)
		}

		_select(_index) {
			_selection := this._selection, _selection.index := _index
			((_fn:=this._onSelectionChanged) && _fn.call(_selection))
		}
		_selectUp() {
		_index := this._selection._index
		((--_index < 1) && _index:=this._itemCount)
		this._select(_index)
		}
		_selectDown() {
		_index := this._selection._index
		((++_index > this._itemCount) && _index:=1)
		this._select(_index)
		}

		_dispose() {
		eAutocomplete._eventObjects[ this ] := ""
		}
		__Delete() {
			MsgBox % A_ThisFunc
			GUI % this._parent . ":Destroy"
			DllCall("SelectObject", "UPtr", this._hDC, "UPtr", this._hFont, "UPtr")
			DllCall("ReleaseDC", "UPtr", this._HWND, "UPtr", this._hDC)
		}

	}
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PUBLIC PROPERTIES ■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
		static _properties :=
		(LTrim Join C
			{
				AHKID: "",
				autoSuggest: true,
				collectAt: 4,
				collectWords: true,
				disabled: false,
				endKeys: "?!,;.:(){}[\]'""<>\\@=/|",
				expandWithSpace: true,
				HWND: "",
				learnWords: false,
				matchModeRegEx: true,
				minWordLength: 4,
				dropDownList: {
					bkColor: "FFFFFF",
					fontColor: "000000",
					fontName: "Segoe UI",
					fontSize: "13",
					maxSuggestions: 7,
					transparency: 235
				},
				onCompletionCompleted: "",
				onReplacement: "",
				onResize: "",
				onSuggestionLookUp: "",
				onValueChanged: "",
				regExSymbol: "*",
				source: eAutocomplete._Resource.table["Default"],
				suggestAt: 2
			}
		)
	__Set(_k, _v) {
		if (eAutocomplete._properties.hasKey(_k))
		{
			if ((_k = "AHKID") || (_k = "dropDownList") || (_k = "HWND"))
				return this["_" . _k]
			else if ((_k = "autoSuggest") || (_k = "collectWords") || (_k = "expandWithSpace") || (_k = "learnWords") || (_k = "matchModeRegEx"))
				return this["_" . _k] := !!_v
			else if (_k = "source") {
				if ((_v <> this._source.name) && eAutocomplete._Resource.table.hasKey(_v)) {
					_state := this._disabled
					this.disabled := true
					(this._learnWords && this._source.update())
				return this._source:=eAutocomplete._Resource.table[_v], this._disabled := _state
				}
			return this._source
			}
			else if (_k = "disabled") {
				((this._disabled:=!!_v) && this._suggest(false))
			return this._disabled
			}
			else if ((_k = "onCompletionCompleted") || (_k = "onResize") || (_k = "onValueChanged"))
				return eAutocomplete._eventObjects[ this, "_" . _k ] := _v
			else if ((_k = "onReplacement") || (_k = "onSuggestionLookUp")) {
				((_v <> "") || _v:=this["__" . _k].bind(this))
			return eAutocomplete._eventObjects[ this, "_" . _k ] := _v
			}
			else if ((_k = "collectAt") || (_k = "minWordLength") || (_k = "suggestAt"))
				return (not ((_v:=Floor(_v)) > 0)) ? this["_" . _k] : this["_" . _k]:=_v
			else if (_k = "endKeys") {
				static _lastEndKeys := eAutocomplete._properties.endKeys
				if InStr(_v, this._regExSymbol)
					return this["_endKeys"]
				_lastEndKeys := "", _endKeys := ""
				Loop, parse, % RegExReplace(_v, "\s")
				{
					if (InStr(_lastEndKeys, A_LoopField))
						continue
					_lastEndKeys .= A_LoopField
					if A_LoopField in ^,-,],\
						_endKeys .= "\" . A_LoopField
					else _endKeys .= A_LoopField
				}
				return this["_endKeys"] := _endKeys
			}
			else if (_k = "regExSymbol") {
				_v := Trim(_v, _lastEndKeys . A_Space . "`t`r`n")
			return (not (StrLen(_v) = 1)) ? this._regExSymbol : this._regExSymbol:=_v
			}
		}
	}
	__Get(_k, _params*) {
		if (eAutocomplete._properties.hasKey(_k))
			return this["_" . _k]
	}
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PUBLIC METHODS ■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	dispose() {
		if not (eAutocomplete._instances.hasKey(this._HWND))
			return
		this.disabled := true
		eAutocomplete._instances.delete(this._HWND)
		for _, _instance in eAutocomplete._instances, _noMoreInstance := true, _noMoreFromProcess := true {
			_noMoreInstance := false
			if (_instance._idProcess = this._idProcess) {
				_noMoreFromProcess := false
			break
			}
		}
		(_noMoreInstance && eAutocomplete._winEventHookFunctions[ "DWORD" 0 ]:="")
		(_noMoreFromProcess && eAutocomplete._winEventHookFunctions[ "DWORD" this._idProcess ]:="")
		for _, _ifFuncObj in this._hkIfFuncObjects
			eAutocomplete._hotkeys[ _ifFuncObj ] := ""
		eAutocomplete._eventObjects[ this ] := ""
		if (this.hasKey("_hEditLowerCornerHandle"))
			GuiControl, -g, % this._hEditLowerCornerHandle
		if (this._learnWords)
			this._source.update()
		this._dropDownList._dispose()
	}
	__Delete() {
		MsgBox % A_ThisFunc
	}
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PUBLIC BASE OBJECT METHODS ■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	create(_GUIID, _opt:="") {
		_hLastFoundWindow := WinExist()
		try {
			Gui % _GUIID . ":+LastFoundExist"
			IfWinNotExist
				throw Exception("Invalid GUI window.",, _GUIID)
		} finally WinExist("ahk_id " . _hLastFoundWindow)
	return new eAutocomplete(_GUIID, _opt)
	}
	attach(_hEdit, _opt:="") {
		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinGetClass, _class, % "ahk_id " . _hEdit
		DetectHiddenWindows % _detectHiddenWindows
		if not (_class = "Edit")
			throw Exception("The host control either does not exist or is not a representative of the class Edit.")
		_GUIID := DllCall("user32\GetAncestor", "Ptr", _hEdit, "UInt", 1, "Ptr")
	return new eAutocomplete(_GUIID, _opt, _hEdit)
	}
	setSourceFromVar(_sourceName, _list:="") {
	eAutocomplete._Resource._set(_sourceName, "", _list)
	}
	setSourceFromFile(_sourceName, _fileFullPath) {
	eAutocomplete._Resource._set(_sourceName, _fileFullPath)
	}
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PRIVATE PROPERTIES ■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	_hEditLowerCornerHandle := ""
	_minSize := {w: 51, h: 21}
	_maxSize := {w: A_ScreenWidth, h: A_ScreenHeight}
	_content := ""
	_pendingWord := ""
	_completionData := ""
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PRIVATE METHODS ■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	__New(_GUIID, _opt:="", _hEdit:=0x0) {

		_clone := eAutocomplete._properties.clone()
		_dropDownListOptions := _clone.remove("dropDownList")
		for _key, _defaultValue in _clone
			ObjRawSet(this, "_" . _key, _defaultValue)

		_idProcess := "", DllCall("User32.dll\GetWindowThreadProcessId", "Ptr", _GUIID, "UIntP", _idProcess, "UInt")
		if not (_idProcess)
			throw Exception("Could not retrieve the identifier of the process that created the host window.")
		this._idProcess := _idProcess

		this._parent := _GUIID

		if (IsObject(_opt)) {
			_opt := _opt.clone()
			if (_opt.hasKey("dropDownList") && IsObject(_DDLOptions:=_opt.dropDownList))
				for _k, _v in _DDLOptions
					_dropDownListOptions[_k] := _v
		} else _opt:={editOptions: ""}

		_editOptions := _opt.remove("editOptions")
		if not (_hEdit) {
			GUI, % _GUIID . ":Add", Edit, % _editOptions . " hwnd_hEdit",
			if ((_editOptions <> "") && (_editOptions ~= "i)(^|\s)\K\+?[^-]?Resize(?=\s|$)")) {
				GuiControlGet, _pos, Pos, % _hEdit
				GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 " . Format("x{1} y{2}", _posx + _posw - 7, _posy + _posh - 7) . " hwnd_hEditLowerCornerHandle",
				this._hEditLowerCornerHandle := _hEditLowerCornerHandle, _fn := this.__resize.bind(this)
				GuiControl +g, % _hEditLowerCornerHandle, % _fn
			}
		}
		this._AHKID := "ahk_id " . (this._HWND:=_hEdit)

		_dropDownList := this._dropDownList := new eAutocomplete._dropDownList(_GUIID, _dropDownListOptions)
		eAutocomplete._eventObjects[ this._dropDownList, "_onSelectionChanged" ] := this._showcaseInterimResult.bind(this)

		for _key, _value in _opt
			(_clone.hasKey(_key) && this[_key]:=_value)
		((this._onSuggestionLookUp = "") && this.onSuggestionLookUp:="")
		((this._onReplacement = "") && this.onReplacement:="")

		_HWINEVENTHOOK := ""
		if not (eAutocomplete._winEventHookFunctions[ "DWORD" this._idProcess ]) {
			eAutocomplete._winEventHookFunctions[ "DWORD" this._idProcess, _HWINEVENTHOOK, 0x800E, 0x800E ]
				:= RegisterCallback("eAutocomplete._objectValueChangeEventMonitor")
			eAutocomplete._winEventHookFunctions[ "DWORD" this._idProcess, _HWINEVENTHOOK, 0x000A, 0x000A ]
				:= RegisterCallback("eAutocomplete._systemMoveSizeEventMonitor")
		}
		if not (eAutocomplete._winEventHookFunctions[ "DWORD" 0 ])
			eAutocomplete._winEventHookFunctions[ "DWORD" 0, _HWINEVENTHOOK, 0x8005, 0x8005 ]
				:= RegisterCallback("eAutocomplete._focusEventMonitor")

		this._hkIfFuncObjects := []
		_ifFuncObj := this._hkIfFuncObjects.1 := this._hotkeyPressHandler.bind("", _hEdit)
			eAutocomplete._hotkeys[ _ifFuncObj, "Escape" ] := ObjBindMethod(this, "_suggest", false)
			eAutocomplete._hotkeys[ _ifFuncObj, "Up" ] := ObjBindMethod(_dropDownList, "_selectUp")
			eAutocomplete._hotkeys[ _ifFuncObj, "Down" ] := ObjBindMethod(_dropDownList, "_selectDown")
			eAutocomplete._hotkeys[ _ifFuncObj, "Right" ] := ObjBindMethod(this, "_completionDataLookUp", 2)
			eAutocomplete._hotkeys[ _ifFuncObj, "+Right" ] := ObjBindMethod(this, "_completionDataLookUp", 3)
			eAutocomplete._hotkeys[ _ifFuncObj, "Tab" ] := ObjBindMethod(this, "_complete", "Tab")
			eAutocomplete._hotkeys[ _ifFuncObj, "+Tab" ] := ObjBindMethod(this, "_complete", "Tab")
			eAutocomplete._hotkeys[ _ifFuncObj, "Enter" ] := ObjBindMethod(this, "_complete", "Enter")
			eAutocomplete._hotkeys[ _ifFuncObj, "+Enter" ] := ObjBindMethod(this, "_complete", "Enter")

	return eAutocomplete._instances[_hEdit] := this
	}

	; ==================================================================

	__valueChanged(_hEdit) {
		if (this._hasSuggestions)
			(this._autoSuggest && this._suggest())
		else this._suggest(false)
		(this._onValueChanged && this._onValueChanged.call(this, _hEdit, this._content))
	}
	_capturePendingWord() {
		_wrapper := {base: new eAutocomplete._pendingWordMatchObjectWrapper}
		_content := this._content, _caretPos := this._getSelection()
		_caretIsWellPositioned := (StrLen(RegExReplace(SubStr(_content, _caretPos, 2), "\s$")) <= 1)
		if not (_caretIsWellPositioned)
			return _wrapper
		_leftPart := "?P<leftPart>[^\s" . this._endKeys . this._regExSymbol . "]{" . this._suggestAt - 1 . ",}"
		_isRegex := "?P<isRegEx>\Q" . this._regExSymbol . "\E?"
		_rightPart := "?P<rightPart>[^\s" . this._endKeys . this._regExSymbol . "]+"
		_match := "?P<match>(" . _leftPart . ")(" . _isRegex . ")(" . _rightPart . ")"
		_isComplete := "?P<isComplete>[\s" . this._endKeys . "]?"
		RegExMatch(SubStr(_content, 1, _caretPos), "`nOi)(" . _match . ")(" . _isComplete . ")$", _pendingWord)
		if (_pendingWord.len("isComplete")) {
			_match := _pendingWord.value("match")
			if (_match <> this._dropDownList._getItemData(this._dropDownList._selection.text).1)
				this.__hapax(_match, _pendingWord.len("match"))
		return _wrapper
		}
		for _subPatternName, _subPatternObject in _wrapper.base
			for _property in _subPatternObject
				_wrapper[_subPatternName][_property] := _pendingWord[_property](_subPatternName)
		return _wrapper
	}
	__hapax(_match, _len) {
		if (!this._collectWords || (_len < this._minWordLength))
			return
		_hapaxLegomena := this._source.hapaxLegomena
		(_hapaxLegomena.hasKey(_match) || _hapaxLegomena[_match]:=0)
		if not (++_hapaxLegomena[_match] = this.collectAt)
			return
		this._source.appendValue(_match)
	}
	_hasSuggestions {
		get {
			_pendingWord := this._pendingWord := this._capturePendingWord()
			this._completionData := ""
			if not (this._pendingWord.match.len)
		return 0
			_list := ""
			if ((_subsection:=this._source.subsections[ SubStr(_pendingWord.match.value, 1, 1) ]) <> "") {
				if (_pendingWord.isRegEx.len && this._matchModeRegEx) {
					_substring := _pendingWord.leftPart.value
					RegExMatch(_subsection, "`nsi)\n\Q" . _substring . "\E[^\n]+(?:.*\n\Q" . _substring . "\E.+?(?=\n))?", _match)
					_len := _pendingWord.leftPart.len + 1, _rightPart := _pendingWord.rightPart.value
					_listLines := A_ListLines
					ListLines, Off
					Loop, parse, % _match, `n
					{
						if (InStr(SubStr(A_LoopField, _len), _rightPart))
							_list .= A_LoopField . "`n"
					}
					ListLines % _listLines ? "On" : "Off"
				} else {
					_substring := _pendingWord.match.value
					RegExMatch(_subsection, "`nsi)\n\Q" . _substring . "\E[^\n]+(?:.*\n\Q" . _substring . "\E.+?(?=\n))?", _list)
				}
			}
			this._dropDownList._setData(_list)
		return this._dropDownList._itemCount
		}
	}
	_suggest(_boolean:=true) {
		if (_boolean) {
			this._dropDownList._showDropDown()
		} else {
			(this._dropDownList._selection._index && this._setSelection())
			this._dropDownList._setData("")
			this._dropDownList._hideDropDown()
		}
	}

	_showcaseInterimResult(_selection) {
		_pendingWord := this._pendingWord
		_itemData := this._completionData := this._dropDownList._getItemData(_selection.text)
		if (_pendingWord.isRegEx.len) {
			StringTrimLeft, _missingPart, % _itemData.1, % _pendingWord.leftPart.len
			_pos := _pendingWord.isRegEx.pos - 1
			_len := StrLen(_missingPart)
			this._setSelection(_pos, _pos + 1 + _pendingWord.rightPart.len)
			_pendingWord.match := _pendingWord.leftPart
			_pendingWord.isRegEx.len := 0
		} else {
			StringTrimLeft, _missingPart, % _itemData.1, % StrLen(_pendingWord.match.value)
			_pos := _pendingWord.match.pos - 1 + _pendingWord.match.len
			_len := StrLen(_missingPart)
		}
		this._rawPaste(_missingPart)
		this._setSelection(_pos + _len, _pos)
	}
	_completionDataLookUp(_tabIndex) {
	if not (this._completionData)
		return
	_dropDownList := this._dropDownList
	_coordModeToolTip := A_CoordModeToolTip
	CoordMode, ToolTip, Screen
		_x := _dropDownList._lastX + 10
		_y := _dropDownList._lastY + (_dropDownList._selection.offsetTop - 0.5) * _dropDownList._itemHeight
		ToolTip % this._onSuggestionLookUp.call(this._completionData.1, _tabIndex + 1), % _x, % _y
		KeyWait, Right
		ToolTip
	CoordMode, ToolTip, % _coordModeToolTip
	}
	__onSuggestionLookUp(_value, _tabIndex) {
	return this._completionData[ _tabIndex + 1 ]
	}

	_complete(_completionKey) {
		KeyWait % _completionKey, T0.6
		_isLongPress := ErrorLevel
		if not (this._completionData) {
			this._dropDownList._selectDown()
		return
		}
		_start := this._pendingWord.match.pos - 1, _value := this._completionData.1
		if (_isLongPress) {
			this._setSelection(_start + StrLen(_value), _start)
			_value := this._onReplacement.call(_value, 1 + (A_ThisHotkey <> _completionKey))
			this._rawPaste(_value)
		}
		KeyWait % _completionKey
		this._suggest(false)
		_pos := _start + StrLen(_value), this._setSelection(_pos, _pos)
		if (_completionKey = "Enter") {
			ControlSend,, {Enter}, % this._AHKID
		} else (this._expandWithSpace && this._rawSend("{Space}"))
		((_fn:=this._onCompletionCompleted) && _fn.call(this, _value, _isLongPress))
	}
	__onReplacement(_value, _tabIndex) {
	return this._completionData[ _tabIndex + 1 ]
	}

	; -----------------------------------------------------------------------------------------------
	_getText() {
	ControlGetText, _text,, % this._AHKID
	this._content := _text
	}
	_getSelection(ByRef _startSel:="", ByRef _endSel:="") {
		static EM_GETSEL := 0xB0
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage, % EM_GETSEL, &_startPos, &_endPos,, % this._AHKID
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_setSelection(_startSel:=-1, _endSel:=0) {
		static EM_SETSEL := 0xB1
		SendMessage % EM_SETSEL, % _startSel, % _endSel,, % this._AHKID
	}
	_rawPaste(_string) {
	_state := eAutocomplete._bypassToggle
	eAutocomplete._bypassToggle := true
	Control, EditPaste, % _string,, % this._AHKID
	eAutocomplete._bypassToggle := _state
	}
	_rawSend(_key) {
	_state := eAutocomplete._bypassToggle
	eAutocomplete._bypassToggle := true
	ControlSend,, % _key, % this._AHKID
	eAutocomplete._bypassToggle := _state
	}
	; -----------------------------------------------------------------------------------------------

	__resize(_hEditLowerCornerHandle) {

		_listLines := A_ListLines
		ListLines, Off
		_coordModeMouse := A_CoordModeMouse
		CoordMode, Mouse, Client
		GuiControlGet, _start, Pos, % _hEdit:=this._HWND
		_minSz := this._minSize, _maxSz := this._maxSize
		_state := eAutocomplete._bypassToggle
		eAutocomplete._bypassToggle := true
		while (GetKeyState("LButton", "P")) {
			MouseGetPos, _x, _y
			_w := _x - _startX, _h := _y - _startY
			if (_w <= _minSz.w)
				_w := _minSz.w
			else if (_w >= _maxSz.w)
				_w := _maxSz.w
			if (_h <= _minSz.h)
				_h := _minSz.h
			else if (_h >= _maxSz.h)
				_h := _maxSz.h
			if (this._onResize && this._onResize.call(A_GUI, this, _w, _h, _x, _y))
				Exit
			GuiControl, Move, % _hEdit, % "w" . _w . " h" . _h
			GuiControlGet, _pos, Pos, % _hEdit
			GuiControl, MoveDraw, % _hEditLowerCornerHandle, % "x" . (_posx + _posw - 7) . " y" . _posy + _posh - 7
		sleep, 15
		}
		eAutocomplete._bypassToggle := _state
		CoordMode, Mouse, % _coordModeMouse
		ListLines % _listLines ? "On" : "Off"

	}

	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■ PRIVATE BASE OBJECT METHODS ■■■■■■■■■■■■
	; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	_hotkeyPressHandler(_hwnd, _thisHotkey) {
		_inst := eAutocomplete._instances[_hwnd]
		if not (WinActive("ahk_id " . _inst._parent))
			return false
		ControlGetFocus, _focusedControl, % "ahk_id " . _inst._parent
		ControlGet, _focusedControl, Hwnd,, % _focusedControl, % "ahk_id " . _inst._parent
		if (_focusedControl = _hwnd) {
			_dropDownList := _inst._dropDownList
			if not (_dropDownList._visible) {
				if not ((_thisHotkey = "Down") && _dropDownList._itemCount)
					return false
				_inst._suggest()
			}
		return true
		}
	return false
	}

	_objectValueChangeEventMonitor(_event, _hwnd, _idObject, _idChild, _dwEventThread, _dwmsEventTime) {
		static _isHandlingEvent := false
		static _t := 0
		; static _j := 0
		; ToolTip % ++_j, 800, 0, 8
		if ((_dwmsEventTime - _t) < 30)
			return
		_t := _dwmsEventTime
		if not (_isHandlingEvent) {
			if (_isHandlingEvent:=eAutocomplete._instances.hasKey(_hwnd)) {
			; static _k := 0
			; ToolTip % ++_k, 700, 0, 7
				_inst := eAutocomplete._instances[_hwnd]
				if (_inst._disabled || eAutocomplete._bypassToggle) {
					_isHandlingEvent := false
				return
				}
				_inst._getText(), _inst.__valueChanged(_hwnd)
				_isHandlingEvent := false
			}
		} else if (eAutocomplete._instances.hasKey(_hwnd)) {
			; static _i := 0
			; ToolTip % ++_i, 900, 0, 9
			_inst := eAutocomplete._instances[_hwnd]
			ControlGetText, _text,, % _inst._AHKID
			if (_text <> _inst._content) {
				_inst._getText()
				_fn := _inst.__valueChanged.bind(_inst, _hwnd)
				SetTimer % _fn, -50
			}
			Exit
		}
	}
	_focusEventMonitor(_event, _hwnd) {
		for _each, _instance in eAutocomplete._instances {
			if (_instance._dropDownList._HWND = _hwnd)
				return
		}
		(eAutocomplete._lastFoundInstance && eAutocomplete._instances[eAutocomplete._lastFoundInstance]._suggest(false))
		eAutocomplete._lastFoundInstance := (eAutocomplete._instances.hasKey(_hwnd)) ? _hwnd : 0x0
	}
	_systemMoveSizeEventMonitor(_event, _hwnd) {
			for _each, _instance in eAutocomplete._instances {
				if (_instance._parent = _hwnd) {
					(_instance._dropDownList._visible && _instance._suggest(false))
				}
			}
	}

}
