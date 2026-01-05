---
title: "Web Scraping with Python"
description: "Comprehensive guide to web scraping using Python, covering BeautifulSoup, Selenium, Scrapy, and best practices"
author: "Joseph Streeter"
ms.date: "2026-01-04"
ms.topic: "article"
---

## Web Scraping with Python

Web scraping is the automated process of extracting data from websites programmatically. Python provides powerful libraries and frameworks that make web scraping accessible and efficient for data collection, analysis, and automation tasks.

## Overview

Web scraping enables you to:

- Extract structured data from websites for analysis
- Monitor price changes or content updates
- Aggregate data from multiple sources
- Automate repetitive data collection tasks
- Build datasets for machine learning projects

This guide covers the essential tools, techniques, and best practices for ethical and effective web scraping with Python.

## Prerequisites

Before starting with web scraping, ensure you have:

- Python 3.8 or higher installed
- Basic understanding of HTML and CSS structure
- Familiarity with HTTP requests and responses
- Understanding of Python data structures (lists, dictionaries)
- Basic knowledge of regular expressions (helpful but not required)

## Installation

Install the essential web scraping libraries:

```bash
# Core libraries
pip install requests beautifulsoup4 lxml

# For dynamic content
pip install selenium

# For advanced scraping
pip install scrapy

# Additional utilities
pip install html5lib fake-useragent
```

## BeautifulSoup for HTML Parsing

BeautifulSoup is the most popular library for parsing HTML and XML documents. It creates a parse tree that makes it easy to extract data.

### Basic Usage

```python
import requests
from bs4 import BeautifulSoup

# Make HTTP request
Url = "https://example.com"
Response = requests.get(Url)

# Parse HTML content
Soup = BeautifulSoup(Response.content, 'lxml')

# Extract data
Title = Soup.find('h1').text
Paragraphs = Soup.find_all('p')

for Paragraph in Paragraphs:
    print(Paragraph.text)
```

### Finding Elements

```python
from bs4 import BeautifulSoup

# Find single element
FirstDiv = Soup.find('div', class_='content')
FirstId = Soup.find(id='main-content')

# Find all matching elements
AllLinks = Soup.find_all('a')
AllDivs = Soup.find_all('div', class_='article')

# CSS selectors
MainSection = Soup.select_one('section.main')
AllButtons = Soup.select('button.submit')

# Navigate the tree
Parent = FirstDiv.parent
NextSibling = FirstDiv.next_sibling
Children = list(FirstDiv.children)
```

### Extracting Attributes

```python
# Get href from link
Link = Soup.find('a')
Href = Link.get('href')
# Or: Href = Link['href']

# Get all attributes
Attributes = Link.attrs

# Check if attribute exists
if Link.has_attr('target'):
    Target = Link['target']
```

### Practical Example: Scraping Article Data

```python
import requests
from bs4 import BeautifulSoup
from typing import List, Dict

def scrape_articles(url: str) -> List[Dict[str, str]]:
    """
    Scrape article titles and links from a webpage.
    
    Args:
        url: The URL to scrape
        
    Returns:
        List of dictionaries containing article data
    """
    try:
        Response = requests.get(url, timeout=10)
        Response.raise_for_status()
        
        Soup = BeautifulSoup(Response.content, 'lxml')
        Articles = []
        
        # Find all article elements
        for Article in Soup.find_all('article', class_='post'):
            Title = Article.find('h2').text.strip()
            Link = Article.find('a')['href']
            Summary = Article.find('p', class_='summary').text.strip()
            
            Articles.append({
                'title': Title,
                'link': Link,
                'summary': Summary
            })
        
        return Articles
        
    except requests.RequestException as e:
        print(f"Error fetching URL: {e}")
        return []

# Usage
Articles = scrape_articles("https://example.com/blog")
for Article in Articles:
    print(f"Title: {Article['title']}")
    print(f"Link: {Article['link']}")
    print(f"Summary: {Article['summary']}\n")
```

## Selenium for Dynamic Content

