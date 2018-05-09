#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
SendMode, Input
CoordMode, ToolTip, Screen
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.28.00 32-bit Unicode

#Include %A_ScriptDir%\eAutocomplete.ahk

; lists /-----------------------------------------------------------------------------------------------------------------------
list =
(
abrasif
abreuver
abriter
abroger
abrupt
absence
absolu
absurde
abusif
abyssal
académie
acajou
acarien
accabler
accepter
acclamer
accolade
accroche
accuser
acerbe
achat
acheter
)
if not FileExist(listPath:=A_ScriptDir . "\myList.txt")
	FileAppend,
	(LTrim Join`n
	anunciar
	anuncio
	análisis
	anécdota
	anónimo
	apagado
	apagar
	aparato
	aparecer
	aparentar
	aparente
	aparentemente
	aparición
	apariencia
	apartar
	aparte
	apasionado
	apelar
	apellido
	apenas
	apertura
	), % listPath, UTF-8
; -----------------------------------------------------------------------------------------------------------------------/ lists

; GUI /-----------------------------------------------------------------------------------------------------------------------
GUIDelimiter := "`n" ; recommended
GUI, +Delimiter%GUIDelimiter% +hwndGUIID ; +hwndGUIID stores the window handle (HWND) of the GUI in 'GUIID'
GUI, Font, s14, Segoe UI
GUI, Color, White, Silver
A := new eAutocomplete(GUIID, {options: "Section x11 y11 w300 h158 +Limit"
							, menuOptions: "ys w160 h200 -VScroll"
							, menuFontOptions: "s9 c2372e0"
							, menuFontName: "Arial"
							, onEvent: "A_onEventMonitor"
							, disabled: false
							, startAt: 3 ; the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items
							, appendHapax: true ; append hapax legomena ?
							, delimiter: GUIDelimiter})
A.addSourceFromFile("myNewList", listPath)
A.addSource("myOtherList", list)
A.setSource("myNewList") ; defines the word list to use.
GUI, Show, AutoSize, eAutocomplete
OnExit, handleExit
return

handleExit:
A.dispose()
ExitApp
; -----------------------------------------------------------------------------------------------------------------------/ GUI

; hotkeys /-----------------------------------------------------------------------------------------------------------------------
!Down::A.menuSetSelection(+1) ; select the next suggestion (predictive text input)
!Up::A.menuSetSelection(-1) ; select the previous suggestion (predictive text input)
!i::MsgBox % st_printArr(eAutocomplete)
return
!m::A.setSource("myOtherList")
; -----------------------------------------------------------------------------------------------------------------------/ hotkeys

; callback (optional) /-----------------------------------------------------------------------------------------------------------------------
A_onEventMonitor(_autocomplete, _input) {

	_input := StrReplace(_input, A_Space, "")
	if _input is not alnum
		MsgBox % A_ThisFunc

}
; -----------------------------------------------------------------------------------------------------------------------/ callback (optional)

st_printArr(_array, _depth:=5, _indentLevel:="") { ; cf. https://autohotkey.com/boards/viewtopic.php?f=6&t=53

	for _k, _v in _array, _list := "" {
		if (SubStr(_k, 1, 1) = "_")
			continue
		_list .= _indentLevel . "[" . _k . "]"
		if (IsObject(_v) && _depth > 1)
			_list .= "`n" . st_printArr(_v, _depth - 1, _indentLevel . A_Tab)
		else _list .= " => " . _v
		_list .= "`n"
	}
	return RTrim(_list)

}