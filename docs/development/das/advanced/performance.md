---
title: Performance Optimization
description: Advanced techniques for optimizing DocFX site performance and user experience
---

## Performance Optimization

Implement advanced performance optimization strategies to deliver fast, responsive documentation experiences that scale with your organization's needs.

## Performance Analysis Framework

### Core Web Vitals Monitoring

```javascript
// performance-monitor.js
class PerformanceMonitor {
  constructor() {
    this.metrics = {};
    this.observers = {};
    this.init();
  }
  
  init() {
    this.setupWebVitalsTracking();
    this.setupCustomMetrics();
    this.setupRealUserMonitoring();
  }
  
  setupWebVitalsTracking() {
    // Largest Contentful Paint
    new PerformanceObserver((entryList) => {
      const entries = entryList.getEntries();
      const lastEntry = entries[entries.length - 1];
      this.metrics.lcp = lastEntry.startTime;
      this.reportMetric('lcp', lastEntry.startTime);
    }).observe({ entryTypes: ['largest-contentful-paint'] });
    
    // First Input Delay
    new PerformanceObserver((entryList) => {
      const firstInput = entryList.getEntries()[0];
      if (firstInput) {
        this.metrics.fid = firstInput.processingStart - firstInput.startTime;
        this.reportMetric('fid', this.metrics.fid);
      }
    }).observe({ entryTypes: ['first-input'], buffered: true });
    
    // Cumulative Layout Shift
    let clsValue = 0;
    new PerformanceObserver((entryList) => {
      for (const entry of entryList.getEntries()) {
        if (!entry.hadRecentInput) {
          clsValue += entry.value;
        }
      }
      this.metrics.cls = clsValue;
      this.reportMetric('cls', clsValue);
    }).observe({ entryTypes: ['layout-shift'], buffered: true });
  }
  
  setupCustomMetrics() {
    // Time to First Meaningful Paint
    const observer = new PerformanceObserver((entryList) => {
      const entries = entryList.getEntries();
      for (const entry of entries) {
        if (entry.name === 'first-meaningful-paint') {
          this.metrics.fmp = entry.startTime;
          this.reportMetric('fmp', entry.startTime);
        }
      }
    });
    observer.observe({ entryTypes: ['paint'] });
    
    // Search Response Time
    this.trackSearchPerformance();
    
    // Navigation Timing
    this.trackNavigationTiming();
  }
  
  trackSearchPerformance() {
    const originalFetch = window.fetch;
    window.fetch = function(url, options) {
      if (url.includes('/search')) {
        const startTime = performance.now();
        return originalFetch.apply(this, arguments)
          .then(response => {
            const endTime = performance.now();
            const duration = endTime - startTime;
            window.performanceMonitor.reportMetric('search_response_time', duration);
            return response;
          });
      }
      return originalFetch.apply(this, arguments);
    };
  }
  
  trackNavigationTiming() {
    window.addEventListener('load', () => {
      const navigation = performance.getEntriesByType('navigation')[0];
      
      this.metrics.pageLoad = navigation.loadEventEnd - navigation.loadEventStart;
      this.metrics.domContentLoaded = navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart;
      this.metrics.timeToInteractive = this.calculateTTI();
      
      this.reportMetric('page_load', this.metrics.pageLoad);
      this.reportMetric('dom_content_loaded', this.metrics.domContentLoaded);
      this.reportMetric('time_to_interactive', this.metrics.timeToInteractive);
    });
  }
  
  calculateTTI() {
    // Simplified TTI calculation
    // In production, use a more sophisticated algorithm
    const navigation = performance.getEntriesByType('navigation')[0];
    return navigation.domContentLoadedEventEnd - navigation.fetchStart;
  }
  
  reportMetric(name, value) {
    // Send to analytics service
    if (typeof gtag !== 'undefined') {
      gtag('event', 'performance_metric', {
        metric_name: name,
        metric_value: Math.round(value),
        page_path: window.location.pathname
      });
    }
    
    // Send to Application Insights
    if (typeof appInsights !== 'undefined') {
      appInsights.trackMetric({ name: name, average: value });
    }
    
    // Log to console in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`Performance metric ${name}: ${value}ms`);
    }
  }
  
  generatePerformanceReport() {
    return {
      coreWebVitals: {
        lcp: this.metrics.lcp,
        fid: this.metrics.fid,
        cls: this.metrics.cls
      },
      customMetrics: {
        fmp: this.metrics.fmp,
        pageLoad: this.metrics.pageLoad,
        domContentLoaded: this.metrics.domContentLoaded,
        timeToInteractive: this.metrics.timeToInteractive
      },
      recommendations: this.generateRecommendations()
    };
  }
  
  generateRecommendations() {
    const recommendations = [];
    
    if (this.metrics.lcp > 2500) {
      recommendations.push({
        metric: 'LCP',
        issue: 'Large Contentful Paint is too slow',
        suggestion: 'Optimize images, use CDN, implement lazy loading'
      });
    }
    
    if (this.metrics.fid > 100) {
      recommendations.push({
        metric: 'FID',
        issue: 'First Input Delay is too high',
        suggestion: 'Reduce JavaScript execution time, use web workers'
      });
    }
    
    if (this.metrics.cls > 0.1) {
      recommendations.push({
        metric: 'CLS',
        issue: 'Cumulative Layout Shift is too high',
        suggestion: 'Set image dimensions, avoid dynamic content insertion'
      });
    }
    
    return recommendations;
  }
}

// Initialize performance monitoring
window.performanceMonitor = new PerformanceMonitor();
```

