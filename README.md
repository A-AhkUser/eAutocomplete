## eAutocomplete

Enables users to quickly find and select from a dynamic pre-populated list of suggestions as they type in an Edit control, leveraging typing, searching and/or filtering.

> forum thread @[AutoHotkey.com](https://autohotkey.com/boards/viewtopic.php?f=6&t=48940)

***

<p align="center">
  <img src="https://raw.githubusercontent.com/A-AhkUser/AHK-forums/master/eAutocomplete/eAutocomplete.gif" />
</p>

***
## Table of Contents
<ul>
  <li><a href="#description-commands">Description, commands</a></li>
  <li>How to use
    <ul>
    <li><a href="#how-to">Without scripting</a></li>
    <li><a href="#how-to">Through scripting</a></li>
    </ul>
  </li>
 </ul>
 <ul>
  <li><a href="#create-method">Create base method</a></li>
  <li><a href="#attach-method">Attach base method</a></li>
  <li><a href="#options">Options</a></li>
  <li><a href="#available-methods">Available methods</a></li>
  <li><a href="#event-handling">Event handling</a></li>
</ul>

## Description, commands
The script enables users, as typing in an Edit control, to quickly find and select from a dynamic pre-populated list of suggestions and expand partially entered strings into complete strings. When a user starts to type in the edit control, a listbox should display suggestions to complete the word, based both on earlier typed letters and the content of a [custom list](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#available-methods).

* Use `Tab` to select the top most suggestion and both the `Down` and `Up` arrow keys to select from the list all other available suggestions. If the `autoAppend` option is enabled, the top most suggestion is automatically selected (see also: [options](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options)).
* Press the `Tab` key to send the selected item (or simply `Enter` if you also intend to move to the next line at the same time).
* The drop-down list can be closed by pressing the `Esc` key.
* Use the `Alt+Left` and `Alt+Right` keyboard shortcuts to respectively shrink/expand the menu.

By default, an occurrence of the `regExSymbol` (by default: the asterisk) in the middle of a string will be interpreted not literally but as a regular expression, matching zero or more occurrences of any non-space character (for example, ' **v**\***o** ' matches ' **v**olcan**o** '). As for *hapax legomena*, they are appended to the current list, whether it is a variable or a file.

## How to

#### Without scripting

- Download this repository from [zip/master](https://github.com/A-AhkUser/eAutocomplete/archive/master.zip) and unzip its content in your system.
- Download and install *AutoHotkey* (Unicode 32-bit version) [[Autohotkey.com](https://autohotkey.com/)].
- Run notepad.
- Double-click on `example_attach.ahk` in the main directory. You should in all likelihood see the script's icon on the tray menu (bottom-right part of the screen by default).
- That's it!
  
#### Through scripting

You can either [create](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#create-method) an `eAutocomplete` control or endow with word completion feature an existing edit control by means of the [attach method](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#attach-method).

##
## Create method
***
```Autohotkey
A := eAutocomplete.create(_GUIID, _options:="")
```
***
##### parameters:
. ``_GUIID`` [HWND]
###### description:
> A GUI's HWND.
#####
. ``_options`` *OPTIONAL* [OBJECT]
###### description:</br>
> An object. If applicable, the [following keys](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options) are processed.
##
## Attach method
***
```Autohotkey
A := eAutocomplete.attach(_GUIID, _eHwnd, _options:="")
```
***
##### description:
Endow with word completion feature an existing edit control.
##### parameters:
. ``_GUIID`` [HWND]
###### description:
> The GUI's HWND.
#####
. ``_eHwnd`` [HWND]
###### description:
> The edit control's HWND.
#####
. ``_options`` *OPTIONAL* [OBJECT]
###### description:</br>
> An object. If applicable, the [following keys](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options) are processed:
### Options
*Keys that are marked with asterisk may at any time be modified after the control is created by setting the value of the respective property. In other cases, use [GuiControl](https://www.autohotkey.com/docs/commands/GuiControl.htm) or [Control](https://www.autohotkey.com/docs/commands/Control.htm) to make a variety of changes to a control in a window once it is created. `A.HWND` and `A.menu.HWND` contain respectively the edit control and the drop-down list control's HWND.*

| key | description | default value
| :---: | :---: | :---: |
| ``editOptions`` | Set the edit control's options. The `+Resize` option may be listed in ``options`` to allow the user to resize both the height and width of the edit control. This option has no effect if the control is created using the `attach` method. | `""`
| ``onEvent``* | Associate a function object with the edit control. The value can be either the name of a function or a function reference. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling) | `""`
| ``disabled``* | Determine whether or not the word completion feature should start off in an initially-disabled state. | `false`
| ``startAt``* | Set the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items. | `2`
| ``autoAppend``* |  If it evaluates to `true` - and presuming that the last word partially entered is not a regular expression - the top most item in the drop-down list is pre-selected without the need to press the `Tab` key. | `false`
| ``matchModeRegEx``* | If set to `true`, an occurrence of the `regExSymbol` character (see below) in the middle of a string will be interpreted not literally but as a regular expression. | `true`
| ``regExSymbol``* | The character which is intended to  be interpreted - assuming `matchModeRegEx` is set to `true` - as a regular expression, matching zero or more occurrences of any non-space character (for example, **v**\***o** matches **v**olcan**o**). | `*`
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

*All methods set `ErrorLevel` and return `false` upon failure*
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
eAutocomplete.addSource(_source, _list, _delimiter:="`n")
```
***
##### description:
Creates a new autocomplete dictionary from an input string, storing it directly in the base object.

| parameters | description |
|:-|:-|
| ``_source`` | The name of the source, which may consist of alphanumeric characters, underscore and non-ASCII characters. |
| ``_list`` | The list as string of characters. |
| ``_delimiter`` [OPTIONAL] | The delimiter which seperates each item in the list. |
##
***
```AutoHotkey
eAutocomplete.addSourceFromFile(_source, _fileFullPath, _delimiter:="`n")
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
Executes a custom function each time the user changes the contents of the edit control.
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
Executes a custom function when the user resizes the edit control (note: the control must have been created using the `create` method and have +Resize listed in `editOptions` to allow resizing by the user).
The function can optionally accept the following parameters:</br>
``mySizeEventMonitor(_parent, this, _w, _h, _mousex, _mousey)``

| parameters | description |
|:-|:-|
| ``_parent`` | The name, number or HWND of the GUI itself. |
| ``_w`` | The current edit control's width. |
| ``_h`` | The current edit control's height. |
| ``_mousex`` |  The current position (abscissa) of the mouse cursor (coordinate is relative to the active window's client area). |
| ``_mousey`` | The current position (ordinate) of the mouse cursor (coordinate is relative to the active window's client area). |
