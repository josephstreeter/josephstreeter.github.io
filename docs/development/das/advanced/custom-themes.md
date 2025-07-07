---
title: Custom Themes and Styling
description: Creating and customizing DocFX themes for branded documentation experiences
---

## Custom Themes and Styling

Create distinctive, branded documentation experiences through custom DocFX themes and advanced styling techniques.

## Overview

Custom themes allow you to transform the standard DocFX appearance into a unique, branded experience that aligns with your organization's visual identity and user experience requirements.

## Theme Architecture

### DocFX Theme Structure

```text
custom-theme/
├── styles/
│   ├── main.css
│   ├── bootstrap.min.css
│   └── highlight.js.css
├── templates/
│   ├── conceptual.html.primary.tmpl
│   ├── toc.html.tmpl
│   └── partials/
│       ├── head.tmpl
│       ├── navbar.tmpl
│       ├── footer.tmpl
│       └── scripts.tmpl
├── fonts/
│   ├── custom-font.woff2
│   └── icons.woff
├── images/
│   ├── logo.svg
│   ├── favicon.ico
│   └── background-patterns/
└── scripts/
    ├── main.js
    └── analytics.js
```

### Theme Configuration

```json
{
  "template": [
    "default",
    "custom-theme"
  ],
  "globalMetadata": {
    "_appTitle": "Your Documentation",
    "_appLogoPath": "images/logo.svg",
    "_appFaviconPath": "images/favicon.ico",
    "_enableSearch": true,
    "_enableNewTab": true,
    "_disableContribution": false,
    "_gitContribute": {
      "repo": "https://github.com/your-org/docs",
      "branch": "main"
    }
  },
  "fileMetadata": {
    "_layout": {
      "docs/**/*.md": "Conceptual",
      "api/**/*.yml": "ManagedReference"
    }
  }
}
```

## Advanced CSS Customization

### CSS Variables for Theme Consistency

```css
/* styles/main.css */
:root {
  /* Brand Colors */
  --primary-color: #0066cc;
  --secondary-color: #004d99;
  --accent-color: #ff6b35;
  --success-color: #28a745;
  --warning-color: #ffc107;
  --danger-color: #dc3545;
  
  /* Neutral Colors */
  --text-primary: #2c3e50;
  --text-secondary: #6c757d;
  --text-muted: #868e96;
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --bg-tertiary: #e9ecef;
  
  /* Typography */
  --font-family-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-family-mono: 'JetBrains Mono', 'Fira Code', 'Monaco', monospace;
  --font-size-base: 16px;
  --line-height-base: 1.6;
  
  /* Spacing */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 3rem;
  
  /* Borders and Shadows */
  --border-radius: 0.375rem;
  --border-color: #dee2e6;
  --shadow-sm: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  --shadow-md: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 1rem 3rem rgba(0, 0, 0, 0.175);
}

/* Dark Theme Variables */
[data-theme="dark"] {
  --text-primary: #e9ecef;
  --text-secondary: #adb5bd;
  --text-muted: #6c757d;
  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --bg-tertiary: #404040;
  --border-color: #404040;
}
```

### Modern Navigation Design

```css
/* Enhanced Navigation */
.navbar {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  box-shadow: var(--shadow-md);
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.navbar-brand {
  display: flex;
  align-items: center;
  font-weight: 600;
  color: white !important;
  text-decoration: none;
}

.navbar-brand img {
  height: 32px;
  margin-right: var(--spacing-sm);
  filter: brightness(0) invert(1);
}

.navbar-nav .nav-link {
  color: rgba(255, 255, 255, 0.9) !important;
  font-weight: 500;
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--border-radius);
  transition: all 0.3s ease;
}

.navbar-nav .nav-link:hover {
  color: white !important;
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-1px);
}

/* Search Enhancement */
.navbar-form {
  position: relative;
}

.navbar-form .form-control {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  border-radius: 25px;
  padding-left: 40px;
  width: 300px;
  transition: all 0.3s ease;
}

.navbar-form .form-control::placeholder {
  color: rgba(255, 255, 255, 0.7);
}

.navbar-form .form-control:focus {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.4);
  box-shadow: 0 0 0 0.2rem rgba(255, 255, 255, 0.1);
  width: 350px;
}

.navbar-form::before {
  content: '🔍';
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(255, 255, 255, 0.7);
}
```

