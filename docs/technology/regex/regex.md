# Regular Expressions

There isn't going to be much here other than some examples.

## Examples

**Remove dots from email alias**:

```text
(\.(?=[^@]*?@)|\+[^@]*?(?=@))
```

**Double quote each line**:

```text
"^((.*)$)" => "<<"(.*?)>>"
```

**Double quote each line in Notepad++**:

You can save this as a macro for easy use.

```text
AliceBlue
AntiqueWhite
Aqua
Aquamarine
Azure
Beige
Bisque
Black
BlanchedAlmond
```

Find (in regular expression mode):

```text
(.+)
```

Replace with:

```text
"\1"
```

This adds the quotes:

```text
"AliceBlue"
"AntiqueWhite"
"Aqua"
"Aquamarine"
"Azure"
"Beige"
"Bisque"
"Black"
"BlanchedAlmond"
```

Find (in extended mode):

```text
\r\n
```

Replace with (with a space after the comma, not shown):

```text
, 
```

> This is a work in progress
> [https://how-to-learn-regex.netlify.app/tutorials/how-to-add-double-quotes-to-text-line-using-regex/](https://how-to-learn-regex.netlify.app/tutorials/how-to-add-double-quotes-to-text-line-using-regex/)
