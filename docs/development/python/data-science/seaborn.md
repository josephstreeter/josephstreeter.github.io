---
title: Seaborn - Statistical Data Visualization
description: Comprehensive guide to creating beautiful statistical graphics with Seaborn, including distribution plots, categorical visualizations, regression analysis, and advanced styling techniques
author: Joseph Streeter
date: 2026-01-04
tags: [python, seaborn, data-visualization, statistics, plotting, matplotlib, pandas]
---

## Overview

Seaborn is a powerful Python data visualization library built on top of matplotlib that provides a high-level interface for creating attractive and informative statistical graphics. It comes with several built-in themes, color palettes, and plot types designed to make complex visualizations more accessible and aesthetically pleasing.

### Key Features

- **High-level interface** for complex visualizations with minimal code
- **Built-in statistical estimation** and plotting functions
- **Beautiful default themes** and color palettes
- **Tight integration** with pandas DataFrames
- **Support for multi-plot grids** and complex layouts
- **Automatic statistical aggregation** for categorical data

### When to Use Seaborn

- Creating statistical visualizations quickly
- Exploring relationships in datasets
- Visualizing distributions and categorical data
- Building publication-quality graphics
- Working with pandas DataFrames
- Needing automatic statistical estimation

## Installation

### Basic Installation

```bash
pip install seaborn
```

### Installation with Optional Dependencies

```bash
pip install seaborn[all]
```

### Verify Installation

```python
import seaborn as sns
print(sns.__version__)
```

## Getting Started

### Basic Imports

```python
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# Set default theme
sns.set_theme()
```

### Loading Sample Datasets

Seaborn includes several built-in datasets for learning and testing:

```python
# Available datasets
print(sns.get_dataset_names())

# Load a dataset
tips = sns.load_dataset('tips')
iris = sns.load_dataset('iris')
titanic = sns.load_dataset('titanic')
diamonds = sns.load_dataset('diamonds')
```

### Basic Plotting Workflow

```python
# Create a simple scatter plot
sns.scatterplot(data=tips, x='total_bill', y='tip', hue='time')
plt.title('Tips vs Total Bill')
plt.show()
```

## Distribution Plots

Distribution plots help visualize the distribution of data values.

### Histogram with KDE

```python
# Basic histogram
sns.histplot(data=tips, x='total_bill')

# Histogram with KDE overlay
sns.histplot(data=tips, x='total_bill', kde=True)

# Multiple distributions
sns.histplot(data=tips, x='total_bill', hue='time', multiple='stack')

# With custom bins
sns.histplot(data=tips, x='total_bill', bins=20, kde=True)
```

### KDE Plot

```python
# Kernel Density Estimation plot
sns.kdeplot(data=tips, x='total_bill')

# Bivariate KDE
sns.kdeplot(data=tips, x='total_bill', y='tip')

# Multiple distributions
sns.kdeplot(data=tips, x='total_bill', hue='time', fill=True)

# Adjust bandwidth
sns.kdeplot(data=tips, x='total_bill', bw_adjust=0.5)
```

### Distribution Plot (displot)

The `displot()` function is a figure-level function for distribution visualization:

```python
# Basic distribution plot
sns.displot(data=tips, x='total_bill', kde=True)

# Multiple plots by category
sns.displot(data=tips, x='total_bill', col='time', row='sex')

# ECDF (Empirical Cumulative Distribution Function)
sns.displot(data=tips, x='total_bill', kind='ecdf')

# Rug plot addition
sns.displot(data=tips, x='total_bill', kde=True, rug=True)
```

### Box Plot

```python
# Basic box plot
sns.boxplot(data=tips, x='day', y='total_bill')

# Horizontal box plot
sns.boxplot(data=tips, x='total_bill', y='day')

# Multiple categories
sns.boxplot(data=tips, x='day', y='total_bill', hue='time')

# Custom width
sns.boxplot(data=tips, x='day', y='total_bill', width=0.5)
```

### Violin Plot

```python
# Basic violin plot
sns.violinplot(data=tips, x='day', y='total_bill')

# Split violin for comparison
sns.violinplot(data=tips, x='day', y='total_bill', hue='sex', split=True)

# Inner representation options
sns.violinplot(data=tips, x='day', y='total_bill', inner='box')
sns.violinplot(data=tips, x='day', y='total_bill', inner='quartile')
sns.violinplot(data=tips, x='day', y='total_bill', inner='point')
```