### Content Layout Enhancements

```css
/* Main Content Area */
.content-wrapper {
  display: grid;
  grid-template-columns: 280px 1fr 240px;
  grid-template-areas: 
    "sidebar content toc";
  gap: var(--spacing-xl);
  max-width: 1400px;
  margin: 0 auto;
  padding: var(--spacing-xl);
}

@media (max-width: 1200px) {
  .content-wrapper {
    grid-template-columns: 1fr;
    grid-template-areas: 
      "content";
  }
  
  .sidebar, .toc {
    display: none;
  }
}

/* Article Styling */
.article {
  grid-area: content;
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: var(--spacing-xl);
  line-height: var(--line-height-base);
}

.article h1, .article h2, .article h3, .article h4, .article h5, .article h6 {
  font-family: var(--font-family-sans);
  font-weight: 600;
  line-height: 1.3;
  margin-top: var(--spacing-lg);
  margin-bottom: var(--spacing-md);
  color: var(--text-primary);
}

.article h1 {
  font-size: 2.5rem;
  color: var(--primary-color);
  border-bottom: 3px solid var(--primary-color);
  padding-bottom: var(--spacing-sm);
}

.article h2 {
  font-size: 2rem;
  position: relative;
}

.article h2::before {
  content: '';
  position: absolute;
  left: -var(--spacing-md);
  top: 0;
  bottom: 0;
  width: 4px;
  background: var(--accent-color);
  border-radius: 2px;
}

/* Code Blocks */
.article pre {
  background: var(--bg-tertiary);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  padding: var(--spacing-lg);
  overflow-x: auto;
  font-family: var(--font-family-mono);
  font-size: 0.875rem;
  line-height: 1.5;
  position: relative;
}

.article pre::before {
  content: attr(data-lang);
  position: absolute;
  top: var(--spacing-sm);
  right: var(--spacing-sm);
  background: var(--primary-color);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
}

.article code {
  background: rgba(var(--primary-color), 0.1);
  color: var(--primary-color);
  padding: 0.125rem 0.25rem;
  border-radius: 0.25rem;
  font-family: var(--font-family-mono);
  font-size: 0.875em;
}

/* Tables */
.article table {
  width: 100%;
  border-collapse: collapse;
  margin: var(--spacing-lg) 0;
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.article th {
  background: var(--primary-color);
  color: white;
  padding: var(--spacing-md);
  text-align: left;
  font-weight: 600;
}

.article td {
  padding: var(--spacing-md);
  border-bottom: 1px solid var(--border-color);
}

.article tr:nth-child(even) {
  background: var(--bg-secondary);
}

.article tr:hover {
  background: rgba(var(--primary-color), 0.05);
}
```

### Interactive Components