### Performance Budget Configuration

```json
{
  "performance_budget": {
    "core_web_vitals": {
      "lcp": {
        "target": 1500,
        "threshold": 2500,
        "unit": "ms"
      },
      "fid": {
        "target": 50,
        "threshold": 100,
        "unit": "ms"
      },
      "cls": {
        "target": 0.05,
        "threshold": 0.1,
        "unit": "score"
      }
    },
    "resource_budgets": {
      "total_size": {
        "target": "1MB",
        "threshold": "2MB"
      },
      "javascript": {
        "target": "200KB",
        "threshold": "400KB"
      },
      "css": {
        "target": "50KB",
        "threshold": "100KB"
      },
      "images": {
        "target": "500KB",
        "threshold": "1MB"
      },
      "fonts": {
        "target": "100KB",
        "threshold": "200KB"
      }
    },
    "request_budgets": {
      "total_requests": {
        "target": 50,
        "threshold": 100
      },
      "third_party_requests": {
        "target": 5,
        "threshold": 10
      }
    }
  }
}
```

## Content Optimization

### Image Optimization Pipeline

```yaml
# image-optimization-pipeline.yml
name: Image Optimization Pipeline

trigger:
  paths:
    include:
    - 'docs/**/*.png'
    - 'docs/**/*.jpg'
    - 'docs/**/*.jpeg'
    - 'docs/**/*.svg'

jobs:
- job: OptimizeImages
  displayName: 'Optimize and Process Images'
  
  steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'
    
  - script: |
      npm install -g imagemin-cli imagemin-pngquant imagemin-mozjpeg imagemin-svgo
    displayName: 'Install image optimization tools'
  
  - script: |
      # Optimize PNG images
      find docs -name "*.png" -exec imagemin {} --plugin=pngquant --out-dir=optimized/{} \;
      
      # Optimize JPEG images
      find docs -name "*.jpg" -o -name "*.jpeg" -exec imagemin {} --plugin=mozjpeg --out-dir=optimized/{} \;
      
      # Optimize SVG images
      find docs -name "*.svg" -exec imagemin {} --plugin=svgo --out-dir=optimized/{} \;
    displayName: 'Optimize images'
  
  - script: |
      # Generate WebP versions
      find optimized -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | while read img; do
        cwebp "$img" -o "${img%.*}.webp"
      done
      
      # Generate AVIF versions for modern browsers
      find optimized -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | while read img; do
        avifenc "$img" "${img%.*}.avif"
      done
    displayName: 'Generate modern image formats'
  
  - script: |
      # Generate responsive image variants
      for size in 320 768 1024 1920; do
        find optimized -name "*.jpg" -o -name "*.png" | while read img; do
          convert "$img" -resize "${size}x>" "${img%.*}-${size}w.${img##*.}"
        done
      done
    displayName: 'Generate responsive variants'
  
  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: 'optimized'
      artifactName: 'optimized-images'
```

### Responsive Images Implementation

```html
<!-- Responsive images with modern formats -->
<picture>
  <!-- AVIF for modern browsers -->
  <source 
    srcset="
      images/diagram-320w.avif 320w,
      images/diagram-768w.avif 768w,
      images/diagram-1024w.avif 1024w,
      images/diagram-1920w.avif 1920w
    "
    sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 25vw"
    type="image/avif">
  
  <!-- WebP for wider browser support -->
  <source 
    srcset="
      images/diagram-320w.webp 320w,
      images/diagram-768w.webp 768w,
      images/diagram-1024w.webp 1024w,
      images/diagram-1920w.webp 1920w
    "
    sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 25vw"
    type="image/webp">
  
  <!-- Fallback to JPEG/PNG -->
  <img 
    src="images/diagram-768w.jpg"
    srcset="
      images/diagram-320w.jpg 320w,
      images/diagram-768w.jpg 768w,
      images/diagram-1024w.jpg 1024w,
      images/diagram-1920w.jpg 1920w
    "
    sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 25vw"
    alt="System architecture diagram"
    loading="lazy"
    decoding="async">
</picture>
```

