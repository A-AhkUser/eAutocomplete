Class Word {
	Class _Match {
		isPending := {value: "", pos: 0, len: 0}
		isComplete := {value: "", pos: 0, len: 0}
	}
	_minLength := (this.minLength:=2)
	minLength {
		set {
		return (not ((value:=Floor(value)) > 0)) ? this._minLength : this._minLength:=value
		}
		get {
		return this._minLength
		}
	}
	_endKeys := (this.endKeys:="\/|?!,;.:(){}[]'""<>@=")
	endKeys {
		set {
			local
			_lastEndKeys := "", _endKeys := ""
			_listLines := A_ListLines
			ListLines, 0
			Loop, parse, % RegExReplace(value, "\s")
			{
				if (InStr(_lastEndKeys, A_LoopField))
					continue
				_lastEndKeys .= A_LoopField
				if A_LoopField in \,.,*,?,+,[,],{,},|,(,),^,$
					_endKeys .= "\" . A_LoopField
				else _endKeys .= A_LoopField
			}
			ListLines % _listLines
		return this._endKeys:=_endKeys
		}
		get {
		return this._endKeys
		}
	}
	test(_string, ByRef _wrapper:="") {
		local
		_isPending := "?P<isPending>[^\s" . this.endKeys . "]{" . this.minLength . ",}", _isComplete := "?P<isComplete>[\s" . this.endKeys . "]?"
		_pos := RegExMatch(_string, "`aOi)(" . _isPending . ")(" . _isComplete . ")$", _match)
		for _subPatternName, _subPatternObject in _wrapper := new this._Match()
			for _property in _subPatternObject, _o := _wrapper[_subPatternName]
				_o[_property] := _match[_property](_subPatternName)
		return _pos
	}
}