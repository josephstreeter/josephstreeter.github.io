# DocFx Flavored Markdown

DocFX supports "DocFX Flavored Markdown," or DFM. It is 100% compatible with GitHub Flavored Markdown, and adds some additional functionality, including cross reference and file inclusion.

## Table of Contents

- [Notes](notes)
- [Yaml Header](yaml-header)
- [Cross Reference](cross-reference)


## Yaml Header

Yaml header in DFM is considered as the metadata for the Markdown file. It will transform to yamlheader tag when processed. Yaml header MUST be the first thing in the file and MUST take the form of valid YAML set between triple-dashed lines.

A basic example:

```yaml
---
uid: page.md
title: Page
---
```

## Cross Reference

Cross reference allows you to link to another topic by using its unique identifier (called UID) instead of using its file path.
For conceptual Markdown files UID can be defined by adding a uid metadata in YAML header:

```text
---
uid: uid_of_the_file
---
```

This is a conceptual topic with ```uid``` specified.

## File Inclusion

DFM adds syntax to include other file parts into current file, the included file will also be considered as in DFM syntax. ***NOTE*** that YAML header is **NOT** supported when the file is an inclusion. There are two types of file inclusion: Inline and block, as similar to inline code span and block code.

### Inline

Inline file inclusion is in the following syntax, in which ```<title>``` stands for the title of the included file, and ```<filepath>``` stands for the file path of the included file. The file path can be either absolute or relative.```<filepath>``` can be wrapped by ' or ". NOTE that for inline file inclusion, the file included will be considered as containing only inline tags, for example, ###header inside the file will not transfer since ```<h3>``` is a block tag, while [a](b) will transform to ```<a href='b'>a</a>``` since ```<a>``` is an inline tag.

```text
...Other inline contents... [!include[<title>](<filepath>)]
```

### Block

Block file inclusion must be in a single line and with no prefix characters before the start ```[```. Content inside the included file will transform using DFM syntax.

```text
[!include[<title>](<filepath>)]
```

### Section definition

User may need to define section. Mostly used for code table. Give an example below.

```text
> [!div class="tabbedCodeSnippets" data-resources="OutlookServices.Calendar"]
> ```cs
> <cs code text>
> ```
> ```javascript
> <js code text>
> ```
```

The above blockquote Markdown text will transform to section html as in the following:

```text
<div class="tabbedCodeSnippets" data-resources="OutlookServices.Calendar">
  <pre><code>cs code text</code></pre>
  <pre><code>js code text</code></pre>
</div>
```

### Code Snippet

Allows you to insert code with code language specified. The content of specified code path will expand.

```text
[!code-<language>[<name>](<codepath><queryoption><queryoptionvalue> "<title>")]
```

- ```<language>``` can be made up of any number of character and '-'. However, the recommended value should follow [Highlight.js language names and aliases](http://highlightjs.readthedocs.org/en/latest/css-classes-reference.html#language-names-and-aliases).
- ```<codepath>``` is the relative path in file system which indicates the code snippet file that you want to expand.
- ```<queryoption>``` and ```<queryoptionvalue>``` are used together to retrieve part of the code snippet file in the line range or tag name way. We have 2 query string options to represent these two ways:

|                   |query string using ```#``` |query string using ```?```|
|-------------------|---------------------------|--------------------------|
|1. line range|```#L{startlinenumber}-L{endlinenumber}```|```?start={startlinenumber}&end={endlinenumber}```|
|2. tagname|```#{tagname}```|```?name={tagname}```|
|3. multiple region range|***Unsupported***|```?range={rangequerystring}```|
|4. highlight lines|***Unsupported***|```?highlight={rangequerystring}```|
|5. dedent|***Unsupported***|```?dedent={dedentlength}```|

In ```?``` query string, the whole file will be included if none of the first three option is specified.
If ```dedent``` isn't specified, the maximum common indent will be trimmed automatically.
```<title>``` can be omitted.

### Code Snippet Sample

```text
[!code-csharp[Main](Program.cs)]

[!code[Main](Program.cs#L12-L16 "This is source file")]
[!code-vb[Main](../Application/Program.vb#testsnippet "This is source file")]

[!code[Main](index.xml?start=5&end=9)]
[!code-javascript[Main](../jquery.js?name=testsnippet)]
[!code[Main](index.xml?range=2,5-7,9-) "This includes the lines 2, 5, 6, 7 and lines 9 to the last line"]
[!code[Main](index.xml?highlight=2,5-7,9-) "This includes the whole file with lines 2,5-7,9- highlighted"]
```

### Tag Name Representation in Code Snippet Source File

DFM currently only supports the following ```<language>``` values to be able to retrieve by tag name:

- C#: cs, csharp
- VB: vb, vbnet
- C++: cpp, c++
- F#: fsharp
- XML: xml
- Html: html
- SQL: sql
- Javascript: javascript

## Notes

### Code

```text
> [!NOTE]  
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]  
> Crucial information necessary for users to succeed.

> [!WARNING]  
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.
```

### How each is displayed

Note
> [!NOTE]  
> Highlights information that users should take into account, even when skimming.

Tip
> [!TIP]
> Optional information to help a user be more successful.

Important
> [!IMPORTANT]  
> Crucial information necessary for users to succeed.

Warning
> [!WARNING]  
> Critical content demanding immediate user attention due to potential risks.

Caution
> [!CAUTION]
> Negative potential consequences of an action.