### Box-Violin Combination

```python
# Violin with box plot inside
fig, ax = plt.subplots(figsize=(10, 6))
sns.violinplot(data=tips, x='day', y='total_bill', ax=ax, color='lightgray')
sns.boxplot(data=tips, x='day', y='total_bill', ax=ax, width=0.3)
plt.show()
```

## Categorical Plots

Categorical plots show relationships between categorical and numerical variables.

### Bar Plot

```python
# Basic bar plot (shows mean by default)
sns.barplot(data=tips, x='day', y='total_bill')

# Custom estimator
sns.barplot(data=tips, x='day', y='total_bill', estimator=sum)
sns.barplot(data=tips, x='day', y='total_bill', estimator=np.median)

# With error bars
sns.barplot(data=tips, x='day', y='total_bill', errorbar='sd')

# Multiple categories
sns.barplot(data=tips, x='day', y='total_bill', hue='sex')
```

### Count Plot

```python
# Count occurrences
sns.countplot(data=tips, x='day')

# Horizontal count plot
sns.countplot(data=tips, y='day')

# Multiple categories
sns.countplot(data=tips, x='day', hue='sex')

# Order categories
sns.countplot(data=tips, x='day', order=['Thur', 'Fri', 'Sat', 'Sun'])
```

### Point Plot

```python
# Point plot with error bars
sns.pointplot(data=tips, x='day', y='total_bill')

# Multiple categories
sns.pointplot(data=tips, x='day', y='total_bill', hue='sex')

# Custom markers and line styles
sns.pointplot(data=tips, x='day', y='total_bill', markers=['o', 's'], 
              linestyles=['-', '--'])
```

### Strip Plot

```python
# Show all points
sns.stripplot(data=tips, x='day', y='total_bill')

# Add jitter to avoid overlap
sns.stripplot(data=tips, x='day', y='total_bill', jitter=True)

# Combine with violin plot
sns.violinplot(data=tips, x='day', y='total_bill', color='lightgray')
sns.stripplot(data=tips, x='day', y='total_bill', color='black', alpha=0.3)
```

### Swarm Plot

```python
# Non-overlapping points
sns.swarmplot(data=tips, x='day', y='total_bill')

# Multiple categories
sns.swarmplot(data=tips, x='day', y='total_bill', hue='sex')

# Combine with box plot
sns.boxplot(data=tips, x='day', y='total_bill', color='lightgray')
sns.swarmplot(data=tips, x='day', y='total_bill', color='black', size=3)
```

### Categorical Plot (catplot)

Figure-level function for categorical data:

```python
# Basic categorical plot
sns.catplot(data=tips, x='day', y='total_bill', kind='box')

# Multiple plots
sns.catplot(data=tips, x='day', y='total_bill', col='time', kind='violin')

# Different plot types
sns.catplot(data=tips, x='day', y='total_bill', kind='bar')
sns.catplot(data=tips, x='day', y='total_bill', kind='strip')
sns.catplot(data=tips, x='day', y='total_bill', kind='swarm')
```

## Regression Plots

Visualize relationships and trends between variables.

### Scatter Plot with Regression

```python
# Basic regression plot
sns.regplot(data=tips, x='total_bill', y='tip')

# Polynomial regression
sns.regplot(data=tips, x='total_bill', y='tip', order=2)

# Logistic regression
sns.regplot(data=tips, x='total_bill', y='tip', logistic=True)

# Robust regression
sns.regplot(data=tips, x='total_bill', y='tip', robust=True)

# Custom scatter and line properties
sns.regplot(data=tips, x='total_bill', y='tip', 
            scatter_kws={'alpha': 0.5, 's': 50},
            line_kws={'color': 'red', 'linewidth': 2})
```

### LM Plot (Figure-level)

```python
# Basic linear model plot
sns.lmplot(data=tips, x='total_bill', y='tip')

# Multiple regression lines
sns.lmplot(data=tips, x='total_bill', y='tip', hue='smoker')

# Separate plots
sns.lmplot(data=tips, x='total_bill', y='tip', col='time')

# Grid of plots
sns.lmplot(data=tips, x='total_bill', y='tip', col='time', row='sex')

# No confidence interval
sns.lmplot(data=tips, x='total_bill', y='tip', ci=None)
```

### Residual Plot

