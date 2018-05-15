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
CoordMode, ToolTip, Screen
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
GUI, +Resize +hwndGUIID ; +hwndGUIID stores the window handle (HWND) of the GUI in 'GUIID'
GUI, Font, s14, Segoe UI
GUI, Color, White, White
options :=
(LTrim Join C
	{
		editOptions: "x11 y11 w300 h65 +Resize", ; sets the edit control's options; the 'Resize' option may be listed to allow the user to resize both the height and width of the edit control
		menuOptions: "VScroll r10",
		startAt: 2, ; the minimum number of characters a user must type before a search is performed
		matchModeRegEx: true, ;  an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (.*)
		appendHapax: true ; hapax legomena will be appended to the current local word list
	}
)
A := new eAutocomplete(GUIID, options)
GUIDelimiter := "`n"
GUI, +Delimiter%GUIDelimiter% ; important
A.addSource("frenchWords", frenchWords, GUIDelimiter)
A.setSource("frenchWords") ; defines the word list to use
GUI, Show, w400 h330, eAutocomplete
return
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
*Keys that are marked with asterisk may at any time be modified after the control is created by setting the value of the respective property.
Otherwise, use [GuiControl](https://www.autohotkey.com/docs/commands/GuiControl.htm) to make a variety of changes to a control in a GUI window once it is created. `A.HWND` and `A.menu.HWND` contain respectively the edit control and the drop-down list control's HWND.*

| key | description | default value
| :---: | :---: | :---: |
| ``editOptions`` | Set the edit control's options. The `+Resize` option may be listed in ``options`` to allow the user to resize both the height and width of the edit control. *note: The edit control comes with the `ES_MULTILINE` style - which designates a multiline edit control - regardless of whether the `+Multi` is listed in options. It is coerced due to a internal limitation.* | `"w150 h35 Multi"`
| ``menuOptions`` | Set the menu control's options. | `"-VScroll r7"`
| ``onEvent``* | Associate a function object with the edit control. The value can be either the name of a function or a function reference. | `""`
| ``disabled``* | Determine whether or not the word completion feature should start off in an initially-disabled state. | `false`
| ``delimiter``* | Specify the delimiter used by the word list used as source for the word completion. | `` "`n" ``
| ``startAt``* | Set the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items. | `2`
| ``matchModeRegEx``* | If set to `true`, an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (`.*` dot-star pattern). | `true`
| ``appendHapax``* | If the value evaluates to `true`, *hapax legomena* will be appended to the current local word list. | `false`
| ``onSelect``* | Associate a function object with the drop-down list. The value can be either the name of a function or a function reference. | `""`
| ``useTab``* | If the value evaluates to `true`, users can use the TAB key to select an item from the drop-down list. | `false`
##
### Available methods

* setsource
* addSource
* addSourceFromFile
* setdimensions
* dispose
