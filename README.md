## eAutocomplete

Enables users to quickly find and select from a dynamic pre-populated list of suggestions as they type in an AHK Edit control, leveraging searching and filtering.

***

<p align="center">
  <img src="https://raw.githubusercontent.com/A-AhkUser/AHK-forums/master/eAutocomplete/eAutocomplete.png" />
</p>

***

## How to
First create a GUI and use the [+HwndGuiHwnd option](https://www.autohotkey.com/docs/commands/Gui.htm#GuiHwndOutputVar) to store the HWND of the window in `GuiHwnd`
. Create a new instance of `eAutocomplete` in accordance with the following syntax:

```Autohotkey
#NoEnv
#SingleInstance force
SetWorkingDir % A_ScriptDir
SendMode, Input
#Warn

#Include %A_ScriptDir%\eAutocomplete.ahk

list =
(
accepter
acclamer
accolade
accroche
accuser
acerbe
achat
acheter
)
GUIDelimiter := "`n" ; recommended
GUI, +Delimiter%GUIDelimiter% +hwndGUIID
; +hwndGUIID stores the window handle (HWND) of the GUI in 'GUIID'
GUI, Font, s14, Segoe UI
A := new eAutocomplete(GUIID, {options: "Section x11 y11 w300 h65 +Limit"
                             , menuOptions: "ys w100 h200 -VScroll"
                             , startAt: 2})
A.addSource("myList", list)
A.setSource("myList")
GUI, Show, AutoSize, eAutocomplete
return

!Down::A.menuSetSelection(+1) ; select the next suggestion
!Up::A.menuSetSelection(-1) ; select the previous suggestion
```
##
```Autohotkey
A := new eAutocomplete(_GUIID, _options:="")
```
##### parameters:
. ``_GUIID`` [HWND]
###### description:
> A GUI's HWND.
#####
. ``_options`` *OPTIONAL* [OBJECT]
###### description:</br>
> An object. If applicable, the following properties are processed:
##
*Parameters that are marked with asterisk may at any time be modified after the control is created by setting the value of the respective property.
Otherwise, use [GuiControl](https://www.autohotkey.com/docs/commands/GuiControl.htm) to a variety of changes to a control in a GUI window once it is created. `A.HWND` and `A.menu.HWND` contain respectively the edit control and the listbox control's HWND.*

| parameters | description | default value
| :---: | :---: | :---: |
| ``options`` | Set the edit control's options. The `+Resize` option may be listed in ``options`` to allow the user to resize both the height and width of the edit control. *note: The edit control comes with the `ES_MULTILINE` style - which designates a multiline edit control - regardless of whether the `+Multi` is listed in options. It is coerced due to a internal limitation.* | `Section w150 h35 +Multi`
| ``onEvent``* | Associate a function object with the edit control. The value can be either the name of a function or a function reference. | `""`
| ``menuOptions`` | Set the listbox control's options. | `ys h130 w110 -VScroll`
| ``onEvent``* | Associate a function object with the listbox control. The value can be either the name of a function or a function reference. | `""`
| ``menuFontOptions`` | Set the font size, style, and/or color for the listbox control (and for controls added to the window from this point onward just as with the [GUI, Color command](https://www.autohotkey.com/docs/commands/Gui.htm#Color) on which the class relies internally). | `""`
| ``menuFontName`` | Set the font typeface for the listbox control (and for controls added to the window from this point onward just as with the [GUI, Color command](https://www.autohotkey.com/docs/commands/Gui.htm#Color) on which the class relies internally). | `""`
| ``disabled``* | Determine whether or not the word completion feature should start off in an initially-disabled state. | `false`
| ``delimiter``* | Specify the delimiter used by the word list used as source for the word completion. | `"``n"`
| ``startAt``* | Set the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items. | `2`
| ``matchModeRegEx``* | If set to `true`, an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (dot-star pattern). | `true`
| ``appendHapax``* | If the value evaluates to `true`, each *hapax* will be appended to the current local word list (`A.sources[A.source].list`). | `false`
