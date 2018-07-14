# *eAutocomplete*
###### AutoHotkey v1.28.00+
***

The library enables users to quickly find, get info tips and select from a dynamic pre-populated list of data (*e.g.* complete strings, replacement strings) as they type in an Edit control, leveraging typing, definition lookups, searching, translation, filtering *etc.*

#### Download the [latest release](https://github.com/A-AhkUser/eAutocomplete/releases)
> note: **Unlike the latest release, the master branch is NOT considered as fully tested on each commit.**

## Table of Contents

<ul>
  <li><a href="#description-commands">Description, commands</a></li>
  <li>How to use
    <ul>
    <li><a href="#how-to">Through scripting</a></li>
    </ul>
  </li>
</ul>
<ul>
  <li><a href="#create-base-method">Create base method</a></li>
  <li><a href="#attach-base-method">Attach base method</a></li>
  <li><a href="#options">Options</a></li>
  <li><a href="#custom-databases">Custom databases</a></li>
  <li><a href="#available-methods">Available methods</a></li>
  <li><a href="#dispose-method">Dispose method</a></li>
  <li><a href="#event-handling">Event handling</a></li>
</ul>

## Description, commands

***

<table align="center">
	<tr>
		<td><img src="https://raw.githubusercontent.com/A-AhkUser/AHK-forums/master/eAutocomplete/eAutocomplete.gif" /></td>
		<td><img src="https://raw.githubusercontent.com/A-AhkUser/AHK-forums/master/eAutocomplete/eAutocomplete2.gif" /></td>
	</tr>
</table>

***

