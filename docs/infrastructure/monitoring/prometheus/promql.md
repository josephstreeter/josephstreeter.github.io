---
title: "PromQL Query Language"
description: "Reference for PromQL, the Prometheus query language - data model, selectors, operators, functions, aggregation, rates, histograms, and subqueries."
author: "josephstreeter"
ms.author: josephstreeter
ms.topic: reference
ms.date: 07/18/2026
keywords: ["prometheus", "promql", "query language", "rate", "histogram_quantile", "aggregation", "selectors", "subquery"]
uid: docs.infrastructure.prometheus.promql
---

## PromQL Query Language

PromQL (Prometheus Query Language) is the functional expression language used to select and aggregate time-series data in Prometheus. It is the language behind every graph, alert rule, and recording rule in this stack, and it is understood by every Prometheus-compatible engine — Thanos, Mimir, VictoriaMetrics, and Azure Monitor Managed Service for Prometheus.

This page is the **canonical PromQL reference** for the monitoring section. The [Prometheus overview](index.md) covers running the server; [Alerting](alerting.md) applies PromQL in alert rules; and [Grafana dashboards](../grafana/dashboards.md) apply it in panels. Each of those links back here for the language itself.

> [!NOTE]
> Every query is evaluated against the [Prometheus data model](index.md#data-model-and-metric-types): a time series is identified by a metric name plus a set of key/value labels, and holds a stream of `(timestamp, value)` samples. PromQL selects subsets of those series and computes new values from them.

## Expression types

A PromQL expression evaluates to one of four types. Knowing which type a subexpression produces explains most "no data" and type-error surprises.

| Type | What it is | Example |
| ---- | ---------- | ------- |
| **Instant vector** | One sample per series at the eval timestamp | `http_requests_total` |
| **Range vector** | A window of samples per series | `http_requests_total[5m]` |
| **Scalar** | A single numeric value | `100`, `scalar(up)` |
| **String** | A string literal (rarely used) | `"prometheus"` |

> [!IMPORTANT]
> Functions expect specific types. `rate()` takes a **range vector** and returns an **instant vector**; most arithmetic and aggregation takes an **instant vector**. You cannot apply a range selector to the result of a function — `rate(rate(x[5m])[5m])` is invalid. Use a [subquery](#subqueries) when you need a range over a computed value.

## Selectors and matchers

An **instant vector selector** picks series by metric name and label matchers:

```promql
# Simple metric selection (all series with this name)
http_requests_total

# Filter by an exact label value
http_requests_total{method="GET"}

# Multiple matchers are AND-ed together
http_requests_total{method="GET", status="200"}

# Regular-expression match (RE2, fully anchored)
http_requests_total{handler=~"/api/.*"}

# Negative exact match
http_requests_total{status!="200"}

# Negative regex match
http_requests_total{handler!~"/health|/metrics"}
```

The four matcher operators:

| Operator | Meaning |
| -------- | ------- |
| `=` | Label equals value exactly |
| `!=` | Label does not equal value |
| `=~` | Label matches the RE2 regex (anchored at both ends) |
| `!~` | Label does not match the regex |

A **range vector selector** appends a duration in square brackets, producing the window of raw samples used by rate-style functions:

```promql
# The last 5 minutes of raw samples for each series
http_requests_total[5m]

# Valid duration units: ms, s, m, h, d, w, y (and combinations like 1h30m)
node_cpu_seconds_total[1h30m]
```

> [!TIP]
> A regex matcher is anchored — `=~"api"` matches only the exact string `api`, not `/api/v1`. Write `=~".*api.*"` (or `=~"/api/.*"`) to match substrings. Empty-value matchers are meaningful: `{env=""}` selects series that do not have the `env` label at all.

The `offset` modifier and `@` modifier shift the evaluation time:

```promql
# Value as it was 1 hour ago
http_requests_total offset 1h

# Rate evaluated at a fixed timestamp (Unix seconds)
rate(http_requests_total[5m] @ 1700000000)

# Week-over-week comparison
rate(http_requests_total[5m]) / rate(http_requests_total[5m] offset 7d)
```

## Operators

### Arithmetic and comparison

Binary arithmetic (`+ - * / % ^`) and comparison (`== != > < >= <=`) operators work between vectors and scalars:

```promql
# Scalar arithmetic on every sample
node_memory_MemTotal_bytes / 1024 / 1024

# CPU utilization percentage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory utilization percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Comparison as a FILTER (keeps series where true)
up == 0

# Comparison with bool (returns 0/1 instead of filtering)
(rate(http_requests_total[5m]) > bool 100)
```

> [!NOTE]
> A comparison operator **filters** by default — `up == 0` returns only the series that are down. Add `bool` (`up == bool 0`) to turn it into a 0/1 result for every series instead, which is what you usually want inside arithmetic or for graphing a boolean.

### Vector matching

When both sides are vectors, PromQL matches samples by their label sets. Control the join with `on`/`ignoring` and `group_left`/`group_right`:

```promql
# Match on a subset of labels
rate(http_requests_total{status=~"5.."}[5m])
  / ignoring(status) group_left
    sum without (status) (rate(http_requests_total[5m]))

# Many-to-one: attach a metadata metric (e.g. a "info" series)
node_cpu_seconds_total * on(instance) group_left(nodename) node_uname_info
```

`ignoring(...)` drops the listed labels before matching; `on(...)` matches only on the listed labels. `group_left`/`group_right` allow many-to-one and one-to-many joins and carry extra labels from the "one" side.

### Logical/set operators

`and`, `or`, and `unless` combine instant vectors by label set:

```promql
# Series present in both (intersection)
high_cpu and high_memory

# Series in either (union)
critical_alerts or warning_alerts

# Series in the first but NOT the second (difference)
up == 1 unless on(instance) node_maintenance_mode
```

## Functions

PromQL ships a large function library. The ones you reach for constantly:

| Function | Purpose |
| -------- | ------- |
| `rate(v[d])` | Per-second average rate of a counter over the range |
| `irate(v[d])` | Per-second instant rate from the last two samples |
| `increase(v[d])` | Total increase of a counter over the range |
| `delta(v[d])` | Difference between first and last value of a gauge |
| `deriv(v[d])` | Per-second derivative of a gauge (linear regression) |
| `predict_linear(v[d], t)` | Extrapolate a gauge `t` seconds into the future |
| `histogram_quantile(φ, v)` | φ-quantile from classic histogram buckets |
| `<agg>_over_time(v[d])` | `avg/min/max/sum/count/quantile/last/stddev` over a range per series |
| `absent(v)` / `absent_over_time(v[d])` | 1 when the selector matches no series |
| `clamp_max/min`, `round`, `abs`, `ceil`, `floor` | Value shaping |
| `label_replace`, `label_join` | Rewrite/synthesize labels |

### Counters: rate, irate, increase

Counters only ever go up (until they reset to zero on restart). Never graph a raw counter — always wrap it in `rate`, `irate`, or `increase`, all of which are reset-aware:

```promql
# Per-second average rate over 5 minutes (use for graphs and alerts)
rate(http_requests_total[5m])

# Instant rate from the last two samples (spiky; use for fast-moving graphs)
irate(http_requests_total[5m])

# Total requests in the last hour (use for "how many", not "how fast")
increase(http_requests_total[1h])
```

> [!IMPORTANT]
> Prefer `rate()` for alerting and most dashboards — it is smooth and resilient to scrape jitter. Reserve `irate()` for high-resolution graphs of volatile signals. Always choose a range at least **4× the scrape interval** (e.g. `[1m]` or more for a 15s scrape) so every window contains enough samples; too short a range yields gaps and noise.

### Gauges: delta, deriv, predict_linear

Gauges go up and down. Use gauge functions to measure change and forecast:

```promql
# How much a gauge changed over 10 minutes
delta(node_memory_MemAvailable_bytes[10m])

# Per-second derivative (trend) of a gauge
deriv(node_filesystem_avail_bytes[1h])

# Seconds until a filesystem fills, extrapolated from the last hour
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4 * 3600) < 0
```

### `*_over_time` aggregation across time

Where `rate` summarizes a counter, the `_over_time` family summarizes any series across its range window (one result per series):

```promql
# Availability ratio over the last hour
avg_over_time(up[1h])

# Peak memory in the last day
max_over_time(node_memory_MemUsed_bytes[1d])

# 95th percentile of a gauge over 30 minutes
quantile_over_time(0.95, node_load1[30m])
```

## Aggregation operators

Aggregation operators collapse many series into fewer, grouped by labels with `by` (keep only these) or `without` (keep all but these):

```promql
# Sum across all series
sum(rate(http_requests_total[5m]))

# Sum grouped by job
sum by (job) (rate(http_requests_total[5m]))

# Average per instance, dropping all other labels
avg by (instance) (rate(node_cpu_seconds_total[5m]))

# Everything except the noisy 'le' label
sum without (le) (rate(http_request_duration_seconds_bucket[5m]))

# Count healthy targets
count(up == 1)

# Top 5 / bottom 3 series
topk(5, rate(node_cpu_seconds_total[5m]))
bottomk(3, node_memory_MemAvailable_bytes)
```

Available aggregators include `sum`, `avg`, `min`, `max`, `count`, `count_values`, `stddev`, `stdvar`, `group`, `topk`, `bottomk`, and `quantile`.

> [!TIP]
> `by` and `without` are opposites — `by (instance)` keeps only `instance`, while `without (le)` keeps everything except `le`. Prefer `without` when you want to preserve identifying labels (job, instance) and only drop an aggregation dimension.

## Histograms and quantiles

Classic histograms expose cumulative `_bucket` series with an `le` ("less than or equal") label. Compute a quantile by rating the buckets, summing by `le`, and applying `histogram_quantile`:

```promql
# 95th percentile request latency across all instances
histogram_quantile(0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# 99th percentile per service
histogram_quantile(0.99,
  sum by (le, service) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency (sum / count), NOT a percentile
sum(rate(http_request_duration_seconds_sum[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

> [!WARNING]
> You must `rate()` the `_bucket` series and keep the `le` label in the aggregation (`sum by (le) (...)`). Aggregating away `le`, or feeding a raw counter to `histogram_quantile`, produces meaningless results. Quantile accuracy is bounded by your bucket boundaries — a `0.99` quantile is only as precise as the buckets around it.

## Subqueries

A subquery evaluates an instant-vector expression over a range, producing a range vector you can feed to another range function. This is the correct way to take a range over a computed value:

```promql
# Max of a 5m rate, sampled over the last hour at 1m resolution
max_over_time(rate(http_requests_total[5m])[1h:1m])

# Is the request rate now well above its own recent peak?
rate(http_requests_total[5m])
  > 2 * avg_over_time(rate(http_requests_total[5m])[1h:5m])
```

The syntax is `expr[<range>:<resolution>]`. Subqueries are expensive — prefer a [recording rule](#recording-rules-and-heavy-queries) for anything evaluated frequently.

## Common patterns

```promql
# Error rate as a percentage of all requests
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m])) * 100

