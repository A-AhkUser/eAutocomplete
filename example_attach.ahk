#NoEnv
#SingleInstance force
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.28.00 32-bit Unicode

#Include %A_ScriptDir%\eAutocomplete.ahk

frenchWords =
(
alpha
accepter
acclamer
accolade
accroche
accuser
acerbe
achat
acheter
)
WinWait, ahk_class Notepad
ControlGet, eHwnd, Hwnd,, Edit1, % "ahk_id " . WinExist()
A := eAutocomplete.attach(WinExist(), eHwnd, {startAt: 2, matchModeRegEx: true, maxSuggestions: 5, autoAppend: true})
eAutocomplete.addSource("frenchWords", frenchWords, "`n")
A.setSource("frenchWords")
OnExit, handleExit
return

handleExit: ; the script should dispose the instance before exiting
A.dispose()
ExitApp