The library enables users, as typing in an Edit control, to quickly find and select from a dynamic pre-populated list of suggestions and, by this means, to expand/replace partially entered strings into/by complete strings. When a user starts to type in the edit control, the script starts searching for entries that match and should display complete strings to choose from, based both on earlier typed letters and the content of a [custom list](#custom-databases). If the host edit control is a single-line edit control, the list of choices is displayed beneath the control, in the manner of a combobox.

* Use `Tab` to select the top most suggestion and both the `Down` and `Up` arrow keys to select from the list all other available suggestions.
* Press the `Tab` key to complete a pending word with the selected suggestion.
* Long press `Tab`/`Shift+Tab` to replace the current partial string by respectively the first/second of the selected [suggestion's own replacement strings](#custom-databases) (or, alternatively, by a [dynamic string](#onreplacement-callback)).
* The `Enter` key is functionally equivalent to the `Tab` one except that it also moves the caret to the next line at the same time.
* The drop-down list can be closed by pressing the `Esc` key.
* Press and hold the `Right`/`Shift+Right` hotkeys to look up respectively the first/second of the selected [suggestion's associated data](#custom-databases) (or, alternatively, [dynamic data](#onsuggestionlookup-callback)). When applicable, data appear in a tooltip, near the selected suggestion.
* If `autoSuggest` is disabled, `Down` displays the drop-down list, assuming one or more suggestions are available (see also: [options](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options)).


By default, an occurrence of the `regExSymbol` - by default: the asterisk - in the middle of a string will be interpreted not literally but as a pattern, matching zero or more occurrences of any non-delimiter characters (*e.g.* ``a*h`` matches ``autohotkey``).
An instance can optionally learn words at their first onset (or simply collect them for use in a single session) by setting the value of both the `learnWords` and `collectWords` options.

## How to
***

#### Through scripting

*An instance of `eAutocomplete` will be from now on referred to as `eA`.*

- Download the [latest release](https://github.com/A-AhkUser/eAutocomplete/releases) and extract the content of the zip file to a location of your choice, for example into your project's folder hierarchy.
- Load the library (`\eAutocomplete.ahk`) by means of the [#Include directive](https://www.autohotkey.com/docs/commands/_Include.htm).
- You can either [create](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#create-method) an `eAutocomplete` control (that is, add a custom edit control to an existing ahk GUI window) or endow with word completion feature an existing edit control (*e.g* *Notepad*'s one) by means of the [attach method](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#attach-method) - both methods returning a new instance of `eAutocomplete`.

## Create base method
***

```Python
eA := eAutocomplete.create(_GUIID, _options:="")
```
***
*The `create` method throws an exception upon failure (such as if the host window does not exist).*

| parameter | description |
|:-|:-|
| ``_GUIID`` [HWND] | The host [window's HWND](https://www.autohotkey.com/docs/misc/WinTitle.htm#ahk_id). |
| ``_options`` *OPTIONAL* [OBJECT] | An [object](https://www.autohotkey.com/docs/Objects.htm#Usage_Associative_Arrays). If applicable, the [following keys](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options) are processed. |

## Attach base method
***

```Python
eA := eAutocomplete.attach(_hEdit, _options:="")
```
***
*The `attach` method throws an exception upon failure (such as if the host control is not a representative of the class `Edit`).*

| parameter | description |
|:-|:-|
| ``_hEdit`` [HWND] | The host edit [control's HWND](https://www.autohotkey.com/docs/commands/ControlGet.htm#Hwnd). |
| ``_options`` *OPTIONAL* [OBJECT] | An [object](https://www.autohotkey.com/docs/Objects.htm#Usage_Associative_Arrays). If applicable, the [following keys](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#options) are processed. |

### Options
***

###### Keys that are marked with asterisk may at any time be modified after [the instance is created](#create-base-method) by setting the value of the respective [property](https://www.autohotkey.com/docs/Objects.htm#Usage_Objects). In other cases, use [GuiControl](https://www.autohotkey.com/docs/commands/GuiControl.htm) or [Control](https://www.autohotkey.com/docs/commands/Control.htm) to make a variety of changes to a control in a window once it is created. `eA.HWND` and `eA.dropDownList.HWND` contain respectively the edit control and the drop-down list control's HWND.

| key (property) | description | default value |
| :---: | :- | :---: |
| ``editOptions`` | Set the [edit control's options](https://www.autohotkey.com/docs/commands/GuiControls.htm#Edit_Options). The `+Resize` option may be listed in ``options`` to allow the user to resize both the height and width of the edit control. This key is not processed if the control is created using the `attach` method. | `""` |
|  |  |  |
| ``autoSuggest``* | If set to `true` the autocompletion automatically displays a drop-down list beneath the current partial string as soon as suggestions are available. Otherwise, if set to `false`, the `Down` key can display the drop-down list, assuming one or more suggestions are available. | `true` |
| ``collectAt``* | Specify how many times a 'word' absent from the database should be typed before being actually collected by the instance. Instance's concept of 'word' is affected by both the `endKeys` and the `minWordLength` options. Once collected, words are valid during a single session (see also: `learnWords`). | `4` |
| ``collectWords``* | Specify whether or not an instance should collect 'words' at their `collectAt`-nth onset. Once collected, words are valid during a single session (see also: `learnWords`). | `true` |
| ``disabled``* | Determine whether or not the word completion feature should start off in an initially-disabled state. | `false` |
| ``endKeys``* | A list of zero or more characters, considered as not being part of a 'word'. Its value affects the behaviour of the `minWordLength`, the `suggestAt` and the `collectWords` options. In particular, any trailing end keys is removed from a string before being collected and, as the case may be, learned. Space characters - space, tab, and newlines - are always considered as end keys. | ` \/\|?!,;.:(){}[]'""<>@= ` |
| ``expandWithSpace``* | If set to `true`, the script automatically expands the complete string with a space upon text expansion/replacement. | `true` |
| ``learnWords``* | If the value evaluates to `true`, collected words will be stored into the instance's current database (note: **if the [source](#custom-databases) is a file, its content will be overwritten, either at the time the source is replaced by a new one by setting the eponymous property or at the time the `dispose` method is called**). | `false` |
| ``matchModeRegEx``* | If set to `true`, an occurrence of the `regExSymbol` (see below) character in the middle of a string will be interpreted not literally but as part of a regular expression. | `true` |
| ``minWordLength``* | Set the minimum number of characters a word must contain to be actually seen as a 'word'. Its value affects the `collectWords` option. | `4` |
| ``regExSymbol``* | The character which is intended to be interpreted - assuming `matchModeRegEx` is set to `true` - as a pattern, matching zero or more occurrences of any non-delimiter character (*e.g.* **a**\***h** matches **a**uto**h**otkey). The value can be any non-space character not listed in the `endKeys` option. | `*` |
| ``source``* | Specifies the [autocomplete list](#custom-databases) to use. The value must be the name of a source that was previously defined using either the [``setSourceFromVar`` or the ``setSourceFromFile`` base method](#available-methods). | `""` |
| ``suggestAt``* | Set the minimum number of characters a user must type before a search is performed. Zero is useful for local data with just a few items, but a higher value should be used when a single character search could match a few thousand items. | `2` |
|  |  |  |
| ``onCompletionCompleted``* | Associate a function with the `completionCompleted` event, which is user-side. This can be used, for example, to an launch a search engine when the user has selected an item. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling). | `""` |
| ``onReplacement``* | Associate a function with the `replacement` event, which is user-side. This can be used to allow dynamic replacements, such as when replacement strings come from a translation API, as an example. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling). | `""` |
| ``onResize``* | Associate a function with the little UI handle which allows resizing by the user and with which is endowed an edit control when it has been created using the `create` method and have `+Resize` listed in `editOptions`. It is launched automatically whenever the user resizes the edit control by its means. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling). | `""` |
| ``onSuggestionLookUp``* | Associate a function with the `suggestionLookUp` event, which is user-side. This can be used to allow dynamic description lookups such as when description strings come from a dictionary API, as an example. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling). | `""` |
| ``onValueChanged``* | Associate a function with the `valueChanged` event, which fires from the host edit control. See also: [Event handling](https://github.com/A-AhkUser/eAutocomplete/blob/master/README.md#event-handling). | `""` |
|  |  |  |
| ``dropDownList.bkColor`` | Sets the background color of the drop-down list. | `FFFFFF` |
| ``dropDownList.fontColor`` | Sets the font color for the drop-down list. | `000000` |
| ``dropDownList.fontName`` | Sets the font typeface for the drop-down list. | `Segoe UI` |
| ``dropDownList.fontSize`` | Sets the font size for the drop-down list. | `13` |
| ``dropDownList.maxSuggestions``* | The maximum number of suggestions to display in the drop-down list, without having to scrolling, if necesary. | `7` |
| ``dropDownList.transparency``* | Specify a number between 0 and 255 to indicate the drop-down list's degree of transparency. | `235` |
|  |  |  |
| ``useRTL``* | The language is intended to be displayed in right-to-left (RTL) mode as with Arabic or Hebrew. **(not yet implemented)** | `false` |

### Custom databases
***

#### Autocompletion data are assumed to be described in a linefeed-separated list of a TSV-formatted lines. A line can describe up to three items, in a tabular structure:
```
автомобиль	véhicule	voiture
```
#### In particular, in this case:
- the first tab-separated item represents the string value which is intended to be displayed in the drop-down list, as an actual suggestion.
- the other two optional items represent potential replacement strings - aside from being able to be displayed as info tips.

Both the second and the third items may be omitted (that is, a line may consist in a single field, whether it is a word or a group of word) - while specifying an empty string (that is, two consecutive tab characters) allows to omit the second item while being able to use the third one as third. Also, each line may be commented out by prefixing it by one or more space (or tab) characters.
</br>

*note: A linefeed-separated list of a TSV-formatted lines can be built in particular from you office suite - from a spreadsheet by saving it as... `.csv` (and specifying a tabulation as field separator)*.

## Available methods
***

* **setSourceFromVar**
* **setSourceFromFile**

*Both methods throw an exception upon failure*

##
***
```Python
eAutocomplete.setSourceFromVar(_sourceName, _list:="")
```
***

###### Creates a new autocomplete dictionary from an input string, storing it directly in the base object.

| parameter | description |
|:-|:-|
| ``_source`` | The name of the source, which may consist of alphanumeric characters, underscore and non-ASCII characters. |
| ``_list`` [OPTIONAL] | The list as string of characters. |

##
***
```Python
eAutocomplete.setSourceFromVar(_sourceName, _fileFullPath)
```
***

###### Creates a new autocomplete dictionary from a file's content, storing it directly in the base object.

| parameter | description |
|:-|:-|
| ``_source`` | The name of the source, which may consist of alphanumeric characters, underscore and non-ASCII characters. |
| ``_fileFullPath`` | The absolute path of the file to read (note: **its content will be overwritten and replaced by an indexed list of suggestion items, either at the time the source is replaced by a new one by setting the eponymous property or at the time the `dispose` method is called**). |

## Dispose method
***

```AutoHotkey
eA.dispose()
```
***

 Releases all circular references by unregistering instance's own hotkeys and event handlers. It also removes instance's own event hook functions (the class hook a few events instead of querying windows objects when needed). A script should call the `dispose` method, at the latest at the time the script exits. Moreover, calling `dispose` ensures that collected words, if any, are stored into the appropriate database, as the case may be. Once the method has been called, any further call has no effect.

## Event handling
***

The script is able to call a user-defined callback for the following events:

- `onValueChanged`
- `onCompletionCompleted`
- `onSuggestionLookUp`
- `onReplacement`
- `onSize`

The value can be either the name of a function, a function reference or a boundFunc object. In the latter case, stucked bound references, if any, are freed at the time the `dispose` instance's own method is called.

###### onValueChanged callback

***
```Python
eA.onValueChanged := Func("myValueChangedEventMonitor")
```
***

Executes a custom function each time the content of the edit control is altered. It is called only after the internal autocomplete search engine actually provided suggestions, if any (as an indicator, it benchmarked [1.1.00+] at 90ms ~ 150ms when testing it using a word list with a overall result for the first type letter of approximately 355000 matching items; otherwise, it is nearly instantaneous). In any event, the callback should be designed to complete quickly. Naturally, **the `onValueChanged` callback should not itself change the value of the host edit control**!

- The function can optionally accept the following parameters:
``myValueChangedEventMonitor(this, _hEdit, _content)``

| parameter | description |
| :---: | :---: |
| ``_hEdit`` | Contains the edit control's HWND. |
| ``_content`` | Contains the edit control's current content. |

###### onCompletionCompleted callback

***
```Python
eA.onCompletionCompleted := Func("myCompletionCompletedEventMonitor")
```
***

 Executes a custom function whenever the user has performed a completion or a replacement by pressing/long pressing either the `Tab` or the `Enter` key.

- The function can optionally accept the following parameters:
``myCompletionCompletedEventMonitor(this, _completeString, _isReplacement)``

| parameter | description |
| :---: | :---: |
| ``_completeString`` | Contains the text of the complete string. |
| ``_isReplacement`` | A boolean value which determines whether or not a remplacement has been performed beforehand. |

###### onSuggestionLookup callback

***
```Python
eA.onSuggestionLookup := Func("mySuggestionLookupEventMonitor")
```
***

 Associate a function with the `suggestionLookUp` event. This would cause the function to be launched automatically whenever the user attempts to query an info tip from the selected suggestion by pressing and holding either the `Right` key (querying the first suggestion's associated *datum*) or the `Shift+Right` hotkey (querying the second suggestion's associated *datum*). The return value of the callback will be used as the actual text displayed in the tooltip. This can be used to allow dynamic description lookups such as when description strings come from a dictionary API, as an example.

- The function can optionally accept the following parameters:
``infoTipText := mySuggestionLookupEventMonitor(_suggestionText, _tabIndex)``

| parameter | description |
| :---: | :---: |
| ``_suggestionText`` | The text of the selected suggestion, as visible in the drop-down list. |
| ``_tabIndex`` | If a variable is specified, it is assigned a number indicating the index of the suggestion's associated *datum*. |

###### onReplacement callback

***
```Python
eA.onReplacement := Func("myReplacementEventMonitor")
```
***

 Associate a function with the `replacement` event. This would cause the function to be launched automatically whenever the user is about to perform a replacement by long pressing either the `Tab`/`Enter` key (first suggestion's associated replacement string) or the `Shift+Tab`/`Shift+Enter` hotkey (second suggestion's associated replacement string). The event fires before the replacement string has been actually sent to the edit control - the return value of the function being actually used as the actual replacement string. This can be used to allow dynamic replacements, such as when replacement strings come from a translation API, as an example.

- The function can optionally accept the following parameters:
``replacementText := myReplacementEventMonitor(_suggestionText, _tabIndex)``

| parameter | description |
| :---: | :---: |
| ``_suggestionText`` | The text of the selected suggestion, as visible in the drop-down list. |
| ``_tabIndex`` | If a variable is specified, it is assigned a number indicating the index of the suggestion's associated replacement string. |

###### onSize callback

***
```Python
eA.onSize := Func("mySizeEventMonitor")
```
***

 Associate a function with the little UI handle which allows resizing by the user and with which is endowed an edit control when it has been created using the `create` method and had `+Resize` listed in `editOptions`. The function is executed automatically whenever the user resizes the edit control by its means. The function can prevent resizing by returning a non-zero integer.

- The function can optionally accept the following parameters:
``preventResizing := mySizeEventMonitor(_parent, this, _w, _h, _mousex, _mousey)``

| parameter | description |
| :---: | :---: |
| ``_parent`` | The name, number or HWND of the GUI itself. |
| ``_w`` | The current edit control's width. |
| ``_h`` | The current edit control's height. |
| ``_mousex`` | The current position (abscissa) of the mouse cursor (coordinate is relative to the active window's client area). |
| ``_mousey`` | The current position (ordinate) of the mouse cursor (coordinate is relative to the active window's client area). |