Selenium automates web browsers and is essential for scraping JavaScript-heavy websites that load content dynamically.

### Setup

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options

# Configure Chrome options
ChromeOptions = Options()
ChromeOptions.add_argument('--headless')  # Run without GUI
ChromeOptions.add_argument('--no-sandbox')
ChromeOptions.add_argument('--disable-dev-shm-usage')

# Initialize driver
Driver = webdriver.Chrome(options=ChromeOptions)
```

### Basic Operations

```python
# Navigate to URL
Driver.get("https://example.com")

# Find elements
Element = Driver.find_element(By.ID, "content")
Elements = Driver.find_elements(By.CLASS_NAME, "article")

# Extract data
Title = Driver.find_element(By.TAG_NAME, "h1").text
Links = [elem.get_attribute('href') for elem in Driver.find_elements(By.TAG_NAME, "a")]

# Interact with page
SearchBox = Driver.find_element(By.NAME, "search")
SearchBox.send_keys("python web scraping")
SearchBox.submit()

# Close driver
Driver.quit()
```

### Waiting for Dynamic Content

```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Explicit wait for element to appear
Wait = WebDriverWait(Driver, 10)
Element = Wait.until(
    EC.presence_of_element_located((By.ID, "dynamic-content"))
)

# Wait for element to be clickable
Button = Wait.until(
    EC.element_to_be_clickable((By.CLASS_NAME, "load-more"))
)
Button.click()

# Wait for multiple elements
Elements = Wait.until(
    EC.presence_of_all_elements_located((By.CLASS_NAME, "item"))
)
```

### Practical Example: Scraping JavaScript-Rendered Content

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
import time

def scrape_dynamic_content(url: str) -> List[Dict[str, str]]:
    """
    Scrape content from JavaScript-rendered pages.
    
    Args:
        url: The URL to scrape
        
    Returns:
        List of dictionaries containing scraped data
    """
    ChromeOptions = Options()
    ChromeOptions.add_argument('--headless')
    
    Driver = webdriver.Chrome(options=ChromeOptions)
    Results = []
    
    try:
        Driver.get(url)
        
        # Wait for content to load
        Wait = WebDriverWait(Driver, 10)
        Wait.until(EC.presence_of_element_located((By.CLASS_NAME, "product")))
        
        # Scroll to load more content
        LastHeight = Driver.execute_script("return document.body.scrollHeight")
        while True:
            Driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(2)
            
            NewHeight = Driver.execute_script("return document.body.scrollHeight")
            if NewHeight == LastHeight:
                break
            LastHeight = NewHeight
        
        # Extract data
        Products = Driver.find_elements(By.CLASS_NAME, "product")
        for Product in Products:
            Name = Product.find_element(By.CLASS_NAME, "name").text
            Price = Product.find_element(By.CLASS_NAME, "price").text
            
            Results.append({
                'name': Name,
                'price': Price
            })
        
        return Results
        
    finally:
        Driver.quit()

# Usage
Products = scrape_dynamic_content("https://example.com/products")
for Product in Products:
    print(f"{Product['name']}: {Product['price']}")
```

## Scrapy Framework

Scrapy is a powerful web scraping framework for large-scale projects. It handles requests, parsing, and data storage efficiently.

### Creating a Scrapy Project

```bash
# Create new project
scrapy startproject myproject
cd myproject

# Generate spider
scrapy genspider example example.com
```

### Basic Spider

```python
import scrapy

class ExampleSpider(scrapy.Spider):
    name = 'example'
    allowed_domains = ['example.com']
    start_urls = ['https://example.com']
    
    def parse(self, response):
        """
        Parse the response and extract data.
        
        Args:
            response: The response object from Scrapy
        """
        # Extract data using CSS selectors
        for Article in response.css('article.post'):
            yield {
                'title': Article.css('h2::text').get(),
                'link': Article.css('a::attr(href)').get(),
                'author': Article.css('.author::text').get(),
                'date': Article.css('.date::text').get()
            }
        
        # Follow pagination links
        NextPage = response.css('a.next::attr(href)').get()
        if NextPage:
            yield response.follow(NextPage, self.parse)
```

