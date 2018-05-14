﻿#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
SendMode, Input
CoordMode, ToolTip, Screen
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.28.00 32-bit Unicode

#Include %A_ScriptDir%\eAutocomplete.ahk

if not (FileExist(listPath:=A_ScriptDir . "\englishWordList.txt"))
	UrlDownloadToFile, https://raw.githubusercontent.com/A-AhkUser/keypad-library/master/Keypad/Autocompletion/en, % listPath
frenchWords = alpha|accepter|acclamer|accolade|accroche|accuser|acerbe|achat|acheter

GUI, +Resize +hwndGUIID ; +hwndGUIID stores the window handle (HWND) of the GUI in 'GUIID'
GUI, Font, s14, Segoe UI
GUI, Color, White, White
options :=
(LTrim Join C
	{
		editOptions: "x11 y11 w300 h65 +Resize", ; sets the edit control's options; the 'Resize' option may be listed to allow the user to resize both the height and width of the edit control
		onSize: "onSizeEventMonitor",
		onEvent: "onEventMonitor", ; sets a function object to handle the edit control's events
		onSelect: "onSelectEventMonitor",
		useTab: false,
		menuOptions: "VScroll r10",
		startAt: 2, ; the minimum number of characters a user must type before a search is performed
		matchModeRegEx: true, ;  an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (.*)
		appendHapax: true ; hapax legomena will be appended to the current local word list
	}
)
A := new eAutocomplete(GUIID, options)
GUIDelimiter := "`n"
; GUI, +Delimiter%GUIDelimiter% ; important
; A.addSourceFromFile("englishWordList", listPath, GUIDelimiter)
; A.setSource("englishWordList")
GUIDelimiter := "|"
GUI, +Delimiter%GUIDelimiter% ; important
A.addSource("frenchWords", frenchWords,, GUIDelimiter)
A.setSource("frenchWords") ; defines the word list to use
A.setDimensions(minWidth:=120, minHeight:=55)
A.onSize := Func("onSizeEventMonitor")
GUI, Show, w400 h330, eAutocomplete
OnExit, handleExit
return

handleExit:
A.dispose()
ExitApp

!a::A.appendHapax:=!A.appendHapax
!d::A.disabled:=!A.disabled
!m::A.matchModeRegEx:=!A.matchModeRegEx
!i::
MsgBox % A.onEvent.name
MsgBox % A.onSize.name
MsgBox % A.sources.frenchWords.list
MsgBox % A.HWND
MsgBox % A.menu.HWND
return
onEventMonitor(_autocomplete, _eHwnd, _input) {
ToolTip % _autocomplete.HWND+0 "," _eHwnd "," _input
}
onSelectEventMonitor(_autocomplete, _selection) {
MsgBox, 4,, % "Do you want to search the word " . _selection . "?"
IfMsgBox No
    return
run % "https://duckduckgo.com/?q=" . _selection
}
onSizeEventMonitor(_GUI, _autocomplete, _w, _h, _mousex, _mousey) {
ToolTip % _GUI "," _autocomplete.HWND "," _w "," _h "," _mousex "," _mousey
}