```css
/* Collapsible Sections */
.collapsible {
  background: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  margin: var(--spacing-md) 0;
  overflow: hidden;
}

.collapsible-header {
  padding: var(--spacing-md);
  background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
  color: white;
  cursor: pointer;
  user-select: none;
  display: flex;
  align-items: center;
  justify-content: space-between;
  transition: all 0.3s ease;
}

.collapsible-header:hover {
  background: linear-gradient(90deg, var(--secondary-color), var(--primary-color));
}

.collapsible-content {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease;
}

.collapsible.active .collapsible-content {
  max-height: 500px;
}

.collapsible-body {
  padding: var(--spacing-lg);
}

/* Alert Boxes */
.alert {
  padding: var(--spacing-md);
  border-radius: var(--border-radius);
  margin: var(--spacing-md) 0;
  border-left: 4px solid;
  position: relative;
  display: flex;
  align-items: flex-start;
}

.alert::before {
  font-size: 1.5rem;
  margin-right: var(--spacing-sm);
}

.alert-info {
  background: rgba(13, 202, 240, 0.1);
  border-color: #0dcaf0;
  color: #055160;
}

.alert-info::before {
  content: 'ℹ️';
}

.alert-warning {
  background: rgba(255, 193, 7, 0.1);
  border-color: var(--warning-color);
  color: #664d03;
}

.alert-warning::before {
  content: '⚠️';
}

.alert-danger {
  background: rgba(220, 53, 69, 0.1);
  border-color: var(--danger-color);
  color: #721c24;
}

.alert-danger::before {
  content: '🚫';
}

.alert-success {
  background: rgba(40, 167, 69, 0.1);
  border-color: var(--success-color);
  color: #0f5132;
}

.alert-success::before {
  content: '✅';
}

/* Tabs */
.tabs {
  margin: var(--spacing-lg) 0;
}

.tab-headers {
  display: flex;
  border-bottom: 2px solid var(--border-color);
  margin-bottom: var(--spacing-md);
}

.tab-header {
  padding: var(--spacing-sm) var(--spacing-lg);
  background: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-bottom: none;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.tab-header:first-child {
  border-top-left-radius: var(--border-radius);
}

.tab-header:last-child {
  border-top-right-radius: var(--border-radius);
}

.tab-header.active {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.tab-content {
  display: none;
  padding: var(--spacing-lg);
  background: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: 0 0 var(--border-radius) var(--border-radius);
}

.tab-content.active {
  display: block;
}
```

## JavaScript Enhancements

### Theme Switcher

```javascript
// scripts/theme-switcher.js
class ThemeSwitcher {
  constructor() {
    this.currentTheme = localStorage.getItem('theme') || 'light';
    this.init();
  }
  
  init() {
    this.applyTheme(this.currentTheme);
    this.createToggleButton();
    this.bindEvents();
  }
  
  createToggleButton() {
    const button = document.createElement('button');
    button.className = 'theme-toggle';
    button.innerHTML = this.currentTheme === 'dark' ? '☀️' : '🌙';
    button.setAttribute('aria-label', 'Toggle theme');
    
    const navbar = document.querySelector('.navbar-nav');
    if (navbar) {
      navbar.appendChild(button);
    }
  }
  
  bindEvents() {
    document.addEventListener('click', (e) => {
      if (e.target.classList.contains('theme-toggle')) {
        this.toggleTheme();
      }
    });
  }
  
  toggleTheme() {
    this.currentTheme = this.currentTheme === 'light' ? 'dark' : 'light';
    this.applyTheme(this.currentTheme);
    localStorage.setItem('theme', this.currentTheme);
    
    const button = document.querySelector('.theme-toggle');
    if (button) {
      button.innerHTML = this.currentTheme === 'dark' ? '☀️' : '🌙';
    }
  }
  
  applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
  }
}

// Initialize theme switcher
document.addEventListener('DOMContentLoaded', () => {
  new ThemeSwitcher();
});
```

### Enhanced Search