### Advanced Spider with Item Pipeline

```python
# items.py
import scrapy

class ArticleItem(scrapy.Item):
    title = scrapy.Field()
    link = scrapy.Field()
    author = scrapy.Field()
    date = scrapy.Field()
    content = scrapy.Field()

# spider.py
import scrapy
from myproject.items import ArticleItem

class AdvancedSpider(scrapy.Spider):
    name = 'advanced'
    allowed_domains = ['example.com']
    start_urls = ['https://example.com/articles']
    
    custom_settings = {
        'DOWNLOAD_DELAY': 1,
        'CONCURRENT_REQUESTS': 16,
        'USER_AGENT': 'Mozilla/5.0 (compatible; MyBot/1.0)'
    }
    
    def parse(self, response):
        """Parse article list page."""
        ArticleLinks = response.css('article.post a::attr(href)').getall()
        
        for Link in ArticleLinks:
            yield response.follow(Link, callback=self.parse_article)
    
    def parse_article(self, response):
        """Parse individual article page."""
        Item = ArticleItem()
        Item['title'] = response.css('h1::text').get()
        Item['author'] = response.css('.author::text').get()
        Item['date'] = response.css('.date::text').get()
        Item['content'] = ' '.join(response.css('.content p::text').getall())
        Item['link'] = response.url
        
        yield Item
```

### Running Scrapy Spiders

```bash
# Run spider and save to JSON
scrapy crawl example -o output.json

# Save to CSV
scrapy crawl example -o output.csv

# Save to JSON Lines format
scrapy crawl example -o output.jsonl

# With custom settings
scrapy crawl example -o output.json -s DOWNLOAD_DELAY=2
```

## Handling Common Challenges

### User Agents and Headers

```python
import requests
from fake_useragent import UserAgent

# Use random user agent
Ua = UserAgent()
Headers = {
    'User-Agent': Ua.random,
    'Accept': 'text/html,application/xhtml+xml',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://www.google.com/'
}

Response = requests.get(url, headers=Headers)
```

### Session Management

```python
import requests

# Use session to persist cookies
Session = requests.Session()
Session.headers.update({'User-Agent': 'Mozilla/5.0'})

# Login
LoginData = {'username': 'user', 'password': 'pass'}
Session.post('https://example.com/login', data=LoginData)

# Make authenticated requests
Response = Session.get('https://example.com/protected')
```

### Rate Limiting

```python
import time
from datetime import datetime

class RateLimiter:
    """Simple rate limiter for web scraping."""
    
    def __init__(self, requests_per_second: float):
        """
        Initialize rate limiter.
        
        Args:
            requests_per_second: Maximum requests per second
        """
        self.RequestsPerSecond = requests_per_second
        self.MinInterval = 1.0 / requests_per_second
        self.LastRequest = 0
    
    def wait(self):
        """Wait if necessary to respect rate limit."""
        Elapsed = time.time() - self.LastRequest
        if Elapsed < self.MinInterval:
            time.sleep(self.MinInterval - Elapsed)
        self.LastRequest = time.time()

# Usage
Limiter = RateLimiter(2)  # 2 requests per second

for Url in Urls:
    Limiter.wait()
    Response = requests.get(Url)
    # Process response
```

### Handling Errors and Retries

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def create_session_with_retries() -> requests.Session:
    """
    Create a requests session with automatic retries.
    
    Returns:
        Configured requests Session object
    """
    Session = requests.Session()
    
    RetryStrategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "OPTIONS"]
    )
    
    Adapter = HTTPAdapter(max_retries=RetryStrategy)
    Session.mount("http://", Adapter)
    Session.mount("https://", Adapter)
    
    return Session

# Usage
Session = create_session_with_retries()
try:
    Response = Session.get(url, timeout=10)
    Response.raise_for_status()
except requests.exceptions.RequestException as e:
    print(f"Error: {e}")
```

### Parsing JSON APIs

```python
import requests
import json

