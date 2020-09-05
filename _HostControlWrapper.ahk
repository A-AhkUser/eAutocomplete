Class _HostControlWrapper {
	; static COMPATIBLE_CLASSES := "Edit"
	static COMPATIBLE_CLASSES := "Edit|RICHEDIT50W"
	instances := []
	lastFound := 0x0
	lastFoundValue := ""
	_notify := false
	notify {
		set {
			value:=!!value
			OnMessage(0x8003, this, value), OnMessage(0x8004, this, value)
		return this._notify:=value
		}
		get {
		return this._notify
		}
	}
	wrap(_hControlAsDigit, _cb:="") {
		local
		_detectHiddenWindows := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinGetClass, _class, % "ahk_id " . _hControlAsDigit
		DetectHiddenWindows % _detectHiddenWindows
		if not (_class ~= "^(" . this.COMPATIBLE_CLASSES . ")$") {
			throw Exception("The host control either does not exist or is not a representative of the class " . this.COMPATIBLE_CLASSES . ".", -1, _class)
		return false
		}
		if (this.instances.hasKey(_hControlAsDigit)) {
			throw Exception("Could not wrap the control (the control is already interfaced).", -1, _hControlAsDigit)
		return false
		}
		this.instances[_hControlAsDigit] := _class
		_hwnd := ""
		try {
			ControlGetFocus, _focusedControl, A
			ControlGet, _hwnd, Hwnd,, % _focusedControl, A
		} catch
			return true
		if (_hwnd = _hControlAsDigit)
			this.lastFound := _hControlAsDigit, (_cb && _cb.call(_hControlAsDigit))
	return true
	}
	unwrap(_hControlAsDigit, _cb:="") {
		this.instances[_hControlAsDigit] := ""
		this.instances.delete(_hControlAsDigit), (_cb && _cb.call())
	}
	unwrapAll() {
		local
		for _hControlAsDigit in this.instances.clone()
			this.unwrap(_hControlAsDigit)
	}
	_dispose() {
		this.notify := false
		this.__focus := this.__value := ""
	}
	__Delete() {
		; MsgBox % A_ThisFunc
	}
	__Call(_callee, _params*) {
		local
		if (IsFunc(this.base.__Class "._" _callee)) {
			_toggle := this.notify
			this.notify := false
			this["_" . _callee](_params*)
			sleep, 10 ; <<<<
			this.notify := _toggle
		}
	}
	_sendText(_text) {
		this._send("{Text}" . _text)
	}
	_send(_keys) {
		local
		sleep, 1 ; <<<<
		ControlFocus,, % "ahk_id " . this.lastFound
		_keyDelay := A_KeyDelay
		SetKeyDelay, 0
		SendInput, % _keys
		SetKeyDelay % _keyDelay
	}
	getCaretPos(ByRef _atWordBufferPos:="", ByRef _startPos:="", ByRef _endPos:="") {
		local
		static EM_GETSEL := 0xB0
		VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
		SendMessage, % EM_GETSEL, &_startPos, &_endPos,, % "ahk_id " . this.lastFound
		_caretPos := ""
		if (IsByref(_atWordBufferPos)) {
			_caretPos := NumGet(_endPos)
			_atWordBufferPos := ((_startPos = _endPos) && (StrLen(RegExReplace(SubStr(this.lastFoundValue, _caretPos, 2), "\s$")) <= 1))
		}
	return _caretPos
	}
	call(_param1, _param2, _msg, _hwnd) {
		local
		static OBJID_CLIENT := 0xFFFFFFFC
		static EVENT_FOCUS := 0x8003
		static EVENT_VALUE := 0x8004
		Critical
		if (_msg = EVENT_VALUE) {
			if (this.instances.hasKey(_param1)) {
				_acc := this._Utils.Acc.ObjectFromEvent(_idChild_, _param1, OBJID_CLIENT, _param2)
				try this.lastFoundValue := _acc.accValue(0)
				this.__value.call()
			}
		} else if (_msg = EVENT_FOCUS) {
			this.__focus.call(this.lastFound:=this.instances.hasKey(_param1) * _param1)
		}
	}
	Class _Utils {
		Class Acc {
			Init() {
				static _h := ""
				IfNotEqual, _h,, return
				_h := DllCall("Kernel32.dll\LoadLibrary", "Str", "Oleacc.dll", "UPtr")
			}
			ObjectFromEvent(ByRef _idChild_, _hWnd, _idObject, _idChild) {
				local
				static VT_DISPATCH := 9
				static S_OK := 0x00
				this.Init(), _pAcc := ""
				_hResult := DllCall("Oleacc.dll\AccessibleObjectFromEvent"
				, "Ptr", _hWnd, "UInt", _idObject, "UInt", _idChild, "PtrP", _pAcc, "Ptr", VarSetCapacity(_varChild, 8 + 2 * A_PtrSize, 0) * 0 + &_varChild)
				if (_hResult = 0)
					return ComObj(VT_DISPATCH, _pAcc, 1), _idChild_ := NumGet(_varChild, 8, "UInt")
			}
		}
	}
	#Include %A_LineFile%\..\_HostControlWrapper.Complete.ahk
	#Include %A_LineFile%\..\_HostControlWrapper.EventsMessenger.ahk
}