```javascript
// scripts/enhanced-search.js
class EnhancedSearch {
  constructor() {
    this.searchIndex = null;
    this.searchResults = [];
    this.init();
  }
  
  async init() {
    await this.loadSearchIndex();
    this.bindEvents();
    this.createSearchSuggestions();
  }
  
  async loadSearchIndex() {
    try {
      const response = await fetch('/search-index.json');
      this.searchIndex = await response.json();
    } catch (error) {
      console.error('Failed to load search index:', error);
    }
  }
  
  bindEvents() {
    const searchInput = document.querySelector('#search-query');
    if (searchInput) {
      searchInput.addEventListener('input', this.debounce(this.handleSearch.bind(this), 300));
      searchInput.addEventListener('keydown', this.handleKeyDown.bind(this));
    }
  }
  
  handleSearch(event) {
    const query = event.target.value.trim();
    if (query.length < 2) {
      this.hideSearchResults();
      return;
    }
    
    this.searchResults = this.performSearch(query);
    this.displaySearchResults(this.searchResults);
  }
  
  performSearch(query) {
    if (!this.searchIndex) return [];
    
    const results = [];
    const queryLower = query.toLowerCase();
    
    for (const item of this.searchIndex) {
      let score = 0;
      
      // Title match (highest weight)
      if (item.title.toLowerCase().includes(queryLower)) {
        score += 10;
      }
      
      // Content match
      if (item.content.toLowerCase().includes(queryLower)) {
        score += 5;
      }
      
      // Tag match
      if (item.tags && item.tags.some(tag => tag.toLowerCase().includes(queryLower))) {
        score += 3;
      }
      
      if (score > 0) {
        results.push({ ...item, score });
      }
    }
    
    return results.sort((a, b) => b.score - a.score).slice(0, 10);
  }
  
  displaySearchResults(results) {
    const container = this.getOrCreateResultsContainer();
    
    if (results.length === 0) {
      container.innerHTML = '<div class="search-no-results">No results found</div>';
    } else {
      container.innerHTML = results.map(result => `
        <div class="search-result-item">
          <h4><a href="${result.url}">${this.highlightText(result.title, query)}</a></h4>
          <p>${this.highlightText(this.getExcerpt(result.content, query), query)}</p>
          <div class="search-result-meta">
            ${result.tags ? result.tags.map(tag => `<span class="tag">${tag}</span>`).join('') : ''}
          </div>
        </div>
      `).join('');
    }
    
    container.style.display = 'block';
  }
  
  highlightText(text, query) {
    const regex = new RegExp(`(${query})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  }
  
  getExcerpt(content, query, length = 150) {
    const index = content.toLowerCase().indexOf(query.toLowerCase());
    if (index === -1) return content.substring(0, length) + '...';
    
    const start = Math.max(0, index - 50);
    const end = Math.min(content.length, start + length);
    
    return (start > 0 ? '...' : '') + 
           content.substring(start, end) + 
           (end < content.length ? '...' : '');
  }
  
  getOrCreateResultsContainer() {
    let container = document.querySelector('.search-results');
    if (!container) {
      container = document.createElement('div');
      container.className = 'search-results';
      
      const searchForm = document.querySelector('.navbar-form');
      if (searchForm) {
        searchForm.appendChild(container);
      }
    }
    return container;
  }
  
  hideSearchResults() {
    const container = document.querySelector('.search-results');
    if (container) {
      container.style.display = 'none';
    }
  }
  
  debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
}

// Initialize enhanced search
document.addEventListener('DOMContentLoaded', () => {
  new EnhancedSearch();
});
```

### Interactive Features

```javascript
// scripts/interactive-features.js
class InteractiveFeatures {
  constructor() {
    this.init();
  }
  
  init() {
    this.initCollapsibles();
    this.initTabs();
    this.initCodeCopyButtons();
    this.initScrollSpy();
    this.initSmoothScrolling();
  }
  
  initCollapsibles() {
    document.querySelectorAll('.collapsible-header').forEach(header => {
      header.addEventListener('click', () => {
        const collapsible = header.closest('.collapsible');
        collapsible.classList.toggle('active');
      });
    });
  }
  
  initTabs() {
    document.querySelectorAll('.tab-header').forEach(header => {
      header.addEventListener('click', () => {
        const tabContainer = header.closest('.tabs');
        const tabId = header.dataset.tab;
        
        // Remove active class from all headers and contents
        tabContainer.querySelectorAll('.tab-header').forEach(h => h.classList.remove('active'));
        tabContainer.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        // Add active class to clicked header and corresponding content
        header.classList.add('active');
        tabContainer.querySelector(`[data-tab-content="${tabId}"]`).classList.add('active');
      });
    });
  }
  