def fetch_api_data(url: str, params: dict = None) -> dict:
    """
    Fetch data from JSON API.
    
    Args:
        url: API endpoint URL
        params: Query parameters
        
    Returns:
        Parsed JSON response
    """
    Headers = {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0'
    }
    
    try:
        Response = requests.get(url, headers=Headers, params=params, timeout=10)
        Response.raise_for_status()
        return Response.json()
    except requests.exceptions.RequestException as e:
        print(f"API Error: {e}")
        return {}

# Usage
Data = fetch_api_data("https://api.example.com/data", params={'page': 1})
```

## Best Practices

### Respect robots.txt

```python
from urllib.robotparser import RobotFileParser

def can_fetch(url: str, user_agent: str = '*') -> bool:
    """
    Check if URL can be fetched according to robots.txt.
    
    Args:
        url: URL to check
        user_agent: User agent string
        
    Returns:
        True if fetching is allowed
    """
    from urllib.parse import urlparse
    
    ParsedUrl = urlparse(url)
    RobotsUrl = f"{ParsedUrl.scheme}://{ParsedUrl.netloc}/robots.txt"
    
    Rp = RobotFileParser()
    Rp.set_url(RobotsUrl)
    try:
        Rp.read()
        return Rp.can_fetch(user_agent, url)
    except:
        return True  # Allow if robots.txt not accessible

# Usage
if can_fetch("https://example.com/page"):
    # Proceed with scraping
    pass
```

### Data Cleaning and Validation

```python
import re
from typing import Optional

def clean_text(text: str) -> str:
    """
    Clean scraped text by removing extra whitespace.
    
    Args:
        text: Raw text to clean
        
    Returns:
        Cleaned text
    """
    if not text:
        return ""
    
    # Remove extra whitespace
    Text = re.sub(r'\s+', ' ', text)
    Text = Text.strip()
    
    return Text

def validate_email(email: str) -> bool:
    """
    Validate email address format.
    
    Args:
        email: Email address to validate
        
    Returns:
        True if valid email format
    """
    Pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(Pattern, email))

def extract_price(text: str) -> Optional[float]:
    """
    Extract price from text.
    
    Args:
        text: Text containing price
        
    Returns:
        Price as float, or None if not found
    """
    Match = re.search(r'\$?(\d+(?:,\d{3})*(?:\.\d{2})?)', text)
    if Match:
        PriceStr = Match.group(1).replace(',', '')
        return float(PriceStr)
    return None
```

### Error Handling and Logging

```python
import logging
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('scraper.log'),
        logging.StreamHandler()
    ]
)

Logger = logging.getLogger(__name__)

def safe_scrape(url: str) -> Optional[dict]:
    """
    Scrape URL with comprehensive error handling.
    
    Args:
        url: URL to scrape
        
    Returns:
        Scraped data or None if failed
    """
    try:
        Logger.info(f"Scraping: {url}")
        Response = requests.get(url, timeout=10)
        Response.raise_for_status()
        
        Soup = BeautifulSoup(Response.content, 'lxml')
        Data = {
            'title': Soup.find('h1').text,
            'content': Soup.find('article').text
        }
        
        Logger.info(f"Successfully scraped: {url}")
        return Data
        
    except requests.exceptions.Timeout:
        Logger.error(f"Timeout error for: {url}")
    except requests.exceptions.ConnectionError:
        Logger.error(f"Connection error for: {url}")
    except AttributeError as e:
        Logger.error(f"Parsing error for {url}: {e}")
    except Exception as e:
        Logger.error(f"Unexpected error for {url}: {e}")
    
    return None
```

### Data Storage

```python
import json
import csv
import sqlite3
from typing import List, Dict

def save_to_json(data: List[Dict], filename: str):
    """Save data to JSON file."""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def save_to_csv(data: List[Dict], filename: str):
    """Save data to CSV file."""
    if not data:
        return
    
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        Writer = csv.DictWriter(f, fieldnames=data[0].keys())
        Writer.writeheader()
        Writer.writerows(data)

