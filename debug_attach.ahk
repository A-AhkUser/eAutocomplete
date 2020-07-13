﻿#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
SendMode, Input
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.29.01 32-bit Unicode

#Include %A_ScriptDir%\eAutocomplete.ahk

eAutocomplete.setSourceFromFile("Autocompletion_en", A_ScriptDir . "\Autocompletion_en")
eAutocomplete.setSourceFromFile("Autocompletion_fr", A_ScriptDir . "\Autocompletion_fr")
var =
(
Laurène%A_Tab%test%A_Tab%blabla
Loredana
Francia
)
eAutocomplete.setSourceFromVar("source_test", var)


options :=
(LTrim Join C
	{
		autoSuggest: true,
		collectAt: 4,
		collectWords: true,
		disabled: false,
		editOptions: "w300 h200 +Resize",
		endKeys: "?!,;.:(){}[]'""<>\@=/|",
		expandWithSpace: true,
		learnWords: true,
		minWordLength: 4,
		listbox: {
			bkColor: "FFFFFF",
			fontColor: "000000",
			fontName: "Segoe UI",
			fontSize: "14",
			maxSuggestions: 7,
			transparency: 220
		},
		onCompletion: "test_onCompletion",
		onReplacement: "test_onReplacement",
		onResize: "test_onResize",
		onSuggestionLookUp: "test_onSelectionLookUp",
		source: "Autocompletion_en",
		suggestAt: 2
	}
)
WinWait, ahk_class Notepad
ControlGet, hEdit, Hwnd,, Edit1, % "ahk_id " . WinExist()
A := eAutocomplete.attach(hEdit, options)
; ListLines
; Pause
; =================================================
options2 :=
(LTrim Join C
	{
		autoSuggest: false,
		collectAt: 2,
		collectWords: true,
		disabled: false,
		editOptions: "w300",
		endKeys: "",
		expandWithSpace: false,
		learnWords: false,
		minWordLength: 5,
		listbox: {
			bkColor: "1a4356",
			fontColor: "FFFFFF",
			fontName: "Segoe UI",
			fontSize: "12",
			maxSuggestions: 11,
			transparency: 130
		},
		onCompletion: "test_onCompletion2",
		onReplacement: "",
		onResize: "test_onResize2",
		onSuggestionLookUp: "",
		source: "Autocompletion_fr",
		suggestAt: 1
	}
)
GUI, +Resize +hwndGUIID +LastFound
GUI, Font, s14, Segoe UI
GUI, Color, White, White
GUI, Add, Edit, w400 h400 hwndhEdit,
GUI, Show, AutoSize
WinWaitActive
B := eAutocomplete.attach(hEdit, options2)
OnExit, handleExit
return

!i::
	str := ""
	for k, v in options {
		if (IsObject(v)) {
			str .= ".listbox`r`n"
			for i in v
				str .= A_Tab i A_Tab " ~ " A_Tab (A.listbox)[i] "`r`n"
		} else str .= ((k = "source") || (SubStr(k, 1, 2) = "on")) ? k A_Tab " ~ " A_Tab A[k].name "`r`n" : k A_Tab " ~ " A_Tab A[k] "`r`n"
	}
	MsgBox % str
return

handleExit:
	A.dispose()
	B.dispose()
ExitApp

test_onReplacement(_suggestionText, _tabIndex) {
return "[" _suggestionText "] from " A_ThisFunc " (" _tabIndex ")"
}
test_onCompletion(_instance, _text, _isRemplacement) {
ToolTip % A_ThisFunc " `r`n " _instance.HWND+0 " `r`n " _text "[" _isRemplacement "]"
}
test_onResize(_GUI, _instance, _w, _h, _x, _y) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _w "," _h "," _x "," _y
}
test_onSelectionLookUp(_suggestionText, _tabIndex) {
return _suggestionText "[" _tabIndex "] from " A_ThisFunc
}

test_onReplacement2(_suggestionText, _tabIndex) {
return "[" _suggestionText "] from " A_ThisFunc " (" _tabIndex ")"
}
test_onCompletion2(_instance, _text, _isRemplacement) {
ToolTip % A_ThisFunc " `r`n " _instance.HWND+0 " `r`n " _text "[" _isRemplacement "]"
}
test_onResize2(_GUI, _instance, _w, _h, _x, _y) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _w "," _h "," _x "," _y
}
test_onSelectionLookUp2(_suggestionText, _tabIndex) {
return _suggestionText "[" _tabIndex "] from " A_ThisFunc
}

!s::
	A.autoSuggest := !A.autoSuggest
	A.collectAt := 1
	A.collectWords := !A.collectWords
	; A.disabled := !A.disabled
	A.endKeys := "@"
	A.expandWithSpace := !A.expandWithSpace
	A.learnWords := !A.learnWords
	A.minWordLength := 3
	A.listbox.maxSuggestions := 2
	A.listbox.transparency := 110
	A.listbox.tabStops := 8
	A.onCompletion := "test_onCompletion2"
	A.onReplacement := "test_onReplacement2"
	A.onResize := "test_onResize2"
	A.onSuggestionLookUp := "test_onSelectionLookUp2"
	A.source := "source_test"
	A.suggestAt := 1
return
