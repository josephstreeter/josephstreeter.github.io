# Regular Expressions

This page provides practical regular expression (regex) examples for common text manipulation tasks. Explanations and sample input/output are included for clarity.

## Examples

### Remove Dots and Aliases from Email Addresses

This regex removes dots from the local part of an email address and strips out any alias (the `+something` part):

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
> [https://how-to-learn-regex.netlify.app/tutorials/how-to-add-double-quotes-to-text-line-using-regex/](https://how-to-learn-regex.netlify.app/tutorials/how-to-add-double-quotes-to-text-line-using-regex/index.md)