  initCodeCopyButtons() {
    document.querySelectorAll('pre code').forEach(codeBlock => {
      const pre = codeBlock.parentElement;
      const button = document.createElement('button');
      button.className = 'copy-code-button';
      button.innerHTML = '📋';
      button.setAttribute('aria-label', 'Copy code');
      
      button.addEventListener('click', () => {
        navigator.clipboard.writeText(codeBlock.textContent).then(() => {
          button.innerHTML = '✅';
          setTimeout(() => {
            button.innerHTML = '📋';
          }, 2000);
        });
      });
      
      pre.style.position = 'relative';
      pre.appendChild(button);
    });
  }
  
  initScrollSpy() {
    const headers = document.querySelectorAll('h2, h3, h4');
    const tocLinks = document.querySelectorAll('.toc a');
    
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const id = entry.target.id;
          tocLinks.forEach(link => {
            link.classList.toggle('active', link.getAttribute('href') === `#${id}`);
          });
        }
      });
    }, { rootMargin: '-10% 0% -85% 0%' });
    
    headers.forEach(header => {
      if (header.id) {
        observer.observe(header);
      }
    });
  }
  
  initSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.querySelector(link.getAttribute('href'));
        if (target) {
          target.scrollIntoView({ behavior: 'smooth' });
        }
      });
    });
  }
}

