# Snippets

Snippets are a way to save templates for pieces of code that you use often. It can be a complex one-liner or an entire function.

The snippets are saved in VS Code and can be inserted by pressing ```Ctrl + .``` and selecting the appropriate option from the list. You can filter the list of snippets by typing the name of the snippet you wish to use.

## Configuring Snippets

1. Click ```File``` -> ```Preferecences``` -> ```Configure Snippets```
2. Select the language for the snippets you would like to configure.
3. Add snippets to the file that is opened in the editor.

The file will look something like the text below. Add your snippets inside of the provided brackets.

```json
{
    // Place your snippets for markdown here. Each snippet is defined under a snippet name and has a prefix, body and 
    // description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
    // $1, $2 for tab stops, $0 for the final cursor position, and ${1:label}, ${2:another} for placeholders. Placeholders with the 
    // same ids are connected.
    // Example:
    // "Print to console": {
    //  "prefix": "log",
    //  "body": [
    //      "console.log('$1');",
    //      "$2"
    //  ],
    //  "description": "Log output to console"
    // }
}
```

## Common Administrative Snippets

- On-Prem Exchange Connection
- SQL Server Connection
- Random Password Generation

```json
"Exchange On-Prem Connection": {
        "prefix": "Snip-ExchangeOnlineConnection",
        "body": [
            "function Connect-ExchangeOnPrem()",
            "{",
            "\t[CmdletBinding()]",
            "\tParam",
            "\t(",
            "\t\t[Parameter(Mandatory=$$true)][string]$$Server",
            "\t)",
            "\t$$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $$('https://{0}' -f $$Server) -Credential $$UserCredential -Authentication Basic -AllowRedirection",
            "\tImport-PSSession $$Session -DisableNameChecking",
            "}"
        ],
        "description": "Connect to Exchange On-Prem"
    },
    "SQL Server Connection":{
        "prefix": "Snip-MSSQLConnection",
        "body": [
            "function Invoke-SQLQuery()",
            "{",
            "\t[CmdletBinding()]",
            "\tParam",
            "\t(",
            "\t\t[Parameter(Mandatory=$$true)][string]$$instance,",
            "\t\t[Parameter(Mandatory=$$true)][string]$$database,",
            "\t\t[Parameter(Mandatory=$$true)][string]$$query",
            "\t)",
            "\ttry",
            "\t{",
            "\t\t$$Results = Invoke-Sqlcmd -ServerInstance $instance -Database $database -Query $query -TrustServerCertificate -ErrorAction stop",
            "\t\tReturn $$Results",
            "\t}",
            "\tcatch",
            "\t{",
            "\tWrite-Host _.Exception.Message",
            "\t}",
            "}"
            ],
        "description": "Connect to MS SQL"
    },
    "Password Generation": {
        "prefix": "Snip-PasswordGeneration",
        "body": [
            "Function New-RandomPassword()",
            "{",
            "\t[CmdletBinding()]",
            "\tparam(",
            "\t\t[Parameter(Mandatory=\\$true)][int]\\$LowerCase,",
            "\t\t[Parameter(Mandatory=\\$true)][int]\\$UpperCase,",
            "\t\t[Parameter(Mandatory=\\$true)][int]\\$Numbers,",
            "\t\t[Parameter(Mandatory=\\$true)][int]\\$SpecialChar",
            "\t)",
            "",
            "\t$$pw = [char[]]'abcdefghiklmnoprstuvwxyz' | Get-Random -Count \\$LowerCase",
            "\t$$pw += [char[]]'ABCDEFGHKLMNOPRSTUVWXYZ' | Get-Random -Count \\$UpperCase",
            "\t$$pw += [char[]]'1234567890' | Get-Random -Count \\$Numbers",
            "\t$$pw += [char[]]'!$?_-' | Get-Random -Count \\$SpecialChar",
            "\t$$pw=(\\$pw | Get-Random -Count \\$pw.length) -join ''",
            "\t$$SecString=ConvertTo-SecureString –String \\$pw –AsPlainText –Force",
            "\t$$results = [PSCustomObject] @{Password=\\$pw;SecureString=\\$SecString}",
            "",
            "\treturn $$Results",
            "}"
        ],
        "description": "Connect to Exchange On-Prem"
    }
```

## Knowledgebase Articles

The following snippets are templaces for knowledgebase articles in Markdown. There are four types of articles listed:

- Troubleshooting
- Service Description
- Process
- Frequently Asked Questions

```json
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