```python
# Check regression assumptions
sns.residplot(data=tips, x='total_bill', y='tip')

# Lowess smoothing
sns.residplot(data=tips, x='total_bill', y='tip', lowess=True)
```

## Relational Plots

Show relationships between variables.

### Scatter Plot

```python
# Basic scatter plot
sns.scatterplot(data=tips, x='total_bill', y='tip')

# Multiple categories with color
sns.scatterplot(data=tips, x='total_bill', y='tip', hue='time')

# Size by variable
sns.scatterplot(data=tips, x='total_bill', y='tip', size='size')

# Style by variable
sns.scatterplot(data=tips, x='total_bill', y='tip', style='time')

# Combine all aesthetics
sns.scatterplot(data=tips, x='total_bill', y='tip', 
                hue='time', size='size', style='sex')

# Custom palette
sns.scatterplot(data=tips, x='total_bill', y='tip', 
                hue='time', palette='Set2')
```

### Line Plot

```python
# Basic line plot
data = pd.DataFrame({
    'time': range(100),
    'value': np.cumsum(np.random.randn(100))
})
sns.lineplot(data=data, x='time', y='value')

# Multiple lines
sns.lineplot(data=tips, x='size', y='total_bill', hue='time')

# Confidence interval
sns.lineplot(data=tips, x='size', y='total_bill', ci='sd')

# Multiple estimators
sns.lineplot(data=tips, x='size', y='total_bill', estimator=np.median)
```

### Relational Plot (relplot)

```python
# Figure-level scatter plot
sns.relplot(data=tips, x='total_bill', y='tip', hue='time')

# Multiple plots
sns.relplot(data=tips, x='total_bill', y='tip', col='time', row='sex')

# Line plot
sns.relplot(data=tips, x='size', y='total_bill', kind='line')

# Faceted plots
sns.relplot(data=tips, x='total_bill', y='tip', 
            col='time', hue='smoker', style='sex')
```

## Matrix Plots

Visualize matrices and correlations.

### Heatmap

```python
# Correlation matrix
corr = tips.corr(numeric_only=True)
sns.heatmap(corr)

# With annotations
sns.heatmap(corr, annot=True, fmt='.2f')

# Custom color map
sns.heatmap(corr, cmap='coolwarm', center=0)

# Square cells
sns.heatmap(corr, square=True, linewidths=1)

# Pivot table heatmap
pivot = tips.pivot_table(values='tip', index='day', columns='time')
sns.heatmap(pivot, annot=True)
```

### Cluster Map

```python
# Hierarchical clustering
iris_data = iris.drop('species', axis=1)
sns.clustermap(iris_data.corr())

# Custom clustering
sns.clustermap(iris_data.T, method='average', metric='euclidean',
               cmap='viridis', standard_scale=1)

# No row/column dendrogram
sns.clustermap(iris_data.corr(), row_cluster=False, col_cluster=False)
```

## Pair Plots

Visualize pairwise relationships in a dataset.

### Basic Pair Plot

```python
# All pairwise relationships
sns.pairplot(iris)

# Colored by category
sns.pairplot(iris, hue='species')

# Custom plot types
sns.pairplot(iris, hue='species', diag_kind='kde')

# Subset of variables
sns.pairplot(iris, vars=['sepal_length', 'sepal_width'], hue='species')
```

### Pair Grid

More control over pair plots:

```python
# Create grid
g = sns.PairGrid(iris, hue='species')

# Map different plots
g.map_upper(sns.scatterplot)
g.map_lower(sns.kdeplot)
g.map_diag(sns.histplot)
g.add_legend()

# Custom mapping
g = sns.PairGrid(iris)
g.map_diag(plt.hist)
g.map_offdiag(plt.scatter)
```

## Joint Plots

Combine bivariate and univariate plots.

```python
# Basic joint plot
sns.jointplot(data=tips, x='total_bill', y='tip')

# Hexbin
sns.jointplot(data=tips, x='total_bill', y='tip', kind='hex')

# KDE
sns.jointplot(data=tips, x='total_bill', y='tip', kind='kde')

# Regression
sns.jointplot(data=tips, x='total_bill', y='tip', kind='reg')

# Multiple categories
sns.jointplot(data=tips, x='total_bill', y='tip', hue='time')
```

## Multi-Plot Grids

Create complex multi-plot layouts.

### FacetGrid