### Content Delivery Optimization

```javascript
// lazy-loading-manager.js
class LazyLoadingManager {
  constructor() {
    this.observer = null;
    this.images = [];
    this.init();
  }
  
  init() {
    this.setupIntersectionObserver();
    this.findLazyImages();
    this.observeImages();
  }
  
  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: '50px',
      threshold: 0.1
    };
    
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadImage(entry.target);
          this.observer.unobserve(entry.target);
        }
      });
    }, options);
  }
  
  findLazyImages() {
    this.images = document.querySelectorAll('img[loading="lazy"]');
  }
  
  observeImages() {
    this.images.forEach(img => {
      this.observer.observe(img);
    });
  }
  
  loadImage(img) {
    // Preload the image
    const imageLoader = new Image();
    
    imageLoader.onload = () => {
      // Fade in effect
      img.style.opacity = '0';
      img.src = imageLoader.src;
      
      // Copy srcset if available
      if (img.dataset.srcset) {
        img.srcset = img.dataset.srcset;
      }
      
      // Animate fade in
      requestAnimationFrame(() => {
        img.style.transition = 'opacity 0.3s ease-in-out';
        img.style.opacity = '1';
      });
    };
    
    imageLoader.onerror = () => {
      // Fallback handling
      img.style.background = '#f0f0f0';
      img.alt = 'Image failed to load';
    };
    
    // Start loading
    imageLoader.src = img.dataset.src || img.src;
  }
}

// Initialize lazy loading
document.addEventListener('DOMContentLoaded', () => {
  new LazyLoadingManager();
});
```

## Build Optimization

### DocFX Build Performance

```json
{
  "build": {
    "content": [
      {
        "files": ["docs/**/*.md"],
        "exclude": [
          "docs/**/node_modules/**",
          "docs/**/.git/**",
          "docs/**/bin/**",
          "docs/**/obj/**"
        ]
      }
    ],
    "resource": [
      {
        "files": ["images/**", "files/**"],
        "exclude": ["**/*.tmp", "**/*.cache"]
      }
    ],
    "globalMetadata": {
      "_enableSearch": true,
      "_enableNewTab": true,
      "_disableContribution": false
    },
    "fileMetadata": {
      "_disableContribution": {
        "api/**/*.md": true
      }
    },
    "template": ["default", "modern"],
    "postProcessors": ["ExtractSearchIndex"],
    "markdownEngineName": "markdig",
    "markdownEngineProperties": {
      "markdigExtensions": [
        "abbreviations",
        "autoidentifiers",
        "citations",
        "customcontainers",
        "definitionlists",
        "emphasisextras",
        "figures",
        "footers",
        "footnotes",
        "gridtables",
        "mathematics",
        "medialinks",
        "pipetables",
        "listextras",
        "tasklists",
        "diagrams",
        "autolinks",
        "attributes"
      ]
    }
  },
  "serve": {
    "host": "localhost",
    "port": 8080
  },
  "performance": {
    "caching": {
      "enabled": true,
      "cacheDirectory": ".cache",
      "maxAge": "7d"
    },
    "parallel": {
      "enabled": true,
      "maxWorkers": 4
    },
    "compression": {
      "enabled": true,
      "level": 6
    }
  }
}
```

### Incremental Build Strategy