# Success rate (SLI)
sum(rate(http_requests_total{status=~"2.."}[5m]))
  / sum(rate(http_requests_total[5m]))

# A target is down (scraped but failing)
up == 0

# A series has disappeared entirely (target dropped from discovery / never scraped).
# This is NOT the same as up == 0, which needs the target to still be scraped.
absent_over_time(up{job="my-service"}[5m])

# Container throttling and memory pressure
rate(container_cpu_cfs_throttled_seconds_total[5m])
(container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
```

## Recording rules and heavy queries

When a query is expensive (subqueries, high-cardinality aggregation) or reused across many dashboards and alerts, precompute it with a **recording rule** so Prometheus evaluates it once per interval and stores the result as a new series:

```yaml
# /etc/prometheus/rules/recording.yml
groups:
  - name: dashboard_rules
    interval: 30s
    rules:
      - record: instance:node_cpu_utilization:rate5m
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Dashboards and alerts then reference the cheap precomputed series:

```promql
instance:node_cpu_utilization:rate5m
```

The naming convention is `level:metric:operation`. See [Alerting](alerting.md) for alert rules and [Grafana dashboards](../grafana/dashboards.md#performance-optimization) for how recording rules speed up panels.

## Pitfalls

- **Graphing a raw counter** — always wrap counters in `rate`/`irate`/`increase`; a raw counter is a meaningless ever-rising line that resets to zero on restart.
- **Range too short** — a range selector shorter than ~4× the scrape interval produces gaps; `rate(x[1m])` on a 30s scrape is fragile.
- **Unanchored-regex assumptions** — `=~` is fully anchored; use `.*` for substring matches.
- **Comparisons silently filtering** — `> 100` drops non-matching series; add `bool` when you need a 0/1 for every series.
- **Aggregating away `le`** — breaks `histogram_quantile`; always `sum by (le) (...)`.
- **`up == 0` vs `absent()`** — the first needs the target to still be scraped; the second detects a series that vanished entirely.

## Related

- [Prometheus — Overview](index.md) — running the server, scrape config, and the data model.
- [Prometheus — Alerting](alerting.md) — PromQL in alert and recording rules.
- [Prometheus — Exporters](exporters.md) — the metrics these queries run against.
- [Grafana — Dashboards](../grafana/dashboards.md) — PromQL in dashboard panels.

## References

- [Querying basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Operators](https://prometheus.io/docs/prometheus/latest/querying/operators/)
- [Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)
- [Querying examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Histograms and summaries](https://prometheus.io/docs/practices/histograms/)