```python
# Create grid
g = sns.FacetGrid(tips, col='time', row='sex')
g.map(sns.scatterplot, 'total_bill', 'tip')

# With categories
g = sns.FacetGrid(tips, col='time', hue='smoker')
g.map(sns.scatterplot, 'total_bill', 'tip')
g.add_legend()

# Custom layout
g = sns.FacetGrid(tips, col='day', col_wrap=2, height=3)
g.map(sns.histplot, 'total_bill', kde=True)

# Multiple plots per facet
g = sns.FacetGrid(tips, col='time')
g.map(sns.scatterplot, 'total_bill', 'tip', alpha=0.5)
g.map(sns.regplot, 'total_bill', 'tip', scatter=False, color='red')
```

## Styling and Aesthetics

### Themes

Seaborn provides five preset themes:

```python
# Available themes: darkgrid, whitegrid, dark, white, ticks
sns.set_theme(style='darkgrid')
sns.set_theme(style='whitegrid')
sns.set_theme(style='dark')
sns.set_theme(style='white')
sns.set_theme(style='ticks')

# Remove spines
sns.set_theme(style='white')
sns.despine()  # Remove top and right spines
sns.despine(left=True)  # Remove left spine too
```

### Contexts

Adjust plot elements for different uses:

```python
# Available contexts: paper, notebook, talk, poster
sns.set_context('paper')      # Smallest
sns.set_context('notebook')   # Default
sns.set_context('talk')       # Presentations
sns.set_context('poster')     # Largest

# Custom scaling
sns.set_context('notebook', font_scale=1.5)

# Fine-grained control
sns.set_context('notebook', rc={'lines.linewidth': 2.5})
```

### Color Palettes

```python
# Categorical palettes
sns.set_palette('deep')
sns.set_palette('muted')
sns.set_palette('pastel')
sns.set_palette('bright')
sns.set_palette('dark')
sns.set_palette('colorblind')

# Sequential palettes
sns.set_palette('Blues')
sns.set_palette('YlOrRd')

# Diverging palettes
sns.set_palette('RdBu')
sns.set_palette('coolwarm')

# View palette
sns.palplot(sns.color_palette('husl', 8))

# Custom palette
custom_palette = ['#FF6B6B', '#4ECDC4', '#45B7D1']
sns.set_palette(custom_palette)

# Create color palette
palette = sns.color_palette('viridis', n_colors=10)
palette = sns.light_palette('green', n_colors=8)
palette = sns.dark_palette('purple', n_colors=8)
palette = sns.diverging_palette(220, 20, n=7)
```

### Palette Functions

```python
# Cubehelix palette
sns.cubehelix_palette(start=0, rot=0.4, dark=0.3, light=0.8, n_colors=8)

# Categorical palette
sns.color_palette('Set2')

# Perceptually uniform
sns.color_palette('rocket')
sns.color_palette('mako')
```

### Setting Palette in Context

```python
# Temporary palette
with sns.color_palette('husl'):
    sns.boxplot(data=tips, x='day', y='total_bill')
```

## Customization

### Figure Size and DPI

```python
# Set figure size
sns.set_theme(rc={'figure.figsize': (12, 8)})

# Set DPI
sns.set_theme(rc={'figure.dpi': 100})

# For specific plot
plt.figure(figsize=(10, 6))
sns.scatterplot(data=tips, x='total_bill', y='tip')
```

### Font Properties

```python
# Font size
sns.set_theme(font_scale=1.2)

# Font family
sns.set_theme(rc={'font.family': 'serif'})

# Title and labels
plt.figure(figsize=(10, 6))
sns.scatterplot(data=tips, x='total_bill', y='tip')
plt.title('Tips vs Total Bill', fontsize=16, fontweight='bold')
plt.xlabel('Total Bill ($)', fontsize=12)
plt.ylabel('Tip ($)', fontsize=12)
```

### Axes Properties

```python
# Grid
sns.set_theme(style='whitegrid')
g = sns.scatterplot(data=tips, x='total_bill', y='tip')
g.grid(True, alpha=0.3)

# Limits
plt.xlim(0, 60)
plt.ylim(0, 12)

# Ticks
plt.xticks(rotation=45)
plt.yticks(range(0, 13, 2))
```

### Legend

