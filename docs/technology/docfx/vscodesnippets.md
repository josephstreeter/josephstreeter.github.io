# VS Code Markdown Snippets

Visual Studio Code provides the ability to create custom snippets.

## Creating Custom Snippets

From the Microsoft Visual Studio Code documentation:

> In Visual Studio Code, snippets appear in IntelliSense ```(Ctrl+Space)``` mixed with other suggestions, as well as in a dedicated snippet picker (Insert Snippet in the Command Palette). There is also support for tab-completion: Enable it with ```"editor.tabCompletion": "on"```, type a snippet prefix (trigger text), and press Tab to insert a snippet.

## General Markdown Snippets

The following code covers many of the commonly used elemets used in markdown.

> [!WARNING]
> Much of this was done with CI. Trust but verify.

```yaml
{
    "Table": {
        "prefix": "table",
        "body": [
            "| Header 1 | Header 2 | Header 3 |",
            "| -------- | -------- | -------- |",
            "| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |",
            "| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |",
            "| Row 3 Col 1 | Row 3 Col 2 | Row 3 Col 3 |"
        ],
        "description": "Table"
    },
    "Link": {
        "prefix": "link",
        "body": [
            "[${1:Link Text}](${2:https://example.com})"
        ],
        "description": "Link"
    },
    "Image": {
        "prefix": "image",
        "body": [
            "![${1:Alt Text}](${2:https://example.com/image.jpg})"
        ],
        "description": "Image"
    },
    "Code Block": {
        "prefix": "codeblock",
        "body": [
            "```${1:language}",
            "${2:code}",
            "```"
        ],
        "description": "Code Block"
    },
    "Bold Text": {
        "prefix": "bold",
        "body": [
            "**${1:Bold Text}**"
        ],
        "description": "Bold Text"
    },
    "Italic Text": {
        "prefix": "italic",
        "body": [
            "*${1:Italic Text}*"
        ],
        "description": "Italic Text"
    },
    "Blockquote": {
        "prefix": "blockquote",
        "body": [
            "> ${1:Blockquote Text}"
        ],
        "description": "Blockquote"
    },
    "Horizontal Rule": {
        "prefix": "hr",
        "body": [
            "---"
        ],
        "description": "Horizontal Rule"
    },
    "Ordered List": {
        "prefix": "ol",
        "body": [
            "1. ${1:Item 1}",
            "2. ${2:Item 2}",
            "3. ${3:Item 3}"
        ],
        "description": "Ordered List"
    },
    "Unordered List": {
        "prefix": "ul",
        "body": [
            "- ${1:Item 1}",
            "- ${2:Item 2}",
            "- ${3:Item 3}"
        ],
        "description": "Unordered List"
    },
    "Task List": {
        "prefix": "task",
        "body": [
            "- [ ] ${1:Task 1}",
            "- [ ] ${2:Task 2}",
            "- [ ] ${3:Task 3}"
        ],
        "description": "Task List"
    },
    "Checkbox": {
        "prefix": "checkbox",
        "body": [
            "- [ ] ${1:Unchecked}",
            "- [x] ${2:Checked}"
        ],
        "description": "Checkbox"
    },
    "Table of Contents": {
        "prefix": "toc",
        "body": [
            "## Table of Contents",
            "${1:TOC}"
        ],
        "description": "Table of Contents"
    },
    "Footnote": {
        "prefix": "footnote",
        "body": [
            "${1:Text}[^1]",
            "",
            "[^1]: ${2:Footnote}"
        ],
        "description": "Footnote"
    },
    "Superscript": {
        "prefix": "superscript",
        "body": [
            "${1:Text}<sup>${2:Superscript}</sup>"
        ],
        "description": "Superscript"
    },
    "Subscript": {
        "prefix": "subscript",
        "body": [
            "${1:Text}<sub>${2:Subscript}</sub>"
        ],
        "description": "Subscript"
    },
    "Definition List": {
        "prefix": "deflist",
        "body": [
            "${1:Term}",
            ": ${2:Definition}"
        ],
        "description": "Definition List"
    },
    "Abbreviation": {
        "prefix": "abbr",
        "body": [
            "${1:Abbreviation} (${2:Full Form})"
        ],
        "description": "Abbreviation"
    },
    "Keyboard Shortcut": {
        "prefix": "shortcut",
        "body": [
            "${1:Ctrl}+${2:Alt}+${3:Del}"
        ],
        "description": "Keyboard Shortcut"
    },
    "Math Formula": {
        "prefix": "math",
        "body": [
            "$$",
            "${1:Math Formula}",
            "$$"
        ],
        "description": "Math Formula"
    },
    "Comment": {
        "prefix": "comment",
        "body": [
            "<!-- ${1:Comment} -->"
        ],
        "description": "Comment"
    },
    "Front Matter": {
        "prefix": "frontmatter",
        "body": [
            "---",
            "title: ${1:Title}",
            "date: ${2:YYYY-MM-DD}",
        ],
        "description": "Front Matter"
    },
    "Back Matter": {
        "prefix": "backmatter",
        "body": [
            "---",
            "tags: [${1:Tag1}, ${2:Tag2}]",
            "",
            "---"
        ],
        "description": "Back Matter"
    },
    "Code Snippet": {
        "prefix": "snippet",
        "body": [
            "```${1:language}",
            "${2:code}",
            "```"
        ],
        "description": "Code Snippet"
    },
    "Note": {
        "prefix": "note",
        "body": [
            "> [!NOTE]",
            "> ${1:Note Text}"
        ],
        "description": "Note"
    },
    "Warning": {
        "prefix": "warning",
        "body": [
            "> [!WARNING]", 
            "> ${1:Warning Text}"
        ],
        "description": "Warning"
    },
    "Tip": {
        "prefix": "tip",
        "body": [
            "> [!TIP]",
            "> ${1:Tip Text}"
        ],
        "description": "Tip"
    },
    "Information": {
        "prefix": "information",
        "body": [
            "> [!INFORMATION]",
            "> ${1:Info Text}"
        ],
        "description": "Information"
    },
    "Important": {
        "prefix": "important",
        "body": [
            "> [!Important:", 
            "> ${1:Important Text}"
        ],
        "description": "Important"
    },
    "Error": {
        "prefix": "error",
        "body": [
            "> **Error:** ${1:Error Text}"
        ],
        "description": "Error"
    },
    "Summary": {
        "prefix": "summary",
        "body": [
            "> **Summary:** ${1:Summary Text}"
        ],
        "description": "Summary"
    },
    "Quote": {
        "prefix": "quote",
        "body": [
            "> ${1:Quote Text}"
        ],
        "description": "Quote"
    },
    "Callout": {
        "prefix": "callout",
        "body": [
            "> **${1:Callout Type}:** ${2:Callout Text}"
        ],
        "description": "Callout"
    },
}
```

## KB Article Markdown Snippets

These are snippets to be used as KB Article templates.

```yaml
{
    "KB Troubleshooting Article": {
        "prefix": "KB Troubleshooting Article",
        "body": [
            "# ${1:Title}",
            "",
            "## Introduction",
            "",
            "${2:[Start with a brief introduction explaining the purpose and importance of the troubleshooting guide, emphasizing its role in resolving common issues efficiently.]}",
            "",
            "## Issue description",
            "",
            "${3:[Provide a clear and concise description of the specific issue or problem that this troubleshooting guide addresses.]}",
            "",
            "## Signs and Symptoms",
            "",
            "${4:[List the signs or indicators users may experience when encountering the issue.]}",
            "",
            "## Troubleshooting Steps",
            "",
            "${5:[Provide a checklist of common factors or configurations to verify so users can rule out potential causes of the issue.]}",
            "",
            "**Step 1.** ${6:[Step Title]}",
            "${7:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "**Step 2.** ${8:[Step Title]}",
            "${9:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "**Step 3**. ${10:[Step Title]}",
            "${11:[Provide a detailed description of the most common solution to the issue, including step-by-step instructions for implementation.]}",
            "",
            "## Contact Support",
            "",
            "${12:[Provide contact information or instructions for users to contact support for further assistance if the troubleshooting steps do not resolve the issue.]}",
            "",
            "## Additional Resources",
            "",
            "${13:[Offer links or references to additional resources (such as forums, knowledge base articles, or user guides) that may provide further assistance with troubleshooting the issue.]}",
            "",
            "## Conclusion",
            "",
            "${14:[Conclude the troubleshooting guide with a summary of key points and encourage users to refer back to the guide as needed for future troubleshooting needs.]}",
            "",
            "## Disclaimer",
            "",
            "${15:[Include a disclaimer stating any limitations or liabilities associated with following the troubleshooting guide template, and advise users to use their discretion and seek professional assistance if needed.]}",
            "",
        ],
        "description": "KB Troubleshooting Article"
    },
    "KB Service Description Article": {
        "prefix": "KB Service Description Article",
        "body": [
            "# ${1:Title: [Product/service name]} description",
            "",
            "## Introduction",
            "",
            "${2:[Begin with an engaging introduction that provides context about the product and its purpose.]}",
            "",
            "## Description",
            "",
            "${3:[Provide a brief description of the product, including its main use cases, functionalities, and benefits.]}",
            "",
            "## Key features",
            "",
            "${4:[List the product's key features in bullet points or a numbered list.]}",
            "",
            "## Technical specifications",
            "",
            "${5:[Detail the product's technical specifications, including dimensions, weight, materials, and other relevant technical details.]}",
            "",
            "## Compatibility",
            "",
            "${6:[Specify compatibility requirements or limitations, such as operating systems, software versions, or hardware requirements.]}",
            "",
            "## Maintenance tips",
            "",
            "${7:[Provide advice on maintaining the product for optimal performance and longevity.]}",
            "",
            "## Additional information",
            "",
            "${8:[Include any additional information about the product, such as warranty details, regulatory compliance, or certifications.]}",
            "",
            "## Conclusion",
            "",
            "${8:[Conclude the article by summarizing the main points about the product and encouraging users to explore further or reach out for assistance if needed.]}",
            "",
        ],
        "description": "KB Service Description Article"
    },
    "KB Process Article": {
        "prefix": "KB Process Article",
        "body": [
            "# ${1:Title}",
            "",
            "## Introduction",
            "",
            "${2:[Start with a brief introduction explaining the purpose and importance of the process covered in this guide.]}",
            "",
            "## Process description",
            "",
            "${3:[Provide a concise description of the process, outlining its objectives and significance.]}",
            "",
            "## Prerequisites",
            "",
            "${4:[Detail any prerequisites or requirements necessary before initiating the process.]}",
            "",
            "## Gathering materials/resources",
            "",
            "${5:[Provide instructions on gathering the necessary materials, resources, or information needed for the process.]}",
            "",
            "## Step-by-step instructions",
            "",
            "${6:[Offer detailed, step-by-step instructions for executing each stage of the process.]}",
            "",
            "1. [Insert step]",
            "",
            "2. [Insert step]",
            "etc.",
            "",
            "","## Tips and best practices",
            "",
            "${7:[Include any tips, tricks, or best practices that may aid in completing the process efficiently and effectively.]}",
            "",
            "## Next steps",
            "",
            "${8:[Offer guidance on what to do after completing the process, including any follow-up actions or additional resources.]}",
            "",
            "## Additional information",
            "",
            "${9:[Include any supplementary information relevant to the process, such as related documents, templates, or references.]}",
            "",
            "## Disclaimer",
            "",
            "${10:[Include a disclaimer stating any limitations or liabilities associated with following the process guide template, and advise users to use their discretion and seek professional advice if needed.]}",
            "",
        ],
        "description": "KB Process Article"
    },
    "KB FAQ Article": {
        "prefix": "KB FAQ Article",
        "body": [
            "# ${1:[Title: Topic] FAQs}",
            "",
            "## Introduction",
            "",
            "${2:[Provide a brief introduction to the topic covered in this FAQ article.]}",
            "",
            "**Question 1:** ${3:[Example: What are the system requirements to run this software?]}",
            "",
            "**Answer:**",
            "${4:[Concisely answer the question or direct the reader to the product page where the system requirements can be found.]}",
            "",
            "**Question 2:** ${5:[Example: How do I use a coupon code at checkout?]}",
            "",
            "**Answer**",
            "${6:[Explain where the promo code field is located and include a screenshot.]}",
            "",
            "**Question 3:** ${7:[Example: Do you offer a warranty?]}",
            "",
            "**Answer**",
            "${8:[Mention how long the warranty lasts and direct the reader to the warranty page for more details.]}",
            "",
            "**Question 4:** ${9:[Example: Can I return an item if I've already opened it?]}",
            "",
            "**Answer**",
            "${10:[Explain the criteria that must be met to return an item and receive a full refund.]}",
            "",
            "**Question 5:** ${11:[Example: How long is the free trial?]}",
            "",
            "**Answer**",
            "${12:[Identify the free trial length and encourage the reader to talk to the sales team for more information.]}",
            "",
            "## Additional information",
            "",
            "${13:[Include any additional information or resources that may be helpful to the user, such as links to related articles or external websites, troubleshooting tips, or FAQs not covered in this article.]}",
            ""],
        "description": "KB FAQ Article"
    }
}
```