```powershell
# incremental-build.ps1
param(
    [string]$BuildType = "incremental",
    [string]$OutputPath = "_site",
    [string]$CachePath = ".cache"
)

function Get-ChangedFiles {
    param([string]$Since)
    
    $changedFiles = git diff --name-only $Since HEAD
    return $changedFiles | Where-Object { $_ -like "docs/*" -or $_ -like "*.yml" -or $_ -like "*.json" }
}

function Should-PerformFullBuild {
    param([string[]]$ChangedFiles)
    
    $configFiles = @("docfx.json", "toc.yml", "template/*")
    
    foreach ($file in $ChangedFiles) {
        foreach ($configPattern in $configFiles) {
            if ($file -like $configPattern) {
                return $true
            }
        }
    }
    
    return $false
}

function Optimize-Images {
    param([string[]]$ImageFiles)
    
    foreach ($image in $ImageFiles) {
        if ($image -like "*.png" -or $image -like "*.jpg" -or $image -like "*.jpeg") {
            Write-Host "Optimizing $image"
            
            # Create optimized version
            $optimizedPath = $image -replace "docs/", "optimized/"
            $optimizedDir = Split-Path $optimizedPath -Parent
            
            if (!(Test-Path $optimizedDir)) {
                New-Item -ItemType Directory -Path $optimizedDir -Force
            }
            
            # Use imagemagick for optimization
            magick $image -quality 85 -strip $optimizedPath
        }
    }
}

# Main build logic
Write-Host "Starting DocFX build..."

$lastBuildCommit = Get-Content ".last-build-commit" -ErrorAction SilentlyContinue
$currentCommit = git rev-parse HEAD

if ($BuildType -eq "incremental" -and $lastBuildCommit) {
    $changedFiles = Get-ChangedFiles -Since $lastBuildCommit
    
    if ($changedFiles.Count -eq 0) {
        Write-Host "No changes detected. Skipping build."
        exit 0
    }
    
    Write-Host "Changed files: $($changedFiles -join ', ')"
    
    if (Should-PerformFullBuild -ChangedFiles $changedFiles) {
        Write-Host "Configuration changes detected. Performing full build."
        $BuildType = "full"
    } else {
        Write-Host "Performing incremental build."
        
        # Optimize only changed images
        $changedImages = $changedFiles | Where-Object { $_ -like "*.png" -or $_ -like "*.jpg" -or $_ -like "*.jpeg" }
        if ($changedImages) {
            Optimize-Images -ImageFiles $changedImages
        }
    }
}

# Execute DocFX build
$buildArgs = @("build", "docfx.json")

if ($BuildType -eq "incremental") {
    $buildArgs += "--incremental"
}

$buildArgs += @("--output", $OutputPath)

if (Test-Path $CachePath) {
    $buildArgs += @("--cache", $CachePath)
}

Write-Host "Executing: docfx $($buildArgs -join ' ')"
& docfx $buildArgs

if ($LASTEXITCODE -eq 0) {
    # Update last build commit
    $currentCommit | Out-File ".last-build-commit" -Encoding ASCII
    Write-Host "Build completed successfully."
} else {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
```

## Caching Strategies

### Multi-layer Caching Implementation