```python
# Move legend
plt.legend(loc='upper left')
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')

# Remove legend
plt.legend([],[], frameon=False)

# Custom legend
plt.legend(title='Time of Day', title_fontsize=12, fontsize=10)
```

## Advanced Techniques

### Statistical Annotations

```python
from scipy import stats

# Add statistical test result
fig, ax = plt.subplots()
sns.boxplot(data=tips, x='time', y='total_bill', ax=ax)

# Perform t-test
lunch = tips[tips['time'] == 'Lunch']['total_bill']
dinner = tips[tips['time'] == 'Dinner']['total_bill']
t_stat, p_value = stats.ttest_ind(lunch, dinner)

ax.text(0.5, 45, f'p-value: {p_value:.4f}', ha='center')
```

### Custom Color Mapping

```python
# Create custom color mapping
color_map = {'Lunch': 'skyblue', 'Dinner': 'coral'}
sns.scatterplot(data=tips, x='total_bill', y='tip', 
                hue='time', palette=color_map)
```

### Combining Multiple Plots

```python
# Create subplots
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

sns.histplot(data=tips, x='total_bill', ax=axes[0, 0])
sns.boxplot(data=tips, x='day', y='total_bill', ax=axes[0, 1])
sns.scatterplot(data=tips, x='total_bill', y='tip', ax=axes[1, 0])
sns.violinplot(data=tips, x='day', y='total_bill', ax=axes[1, 1])

plt.tight_layout()
plt.show()
```

### Custom Aggregation

```python
# Custom aggregation function
def percentile_75(x):
    return np.percentile(x, 75)

sns.barplot(data=tips, x='day', y='total_bill', estimator=percentile_75)
```

### Adding Annotations

```python
# Annotate specific points
fig, ax = plt.subplots()
sns.scatterplot(data=tips, x='total_bill', y='tip', ax=ax)

# Find and annotate max tip
max_tip_idx = tips['tip'].idxmax()
max_tip_row = tips.loc[max_tip_idx]
ax.annotate('Highest tip', 
            xy=(max_tip_row['total_bill'], max_tip_row['tip']),
            xytext=(10, 10), textcoords='offset points',
            arrowprops=dict(arrowstyle='->', color='red'))
```

## Performance Optimization

### Sampling Large Datasets

```python
# Sample data for faster plotting
large_data = pd.DataFrame({
    'x': np.random.randn(100000),
    'y': np.random.randn(100000)
})

# Plot sample
sample = large_data.sample(n=10000)
sns.scatterplot(data=sample, x='x', y='y', alpha=0.3)
```

### Using Binning

```python
# Hexbin for large datasets
sns.jointplot(data=large_data, x='x', y='y', kind='hex')

# 2D histogram
sns.histplot(data=large_data, x='x', y='y', bins=50, cmap='Blues')
```

## Common Patterns

### Time Series Visualization

```python
# Create time series data
dates = pd.date_range('2025-01-01', periods=100, freq='D')
values = np.cumsum(np.random.randn(100))
ts_data = pd.DataFrame({'date': dates, 'value': values})

# Plot time series
plt.figure(figsize=(12, 6))
sns.lineplot(data=ts_data, x='date', y='value')
plt.xticks(rotation=45)
plt.title('Time Series Plot')
plt.tight_layout()
```

### Distribution Comparison

```python
# Compare multiple distributions
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

sns.violinplot(data=tips, x='day', y='total_bill', ax=axes[0])
axes[0].set_title('Violin Plot')

sns.boxplot(data=tips, x='day', y='total_bill', ax=axes[1])
axes[1].set_title('Box Plot')

plt.tight_layout()
```

### Correlation Analysis

```python
# Create correlation heatmap with significance
fig, ax = plt.subplots(figsize=(10, 8))
corr = tips.corr(numeric_only=True)
mask = np.triu(np.ones_like(corr, dtype=bool))
sns.heatmap(corr, mask=mask, annot=True, fmt='.2f', 
            cmap='coolwarm', center=0, square=True, ax=ax)
plt.title('Correlation Matrix')
```

## Best Practices

### Data Preparation

```python
# Clean data before plotting
tips_clean = tips.dropna()
tips_clean = tips_clean[tips_clean['total_bill'] > 0]

# Create meaningful categories
tips_clean['tip_percent'] = tips_clean['tip'] / tips_clean['total_bill'] * 100
```

### Choosing Plot Types

