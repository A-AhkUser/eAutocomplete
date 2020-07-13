#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.29.01 32-bit Unicode
CoordMode, ToolTip, Screen

#Include %A_ScriptDir%\eAutocomplete.ahk
eAutocomplete.getInstances := Func("eAutocomplete_getInstances") ; a simple wrapper to access the intended to be internal '_instances' property
eAutocomplete.disposeAll := Func("eAutocomplete_disposeAll")

Autocompletion_en =
(
abandon
ability
able
about
above
absent
absorb
abstract
absurd
abuse
access
accident
account
)
eAutocomplete.setSourceFromVar("Autocompletion_en", Autocompletion_en)

Gui +HWNDID
DllCall("RegisterShellHookWindow", "Ptr", ID) ; https://autohotkey.com/board/topic/80644-how-to-hook-on-to-shell-to-receive-its-messages/
matchingWindowClassName := "Notepad" ; here, we test with all windows which belong to the class 'Notepad'
matchingControlClassName := "Edit" ; otherwise, could also be 'RICHEDIT50W'
options := {autoSuggest: true, suggestAt: 2, onCompletion: "test_onCompletion", source: "Autocompletion_en"} ; some eAutocomplete options
msgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
fn := Func("autoAttachByClassName").bind("Notepad", "Edit", options)
OnMessage(msgNum, fn)
OnExit, handleExit
return

autoAttachByClassName(_wClass, _cClass, _options, _wParam, _lParam) { ; automatically attach any matching control which is not yet wrapped into an eAutocomplete object
	if not ((_wParam = 32772) || (_wParam = 4)) ;  HSHELL_WINDOWACTIVATED := 4 or 32772 > https://superuser.com/questions/971992/how-to-make-autohotkey-automatically-close-a-pop-up-dialog
		return
	; if a new window has been activated...
	WinGetClass, _class, % "ahk_id " . _lParam
	if not (_class == _wClass) ; we first check the window class name against the one passed to the caller...
		return
	WinGet, _list, ControlListHwnd, % "ahk_id " . _lParam
	Loop, parse, % _list, `n
	{
		WinGetClass, _class, % "ahk_id " . A_LoopField
		if not (_class == _cClass) ; ...then we check each control class name against the control class name passed the caller
			return
		; if it is question of a matching control...
		(!eAutocomplete.getInstances().hasKey(A_LoopField) && eAutocomplete.attach(A_LoopField, _options)) ; ...wrap it if it is still not wrapped
		ToolTip % eAutocomplete.getInstances().count() . " control wrapped into a eAutocomplete object.", 0, 0, 1
	}
}

!i::
for k, v in eAutocomplete.getInstances()
	MsgBox % v.AHKID
return

handleExit:
	eAutocomplete.disposeAll()
ExitApp

test_onCompletion(_instance, _text, _isRemplacement) { ; a sample 'onCompletion' callback
ToolTip % A_ThisFunc " `r`n" _text,,, 2
}

eAutocomplete_getInstances() {
return eAutocomplete._instances
}
eAutocomplete_disposeAll() {
	for _each, _instance in eAutocomplete.getInstances().clone() ; we must use a shallow copy of the object returned by getInstances since 'dispose' internally call the 'delete' method
		_instance.dispose()
}