def save_to_database(data: List[Dict], db_name: str, table_name: str):
    """Save data to SQLite database."""
    Conn = sqlite3.connect(db_name)
    Cursor = Conn.cursor()
    
    # Create table
    if data:
        Columns = ', '.join([f"{k} TEXT" for k in data[0].keys()])
        Cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({Columns})")
        
        # Insert data
        for Item in data:
            Placeholders = ', '.join(['?' for _ in Item])
            Cursor.execute(
                f"INSERT INTO {table_name} VALUES ({Placeholders})",
                list(Item.values())
            )
    
    Conn.commit()
    Conn.close()
```

## Legal and Ethical Considerations

### Legal Compliance

- **Review Terms of Service**: Always check a website's ToS before scraping
- **Respect Copyright**: Don't republish copyrighted content without permission
- **Personal Data**: Comply with GDPR, CCPA, and other privacy regulations
- **Computer Fraud Laws**: Avoid bypassing security measures or accessing unauthorized areas

### Ethical Scraping Guidelines

1. **Identify Yourself**: Use a descriptive User-Agent string
2. **Respect robots.txt**: Honor crawling rules and restrictions
3. **Rate Limiting**: Don't overload servers with requests
4. **Off-Peak Hours**: Schedule intensive scraping during low-traffic times
5. **Use APIs When Available**: Prefer official APIs over scraping
6. **Cache Responses**: Don't re-scrape unchanged content
7. **Be Transparent**: Provide contact information in your User-Agent

### Example: Responsible Scraper Configuration

```python
import requests
import time
from urllib.robotparser import RobotFileParser

class ResponsibleScraper:
    """Ethically-configured web scraper."""
    
    def __init__(self, name: str, contact: str):
        """
        Initialize scraper with identification.
        
        Args:
            name: Name of your scraper/project
            contact: Contact email or URL
        """
        self.Headers = {
            'User-Agent': f'{name}/1.0 (+{contact})',
            'Accept': 'text/html,application/xhtml+xml',
            'Accept-Language': 'en-US,en;q=0.9'
        }
        self.MinDelay = 1.0  # Minimum seconds between requests
        self.LastRequest = 0
        self.RobotsParsers = {}
    
    def can_fetch(self, url: str) -> bool:
        """Check robots.txt before scraping."""
        from urllib.parse import urlparse
        
        ParsedUrl = urlparse(url)
        Domain = f"{ParsedUrl.scheme}://{ParsedUrl.netloc}"
        
        if Domain not in self.RobotsParsers:
            Rp = RobotFileParser()
            Rp.set_url(f"{Domain}/robots.txt")
            try:
                Rp.read()
            except:
                pass
            self.RobotsParsers[Domain] = Rp
        
        return self.RobotsParsers[Domain].can_fetch("*", url)
    
    def fetch(self, url: str) -> Optional[requests.Response]:
        """
        Fetch URL with rate limiting and robots.txt compliance.
        
        Args:
            url: URL to fetch
            
        Returns:
            Response object or None if not allowed
        """
        if not self.can_fetch(url):
            Logger.warning(f"Blocked by robots.txt: {url}")
            return None
        
        # Rate limiting
        Elapsed = time.time() - self.LastRequest
        if Elapsed < self.MinDelay:
            time.sleep(self.MinDelay - Elapsed)
        
        try:
            Response = requests.get(url, headers=self.Headers, timeout=10)
            Response.raise_for_status()
            self.LastRequest = time.time()
            return Response
        except requests.exceptions.RequestException as e:
            Logger.error(f"Error fetching {url}: {e}")
            return None

# Usage
Scraper = ResponsibleScraper(
    name="MyResearchProject",
    contact="mailto:contact@example.com"
)

Response = Scraper.fetch("https://example.com")
if Response:
    # Process response
    pass
```

## Complete Example: Article Scraper

Here's a complete, production-ready web scraper that demonstrates best practices:

```python
#!/usr/bin/env python3
"""
Article Scraper - Comprehensive web scraping example.

This script demonstrates best practices for web scraping including
error handling, rate limiting, data validation, and ethical scraping.
"""

