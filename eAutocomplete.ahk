Class eAutocomplete {
	_disabled := false
	_keypressThreshold := 225
	_autoSuggest := true
	_resource := ""
	resource {
		set {
			local
			try _disabled := this.disabled, this.disabled := true, this.WordList._current := value
			catch _exception {
				throw Exception(_exception.message, -1, _exception.extra)
			} finally this.disabled := _disabled
		return this.resource
		}
		get {
		return this.WordList._current
		}
	}
	disabled {
		set {
			value := !!value
			if (value <> this.disabled) {
				OnMessage(0x8004, this._HostControlWrapper, !(this._disabled:=value))
				(value && this._stopPropagation())
				if (this.Menu.isVisible())
					this.Menu.dismiss()
			return this._disabled:=value
			}
		return this.disabled
		}
		get {
		return this._disabled
		}
	}
	keypressThreshold {
		set {
		return (not ((value:=Floor(value)) > 65)) ? this.keypressThreshold : this._keypressThreshold:=value
		}
		get {
		return this._keypressThreshold
		}
	}
	autoSuggest {
		set {
		return this._autoSuggest:=!!value
		}
		get {
		return this._autoSuggest
		}
	}
	WordList {
		set {
			throw Exception("This member is protected (read only).", -1)
		return this.WordList
		}
		get {
		return this._WordList
		}
	}
	Menu {
		set {
			throw Exception("This member is protected (read only).", -1)
		return this.Menu
		}
		get {
		return this._Menu
		}
	}
	Completor {
		set {
			throw Exception("This member is protected (read only).", -1)
		return this.Completor
		}
		get {
		return this._Completor
		}
	}
	wrap(_hHost) {
		local
		_hHost := Format("{:i}", _hHost)
		try _lastFound := "", this._HostControlWrapper.wrap(_hHost, this.__focus__.bind(this))
		catch _exception {
			throw Exception(_exception.message, -1, _exception.extra)
		return
		}
		new this._HostControlWrapper.EventsMessenger(_hHost)
	}
	unwrap(_hHost) {
		local
		_hHost := Format("{:i}", _hwnd:=_hHost)
		try this._HostControlWrapper.EventsMessenger._dispose(_hHost)
		catch _exception {
			throw Exception(_exception.message, -1, _exception.extra)
		return
		}
		this._HostControlWrapper.unwrap(_hHost, this.__focus__.bind(this))
	}
	unwrapAll() {
		this._HostControlWrapper.EventsMessenger._disposeAll()
		this.Menu.owner := ""
		this._HostControlWrapper.unwrapAll()
	}

	__focus__(_hEdit:=0x0, _param2:=false) {
		this._stopPropagation()
		if (_param2)
			this.Menu.hide()
		else if (this._HostControlWrapper.instances.hasKey(Format("{:i}", _hEdit)))
			this.Menu.owner := WinExist("ahk_id " . _hEdit)
		else this.Menu.owner := ""
	}
	__value__() {
		SetTimer % this, % - this._responseTime
	}
	_stopPropagation() {
		SetTimer % this, Off
	}
		_responseTime {
			get {
			return this.keypressThreshold + !this.Menu.isAvailable() * (this.keypressThreshold // 4)
			}
		}
	call(_suggest:=false) {
		local
		static COMPLETEWORD_QUERY := 1
		if ((_suggest || this.autoSuggest) && this._shouldTrigger(_caretPos)) {
			this.Menu._setSuggestionList(_list:="")
			; this.Menu.disabled := true
			_queryType := this.WordList._current.executeQuery(SubStr(this._HostControlWrapper.lastFoundValue, 1, _caretPos), _list)
			if (_queryType < COMPLETEWORD_QUERY)
				this.Menu._setSuggestionList(_list)
			else this.Menu._setSuggestionList()
			; this.Menu.disabled := false
		} else this.Menu._setSuggestionList()
	}
		_shouldTrigger(ByRef _caretPos:="") {
			local
			_HostControlWrapper := this._HostControlWrapper
			_atWordBufferPos := "", _caretPos := _HostControlWrapper.getCaretPos(_atWordBufferPos)
		return _atWordBufferPos
		}

	complete(_eventInfo_:=-1) {
		if (_eventInfo_ > -1)
			this._complete(this.Menu.itemsBox.selection.text, _eventInfo_)
	}
	completeAndGoToNewLine(_eventInfo_:=-1) {
		if (_eventInfo_ > -1)
			this._complete(this.Menu.itemsBox.selection.text, _eventInfo_, -1)
	}
	_complete(_selectedItemText, _variant:=0, _expandModeOverride:="") {
		this._completor(this.WordList._current.Query._history.1, _selectedItemText, _expandModeOverride, _variant)
	}
		__complete__(_fragment, _suggestion, ByRef _expandModeOverride, _variant) {
			local
			_source := this.WordList._current ; ~
			if (_source.deleteItem(_suggestion))
				_source.insertItem(_suggestion)
			_r := this[(_variant) ? "_onReplacement" : "_onComplete"].call(_suggestion, _expandModeOverride)
		return (this.Menu.isAvailable() ? _r : ""), this.Menu._setSuggestionList() ; this.call()
		}
		__complete(_suggestion, ByRef _expandModeOverride:="") {
		return _suggestion
		}
		__remplacement(_suggestion, ByRef _expandModeOverride:="") {
		return _suggestion
		}

	_infoTipInvocationHandler(_text) {
	return this._onSuggestionLookUp.call(_text)
	}
	__suggestionLookUp(_text) {
	return ""
	}
	lookUpSuggestion() {
		_thisHotkey := A_ThisHotkey
		this.Menu.InfoTip.show()
		KeyWait % this._Hotkey(this.Hotkey._ShouldFire, _thisHotkey).key
		this.Menu.InfoTip.hide()
	}
	invokeMenu() {
	this._stopPropagation(), this.call(true)
	}

	#Include %A_LineFile%\..\_HostControlWrapper.ahk
	#Include %A_LineFile%\..\_WordList.ahk
	#Include %A_LineFile%\..\_Window.ahk
	#Include %A_LineFile%\..\_BaseMenu.ahk
	#Include %A_LineFile%\..\_Menu.ahk
	#Include %A_LineFile%\..\_Functor.ahk

	__New() {
		local _classPath, _className
		static _init := -1
		switch _init
		{
			case -1:
				_classPath := StrSplit(this.base.__Class, "."), _className := _classPath.removeAt(1)
				if (_classPath.count() > 0)
					%_className%[_classPath*] := this
				else %_className% := this
			case 0:
				this._Init()
			Default:
				throw Exception(this.__Class . " is at its root designed as a super global automatically initialized singleton. Could not create the new instance.", -1)
		}
		if not (++_init)
			%A_ThisFunc%(this)
	}
	#Include %A_LineFile%\..\_OnEvent.ahk
	Class OnComplete extends eAutocomplete._OnEvent {
	}
	Class OnReplacement extends eAutocomplete._OnEvent {
	}
	Class OnSuggestionLookUp extends eAutocomplete._OnEvent {
	}
	#Include %A_LineFile%\..\_Hotkeys.ahk
	Class _Hotkeys extends eAutocomplete._FunctorEx._Functor {
		Class _ShouldFire {
			hook := Func("StrLen")
			invokeKey := ""
			call(_hotkey) {
			return this.hook.call(_hotkey, (_hotkey = this.invokeKey))
			}
		}
		call(_base, _keyName, _expLevel_:=-1) {
			local _classPath, _count, _className, _target, _method, _exception, _r
			_classPath := StrSplit(this.__Class, ".")
			StrReplace(A_ThisFunc, ".", "", _count)
			_classPath.removeAt(_count)
			_className := _classPath.removeAt(1)
			_method := _classPath.pop()
			_target := %_className%
			; _target := %_className%[_classPath*]
			while (_classPath.count()) {
				_target := _target[_classPath.removeAt(1)]
			}
			try _r := _base.call(eAutocomplete._Hotkeys._ShouldFire, _keyName, _target[_method].bind(_target))
			catch _exception {
				throw Exception(_exception.message, _expLevel_, _exception.extra)
			}
		return _r
		}
		Class _ProxyN extends eAutocomplete._Hotkeys {
			call(_keyName, _expLevel_:=-3) {
			static _lastKeys := {}
			if (_keyName = "") {
				if (_lastKeys.hasKey(this.__Class))
					eAutocomplete._Hotkey(eAutocomplete._Hotkeys._ShouldFire, _lastKeys[ this.__Class ]).unregister()
			return ""
			}
			base.call(eAutocomplete._Hotkey, _keyName, _expLevel_)
			return "", _lastKeys[ this.__Class ] := _keyName
			}
		}
		Class _ProxyL extends eAutocomplete._Hotkeys {
			call(_keyName, _expLevel_:=-3) {
			static _lastKeys := {}
			if (_keyName = "") {
				if (_lastKeys.hasKey(this.__Class))
					eAutocomplete._LongPressHotkey(eAutocomplete._Hotkeys._ShouldFire, _lastKeys[ this.__Class ]).unregister()
			return ""
			}
			base.call(eAutocomplete._LongPressHotkey, _keyName, _expLevel_)
			return "", _lastKeys[ this.__Class ] := _keyName
			}
		}
		Class _ProxyI extends eAutocomplete._Hotkeys._ProxyN {
			call(_keyName) {
				local base
				base.call(_keyName, -4)
			return "", eAutocomplete._Hotkeys._ShouldFire.invokeKey := _keyName
			}
		}
	}
	__keyPress__(_hotkey, _invokeMenu) {
		if (GetKeyState("LButton", "P"))
			return false
		if (_invokeMenu)
			return (!this.Menu.isVisible() && this._shouldTrigger() && !this.Menu.disabled && this.Menu.itemsBox.itemCount)
		if (this.disabled || !this.Menu.isAvailable())
			return false
		else if (this.Menu.isVisible())
			return !this.Menu.disabled
	}
	Class Hotkey extends eAutocomplete._Hotkeys {
		Class LookUpSuggestion extends eAutocomplete._Hotkeys._ProxyN {
		}
		Class complete extends eAutocomplete._Hotkeys._ProxyL {
		}
		Class completeAndGoToNewLine extends eAutocomplete._Hotkeys._ProxyL {
		}
		Class invokeMenu extends eAutocomplete._Hotkeys._ProxyI {
		}
		Class Menu {
			Class hide extends eAutocomplete._Hotkeys._ProxyN {
			}
			Class ItemsBox {
				Class selectPrevious extends eAutocomplete._Hotkeys._ProxyN {
				}
				Class selectNext extends eAutocomplete._Hotkeys._ProxyN {
				}
				Class __selection extends eAutocomplete._Hotkeys._ProxyN {
				}
			}
		}
	}

	_Init() {
		local
		_HostControlWrapper := this._HostControlWrapper := new this._HostControlWrapper()
		_HostControlWrapper.__focus := this.__focus__.bind(this)
		_HostControlWrapper.__value := this.__value__.bind(this)
		this._completor := new _HostControlWrapper.Complete(_HostControlWrapper)
		this._completor.onEvent := this.__complete__.bind(this)
		_Menu := this._Menu := new this._Menu()
		_Menu.itemsBox.onItemClick := this._complete.bind(this)
		_Menu.InfoTip.onInvoke := this._infoTipInvocationHandler.bind(this)
		this.OnComplete(this.__complete.bind(this))
		this.OnReplacement(this.__remplacement.bind(this))
		this.OnSuggestionLookUp(this.__suggestionLookUp.bind(this))
		_HostControlWrapper.notify := true
		_Hotkey := this.Hotkey
		_Hotkey._ShouldFire.hook := this.__keyPress__.bind(this)
		_Hotkey.Menu.hide("+Esc")
		_Hotkey.Menu.itemsBox.selectPrevious("Up")
		_Hotkey.Menu.itemsBox.selectNext("Down")
		_Hotkey.complete("Tab")
		_Hotkey.completeAndGoToNewLine("Enter")
		_Hotkey.lookUpSuggestion("Right")
		_Hotkey.invokeMenu("^+Down")
		OnExit(this._Release.bind(this))
	}
	_Release() {
		this.disabled := true
		try {
			this.unwrapAll()
			this.OnComplete("")
			this.OnReplacement("")
			this.OnSuggestionLookUp("")
			this.Completor.onEvent := ""
			this._HostControlWrapper._dispose()
			this._Hotkey(this.Hotkey._ShouldFire, "")
			this._LongPressHotkey(this.Hotkey._ShouldFire, "")
			this.Menu._dispose()
			this.WordList._disposeAll()
			this.Hotkey._ShouldFire.hook := ""
			; this._HostControlWrapper := ""
			; this._Menu := ""
		}
		this.remove("", Chr(255))
	return 0
	}
	__Version {
		get {
			static __Version := ("2.0.0 α", new eAutocomplete())
		return __Version
		}
		set {
		return this.__Version
		}
	}
}
