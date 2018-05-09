Class eAutocomplete {

	static sources := []

	source := ""

	__New(_GUIID, _options) {

	static _o :=
	(LTrim Join
		{
			options: "",
			content: "",
			onEvent: "",
			menuOptions: "",
			menuOnEvent: "",
			menuFontOptions: "",
			menuFontName: "",
			disabled: false,
			startAt: 2,
			appendHapax: false,
			delimiter: "`n"
		}
	)
	for _option, _value in _options, _params := new _o
		_params[_option] := _value

		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		if not (WinExist("ahk_id " . _GUIID))
			return !ErrorLevel:=1

		GUI, % _GUIID . ":Add", Edit, % _params.options, % _params.content ; RegExReplace(_params.options, "(^|\s)\+?g\S+")
		WinGet, _list, ControlListHwnd
		this.AHKID := "ahk_id " . this.HWND:=(_pos:=InStr(_list, "`n",, 0)) ? SubStr(_list, _pos + 1) : _list
		GUI, % _GUIID . ":Font", % _params.menuFontOptions, % _params.menuFontName
		GUI, % _GUIID . ":Add", ListBox, % _params.menuOptions,
		WinGet, _list, ControlListHwnd
		this.menu := {HWND: _hwnd:=SubStr(_list, InStr(_list, "`n",, 0) + 1), AHKID: "ahk_id " . _hwnd, _selectedItem: 0}
		DetectHiddenWindows % _detectHiddenWindows

		if (IsFunc(_fn:=_params.onEvent)) {
			((_fn.minParams = "") && _fn:=Func(_fn))
			this.onEvent := _fn
		}
		if (IsFunc(_fn:=_params.menuOnEvent)) {
			((_fn.minParams = "") && _fn:=Func(_fn))
			this.menuOnEvent := _fn
		}

		this.disabled := _params.disabled, this.startAt := _params.startAt, this.appendHapax := _params.appendHapax
		this.delimiter := _params.delimiter

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
	if (eAutocomplete.sources.hasKey(_source))
		return !ErrorLevel:=0, this.source := _source
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
	this.sources := []
	GuiControl -g, % this.HWND
	GuiControl -g, % this.menu.HWND
	}

	disabled {
		set {
			if (this._enabled:=!value) {
				_fn := this._suggestWordList.bind(this)
				GuiControl +g, % this.HWND, % _fn
				_fn := this.menuOnEvent.bind(this)
				GuiControl +g, % this.menu.HWND, % _fn
			} else {
				GuiControl -g, % this.HWND
				GuiControl -g, % this.menu.HWND
			}
		return this._enabled
		}
		get {
		return !this._enabled
		}
	}
	startAt {
		set {
		return this._startAt := (value > 1) ? value : this._startAt ? this._startAt : 2
		}
		get {
		return this._startAt
		}
	}
	delimiter {
		set {
		return this._delimiter := (StrLen(value) = 1) ? value : this._delimiter ? this._delimiter : "`n"
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

		_sVicinity := SubStr(_input, _s, 2), _leftSide := SubStr(_input, 1, _s)
		if ((StrLen(RegExReplace(_sVicinity, "\s$")) <= 1)
			&& (RegExMatch(_leftSide, "\S+(?P<IsWord>\s?)$", _m)) ; \n|
			&& (StrLen(_m) >= this.startAt)) {
				if (_mIsWord) {
					if (this.appendHapax && !InStr(_m, "*")) {
						ControlGet, _choice, Choice,,, % _menu.AHKID
						if not ((_m:=RTrim(_m, A_Space)) = _choice)
							this.__hapax(SubStr(_m, 1, 1), _m)
					}
					_match := ""
				} else if (_letter:=SubStr(_m, 1, 1)) {
					if (_str:=this.sources[ this.source ][_letter]) {
						if (InStr(_m, "*") && (_parts:=StrSplit(_m, "*")).length() = 2) {
							_match := RegExReplace(_str, "`am)^(?!" _parts.1 ".*" _parts.2 ").*\n") ; many thanks to AlphaBravo for this regex
							((this.delimiter <> "`n") && _match := StrReplace(_match, "`n", this.delimiter))
						} else {
							RegExMatch("$" . _str, "i)\Q" . _m . "\E.*\n\Q" . _m . "\E.+?(?=\n)", _match)
							((this.delimiter <> "`n") && _match := StrReplace(_match, "`n", this.delimiter))
						}
					}
				}
		} else _match := ""

		GuiControl,, % _menu.HWND, % this.delimiter . _match
		GuiControl, Choose, % _menu.HWND, % _menu._selectedItem:=0

		; ===================================================================
		this.onEvent.call(this, _input)
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