- **Distribution**: `histplot`, `kdeplot`, `boxplot`, `violinplot`
- **Categorical**: `barplot`, `countplot`, `pointplot`, `stripplot`
- **Relational**: `scatterplot`, `lineplot`
- **Regression**: `regplot`, `lmplot`
- **Matrix**: `heatmap`, `clustermap`

### Figure-level vs Axes-level Functions

Figure-level functions (`displot`, `catplot`, `relplot`, `lmplot`, `jointplot`, `pairplot`):

- Return `FacetGrid` object
- Create entire figure
- Support faceting with `col`, `row`
- Better for multi-plot layouts

Axes-level functions (`histplot`, `boxplot`, `scatterplot`, etc.):

- Work with matplotlib axes
- More flexible for custom layouts
- Can be combined in subplots
- Better integration with matplotlib

```python
# Figure-level
g = sns.displot(data=tips, x='total_bill', col='time')

# Axes-level
fig, ax = plt.subplots()
sns.histplot(data=tips, x='total_bill', ax=ax)
```

### Saving Plots

```python
# Save figure-level plot
g = sns.relplot(data=tips, x='total_bill', y='tip')
g.savefig('plot.png', dpi=300, bbox_inches='tight')

# Save axes-level plot
plt.figure(figsize=(10, 6))
sns.scatterplot(data=tips, x='total_bill', y='tip')
plt.savefig('plot.pdf', bbox_inches='tight')
```

## Troubleshooting

### Common Issues

**Issue**: Overlapping labels

```python
# Solution: Rotate labels
plt.xticks(rotation=45, ha='right')

# Or use smaller font
sns.set_context('paper')
```

**Issue**: Legend outside plot area

```python
# Solution: Adjust layout
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()
```

**Issue**: Colors not distinguishable

```python
# Solution: Use colorblind-friendly palette
sns.set_palette('colorblind')
```

**Issue**: Slow plotting with large datasets

```python
# Solution: Sample or use appropriate plot type
sample_data = large_data.sample(n=10000)
sns.scatterplot(data=sample_data, x='x', y='y')

# Or use hexbin/2D histogram
sns.jointplot(data=large_data, x='x', y='y', kind='hex')
```

## Integration with Other Libraries

### Matplotlib Integration

```python
# Combine seaborn and matplotlib
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

sns.boxplot(data=tips, x='day', y='total_bill', ax=axes[0])
axes[0].axhline(y=tips['total_bill'].mean(), color='r', linestyle='--')
axes[0].set_title('With Mean Line')

sns.violinplot(data=tips, x='day', y='total_bill', ax=axes[1])
axes[1].set_ylabel('Total Bill ($)')

plt.tight_layout()
```

### Pandas Integration

```python
# Plot directly from pandas
tips.plot(kind='scatter', x='total_bill', y='tip', alpha=0.5)

# With seaborn styling
sns.set_theme()
tips.plot(kind='scatter', x='total_bill', y='tip')
```

### SciPy Integration

```python
from scipy import stats

# Statistical tests with visualization
fig, ax = plt.subplots()
sns.regplot(data=tips, x='total_bill', y='tip', ax=ax)

# Add correlation
r, p = stats.pearsonr(tips['total_bill'], tips['tip'])
ax.text(0.05, 0.95, f'r={r:.3f}, p={p:.4f}', 
        transform=ax.transAxes, verticalalignment='top')
```

## Examples and Use Cases

### Publication-Quality Figure

```python
# Set publication style
sns.set_theme(style='white', context='paper', font_scale=1.2)

fig, ax = plt.subplots(figsize=(6, 4))
sns.scatterplot(data=tips, x='total_bill', y='tip', 
                hue='time', style='sex', s=100, alpha=0.7, ax=ax)

ax.set_xlabel('Total Bill ($)', fontweight='bold')
ax.set_ylabel('Tip ($)', fontweight='bold')
ax.set_title('Restaurant Tips Analysis', fontsize=14, fontweight='bold')
ax.legend(title='Category', title_fontsize=10)
sns.despine()

plt.tight_layout()
plt.savefig('publication_figure.pdf', dpi=300, bbox_inches='tight')
```

### Dashboard Layout