```javascript
// cache-manager.js
class CacheManager {
  constructor() {
    this.memoryCache = new Map();
    this.localStorageCache = new LocalStorageCache();
    this.indexedDBCache = new IndexedDBCache();
    this.serviceWorkerCache = new ServiceWorkerCache();
    
    this.init();
  }
  
  async init() {
    await this.indexedDBCache.init();
    await this.serviceWorkerCache.init();
    this.setupCacheHierarchy();
  }
  
  setupCacheHierarchy() {
    this.cacheHierarchy = [
      { name: 'memory', cache: this.memoryCache, maxAge: 5 * 60 * 1000 }, // 5 minutes
      { name: 'localStorage', cache: this.localStorageCache, maxAge: 30 * 60 * 1000 }, // 30 minutes
      { name: 'indexedDB', cache: this.indexedDBCache, maxAge: 24 * 60 * 60 * 1000 }, // 24 hours
      { name: 'serviceWorker', cache: this.serviceWorkerCache, maxAge: 7 * 24 * 60 * 60 * 1000 } // 7 days
    ];
  }
  
  async get(key) {
    // Try each cache layer in order
    for (const layer of this.cacheHierarchy) {
      try {
        const result = await layer.cache.get(key);
        if (result && !this.isExpired(result, layer.maxAge)) {
          // Promote to higher cache layers
          await this.promoteToHigherLayers(key, result, layer);
          return result.data;
        }
      } catch (error) {
        console.warn(`Cache layer ${layer.name} failed:`, error);
      }
    }
    
    return null;
  }
  
  async set(key, data, options = {}) {
    const cacheEntry = {
      data: data,
      timestamp: Date.now(),
      metadata: options.metadata || {}
    };
    
    // Store in all appropriate cache layers
    for (const layer of this.cacheHierarchy) {
      try {
        if (!options.skipLayers || !options.skipLayers.includes(layer.name)) {
          await layer.cache.set(key, cacheEntry);
        }
      } catch (error) {
        console.warn(`Failed to store in ${layer.name}:`, error);
      }
    }
  }
  
  async promoteToHigherLayers(key, data, currentLayer) {
    const currentIndex = this.cacheHierarchy.indexOf(currentLayer);
    
    for (let i = 0; i < currentIndex; i++) {
      try {
        await this.cacheHierarchy[i].cache.set(key, data);
      } catch (error) {
        console.warn(`Failed to promote to ${this.cacheHierarchy[i].name}:`, error);
      }
    }
  }
  
  isExpired(cacheEntry, maxAge) {
    return (Date.now() - cacheEntry.timestamp) > maxAge;
  }
  
  async invalidate(key) {
    for (const layer of this.cacheHierarchy) {
      try {
        await layer.cache.delete(key);
      } catch (error) {
        console.warn(`Failed to invalidate ${layer.name}:`, error);
      }
    }
  }
  
  async clear() {
    for (const layer of this.cacheHierarchy) {
      try {
        await layer.cache.clear();
      } catch (error) {
        console.warn(`Failed to clear ${layer.name}:`, error);
      }
    }
  }
}

class LocalStorageCache {
  get(key) {
    try {
      const item = localStorage.getItem(`cache_${key}`);
      return item ? JSON.parse(item) : null;
    } catch (error) {
      return null;
    }
  }
  
  set(key, data) {
    try {
      localStorage.setItem(`cache_${key}`, JSON.stringify(data));
      return true;
    } catch (error) {
      // Handle quota exceeded
      this.clearOldest();
      try {
        localStorage.setItem(`cache_${key}`, JSON.stringify(data));
        return true;
      } catch (retryError) {
        return false;
      }
    }
  }
  
  delete(key) {
    localStorage.removeItem(`cache_${key}`);
  }
  
  clear() {
    const keys = Object.keys(localStorage).filter(key => key.startsWith('cache_'));
    keys.forEach(key => localStorage.removeItem(key));
  }
  
  clearOldest() {
    const cacheKeys = Object.keys(localStorage)
      .filter(key => key.startsWith('cache_'))
      .map(key => {
        try {
          const data = JSON.parse(localStorage.getItem(key));
          return { key, timestamp: data.timestamp };
        } catch {
          return { key, timestamp: 0 };
        }
      })
      .sort((a, b) => a.timestamp - b.timestamp);
    
    // Remove oldest 25% of cache entries
    const toRemove = Math.ceil(cacheKeys.length * 0.25);
    for (let i = 0; i < toRemove; i++) {
      localStorage.removeItem(cacheKeys[i].key);
    }
  }
}

class IndexedDBCache {
  constructor() {
    this.db = null;
    this.dbName = 'DocCache';
    this.version = 1;
  }
  
  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };
      
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains('cache')) {
          const store = db.createObjectStore('cache', { keyPath: 'key' });
          store.createIndex('timestamp', 'timestamp', { unique: false });
        }
      };
    });
  }
  
  async get(key) {
    if (!this.db) return null;
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['cache'], 'readonly');
      const store = transaction.objectStore('cache');
      const request = store.get(key);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const result = request.result;
        resolve(result ? { data: result.data, timestamp: result.timestamp } : null);
      };
    });
  }
  
  async set(key, data) {
    if (!this.db) return false;
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const request = store.put({
        key: key,
        data: data.data,
        timestamp: data.timestamp
      });
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(true);
    });
  }
  
  async delete(key) {
    if (!this.db) return;
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const request = store.delete(key);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }
  
  async clear() {
    if (!this.db) return;
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['cache'], 'readwrite');
      const store = transaction.objectStore('cache');
      const request = store.clear();
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }
}
```

### Service Worker Implementation

```javascript
// service-worker.js
const CACHE_NAME = 'docs-cache-v1';
const STATIC_CACHE = 'static-v1';
const DYNAMIC_CACHE = 'dynamic-v1';

const STATIC_ASSETS = [
  '/',
  '/styles/main.css',
  '/scripts/main.js',
  '/images/logo.svg',
  '/offline.html'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return Promise.all(
          cacheNames
            .filter(name => name !== STATIC_CACHE && name !== DYNAMIC_CACHE)
            .map(name => caches.delete(name))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Handle different types of requests with appropriate strategies
  if (STATIC_ASSETS.includes(url.pathname)) {
    // Cache first for static assets
    event.respondWith(cacheFirst(request));
  } else if (url.pathname.startsWith('/api/search')) {
    // Network first for search API
    event.respondWith(networkFirst(request));
  } else if (url.pathname.endsWith('.html')) {
    // Stale while revalidate for HTML pages
    event.respondWith(staleWhileRevalidate(request));
  } else {
    // Network first for other requests
    event.respondWith(networkFirst(request));
  }
});

async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);
  return cachedResponse || fetch(request);
}

async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    
    // Cache successful responses
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Return offline page for navigation requests
    if (request.destination === 'document') {
      return caches.match('/offline.html');
    }
    
    throw error;
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(DYNAMIC_CACHE);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request).then(networkResponse => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  });
  
  return cachedResponse || fetchPromise;
}

// Background sync for offline actions
self.addEventListener('sync', event => {
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

async function doBackgroundSync() {
  // Handle offline actions when connection is restored
  const requests = await getStoredRequests();
  
  for (const request of requests) {
    try {
      await fetch(request);
      await removeStoredRequest(request.id);
    } catch (error) {
      console.log('Background sync failed for request:', request.id);
    }
  }
}
```

