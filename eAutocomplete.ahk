Class eAutocomplete {

	static sources := []

	source := ""

	__New(_GUIID, _options) {

	static _o :=
	(LTrim Join C
		{
			options: "",
			onEvent: "",
			menuOptions: "",
			menuOnEvent: "",
			menuFontOptions: "",
			menuFontName: "",
			disabled: false,
			delimiter: "`n",
			startAt: 2,
			matchModeRegEx: true,
			appendHapax: false
		}
	)
	for _option, _value in _options, _params := new _o
		_params[_option] := _value

		; Gui % _GUIID . ":+LastFoundExist"
		; IfWinNotExist
			; return !ErrorLevel:=1
		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		if not (WinExist("ahk_id " . _GUIID))
			return !ErrorLevel:=1
		DetectHiddenWindows % _detectHiddenWindows

		RegExReplace(_params.options, "i)(^|\s)\K\+?Resize(?=\s|$)",, _resize)
		GUI, % _GUIID . ":Add", Edit, % _params.options . " hwnd_ID",
		this.AHKID := "ahk_id " . this.HWND:=_ID
		if (_resize) {

			GuiControlGet, _pos, Pos, % _ID
			GUI, % _GUIID . ":Add", Text, % "0x12 w11 h11 x" . _posx + _posw - 7 . " y" . _posy + _posh - 7 . " hwnd_ID", % Chr(9698)
			this._szHwnd := _ID
			_fn := this.__resize.bind(this)
			GuiControl +g, % _ID, % _fn
			this.minSize := {w: 21, h: 21}, this.maxSize := {w: A_ScreenWidth, h: A_ScreenHeight}

		}
		GUI, % _GUIID . ":Font", % _params.menuFontOptions, % _params.menuFontName
		GUI, % _GUIID . ":Add", ListBox, % _params.menuOptions . " hwnd_ID",
		this.menu := {HWND: _ID, AHKID: "ahk_id " . _ID, _selectedItem: 0}

		_options.remove("disabled"), ObjRawSet(this, "_delimiter", "`n"), ObjRawSet(this, "_startAt", 2)
		for _option, _value in _options
			this[_option] := _params[_option]
		this.disabled := _params.disabled

	}

	onEvent {
		set {
			if (IsFunc(_fn:=value)) {
				((_fn.minParams = "") && _fn:=Func(_fn))
				this._onEvent := _fn
			} else this._onEvent := ""
		return _fn
		}
		get {
		return this._onEvent
		}
	}
	menuOnEvent {
		set {
			if (IsFunc(_fn:=value)) {
				((_fn.minParams = "") && _fn:=Func(_fn))
				this._menuOnEvent := _fn
				GuiControl +g, % this.menu.HWND, % _fn
			} else {
				_hwnd := this.menu.HWND
				GuiControl -g, % _hwnd
				GuiControl,, % _hwnd, % this.delimiter
			}
		return _fn
		}
		get {
		return this._menuOnEvent
		}
	}

	__resize(_hwnd) {

		_coordModeMouse := A_CoordModeMouse
		CoordMode, Mouse, Client

		GuiControlGet, _pos, Pos, % _ID:=this.HWND
		_x := _posx, _y := _posy, _minSz := this.minSize, _maxSz := this.maxSize

		while (GetKeyState("LButton", "P")) {
			MouseGetPos, _mousex, _mousey
			_w := _mousex - _x, _h := _mousey - _y
			if (_w <= _minSz.w)
				_w := _minSz.w
			else if (_w >= _maxSz.w)
				_w := _maxSz.w
			if (_h <= _minSz.h)
				_h := _minSz.h
			else if (_h >= _maxSz.h)
				_h := _maxSz.h
			GuiControl, Move, % _ID, % "w" . _w . " h" . _h
			(this.onSize && this.onSize.call(A_GUI, this, _w, _h, _mousex, _mousey))
			GuiControlGet, _pos, Pos, % _ID
			GuiControl, MoveDraw, % _hwnd, % "x" . (_posx + _posw - 7) . " y" . (_posy + _posh - 7)
		sleep, 15
		}
		CoordMode, Mouse, % _coordModeMouse

	}
	onSize {
		set {
			if (IsFunc(_fn:=value)) {
				((_fn.minParams = "") && _fn:=Func(_fn))
				this._onSize := _fn
			} else this._onSize := ""
		return _fn
		}
		get {
		return this._onSize
		}
	}

	addSourceFromFile(_source, _fileFullPath) {
		_list := (_f:=FileOpen(_fileFullPath, 4+0, "UTF-8")).read()
		if (A_LastError)
			return !ErrorLevel:=1, _f.close()
			this.addSource(_source, _list, _fileFullPath)
		return !ErrorLevel:=0, _f.close()
	}
	addSource(_source, _list, _fileFullPath:="") {

		_sources := eAutocomplete.sources
		_source := _sources[_source] := {path: _fileFullPath}

		_list := "`n" . _list . "`n"
		Sort, _list, D`n U
		ErrorLevel := 0
		_list := _source.list := LTrim(_list, "`n")

		while ((_letter:=SubStr(_list, 1, 1)) && _pos:=RegExMatch(_list, "Psi)\Q" . _letter . "\E.*\n\Q" . _letter . "\E.+?\n", _len)) {
			_source[_letter] := SubStr(_list, 1, _pos + _len - 1), _list := SubStr(_list, _pos + _len)
		}

	}
	setSource(_source) {
	if (eAutocomplete.sources.hasKey(_source)) {
		GuiControl,, % this.menu.HWND, % this.delimiter
		GuiControl,, % this.HWND,
	return !ErrorLevel:=0, this.source := _source
	}
	return !ErrorLevel:=1
	}

	menuSetSelection(_prm) {

		if (this.disabled or !Round(_prm) + 0)
	return
		_menu := this.menu
		if (_prm > 0) {
			SendMessage, % 0x18B, 0, 0,, % _menu.AHKID
			Control, Choose, % (_menu._selectedItem < ErrorLevel) ? ++_menu._selectedItem : ErrorLevel,, % _menu.AHKID
		} else Control, Choose, % (_menu._selectedItem - 1 > 0) ? --_menu._selectedItem : 1,, % _menu.AHKID
		this._endWord()

	}

	dispose() {
		GuiControl -g, % this.HWND
		this._onEvent := ""
		this.menuOnEvent := ""
		if (this.hasKey("_szHwnd"))
			GuiControl -g, % this._szHwnd
		this._onSize := ""
	}
	; __Delete() {
	; MsgBox, 16,, % A_ThisFunc
	; }

	disabled {
		set {
			if (this._enabled:=!value) {
				_fn := this._suggestWordList.bind(this)
				GuiControl +g, % this.HWND, % _fn
				this.menuOnEvent := this._menuOnEvent
			} else {
				GuiControl -g, % this.HWND
				this.menuOnEvent := ""
			}
		return value
		}
		get {
		return !this._enabled
		}
	}
	startAt {
		set {
		return this._startAt := (value > 1) ? value : this._startAt
		}
		get {
		return this._startAt
		}
	}
	delimiter {
		set {
		return this._delimiter := (StrLen(value) = 1) ? value : this._delimiter
		}
		get {
		return this._delimiter
		}
	}

	; ==================================================================================
	; ==================================================================================

	_getSelection(ByRef _startSel:="", ByRef _endSel:="") { ; cf. https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage 0xB0, &_startPos, &_endPos,, % this.AHKID ; EM_GETSEL
		_startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	return _endSel
	}
	_suggestWordList(_hwnd) {

		ControlGetText, _input,, % this.AHKID
		_s := this._getSelection(), _menu := this.menu

		_match := ""
		_sVicinity := SubStr(_input, _s, 2), _leftSide := SubStr(_input, 1, _s)
		if ((StrLen(RegExReplace(_sVicinity, "\s$")) <= 1)
			&& (RegExMatch(_leftSide, "\S+(?P<IsWord>\s?)$", _m))
			&& (StrLen(_m) >= this.startAt)) {
				if (_mIsWord) {
					if (this.appendHapax && !InStr(_m, "*")) {
						ControlGet, _choice, Choice,,, % _menu.AHKID
						if not ((_m:=RTrim(_m, A_Space)) = _choice)
							this.__hapax(SubStr(_m, 1, 1), _m)
					}
				} else if (_letter:=SubStr(_m, 1, 1)) {
					if (_str:=this.sources[ this.source ][_letter]) {
						if (InStr(_m, "*") && this.matchModeRegEx && (_parts:=StrSplit(_m, "*")).length() = 2) {
							_match := this.delimiter . RegExReplace(_str, "`ami)^(?!" _parts.1 ".*" _parts.2 ").*\n") ; many thanks to AlphaBravo for this regex
							((this.delimiter <> "`n") && _match := StrReplace(_match, "`n", this.delimiter))
						} else {
							RegExMatch("$`n" . _str, "i)\n\Q" . _m . "\E.*\n\Q" . _m . "\E.+?(?=\n)", _match)
							((this.delimiter <> "`n") && _match := StrReplace(_match, "`n", this.delimiter))
						}
					}
				}
		}

		GuiControl,, % _menu.HWND, % _match
		GuiControl, Choose, % _menu.HWND, % _menu._selectedItem:=0

		; ===================================================================
		(this._onEvent && this._onEvent.call(this, _input))
		; ===================================================================

	}
	__hapax(_letter, _value) {

		if ((_source:=this.sources[ this.source ]).hasKey(_letter))
			_source.list := StrReplace(_source.list, _source[_letter], "")
		else _source[_letter] := ""
		_v := _source[_letter] . _value . "`n"
		Sort, _v, D`n U
		_source.list .= (_source[_letter]:=_v)
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, 4+1, "UTF-8")).write(LTrim(_source.list, "`n")), _f.close()
		}

	}
	_endWord() {

		ControlGetText, _input,, % this.AHKID
		GuiControlGet, _selection,, % this.menu.HWND
		_selection := Trim(_selection)
		_s := this._getSelection(_a, _b), _left := SubStr(_input, 1, _s), _right := SubStr(_input, _s + 1)
		_pos := RegExMatch(_left, "P)\S+$", _l)
		StringTrimRight, _left, % _left, % _l
		ControlSetText,, % _left . _selection . _right, % this.AHKID
		SendMessage, 0xB1, % _pos + 1, % _s + StrLen(_selection) - _l,, % this.AHKID ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)

	}

	; ==================================================================================
	; ==================================================================================

}