```python
# Create dashboard-style layout
fig = plt.figure(figsize=(16, 10))
gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)

# Summary statistics
ax1 = fig.add_subplot(gs[0, :])
summary_data = tips.groupby('day')['total_bill'].agg(['mean', 'std', 'count'])
ax1.axis('tight')
ax1.axis('off')
ax1.table(cellText=summary_data.values, colLabels=summary_data.columns,
          rowLabels=summary_data.index, loc='center')

# Distribution plots
ax2 = fig.add_subplot(gs[1, 0])
sns.histplot(data=tips, x='total_bill', kde=True, ax=ax2)
ax2.set_title('Bill Distribution')

ax3 = fig.add_subplot(gs[1, 1])
sns.boxplot(data=tips, x='day', y='total_bill', ax=ax3)
ax3.set_title('Bills by Day')

ax4 = fig.add_subplot(gs[1, 2])
sns.violinplot(data=tips, x='time', y='total_bill', ax=ax4)
ax4.set_title('Bills by Time')

# Relationship plots
ax5 = fig.add_subplot(gs[2, :2])
sns.scatterplot(data=tips, x='total_bill', y='tip', hue='time', size='size', ax=ax5)
ax5.set_title('Tips vs Bills')

ax6 = fig.add_subplot(gs[2, 2])
corr = tips[['total_bill', 'tip', 'size']].corr()
sns.heatmap(corr, annot=True, fmt='.2f', cmap='coolwarm', ax=ax6)
ax6.set_title('Correlations')

plt.suptitle('Restaurant Tips Dashboard', fontsize=16, fontweight='bold')
```

### Exploratory Data Analysis

```python
# Comprehensive EDA
def explore_dataset(df, target=None):
    """Comprehensive visualization of dataset"""
    
    # Numerical columns
    num_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    cat_cols = df.select_dtypes(include=['object', 'category']).columns.tolist()
    
    # Distribution of numerical variables
    if len(num_cols) > 0:
        fig, axes = plt.subplots(len(num_cols), 2, figsize=(12, 4*len(num_cols)))
        for i, col in enumerate(num_cols):
            if len(num_cols) == 1:
                ax1, ax2 = axes[0], axes[1]
            else:
                ax1, ax2 = axes[i, 0], axes[i, 1]
            
            sns.histplot(data=df, x=col, kde=True, ax=ax1)
            ax1.set_title(f'{col} Distribution')
            
            sns.boxplot(data=df, y=col, ax=ax2)
            ax2.set_title(f'{col} Box Plot')
        
        plt.tight_layout()
        plt.show()
    
    # Categorical distributions
    if len(cat_cols) > 0:
        fig, axes = plt.subplots(1, len(cat_cols), figsize=(5*len(cat_cols), 4))
        if len(cat_cols) == 1:
            axes = [axes]
        
        for i, col in enumerate(cat_cols):
            sns.countplot(data=df, x=col, ax=axes[i])
            axes[i].set_title(f'{col} Distribution')
            axes[i].tick_params(axis='x', rotation=45)
        
        plt.tight_layout()
        plt.show()
    
    # Correlation matrix
    if len(num_cols) > 1:
        plt.figure(figsize=(10, 8))
        sns.heatmap(df[num_cols].corr(), annot=True, fmt='.2f', 
                    cmap='coolwarm', center=0, square=True)
        plt.title('Correlation Matrix')
        plt.tight_layout()
        plt.show()
    
    # Pairplot if target specified
    if target and target in df.columns:
        sns.pairplot(df, hue=target, diag_kind='kde')
        plt.show()

# Use the function
explore_dataset(tips, target='time')
```

## Resources and Further Learning

### Official Documentation

- [Seaborn Documentation](<https://seaborn.pydata.org/>)
- [API Reference](<https://seaborn.pydata.org/api.html>)
- [Gallery of Examples](<https://seaborn.pydata.org/examples/index.html>)
- [Tutorial](<https://seaborn.pydata.org/tutorial.html>)

### Key Concepts

- Statistical graphics
- Data visualization
- Exploratory data analysis
- Publication-quality plots
- Color theory and palettes
- Figure composition

### Related Topics

- Matplotlib fundamentals
- Pandas data manipulation
- NumPy arrays
- Statistical analysis
- Data science workflow

## See Also

- [Matplotlib](matplotlib.md)
- [Pandas](pandas.md)
- [NumPy](numpy.md)
- [Data Visualization Best Practices](../best-practices/data-visualization.md)
- [Statistical Analysis](../data-science/statistical-analysis.md)