## CDN and Edge Optimization

### Azure CDN Configuration

```json
{
  "cdn_profile": {
    "name": "docs-cdn-profile",
    "sku": "Standard_Microsoft",
    "resource_group": "docs-resources",
    "location": "global"
  },
  "endpoints": [
    {
      "name": "docs-content",
      "origin": {
        "host_name": "docs-storage.blob.core.windows.net",
        "http_port": 80,
        "https_port": 443
      },
      "caching_rules": [
        {
          "name": "static-assets",
          "path": "/styles/*",
          "caching_behavior": "Override",
          "cache_duration": "365.00:00:00"
        },
        {
          "name": "images",
          "path": "/images/*",
          "caching_behavior": "Override",
          "cache_duration": "30.00:00:00"
        },
        {
          "name": "html-content",
          "path": "*.html",
          "caching_behavior": "Override",
          "cache_duration": "01:00:00"
        }
      ],
      "compression": {
        "enabled": true,
        "content_types": [
          "text/html",
          "text/css",
          "text/javascript",
          "application/javascript",
          "application/json",
          "text/xml",
          "application/xml"
        ]
      },
      "geo_filters": [],
      "custom_domains": [
        {
          "host_name": "docs.company.com",
          "https_enabled": true
        }
      ]
    }
  ]
}
```

### Edge Computing with Azure Functions

```javascript
// edge-optimization.js
module.exports = async function (context, req) {
    const url = new URL(req.url);
    const userAgent = req.headers['user-agent'] || '';
    const acceptHeader = req.headers.accept || '';
    
    // Device detection
    const isMobile = /Mobile|Android|iPhone|iPad/.test(userAgent);
    const supportsWebP = acceptHeader.includes('image/webp');
    const supportsAVIF = acceptHeader.includes('image/avif');
    
    // Content optimization based on client capabilities
    let optimizedContent = await getContent(url.pathname);
    
    if (url.pathname.includes('/images/')) {
        optimizedContent = await optimizeImage(optimizedContent, {
            isMobile,
            supportsWebP,
            supportsAVIF
        });
    } else if (url.pathname.endsWith('.html')) {
        optimizedContent = await optimizeHTML(optimizedContent, {
            isMobile,
            minify: true,
            inlineCriticalCSS: true
        });
    }
    
    // Set appropriate cache headers
    const cacheHeaders = getCacheHeaders(url.pathname);
    
    context.res = {
        status: 200,
        headers: {
            'Content-Type': getContentType(url.pathname),
            'Cache-Control': cacheHeaders.cacheControl,
            'ETag': cacheHeaders.etag,
            'Last-Modified': cacheHeaders.lastModified,
            'Vary': 'Accept, User-Agent'
        },
        body: optimizedContent
    };
};

async function optimizeImage(imageBuffer, options) {
    const sharp = require('sharp');
    let pipeline = sharp(imageBuffer);
    
    if (options.isMobile) {
        // Reduce quality and size for mobile
        pipeline = pipeline.resize({ width: 800, withoutEnlargement: true });
    }
    
    if (options.supportsAVIF) {
        return pipeline.avif({ quality: 80 }).toBuffer();
    } else if (options.supportsWebP) {
        return pipeline.webp({ quality: 85 }).toBuffer();
    } else {
        return pipeline.jpeg({ quality: 90 }).toBuffer();
    }
}

async function optimizeHTML(html, options) {
    const minify = require('html-minifier').minify;
    
    let optimized = html;
    
    if (options.minify) {
        optimized = minify(optimized, {
            removeComments: true,
            collapseWhitespace: true,
            removeRedundantAttributes: true,
            useShortDoctype: true,
            removeEmptyAttributes: true,
            removeStyleLinkTypeAttributes: true,
            keepClosingSlash: true,
            minifyJS: true,
            minifyCSS: true
        });
    }
    
    if (options.inlineCriticalCSS) {
        optimized = await inlineCriticalCSS(optimized);
    }
    
    if (options.isMobile) {
        // Remove non-essential elements for mobile
        optimized = optimized.replace(/<script[^>]*analytics[^>]*>.*?<\/script>/gi, '');
    }
    
    return optimized;
}

function getCacheHeaders(pathname) {
    const lastModified = new Date().toUTCString();
    const etag = `"${Date.now()}"`;
    
    if (pathname.includes('/styles/') || pathname.includes('/scripts/')) {
        return {
            cacheControl: 'public, max-age=31536000, immutable',
            etag,
            lastModified
        };
    } else if (pathname.includes('/images/')) {
        return {
            cacheControl: 'public, max-age=2592000',
            etag,
            lastModified
        };
    } else {
        return {
            cacheControl: 'public, max-age=3600, must-revalidate',
            etag,
            lastModified
        };
    }
}
```

