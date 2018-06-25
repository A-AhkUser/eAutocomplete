#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
SendMode, Input
#Warn
; Windows 8.1 64 bit - Autohotkey v1.1.28.00 32-bit Unicode

#Include %A_ScriptDir%\eAutocomplete.ahk

if not (FileExist(A_ScriptDir . "\wordlist.txt"))
	UrlDownloadToFile % "https://raw.githubusercontent.com/sl5net/global-IntelliSense-everywhere/master/Wordlists/_globalWordLists/languages/WordList%20English%20Gutenberg.txt", % A_ScriptDir . "\wordlist.txt"
eAutocomplete.setSourceFromFile("mySource", A_ScriptDir . "\wordlist.txt")
if not (FileExist(A_ScriptDir . "\wordlist2.txt"))
	UrlDownloadToFile % "https://raw.githubusercontent.com/A-AhkUser/keypad-library/master/Keypad/Autocompletion/fr", % A_ScriptDir . "\wordlist2.txt"
eAutocomplete.setSourceFromFile("mySource2", A_ScriptDir . "\wordlist2.txt")
var =
(
Laurène%A_Tab%test%A_Tab%blabla
Loredana
Francia
)
eAutocomplete.setSourceFromVar("source_test", var)

GUI, +Resize +hwndGUIID
GUI, Font, s14, Segoe UI
GUI, Color, White, White
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
		matchModeRegEx: true,
		minWordLength: 4,
		dropDownList: {
			bkColor: "FFFFFF",
			fontColor: "000000",
			fontName: "Segoe UI",
			fontSize: "14",
			maxSuggestions: 7,
			transparency: 220
		},
		onCompletionCompleted: "test_onCompletionCompleted",
		onReplacement: "test_onReplacement",
		onResize: "test_onResize",
		onSuggestionLookUp: "test_onSelectionLookUp",
		onValueChanged: "test_onValueChanged",
		regExSymbol: "*",
		source: "mySource",
		suggestAt: 2
	}
)
A := eAutocomplete.create(GUIID, options)
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
		matchModeRegEx: false,
		minWordLength: 5,
		dropDownList: {
			bkColor: "1a4356",
			fontColor: "FFFFFF",
			fontName: "Segoe UI",
			fontSize: "12",
			maxSuggestions: 11,
			transparency: 130
		},
		onCompletionCompleted: "test_onCompletionCompleted2",
		onReplacement: "",
		onResize: "test_onResize2",
		onSuggestionLookUp: "",
		onValueChanged: "test_onValueChanged2",
		regExSymbol: "*",
		source: "mySource2",
		suggestAt: 1
	}
)
B := eAutocomplete.create(GUIID, options2)
GUI, Show, AutoSize, eAutocomplete
OnExit, handleExit
return

!i::
	str := ""
	for k, v in options {
		if (IsObject(v)) {
			str .= ".dropDownList`r`n"
			for i in v
				str .= A_Tab i " > " (A.dropDownList)[i] "`r`n"
		} else str .= ((k = "source") || (SubStr(k, 1, 2) = "on")) ? k " > " A[k].name "`r`n" : k " > " A[k] "`r`n"
	}
	MsgBox % str
return

handleExit:
	A.dispose()
	B.dispose()
ExitApp

test_onReplacement(_suggestionText) {
return _suggestionText " from " A_ThisFunc
}
test_onCompletionCompleted(_instance, _text, _isRemplacement) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _text "[" _isRemplacement "]"
}
test_onValueChanged(_instance, _hEdit, _content) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _hEdit " >>`r`n" _content
}
test_onResize(_GUI, _instance, _w, _h, _x, _y) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _w "," _h "," _x "," _y
}
test_onSelectionLookUp(_value, _tabIndex) {
return _value "[" _tabIndex "] from " A_ThisFunc
}

test_onReplacement2(_suggestionText) {
return _suggestionText " from " A_ThisFunc
}
test_onCompletionCompleted2(_instance, _text, _isRemplacement) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _text "[" _isRemplacement "]"
}
test_onValueChanged2(_instance, _hEdit, _content) {
static _i := 0
ToolTip % ++_i, 300, 0, 7
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _hEdit " >>`r`n" _content
}
test_onResize2(_GUI, _instance, _w, _h, _x, _y) {
ToolTip % A_ThisFunc "|" _instance.HWND+0 "," _w "," _h "," _x "," _y
}
test_onSelectionLookUp2(_value, _tabIndex) {
return _value "[" _tabIndex "] from " A_ThisFunc
}

!s::
	A.autoSuggest := !A.autoSuggest
	A.collectAt := 1
	A.collectWords := !A.collectWords
	; A.disabled := !A.disabled
	A.endKeys := "@"
	A.expandWithSpace := !A.expandWithSpace
	A.learnWords := !A.learnWords
	A.matchModeRegEx := !A.matchModeRegEx
	A.minWordLength := 3
	A.dropDownList.maxSuggestions := 2
	A.dropDownList.transparency := 110
	A.onCompletionCompleted := "test_onCompletionCompleted2"
	A.onReplacement := "test_onReplacement2"
	A.onResize := "test_onResize2"
	A.onSuggestionLookUp := "test_onSelectionLookUp2"
	A.onValueChanged := "test_onValueChanged2"
	A.regExSymbol := "+"
	A.source := "source_test"
	A.suggestAt := 1
return