import requests
from bs4 import BeautifulSoup
import logging
import time
import json
from typing import List, Dict, Optional
from urllib.parse import urljoin, urlparse
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('scraper.log'),
        logging.StreamHandler()
    ]
)

Logger = logging.getLogger(__name__)

class ArticleScraper:
    """Professional article scraper with best practices."""
    
    def __init__(self, base_url: str, delay: float = 1.0):
        """
        Initialize article scraper.
        
        Args:
            base_url: Base URL of the website to scrape
            delay: Delay between requests in seconds
        """
        self.BaseUrl = base_url
        self.Delay = delay
        self.Session = self._create_session()
        self.Articles = []
    
    def _create_session(self) -> requests.Session:
        """Create configured session with retries."""
        Session = requests.Session()
        Session.headers.update({
            'User-Agent': 'ArticleScraper/1.0 (+https://github.com/example)',
            'Accept': 'text/html,application/xhtml+xml',
            'Accept-Language': 'en-US,en;q=0.9'
        })
        return Session
    
    def fetch_page(self, url: str) -> Optional[BeautifulSoup]:
        """
        Fetch and parse a webpage.
        
        Args:
            url: URL to fetch
            
        Returns:
            BeautifulSoup object or None if failed
        """
        try:
            time.sleep(self.Delay)
            Response = self.Session.get(url, timeout=10)
            Response.raise_for_status()
            
            Logger.info(f"Successfully fetched: {url}")
            return BeautifulSoup(Response.content, 'lxml')
            
        except requests.exceptions.RequestException as e:
            Logger.error(f"Error fetching {url}: {e}")
            return None
    
    def parse_article(self, soup: BeautifulSoup, url: str) -> Optional[Dict]:
        """
        Parse article data from soup object.
        
        Args:
            soup: BeautifulSoup object
            url: Article URL
            
        Returns:
            Dictionary with article data or None if parsing failed
        """
        try:
            Article = {}
            
            # Extract title
            TitleTag = soup.find('h1', class_='article-title')
            Article['title'] = TitleTag.text.strip() if TitleTag else 'No title'
            
            # Extract author
            AuthorTag = soup.find('span', class_='author')
            Article['author'] = AuthorTag.text.strip() if AuthorTag else 'Unknown'
            
            # Extract date
            DateTag = soup.find('time', class_='published')
            Article['date'] = DateTag.get('datetime') if DateTag else None
            
            # Extract content
            ContentTag = soup.find('div', class_='article-content')
            if ContentTag:
                Paragraphs = ContentTag.find_all('p')
                Article['content'] = ' '.join([p.text.strip() for p in Paragraphs])
            else:
                Article['content'] = ''
            
            # Add metadata
            Article['url'] = url
            Article['scraped_at'] = datetime.now().isoformat()
            Article['word_count'] = len(Article['content'].split())
            
            return Article
            
        except Exception as e:
            Logger.error(f"Error parsing article at {url}: {e}")
            return None
    
    def scrape_article_list(self, list_url: str) -> List[str]:
        """
        Scrape list of article URLs from index page.
        
        Args:
            list_url: URL of article list page
            
        Returns:
            List of article URLs
        """
        Soup = self.fetch_page(list_url)
        if not Soup:
            return []
        
        ArticleUrls = []
        for Link in Soup.find_all('a', class_='article-link'):
            Href = Link.get('href')
            if Href:
                FullUrl = urljoin(self.BaseUrl, Href)
                ArticleUrls.append(FullUrl)
        
        Logger.info(f"Found {len(ArticleUrls)} articles on {list_url}")
        return ArticleUrls
    
    def scrape_articles(self, max_articles: int = 10) -> List[Dict]:
        """
        Scrape multiple articles.
        
        Args:
            max_articles: Maximum number of articles to scrape
            
        Returns:
            List of article dictionaries
        """
        # Get article URLs
        ListUrl = f"{self.BaseUrl}/articles"
        ArticleUrls = self.scrape_article_list(ListUrl)
        
        # Limit number of articles
        ArticleUrls = ArticleUrls[:max_articles]
        
        # Scrape each article
        for Url in ArticleUrls:
            Soup = self.fetch_page(Url)
            if Soup:
                Article = self.parse_article(Soup, Url)
                if Article:
                    self.Articles.append(Article)
                    Logger.info(f"Scraped: {Article['title']}")
        
        return self.Articles
    
    def save_results(self, filename: str = 'articles.json'):
        """
        Save scraped articles to JSON file.
        
        Args:
            filename: Output filename
        """
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.Articles, f, indent=2, ensure_ascii=False)
        
        Logger.info(f"Saved {len(self.Articles)} articles to {filename}")
    
    def get_statistics(self) -> Dict:
        """
        Get scraping statistics.
        
        Returns:
            Dictionary with statistics
        """
        if not self.Articles:
            return {}
        
        TotalWords = sum(a['word_count'] for a in self.Articles)
        AvgWords = TotalWords / len(self.Articles)
        
        return {
            'total_articles': len(self.Articles),
            'total_words': TotalWords,
            'average_words': round(AvgWords, 2),
            'authors': len(set(a['author'] for a in self.Articles))
        }