## Performance Testing and Monitoring

### Automated Performance Testing

```yaml
# performance-testing-pipeline.yml
name: Performance Testing Pipeline

trigger:
  branches:
    include:
    - main
    - performance/*

jobs:
- job: PerformanceTest
  displayName: 'Run Performance Tests'
  pool:
    vmImage: 'ubuntu-latest'
  
  steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'
  
  - script: |
      npm install -g lighthouse @lhci/cli
    displayName: 'Install Lighthouse CI'
  
  - script: |
      # Build the site
      npm run build
      
      # Start local server
      npm run serve &
      SERVER_PID=$!
      
      # Wait for server to start
      sleep 10
      
      # Run Lighthouse CI
      lhci autorun --config=lighthouserc.json
      
      # Stop server
      kill $SERVER_PID
    displayName: 'Run Lighthouse Performance Tests'
  
  - script: |
      # Install k6 for load testing
      sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
      echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
      sudo apt-get update
      sudo apt-get install k6
      
      # Run load tests
      k6 run performance-tests/load-test.js
    displayName: 'Run Load Tests'
  
  - script: |
      # Run WebPageTest
      npm install -g webpagetest
      webpagetest test https://docs.company.com --key $(WPT_API_KEY) --location $(WPT_LOCATION)
    displayName: 'Run WebPageTest'
  
  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'performance-results/*.xml'
      testRunTitle: 'Performance Tests'
    condition: always()
```

### Real User Monitoring Dashboard

