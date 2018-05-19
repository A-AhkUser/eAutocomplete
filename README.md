## eAutocomplete

Enables users to quickly find and select from a dynamic pre-populated list of suggestions as they type in an AHK Edit control, leveraging typing, searching and/or filtering.

> forum thread @[AutoHotkey.com](https://autohotkey.com/boards/viewtopic.php?f=6&t=48940)

***

<p align="center">
  <img src="https://raw.githubusercontent.com/A-AhkUser/AHK-forums/master/eAutocomplete/eAutocomplete.gif" />
</p>

***
## Table of Contents
<ul>
  <li><a href="#description-commands">Description, commands</a></li>
  <li><a href="#how-to">How to</a></li>
  <li><a href="#options">Options</a></li>
  <li><a href="#available-methods">Available methods</a></li>
  <li><a href="#event-handling">Event handling</a></li>
  <li><a href="https://github.com/A-AhkUser/eAutocomplete/tree/attach"><i>Attach method [experimental]</i></a></li>
</ul>

## Description, commands
The script enables users, as typing in the Edit control, to quickly find and select from a dynamic pre-populated list of suggestions in order to expand partially entered strings into complete strings. When a user starts to type in the edit control, a listbox should display suggestions to complete the word, based both on earlier typed letters and the content of a [custom list](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#available-methods).

* Use both the `Down` and `Up` arrow keys (or alternatively `Tab` and `Shift+Tab`) to select from the list of available suggestions.
* Press the `Right` key to send the selected item (or simply `Enter` if you also intend to move to the next line at the same time).
* The drop-down list can be closed by pressing the `ESC` key.
* Use both the `Alt+Left` and `Alt+Right` keyboard shortcuts to respectively shrink/expand the menu.

By default, an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression, matching zero or more occurrences of any character (for example, ' **v**\***o** ' matches ' **v**olcan**o** '). As for *hapax legomena* they are by default appended to the current list, whether it is a variable or a file (see also: [options](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options)).

## How to
First create a GUI and use the [+HwndGuiHwnd option](https://www.autohotkey.com/docs/commands/Gui.htm#GuiHwndOutputVar) to store the HWND of the window in `GuiHwnd`
. Create a new instance of `eAutocomplete` in accordance with the following syntax:

```Autohotkey
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
englishWords := "door*rain*car*window*time*house*sun"
GUI, +Resize +hwndGUIID ; +hwndGUIID stores the window handle (HWND) of the GUI in 'GUIID'
GUI, Font, s14, Segoe UI
GUI, Color, White, White
options :=
(LTrim Join C
	{
		editOptions: "Section x11 y11 w300 h65 +Resize", ; sets the edit control's options; the 'Resize' option may be listed to allow the user to resize both the height and width of the edit control
		startAt: 2, ; the minimum number of characters a user must type before a search is performed
		matchModeRegEx: true, ;  an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (.*)
		appendHapax: true, ; hapax legomena will be appended to the current local word list
		maxSuggestions: 5
	}
)
A := new eAutocomplete(GUIID, options)
A.addSource("frenchWords", frenchWords, "`n")
A.addSource("englishWords", englishWords, "*")
; A.setSource("englishWords") ; defines the word list to use
A.setSource("frenchWords") ; defines the word list to use
GUI, Show, w400 h330, eAutocomplete
return
```
##
***
```Autohotkey
A := new eAutocomplete(_GUIID, _options:="")
```
***
##### parameters:
. ``_GUIID`` [HWND]
###### description:
> A GUI's HWND.
#####
. ``_options`` *OPTIONAL* [OBJECT]
###### description:</br>
> An object. If applicable, the following properties are processed:
##
### Options
*Keys that are marked with asterisk may at any time be modified after the control is created by setting the value of the respective property.
Otherwise, use [GuiControl](https://www.autohotkey.com/docs/commands/GuiControl.htm) to make a variety of changes to a control in a GUI window once it is created. `A.HWND` and `A.menu.HWND` contain respectively the edit control and the drop-down list control's HWND.*

| key | description | default value
| :---: | :---: | :---: |
| ``editOptions`` | Set the edit control's options. The `+Resize` option may be listed in ``options`` to allow the user to resize both the height and width of the edit control. *note: The edit control comes with the `ES_MULTILINE` style - which designates a multiline edit control - regardless of whether the `+Multi` is listed in options. It is coerced due to a internal limitation.* | `"w150 h35 Multi"`
| ``onEvent``* | Associate a function object with the edit control. The value can be either the name of a function or a function reference. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling) | `""`
| ``disabled``* | Determine whether or not the word completion feature should start off in an initially-disabled state. | `false`
| ``startAt``* | Set the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items. | `2`
| ``autoAppend``* |  If it evaluates to `true` - and presuming that the last word partially entered is not a regular expression - the first item in the drop-down list is pre-select/auto-append without the need to press any of the arrow keys. | `false`
| ``matchModeRegEx``* | If set to `true`, an occurrence of the wildcard character in the middle of a string will be interpreted not literally but as a regular expression (`.*` dot-star pattern). | `true`
| ``appendHapax``* | If the value evaluates to `true`, *hapax legomena* will be appended to the current local word list. | `false`
| ``onSelect``* | Associate a function object with the drop-down list. The value can be either the name of a function or a function reference. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling) | `""`
| ``maxSuggestions``* | The maximum number of suggestions to display in the menu (without having to scrolling, if necesary). | `7`
| ``menuBackgroundColor`` | Sets the background color of the menu. | `""`
| ``menuFontName`` | Sets the font typeface for the menu. | `""`
| ``menuFontOptions`` | Sets the size, style, and/or color for the menu. | `""`
##
## Available methods

* **setSource**
* **addSource**
* **addSourceFromFile**

###
***
```AutoHotkey
A.setSource(_source)
```
***
##### description:
Specifies the autocomplete list to use.

| parameters | description |
|:-|:-|
| ``_source`` | The name of a source that was previously defined with ``addSource`` or ``addSourceFromFile``. |
##
***
```AutoHotkey
A.addSource(_source, _list, _delimiter:="`n")
```
***
##### description:
Creates a new autocomplete dictionary from an input string, storing it directly in the base object.

| parameters | description |
|:-|:-|
| ``_source`` | The name of the source, which may consist of alphanumeric characters, underscore and non-ASCII characters. |
| ``_list`` | The list as string. |
| ``_delimiter`` [OPTIONAL] | The delimiter which seperates each item in the list. |
##
***
```AutoHotkey
A.addSourceFromFile(_source, _fileFullPath, _delimiter:="`n")
```
***
##### description:
Creates a new autocomplete dictionary from a file's content, storing it directly in the base object.

| parameters | description |
|:-|:-|
| ``_source`` | The name of the source, which may consist of alphanumeric characters, underscore and non-ASCII characters. |
| ``_fileFullPath`` | The absolute path of the file to read. |
| ``_delimiter`` [OPTIONAL] | The delimiter which seperates each item in the list. |

##
## Event handling

***
```AutoHotkey
A.onEvent := Func("myEventMonitor")
```
***
##### description:
Executes a custom function each time the user or the script itself changes the contents of the edit control.
The function can optionally accept the following parameters:</br>
``myEventMonitor(this, _eHwnd, _input)``

| parameters | description |
|:-|:-|
| ``_eHwnd`` | Contains the edit control's HWND. |
| ``_input`` | Contains the edit control's current content. |
##
***
```AutoHotkey
A.onSelect := Func("mySelectEventMonitor")
```
***
##### description:
Executes a custom function when the user selects a suggestion from the drop-down list (by pressing `Tab`).
The function can optionally accept the following parameters:</br>
``mySelectEventMonitor(this, _selection)``

| parameters | description |
|:-|:-|
| ``_selection`` | Contains the text of the suggestion selected by the user. |
##
***
```AutoHotkey
A.onSize := Func("mySizeEventMonitor")
```
***
##### description:
Executes a custom function when the user resizes the edit control (note: the control must have +Resize listed in `editOptions` to allow resizing by the user).
The function can optionally accept the following parameters:</br>
``mySizeEventMonitor(_parent, this, _w, _h, _mousex, _mousey)``

| parameters | description |
|:-|:-|
| ``_parent`` | The name, number or HWND of the GUI itself. |
| ``_w`` | The current edit control's width. |
| ``_h`` | The current edit control's height. |
| ``_mousex`` |  The current position (abscissa) of the mouse cursor (coordinate is relative to the active window's client area). |
| ``_mousey`` | The current position (ordinate) of the mouse cursor (coordinate is relative to the active window's client area). |
