---
title: Analytics and Metrics
description: Implementing analytics and metrics for your Documentation as Code site to track usage and performance
---

## Analytics and Metrics

Monitor and analyze your documentation site's performance and usage to make data-driven improvements.

## Overview

Analytics provide valuable insights into how users interact with your documentation, helping you optimize content and improve user experience.

## Analytics Implementation

### Azure Application Insights

Configure Application Insights for your DocFX site:

```json
{
  "ApplicationInsights": {
    "InstrumentationKey": "your-instrumentation-key",
    "ConnectionString": "InstrumentationKey=your-key;IngestionEndpoint=..."
  }
}
```

### Google Analytics Integration

Add Google Analytics to your DocFX site:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_TRACKING_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_TRACKING_ID');
</script>
```

### Custom Analytics Implementation

```javascript
// Custom analytics tracking
function trackPageView(page) {
  // Send page view data to analytics service
  analytics.track('Page View', {
    page: page,
    timestamp: new Date(),
    userAgent: navigator.userAgent
  });
}

function trackSearchQuery(query) {
  // Track search interactions
  analytics.track('Search', {
    query: query,
    resultsCount: getSearchResults(query).length,
    timestamp: new Date()
  });
}
```

## Key Metrics to Track

### Content Performance Metrics

- **Page Views**: Track which pages are most visited
- **Time on Page**: Measure user engagement
- **Bounce Rate**: Identify pages that need improvement
- **Search Queries**: Understand what users are looking for

### User Behavior Metrics

- **Navigation Paths**: How users move through documentation
- **Download Tracking**: Track resource downloads
- **External Link Clicks**: Monitor outbound traffic
- **Feedback Ratings**: Collect user satisfaction data

### Technical Performance Metrics

- **Page Load Times**: Monitor site performance
- **Search Response Times**: Track search functionality
- **Error Rates**: Identify technical issues
- **Mobile Usage**: Understand device preferences

## Analytics Dashboard

### Azure Monitor Dashboard

Create custom dashboards in Azure Monitor:

```json
{
  "dashboard": {
    "title": "Documentation Analytics",
    "widgets": [
      {
        "type": "metric",
        "title": "Page Views",
        "query": "pageViews | summarize count() by bin(timestamp, 1h)"
      },
      {
        "type": "metric",
        "title": "Search Queries",
        "query": "customEvents | where name == 'Search' | summarize count() by bin(timestamp, 1h)"
      }
    ]
  }
}
```

### Power BI Integration

Connect your analytics data to Power BI:

```csharp
// Export analytics data for Power BI
public class AnalyticsExporter
{
    public async Task ExportToDataset(string datasetId)
    {
        var data = await GetAnalyticsData();
        await powerBIClient.Datasets.PostRowsAsync(datasetId, "analytics", data);
    }
    
    private async Task<IEnumerable<AnalyticsRow>> GetAnalyticsData()
    {
        // Query Application Insights or other analytics sources
        return await analyticsService.GetData();
    }
}
```

## Reporting and Insights

### Automated Reports

Set up automated reporting:

```yaml
# Azure DevOps Pipeline for Analytics Reports
trigger:
  schedules:
  - cron: "0 9 * * MON"
    displayName: Weekly Analytics Report
    branches:
      include:
      - main

stages:
- stage: GenerateReport
  jobs:
  - job: AnalyticsReport
    steps:
    - task: PowerShell@2
      displayName: 'Generate Analytics Report'
      inputs:
        targetType: 'inline'
        script: |
          # Generate weekly analytics report
          $report = Invoke-RestMethod -Uri "https://api.applicationinsights.io/v1/apps/$appId/query" `
            -Headers @{Authorization="Bearer $apiKey"} `
            -Body @{query="pageViews | summarize count() by bin(timestamp, 1d)"}
          
          # Send report via email or Teams
          Send-Report -Data $report
