---
title: Seaborn - Statistical Data Visualization
description: Guide to creating beautiful statistical graphics with Seaborn
author: Joseph Streeter
date: 2026-01-04
tags: [python, seaborn, data-visualization, statistics, plotting]
---

## Overview

Seaborn is a Python visualization library based on matplotlib that provides a high-level interface for drawing attractive statistical graphics.

## Installation

```bash
pip install seaborn
```

## Basic Usage

```python
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

# Load sample dataset
tips = sns.load_dataset('tips')

# Create scatter plot
sns.scatterplot(data=tips, x='total_bill', y='tip', hue='time')
plt.show()
```

## Plot Types

### Distribution Plots

```python
# Histogram with KDE
sns.histplot(data=tips, x='total_bill', kde=True)

# Box plot
sns.boxplot(data=tips, x='day', y='total_bill')

# Violin plot
sns.violinplot(data=tips, x='day', y='total_bill')
```

### Categorical Plots

```python
# Bar plot
sns.barplot(data=tips, x='day', y='total_bill', estimator=sum)

# Count plot
sns.countplot(data=tips, x='day')
```

### Regression Plots

```python
# Linear regression plot
sns.regplot(data=tips, x='total_bill', y='tip')

# Multiple regression plots
sns.lmplot(data=tips, x='total_bill', y='tip', hue='smoker')
```

## Styling

```python
# Set style
sns.set_style('darkgrid')

# Set context
sns.set_context('talk')

# Color palettes
sns.set_palette('husl')
```

## See Also

- [Matplotlib](matplotlib.md)
- [Pandas](pandas.md)
- [Data Visualization Best Practices](../best-practices/data-visualization.md)