def main():
    """Main execution function."""
    # Initialize scraper
    Scraper = ArticleScraper(
        base_url="https://example.com",
        delay=1.5
    )
    
    # Scrape articles
    Logger.info("Starting scraping process...")
    Articles = Scraper.scrape_articles(max_articles=5)
    
    # Save results
    Scraper.save_results('articles.json')
    
    # Display statistics
    Stats = Scraper.get_statistics()
    Logger.info(f"Scraping complete: {Stats}")

if __name__ == "__main__":
    main()
```

## Performance Optimization

### Concurrent Requests

```python
import asyncio
import aiohttp
from typing import List
from bs4 import BeautifulSoup

async def fetch_async(session: aiohttp.ClientSession, url: str) -> str:
    """
    Fetch URL asynchronously.
    
    Args:
        session: aiohttp session
        url: URL to fetch
        
    Returns:
        Response text
    """
    async with session.get(url) as Response:
        return await Response.text()

async def scrape_multiple_urls(urls: List[str]) -> List[str]:
    """
    Scrape multiple URLs concurrently.
    
    Args:
        urls: List of URLs to scrape
        
    Returns:
        List of HTML content
    """
    async with aiohttp.ClientSession() as Session:
        Tasks = [fetch_async(Session, url) for url in urls]
        Results = await asyncio.gather(*Tasks)
        return Results

# Usage
Urls = ["https://example.com/page1", "https://example.com/page2"]
Results = asyncio.run(scrape_multiple_urls(Urls))
```

### Caching Results

```python
import requests
from requests_cache import CachedSession
from datetime import timedelta

# Use cached session
Session = CachedSession(
    'scraper_cache',
    expire_after=timedelta(hours=24),
    backend='sqlite'
)

# Requests are automatically cached
Response = Session.get('https://example.com')
```

## Troubleshooting

### Common Issues and Solutions

**Issue**: 403 Forbidden errors

- **Solution**: Add proper User-Agent headers, use rotating proxies, or check robots.txt

**Issue**: Cloudflare or bot protection

- **Solution**: Use Selenium, add delays, rotate User-Agents, or use services like Scrapy-Splash

**Issue**: Dynamic content not loading

- **Solution**: Use Selenium instead of requests, wait for JavaScript to execute

**Issue**: Inconsistent selectors

- **Solution**: Use multiple selector strategies, add fallbacks, validate before accessing

**Issue**: Memory issues with large datasets

- **Solution**: Process data in batches, use generators, write to database incrementally

### Debugging Techniques

```python
# View raw HTML
print(Response.text[:500])

# Inspect parsed structure
print(Soup.prettify()[:1000])

# Check response status
print(f"Status: {Response.status_code}")
print(f"Headers: {Response.headers}")

# Verify selectors
Elements = Soup.select('div.article')
print(f"Found {len(Elements)} elements")