```

### Content Optimization Insights

Use analytics to optimize content:

```sql
-- Query to identify pages needing improvement
SELECT 
    pageName,
    AVG(timeOnPage) as avgTimeOnPage,
    AVG(bounceRate) as avgBounceRate,
    COUNT(*) as pageViews
FROM analytics_data
WHERE timestamp >= DATEADD(month, -1, GETDATE())
GROUP BY pageName
HAVING AVG(bounceRate) > 0.7 OR AVG(timeOnPage) < 30
ORDER BY pageViews DESC
```

## Privacy and Compliance

### GDPR Compliance

Ensure analytics implementation complies with privacy regulations:

```javascript
// Cookie consent management
function initializeAnalytics() {
  if (hasUserConsent()) {
    gtag('config', 'GA_TRACKING_ID', {
      'anonymize_ip': true,
      'cookie_expires': 0
    });
  }
}

function hasUserConsent() {
  return localStorage.getItem('analytics-consent') === 'true';
}
```

### Data Retention Policies

Configure appropriate data retention:

```json
{
  "analytics": {
    "retention": {
      "pageViews": "13 months",
      "searchQueries": "6 months",
      "userSessions": "2 months"
    },
    "anonymization": {
      "enabled": true,
      "ipAddresses": true,
      "userIds": false
    }
  }
}
```

## Troubleshooting

### Common Analytics Issues

1. **Missing Data**
   - Verify instrumentation key
   - Check content security policy
   - Validate tracking code placement

2. **Inaccurate Metrics**
   - Review bot filtering settings
   - Check for duplicate tracking
   - Validate event configuration

3. **Performance Impact**
   - Use asynchronous loading
   - Minimize tracking payload
   - Monitor page load impact

### Debugging Analytics

```javascript
// Debug analytics implementation
function debugAnalytics() {
  console.log('Analytics Debug Information:');
  console.log('GA Loaded:', typeof gtag !== 'undefined');
  console.log('Application Insights:', typeof appInsights !== 'undefined');
  console.log('Custom Events:', window.analyticsEvents || []);
}

// Test analytics events
function testAnalytics() {
  gtag('event', 'test_event', {
    'custom_parameter': 'test_value',
    'debug_mode': true
  });
}
```

## Best Practices

### Implementation Guidelines

- **Progressive Enhancement**: Ensure site works without analytics
- **Performance First**: Don't let analytics slow down your site
- **Privacy by Design**: Implement privacy controls from the start
- **Regular Audits**: Review analytics implementation regularly

### Data Collection

- **Meaningful Metrics**: Focus on actionable insights
- **User Context**: Collect relevant user journey data
- **Quality over Quantity**: Avoid analytics bloat
- **Regular Cleanup**: Archive or delete old data

### Reporting and Analysis

- **Regular Reviews**: Schedule monthly analytics reviews
- **Stakeholder Reports**: Share insights with relevant teams
- **Action-Oriented**: Convert insights into improvements
- **Trend Analysis**: Look for patterns over time

## Integration with Documentation Workflow

### Content Planning

Use analytics to inform content strategy:

```python
# Analyze content gaps
def analyze_content_gaps():
    search_queries = get_search_queries_without_results()
    popular_pages = get_most_visited_pages()
    
    gaps = []
    for query in search_queries:
        if not has_relevant_content(query):
            gaps.append({
                'query': query,
                'frequency': query.frequency,
                'suggested_content': generate_content_suggestion(query)
            })
    
    return gaps
```

### Performance Monitoring

Monitor documentation performance:

```yaml
# Performance monitoring alerts
alerts:
  - name: "Slow Page Load"
    condition: "avg(pageLoadTime) > 3000"
    action: "notify-team"
  
  - name: "High Bounce Rate"
    condition: "avg(bounceRate) > 0.8"
    action: "review-content"
  
  - name: "Search Failures"
    condition: "count(searchErrors) > 10"
    action: "check-search-service"
```

---

*Last updated: [Date] | For analytics support, contact the documentation team*
