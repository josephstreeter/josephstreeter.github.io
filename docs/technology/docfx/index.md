# DocFx

---

## Quick Start

Build your technical documentation site with docfx. Converts .NET assembly, XML code comment, REST API Swagger files and markdown into rendered HTML pages, JSON model or PDF files.

## Create a New Website

In this section we will build a simple documentation site on your local machine.

> Prerequisites
>
> - Familiarity with the command line
> - Install [.NET SDK](https://dotnet.microsoft.com/en-us/download) 6.0 or higher

Make sure you have [.NET SDK](https://dotnet.microsoft.com/en-us/download) installed, then open a terminal and enter the following command to install the latest docfx:

```bash
dotnet tool update -g docfx
```

To create a new docset, run:

```bash
docfx init
```

This command walks you through creating a new docfx project under the current working directory. To build the docset, run:

```bash
docfx docfx.json --serve
```

Now you can preview the website on <http://localhost:8080>.

To preview your local changes, save changes then run this command in a new terminal to rebuild the website:

```bash
docfx docfx.json
```

## Publish to GitHub Pages

Docfx produces static HTML files under the `_site` folder ready for publishing to any static site hosting servers.

To publish to GitHub Pages:

1. [Enable GitHub Pages](https://docs.github.com/en/pages/quickstart).
2. Upload `_site` folder to GitHub Pages using GitHub actions.

This is an example GitHub action file that publishes documents to the `gh-pages` branch:

```yaml
# Your GitHub workflow file under .github/workflows/
# Trigger the action on push to main
on:
  push:
    branches:
      - main

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  actions: read
  pages: write
  id-token: write

# Allow only one concurrent deployment, skipping runs queued between the run in-progress and latest queued.
# However, do NOT cancel in-progress runs as we want to allow these production deployments to complete.
concurrency:
  group: "pages"
  cancel-in-progress: false
  
jobs:
  publish-docs:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    - name: Dotnet Setup
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 8.x

    - run: dotnet tool update -g docfx
    - run: docfx <docfx-project-path>/docfx.json

    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        # Upload entire repository
        path: '<docfx-project-path>/_site'
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v4
```

## Table of Contents

A table of contents (TOC) defines the structure of a set of documents.

To add a TOC, create a file named `toc.yml` in the root of the 'doc' directory. Here's the structure for a simple YAML TOC:

```yaml
items:
- name: Subject Name
  items:
  - href: install.md
  - href: configure.md
  - href: useage.md
  - href: troubleshooting.md
```

TOC node YAML properties:

- `name`: An optional display name for the TOC node. When not specified, uses the `title` metadata or the first Heading 1 element from the referenced article as the display name.
- `href`: The path the TOC node leads to. Optional because a node can exist just to parent other nodes.
- `items`: If a node has children, they're listed in the items array.
- `uid`: The uid of the article. Can be used instead of `href`.
- `expanded`: Expand children on load, only works if the template is `modern`.

When an article is referenced by a TOC through `href`, the corresponding TOC appears when viewing that article. If multiple TOCs reference the same article, or the article isn't referenced by any TOC, the nearest TOC with the least amount of directory jumps is picked.

The `order` property can customize this pick logic, TOCs with a smaller order value are picked first. The default order is 0.

```yml
order: 100
items:
- ...
```

## Nested TOCs

To nest a TOC within another TOC, set the `href` property to point to the `toc.yml` file that you want to nest. You can also use this structure as a way to reuse a TOC structure in one or more TOC files.

Consider the following two `toc.yml` files:

_toc.yml_:

```yaml
items:
- name: Overview
  href: overview.md
- name: Reference
  href: api/toc.yml
```

_api/toc.yml_:

```yaml
items:
- name: System.String
  href: system.string.yml
- name: System.Float
  href: system.float.yml
```

This structure renders as follows:

```text
Overview
Reference
├─ System.String
├─ System.Float
```

Nested TOCs by default have `order` set to `100` to let containing TOCs take precedence.

## Reference TOCs

To reference another TOC without embeding it to a parent TOC using nested TOCs, set the `href` property to point to the directory that you want to reference and end the string with `/`, this will generate a link pointing to the first article in the referenced TOC.

Consider the following folder structure:

```text
toc.yml
├─ System
    ├─ toc.yml
├─ System.Collections
    ├─ toc.yml
```

_toc.yml_:

```yml
- name: System
  href: System/
- name: System.Collections
  href: System.Collections/
```

This structure renders as follows:

```yml
System # Link to the first article in System/toc.yml
System.Collections  # Link to the first article in System.Collections/toc.yml
```

## Navigation Bar

The `toc.yml` file in the `docfx.json` folder will be used to fill the content of the navigation bar at the top of the page. It usually uses [Reference TOCs](#reference-tocs) to navigate to child pages.

The following example creates a navigation bar with two  _Docs_ and _API_ entries:

```text
toc.yml
├─ docs
    ├─ toc.yml
├─ api
    ├─ toc.yml
```

_toc.yml_:

```yml
- name: Docs
  href: docs/
- name: API
  href: api/
```

## Customize the Site

- **Change Site Icon**: -- insert text --

## References

- [Doc-as-Code: Metadata Format Specification](https://hellosnow.github.io/docfx/spec/metadata_format_spec.html)
- [DocFX Flavored Markdown](https://hellosnow.github.io/docfx/spec/docfx_flavored_markdown.html)
- [DocFx - Quick Start](https://dotnet.github.io/docfx/index.html)
- [DocFx - Basic Concepts](https://dotnet.github.io/docfx/docs/basic-concepts.html)
- [DocFx - Markdown](https://dotnet.github.io/docfx/docs/markdown.html?tabs=linux%2Cdotnet)