// Initialize interactive features
document.addEventListener('DOMContentLoaded', () => {
  new InteractiveFeatures();
});
```

## Advanced Template Customization

### Custom Template Processor

```html
<!-- templates/conceptual.html.primary.tmpl -->
{{!Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.}}
{{!include(/^styles/.*/)}}
{{!include(/^fonts/.*/)}}
{{!include(favicon.ico)}}
{{!include(logo.svg)}}
<!DOCTYPE html>
<html{{#_lang}} lang="{{_lang}}"{{/_lang}}>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <title>{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}} {{#_appTitle}}| {{{_appTitle}}}{{/_appTitle}}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="title" content="{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}} {{#_appTitle}}| {{{_appTitle}}}{{/_appTitle}}">
  <meta name="generator" content="docfx {{_docfxVersion}}">
  {{#_description}}<meta name="description" content="{{_description}}">{{/_description}}
  {{#author}}<meta name="author" content="{{author}}">{{/author}}
  
  <!-- Open Graph Tags -->
  <meta property="og:title" content="{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}}">
  {{#_description}}<meta property="og:description" content="{{_description}}">{{/_description}}
  <meta property="og:type" content="article">
  <meta property="og:url" content="{{_currentUrl}}">
  
  <!-- Twitter Card Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{{#title}}{{title}}{{/title}}{{^title}}{{>partials/title}}{{/title}}">
  {{#_description}}<meta name="twitter:description" content="{{_description}}">{{/_description}}
  
  <link rel="shortcut icon" href="{{_rel}}{{{_appFaviconPath}}}{{^_appFaviconPath}}favicon.ico{{/_appFaviconPath}}">
  <link rel="stylesheet" href="{{_rel}}styles/docfx.vendor.css">
  <link rel="stylesheet" href="{{_rel}}styles/docfx.css">
  <link rel="stylesheet" href="{{_rel}}styles/main.css">
  
  <!-- Custom Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  
  <meta property="docfx:navrel" content="{{_navRel}}">
  <meta property="docfx:tocrel" content="{{_tocRel}}">
  {{#_enableSearch}}<meta property="docfx:rel" content="{{_rel}}">{{/_enableSearch}}
  {{#_enableNewTab}}<meta property="docfx:newtab" content="true">{{/_enableNewTab}}
  
  <!-- Custom head content -->
  {{>partials/head}}
</head>

<body data-spy="scroll" data-target="#affix" data-offset="120">
  <div id="wrapper">
    <header>
      {{>partials/navbar}}
    </header>
    
    {{#_enableSearch}}
    <div class="container body-content">
      {{>partials/searchResults}}
    </div>
    {{/_enableSearch}}
    
    <div class="content-wrapper">
      {{#_tocPath}}
      <div class="sidebar">
        {{>partials/toc}}
      </div>
      {{/_tocPath}}
      
      <div role="main" class="article">
        {{>partials/breadcrumb}}
        
        <article id="_content" data-uid="{{uid}}">
          {{#conceptual}}
          {{{conceptual}}}
          {{/conceptual}}
          {{^conceptual}}
          {{!body}}
          {{/conceptual}}
        </article>
        
        {{>partials/contributor}}
      </div>
      
      {{#_tocPath}}
      <div class="toc">
        {{>partials/affix}}
      </div>
      {{/_tocPath}}
    </div>
    
    {{>partials/footer}}
  </div>
  
  {{>partials/scripts}}
  
  <!-- Custom Analytics -->
  {{#_enableAnalytics}}
  <script>
    // Custom analytics implementation
    (function() {
      // Track page views
      if (typeof gtag !== 'undefined') {
        gtag('config', '{{_analyticsTrackingId}}', {
          page_title: document.title,
          page_location: window.location.href
        });
      }
      
      // Track search queries
      document.addEventListener('search', function(e) {
        if (typeof gtag !== 'undefined') {
          gtag('event', 'search', {
            search_term: e.detail.query
          });
        }
      });
    })();
  </script>
  {{/_enableAnalytics}}
</body>
</html>
```

## Performance Optimization

### CSS Optimization

```css
/* Critical CSS for above-the-fold content */
/* This should be inlined for better performance */

/* Layout skeleton for fast rendering */
.content-wrapper {
  display: grid;
  grid-template-columns: 280px 1fr 240px;
  gap: var(--spacing-xl);
}

.navbar {
  height: 60px;
  background: var(--primary-color);
}

.article {
  min-height: 400px;
  background: var(--bg-primary);
}

/* Lazy load non-critical styles */
.fancy-animations,
.decorative-elements {
  /* Load these after initial render */
}
```

### Resource Loading Optimization

```html
<!-- Optimized resource loading -->
<head>
  <!-- Critical resources -->
  <link rel="preload" href="fonts/Inter-Regular.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="styles/critical.css" as="style">
  
  <!-- DNS prefetch for external resources -->
  <link rel="dns-prefetch" href="//fonts.googleapis.com">
  <link rel="dns-prefetch" href="//www.google-analytics.com">
  
  <!-- Preconnect to critical third-party origins -->
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  
  <!-- Critical CSS (inlined) -->
  <style>
    /* Critical above-the-fold styles */
  </style>
  
  <!-- Non-critical CSS (async) -->
  <link rel="preload" href="styles/main.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
  <noscript><link rel="stylesheet" href="styles/main.css"></noscript>
</head>
```

## Testing and Quality Assurance

### Visual Regression Testing

```javascript
// test/visual-regression.test.js
const puppeteer = require('puppeteer');
const pixelmatch = require('pixelmatch');
const PNG = require('pngjs').PNG;
const fs = require('fs');

describe('Visual Regression Tests', () => {
  let browser, page;
  
  beforeAll(async () => {
    browser = await puppeteer.launch();
    page = await browser.newPage();
    await page.setViewport({ width: 1200, height: 800 });
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  test('Homepage renders correctly', async () => {
    await page.goto('http://localhost:8080');
    
    const screenshot = await page.screenshot();
    const baseline = fs.readFileSync('test/baselines/homepage.png');
    
    const diff = compareImages(baseline, screenshot);
    
    expect(diff.mismatchedPixels).toBeLessThan(100);
  });
  
  test('Dark theme renders correctly', async () => {
    await page.goto('http://localhost:8080');
    await page.click('.theme-toggle');
    await page.waitForTimeout(500); // Wait for theme transition
    
    const screenshot = await page.screenshot();
    const baseline = fs.readFileSync('test/baselines/homepage-dark.png');
    
    const diff = compareImages(baseline, screenshot);
    
    expect(diff.mismatchedPixels).toBeLessThan(100);
  });
  
  function compareImages(baseline, current) {
    const img1 = PNG.sync.read(baseline);
    const img2 = PNG.sync.read(current);
    const { width, height } = img1;
    const diff = new PNG({ width, height });
    
    const mismatchedPixels = pixelmatch(
      img1.data, img2.data, diff.data, width, height,
      { threshold: 0.1 }
    );
    
    return { mismatchedPixels, diff };
  }
});
```

### Accessibility Testing

```javascript
// test/accessibility.test.js
const { AxePuppeteer } = require('@axe-core/puppeteer');
const puppeteer = require('puppeteer');

describe('Accessibility Tests', () => {
  let browser, page;
  
  beforeAll(async () => {
    browser = await puppeteer.launch();
    page = await browser.newPage();
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  test('Homepage meets WCAG AA standards', async () => {
    await page.goto('http://localhost:8080');
    
    const results = await new AxePuppeteer(page)
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();
    
    expect(results.violations).toHaveLength(0);
  });
  
  test('Navigation is keyboard accessible', async () => {
    await page.goto('http://localhost:8080');
    
    // Test tab navigation
    await page.keyboard.press('Tab');
    const focusedElement = await page.evaluate(() => document.activeElement.tagName);
    expect(['A', 'BUTTON', 'INPUT']).toContain(focusedElement);
  });
});
```

## Deployment and Distribution

### Theme Packaging

```json
{
  "name": "custom-docfx-theme",
  "version": "1.0.0",
  "description": "Custom branded theme for DocFX documentation",
  "main": "template/",
  "files": [
    "template/",
    "README.md",
    "LICENSE"
  ],
  "keywords": ["docfx", "theme", "documentation"],
  "repository": {
    "type": "git",
    "url": "https://github.com/your-org/custom-docfx-theme"
  },
  "scripts": {
    "build": "npm run build:css && npm run build:js",
    "build:css": "sass styles/main.scss template/styles/main.css --style compressed",
    "build:js": "webpack --mode production",
    "watch": "npm run watch:css & npm run watch:js",
    "watch:css": "sass styles/main.scss template/styles/main.css --watch",
    "watch:js": "webpack --mode development --watch",
    "test": "jest",
    "lint": "stylelint styles/**/*.scss && eslint scripts/**/*.js"
  }
}
```

### Build Pipeline

```yaml
# .github/workflows/build-theme.yml
name: Build and Test Theme

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Lint styles
      run: npm run lint:css
    
    - name: Lint scripts
      run: npm run lint:js
    
    - name: Build theme
      run: npm run build
    
    - name: Run tests
      run: npm test
    
    - name: Visual regression tests
      run: npm run test:visual
    
    - name: Accessibility tests
      run: npm run test:a11y
    
    - name: Package theme
      run: npm pack
    
    - name: Upload theme package
      uses: actions/upload-artifact@v3
      with:
        name: theme-package
        path: "*.tgz"
```

## Best Practices

### Theme Development Guidelines

- **Performance First**: Optimize for fast loading and rendering
- **Accessibility**: Ensure WCAG AA compliance
- **Responsive Design**: Support all device sizes
- **Progressive Enhancement**: Work without JavaScript
- **Maintainability**: Use modern CSS features and methodologies

### Brand Consistency

- **Design System**: Create and maintain a comprehensive design system
- **Component Library**: Build reusable UI components
- **Style Guide**: Document usage guidelines and patterns
- **Version Control**: Track theme changes and maintain backwards compatibility

### Testing Strategy

- **Visual Regression**: Automated screenshot comparisons
- **Accessibility**: Regular WCAG compliance testing
- **Performance**: Monitor Core Web Vitals
- **Cross-browser**: Test on multiple browsers and devices

---

This comprehensive guide provides the foundation for creating sophisticated, branded DocFX themes that enhance the user experience while maintaining performance and accessibility standards.