```javascript
// rum-dashboard.js
class RUMDashboard {
  constructor() {
    this.metrics = {};
    this.charts = {};
    this.init();
  }
  
  async init() {
    await this.loadRUMData();
    this.createDashboard();
    this.setupRealTimeUpdates();
  }
  
  async loadRUMData() {
    try {
      const response = await fetch('/api/rum-metrics');
      this.metrics = await response.json();
    } catch (error) {
      console.error('Failed to load RUM data:', error);
    }
  }
  
  createDashboard() {
    document.getElementById('rum-dashboard').innerHTML = `
      <div class="dashboard-header">
        <h1>Real User Monitoring Dashboard</h1>
        <div class="time-range-selector">
          <select id="time-range">
            <option value="1h">Last Hour</option>
            <option value="24h" selected>Last 24 Hours</option>
            <option value="7d">Last 7 Days</option>
            <option value="30d">Last 30 Days</option>
          </select>
        </div>
      </div>
      
      <div class="core-vitals-grid">
        <div class="vital-card lcp">
          <h3>Largest Contentful Paint</h3>
          <div class="metric-value">${this.metrics.lcp.p75}ms</div>
          <div class="metric-status ${this.getVitalStatus('lcp', this.metrics.lcp.p75)}">
            ${this.getVitalStatus('lcp', this.metrics.lcp.p75)}
          </div>
        </div>
        
        <div class="vital-card fid">
          <h3>First Input Delay</h3>
          <div class="metric-value">${this.metrics.fid.p75}ms</div>
          <div class="metric-status ${this.getVitalStatus('fid', this.metrics.fid.p75)}">
            ${this.getVitalStatus('fid', this.metrics.fid.p75)}
          </div>
        </div>
        
        <div class="vital-card cls">
          <h3>Cumulative Layout Shift</h3>
          <div class="metric-value">${this.metrics.cls.p75}</div>
          <div class="metric-status ${this.getVitalStatus('cls', this.metrics.cls.p75)}">
            ${this.getVitalStatus('cls', this.metrics.cls.p75)}
          </div>
        </div>
      </div>
      
      <div class="charts-container">
        <div class="chart-section">
          <h3>Performance Trends</h3>
          <canvas id="performance-trends"></canvas>
        </div>
        
        <div class="chart-section">
          <h3>Device Breakdown</h3>
          <canvas id="device-breakdown"></canvas>
        </div>
        
        <div class="chart-section">
          <h3>Geographic Performance</h3>
          <canvas id="geographic-performance"></canvas>
        </div>
      </div>
      
      <div class="detailed-metrics">
        <h3>Detailed Metrics</h3>
        <table class="metrics-table">
          <thead>
            <tr>
              <th>Metric</th>
              <th>P50</th>
              <th>P75</th>
              <th>P95</th>
              <th>P99</th>
            </tr>
          </thead>
          <tbody>
            ${this.generateMetricsTable()}
          </tbody>
        </table>
      </div>
    `;
    
    this.createCharts();
  }
  
  getVitalStatus(metric, value) {
    const thresholds = {
      lcp: { good: 2500, poor: 4000 },
      fid: { good: 100, poor: 300 },
      cls: { good: 0.1, poor: 0.25 }
    };
    
    const threshold = thresholds[metric];
    if (value <= threshold.good) return 'good';
    if (value <= threshold.poor) return 'needs-improvement';
    return 'poor';
  }
  
  generateMetricsTable() {
    const metrics = ['lcp', 'fid', 'cls', 'fcp', 'ttfb'];
    
    return metrics.map(metric => {
      const data = this.metrics[metric] || {};
      return `
        <tr>
          <td>${metric.toUpperCase()}</td>
          <td>${data.p50 || 'N/A'}</td>
          <td>${data.p75 || 'N/A'}</td>
          <td>${data.p95 || 'N/A'}</td>
          <td>${data.p99 || 'N/A'}</td>
        </tr>
      `;
    }).join('');
  }
  
  createCharts() {
    // Performance trends chart
    this.charts.trends = new Chart(document.getElementById('performance-trends'), {
      type: 'line',
      data: {
        labels: this.metrics.timeline.labels,
        datasets: [
          {
            label: 'LCP (ms)',
            data: this.metrics.timeline.lcp,
            borderColor: '#FF6384',
            backgroundColor: 'rgba(255, 99, 132, 0.1)'
          },
          {
            label: 'FID (ms)',
            data: this.metrics.timeline.fid,
            borderColor: '#36A2EB',
            backgroundColor: 'rgba(54, 162, 235, 0.1)'
          }
        ]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
    
    // Device breakdown chart
    this.charts.devices = new Chart(document.getElementById('device-breakdown'), {
      type: 'doughnut',
      data: {
        labels: ['Desktop', 'Mobile', 'Tablet'],
        datasets: [{
          data: [
            this.metrics.devices.desktop,
            this.metrics.devices.mobile,
            this.metrics.devices.tablet
          ],
          backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56']
        }]
      },
      options: {
        responsive: true
      }
    });
  }
  
  setupRealTimeUpdates() {
    setInterval(async () => {
      await this.loadRUMData();
      this.updateCharts();
    }, 60000); // Update every minute
  }
  
  updateCharts() {
    Object.values(this.charts).forEach(chart => {
      chart.update();
    });
  }
}

// Initialize RUM dashboard
document.addEventListener('DOMContentLoaded', () => {
  new RUMDashboard();
});
```

## Best Practices Summary

### Performance Optimization Checklist

- **Core Web Vitals**: Monitor and optimize LCP, FID, and CLS
- **Image Optimization**: Use modern formats, responsive images, and lazy loading
- **Caching Strategy**: Implement multi-layer caching with appropriate TTLs
- **Build Optimization**: Use incremental builds and parallel processing
- **CDN Integration**: Leverage edge computing and geographic distribution
- **Code Splitting**: Implement dynamic imports and lazy loading
- **Resource Prioritization**: Use resource hints and critical resource optimization

### Monitoring and Measurement

- **Real User Monitoring**: Track actual user experiences
- **Synthetic Testing**: Automated performance testing in CI/CD
- **Performance Budgets**: Set and enforce performance thresholds
- **Regular Audits**: Schedule periodic performance reviews
- **A/B Testing**: Test performance optimizations with real users

### Continuous Improvement

- **Performance Culture**: Embed performance considerations in development workflow
- **Regular Training**: Keep team updated on performance best practices
- **Tool Updates**: Stay current with performance tools and techniques
- **User Feedback**: Incorporate user experience insights into optimization efforts

---

This comprehensive performance optimization guide provides the tools and techniques needed to deliver exceptional documentation experiences that scale with your organization's growth and user expectations.