# Enable verbose logging
logging.getLogger().setLevel(logging.DEBUG)
```

## Tools and Libraries

### Essential Libraries

- **requests**: HTTP library for making requests
- **BeautifulSoup**: HTML/XML parsing library
- **lxml**: Fast XML/HTML parser
- **Selenium**: Browser automation for dynamic content
- **Scrapy**: Full-featured scraping framework
- **requests-cache**: HTTP caching for faster development

### Useful Utilities

- **fake-useragent**: Random User-Agent generation
- **python-dateutil**: Advanced date parsing
- **pandas**: Data manipulation and analysis
- **aiohttp**: Async HTTP requests
- **playwright**: Modern browser automation alternative to Selenium

### Development Tools

```bash
# Install development tools
pip install ipython jupyter
pip install black pylint  # Code formatting and linting
pip install pytest  # Testing framework
```

## Testing Your Scraper

```python
import unittest
from unittest.mock import Mock, patch

class TestArticleScraper(unittest.TestCase):
    """Unit tests for article scraper."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.TestHtml = """
        <html>
            <body>
                <h1 class="article-title">Test Article</h1>
                <span class="author">John Doe</span>
                <div class="article-content">
                    <p>Test content paragraph.</p>
                </div>
            </body>
        </html>
        """
    
    @patch('requests.Session.get')
    def test_fetch_page(self, mock_get):
        """Test page fetching."""
        MockResponse = Mock()
        MockResponse.content = self.TestHtml
        MockResponse.status_code = 200
        mock_get.return_value = MockResponse
        
        Scraper = ArticleScraper("https://example.com")
        Soup = Scraper.fetch_page("https://example.com/article")
        
        self.assertIsNotNone(Soup)
        self.assertEqual(Soup.find('h1').text, "Test Article")
    
    def test_parse_article(self):
        """Test article parsing."""
        Soup = BeautifulSoup(self.TestHtml, 'lxml')
        Scraper = ArticleScraper("https://example.com")
        Article = Scraper.parse_article(Soup, "https://example.com/test")
        
        self.assertEqual(Article['title'], "Test Article")
        self.assertEqual(Article['author'], "John Doe")
        self.assertIn("Test content", Article['content'])

if __name__ == '__main__':
    unittest.main()
```

## Further Resources

### Documentation

- [BeautifulSoup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Scrapy Documentation](https://docs.scrapy.org/)
- [Selenium Documentation](https://selenium-python.readthedocs.io/)
- [Requests Documentation](https://requests.readthedocs.io/)

### Learning Resources

- [Real Python Web Scraping Tutorials](https://realpython.com/tutorials/web-scraping/)
- [Scrapy Tutorial](https://docs.scrapy.org/en/latest/intro/tutorial.html)
- [Web Scraping with Python (Book)](https://www.oreilly.com/library/view/web-scraping-with/9781491985564/)

### Communities

- [r/webscraping](https://www.reddit.com/r/webscraping/) - Reddit community
- [Stack Overflow](https://stackoverflow.com/questions/tagged/web-scraping) - Q&A platform
- [Scrapy Community Forum](https://community.scrapy.org/)

## Summary

Web scraping with Python is a powerful skill that enables automated data collection from websites. Key takeaways:

- **Choose the right tool**: BeautifulSoup for static content, Selenium for dynamic content, Scrapy for large projects
- **Be ethical**: Respect robots.txt, rate limits, and terms of service
- **Handle errors gracefully**: Implement retries, logging, and validation
- **Optimize performance**: Use caching, concurrent requests, and efficient selectors
- **Stay legal**: Understand copyright, privacy laws, and computer fraud regulations

Start with simple projects using BeautifulSoup, gradually move to more complex scrapers with Selenium, and use Scrapy for production-scale applications. Always prioritize ethical scraping practices and respect website resources.

## See Also

- [Python Automation](../index.md)
- [API Integration](../api-integration.md)
- [Data Processing](../../data-science/data-processing.md)
- [Testing Strategies](../testing/index.md)
