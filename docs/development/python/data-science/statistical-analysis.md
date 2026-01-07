---
title: Statistical Analysis with Python
description: Comprehensive guide to statistical analysis in Python using NumPy, pandas, SciPy, and statsmodels for data exploration, hypothesis testing, and inference
---

Statistical analysis is a fundamental component of data science, providing tools and techniques to understand, interpret, and draw conclusions from data. Python's rich ecosystem of libraries makes it an excellent platform for statistical computing.

## Overview

Python offers comprehensive capabilities for statistical analysis, from basic descriptive statistics to advanced inferential methods and modeling. The primary libraries—NumPy, pandas, SciPy, and statsmodels—provide complementary tools that work seamlessly together for data analysis workflows.

This guide covers essential statistical concepts and their practical implementation in Python, suitable for both beginners learning statistical fundamentals and experienced analysts performing complex analyses.

## Key Concepts

### Descriptive Statistics

Descriptive statistics summarize and describe the characteristics of a dataset:

- **Central Tendency**: Mean, median, mode
- **Dispersion**: Variance, standard deviation, range, interquartile range
- **Shape**: Skewness, kurtosis
- **Position**: Percentiles, quartiles

### Inferential Statistics

Inferential statistics use sample data to make conclusions about populations:

- **Hypothesis Testing**: Testing claims about populations
- **Confidence Intervals**: Estimating population parameters
- **Regression Analysis**: Modeling relationships between variables
- **ANOVA**: Comparing means across groups

### Probability Distributions

Understanding data through probability distributions:

- **Normal (Gaussian)**: Bell curve, most common
- **Binomial**: Binary outcomes
- **Poisson**: Count data
- **Exponential**: Time between events
- **Chi-square, t, F**: Used in hypothesis tests

## Python Libraries for Statistics

### NumPy - Numerical Computing

[NumPy](numpy.md) provides fundamental statistical functions and array operations:

```python
import numpy as np

# Create data
data = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

# Basic statistics
mean = np.mean(data)
median = np.median(data)
std = np.std(data)
var = np.var(data)

# Percentiles
q25 = np.percentile(data, 25)
q75 = np.percentile(data, 75)

# Correlation
x = np.array([1, 2, 3, 4, 5])
y = np.array([2, 4, 5, 4, 5])
correlation = np.corrcoef(x, y)[0, 1]
```

### pandas - Data Analysis

[pandas](pandas.md) excels at descriptive statistics on structured data:

```python
import pandas as pd

# Create DataFrame
df = pd.DataFrame({
    'age': [25, 30, 35, 40, 45],
    'income': [30000, 45000, 55000, 60000, 70000],
    'satisfaction': [3, 4, 5, 4, 5]
})

# Descriptive statistics
summary = df.describe()
correlation = df.corr()

# Group statistics
grouped = df.groupby('satisfaction')['income'].mean()
```

### SciPy - Scientific Computing

SciPy provides comprehensive statistical functions and tests:

```python
from scipy import stats

# Probability distributions
normal_dist = stats.norm(loc=0, scale=1)
probabilities = normal_dist.pdf([0, 1, 2])

# Hypothesis tests
t_stat, p_value = stats.ttest_ind(group1, group2)

# Statistical tests
chi2, p = stats.chi2_contingency(contingency_table)
```

### statsmodels - Statistical Modeling

statsmodels offers advanced statistical models and tests:

```python
import statsmodels.api as sm
from statsmodels.formula.api import ols

# Linear regression
model = ols('y ~ x1 + x2', data=df).fit()
print(model.summary())

# Time series
from statsmodels.tsa.arima.model import ARIMA
model = ARIMA(data, order=(1, 1, 1)).fit()
```

## Working with Descriptive Statistics

### Central Tendency

Measures of the center of a distribution:

```python
import numpy as np
import pandas as pd
from scipy import stats

data = np.array([1, 2, 3, 4, 5, 5, 6, 7, 8, 9])

# Mean - average value
mean = np.mean(data)
# Or with pandas
mean = pd.Series(data).mean()

# Median - middle value
median = np.median(data)

# Mode - most frequent value
mode = stats.mode(data, keepdims=True)
```

### Dispersion

Measures of spread or variability:

```python
# Variance - average squared deviation from mean
variance = np.var(data, ddof=1)  # ddof=1 for sample variance

# Standard deviation - square root of variance
std_dev = np.std(data, ddof=1)

# Range - difference between max and min
data_range = np.ptp(data)  # peak to peak

# Interquartile range (IQR)
q75, q25 = np.percentile(data, [75, 25])
iqr = q75 - q25

# Coefficient of variation
cv = (std_dev / mean) * 100
```

### Shape

Measures of distribution shape:

```python
from scipy.stats import skew, kurtosis

# Skewness - asymmetry of distribution
# Positive: right-tailed, Negative: left-tailed, 0: symmetric
skewness = skew(data)

# Kurtosis - tailedness of distribution
# High: heavy tails, Low: light tails
kurt = kurtosis(data)
```

### Comprehensive Summary

```python
import pandas as pd

df = pd.DataFrame({'values': data})

# Complete descriptive statistics
summary = df.describe()
print(summary)

# Extended statistics
extended_stats = {
    'count': len(data),
    'mean': np.mean(data),
    'median': np.median(data),
    'mode': stats.mode(data, keepdims=True).mode[0],
    'std': np.std(data, ddof=1),
    'variance': np.var(data, ddof=1),
    'skewness': skew(data),
    'kurtosis': kurtosis(data),
    'min': np.min(data),
    'max': np.max(data),
    'range': np.ptp(data),
    'iqr': iqr
}

print(pd.Series(extended_stats))
```

## Understanding Probability Distributions

### Normal Distribution

The most common continuous distribution:

```python
from scipy.stats import norm
import matplotlib.pyplot as plt

# Create normal distribution (mean=0, std=1)
normal = norm(loc=0, scale=1)

# Probability density function (PDF)
x = np.linspace(-4, 4, 100)
pdf = normal.pdf(x)

# Cumulative distribution function (CDF)
cdf = normal.cdf(x)

# Percentiles (inverse CDF)
percentile_95 = normal.ppf(0.95)

# Random samples
samples = normal.rvs(size=1000)

# Plot
plt.figure(figsize=(12, 4))
plt.subplot(131)
plt.plot(x, pdf)
plt.title('PDF')
plt.subplot(132)
plt.plot(x, cdf)
plt.title('CDF')
plt.subplot(133)
plt.hist(samples, bins=30, density=True)
plt.title('Random Samples')
plt.tight_layout()
```

### Other Common Distributions

```python
from scipy.stats import binom, poisson, expon, chi2, t

# Binomial - number of successes in n trials
binomial = binom(n=10, p=0.5)
prob_5_successes = binomial.pmf(5)

# Poisson - count of events in interval
poisson_dist = poisson(mu=5)
prob_3_events = poisson_dist.pmf(3)

# Exponential - time between events
exponential = expon(scale=1/5)  # lambda = 5
prob = exponential.pdf(0.5)

# Chi-square - sum of squared normals
chi_square = chi2(df=5)
critical_value = chi_square.ppf(0.95)

# Student's t - small sample distribution
t_dist = t(df=10)
confidence_interval = t_dist.ppf([0.025, 0.975])
```

### Testing for Normality

```python
from scipy.stats import normaltest, shapiro, kstest

data = np.random.normal(0, 1, 100)

# D'Agostino-Pearson test
stat, p_value = normaltest(data)
print(f"Normality test p-value: {p_value}")

# Shapiro-Wilk test (better for small samples)
stat, p_value = shapiro(data)
print(f"Shapiro-Wilk p-value: {p_value}")

# Kolmogorov-Smirnov test
stat, p_value = kstest(data, 'norm')
print(f"KS test p-value: {p_value}")

# Interpretation: p > 0.05 suggests data is normally distributed
```

## Hypothesis Testing

### Understanding Hypothesis Tests

**Key Concepts**:

- **Null Hypothesis (H₀)**: Default assumption (no effect/difference)
- **Alternative Hypothesis (H₁)**: What we're testing for
- **p-value**: Probability of observing data if H₀ is true
- **Significance Level (α)**: Threshold (typically 0.05)
- **Decision**: Reject H₀ if p-value < α

### One-Sample t-test

Test if sample mean differs from a known value:

```python
from scipy.stats import ttest_1samp

# Sample data
data = np.array([23, 25, 27, 24, 26, 28, 25, 24, 26, 27])

# Test if mean equals 25
population_mean = 25
t_stat, p_value = ttest_1samp(data, population_mean)

print(f"t-statistic: {t_stat}")
print(f"p-value: {p_value}")

if p_value < 0.05:
    print("Reject null hypothesis: Mean is significantly different from 25")
else:
    print("Fail to reject null hypothesis: No significant difference")
```

### Two-Sample t-test

Compare means between two independent groups:

```python
from scipy.stats import ttest_ind

# Two groups
group1 = np.array([23, 25, 27, 24, 26])
group2 = np.array([30, 32, 31, 33, 29])

# Independent t-test
t_stat, p_value = ttest_ind(group1, group2)

print(f"t-statistic: {t_stat}")
print(f"p-value: {p_value}")

# Welch's t-test (unequal variances)
t_stat, p_value = ttest_ind(group1, group2, equal_var=False)
```

### Paired t-test

Compare means of paired observations:

```python
from scipy.stats import ttest_rel

# Before and after measurements
before = np.array([85, 88, 90, 92, 87])
after = np.array([88, 90, 93, 95, 89])

# Paired t-test
t_stat, p_value = ttest_rel(before, after)

print(f"t-statistic: {t_stat}")
print(f"p-value: {p_value}")
```

### Chi-Square Test

Test independence between categorical variables:

```python
from scipy.stats import chi2_contingency

# Contingency table
observed = np.array([
    [10, 20, 30],  # Category A
    [15, 25, 35]   # Category B
])

# Chi-square test
chi2, p_value, dof, expected = chi2_contingency(observed)

print(f"Chi-square statistic: {chi2}")
print(f"p-value: {p_value}")
print(f"Degrees of freedom: {dof}")
print(f"Expected frequencies:\n{expected}")
```

### ANOVA (Analysis of Variance)

Compare means across multiple groups:

```python
from scipy.stats import f_oneway

# Three groups
group1 = np.array([23, 25, 27, 24, 26])
group2 = np.array([30, 32, 31, 33, 29])
group3 = np.array([35, 37, 36, 38, 34])

# One-way ANOVA
f_stat, p_value = f_oneway(group1, group2, group3)

print(f"F-statistic: {f_stat}")
print(f"p-value: {p_value}")
```

### Non-Parametric Tests

When data doesn't meet assumptions for parametric tests:

```python
from scipy.stats import mannwhitneyu, wilcoxon, kruskal

# Mann-Whitney U test (alternative to independent t-test)
group1 = [23, 25, 27, 24, 26]
group2 = [30, 32, 31, 33, 29]
stat, p_value = mannwhitneyu(group1, group2)

# Wilcoxon signed-rank test (alternative to paired t-test)
before = [85, 88, 90, 92, 87]
after = [88, 90, 93, 95, 89]
stat, p_value = wilcoxon(before, after)

# Kruskal-Wallis test (alternative to ANOVA)
group1 = [23, 25, 27, 24, 26]
group2 = [30, 32, 31, 33, 29]
group3 = [35, 37, 36, 38, 34]
stat, p_value = kruskal(group1, group2, group3)
```

## Correlation and Association

### Correlation Coefficients

```python
from scipy.stats import pearsonr, spearmanr, kendalltau

x = np.array([1, 2, 3, 4, 5])
y = np.array([2, 4, 5, 4, 5])

# Pearson correlation (linear relationship)
r, p_value = pearsonr(x, y)
print(f"Pearson r: {r}, p-value: {p_value}")

# Spearman correlation (monotonic relationship, rank-based)
rho, p_value = spearmanr(x, y)
print(f"Spearman rho: {rho}, p-value: {p_value}")

# Kendall's tau (ordinal association)
tau, p_value = kendalltau(x, y)
print(f"Kendall tau: {tau}, p-value: {p_value}")
```

### Correlation Matrix

```python
import pandas as pd
import seaborn as sns

# DataFrame with multiple variables
df = pd.DataFrame({
    'age': [25, 30, 35, 40, 45, 50],
    'income': [30000, 45000, 55000, 60000, 70000, 80000],
    'satisfaction': [3, 4, 5, 4, 5, 5],
    'years_employed': [1, 3, 5, 8, 10, 15]
})

# Correlation matrix
corr_matrix = df.corr()
print(corr_matrix)

# Visualize with heatmap
plt.figure(figsize=(8, 6))
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', center=0)
plt.title('Correlation Matrix')
plt.show()
```

### Covariance

```python
# Covariance
cov_matrix = np.cov(df.T)
print(cov_matrix)

# With pandas
cov_matrix = df.cov()
print(cov_matrix)
```

## Confidence Intervals

### Confidence Interval for Mean

```python
from scipy import stats

def confidence_interval(data, confidence=0.95):
    n = len(data)
    mean = np.mean(data)
    se = stats.sem(data)  # Standard error
    margin = se * stats.t.ppf((1 + confidence) / 2, n - 1)
    return mean - margin, mean + margin

data = np.array([23, 25, 27, 24, 26, 28, 25, 24, 26, 27])
ci_lower, ci_upper = confidence_interval(data, 0.95)
print(f"95% CI: ({ci_lower:.2f}, {ci_upper:.2f})")
```

### Bootstrap Confidence Intervals

```python
from scipy.stats import bootstrap

def mean_function(data):
    return np.mean(data, axis=1)

data = np.array([23, 25, 27, 24, 26, 28, 25, 24, 26, 27])
result = bootstrap((data,), mean_function, confidence_level=0.95, n_resamples=10000)

print(f"Bootstrap 95% CI: ({result.confidence_interval.low:.2f}, {result.confidence_interval.high:.2f})")
```

## Linear Regression

### Simple Linear Regression with SciPy

```python
from scipy.stats import linregress

x = np.array([1, 2, 3, 4, 5])
y = np.array([2, 4, 5, 4, 5])

# Linear regression
slope, intercept, r_value, p_value, std_err = linregress(x, y)

print(f"Slope: {slope}")
print(f"Intercept: {intercept}")
print(f"R-squared: {r_value**2}")
print(f"p-value: {p_value}")

# Predictions
y_pred = slope * x + intercept
```

### Multiple Linear Regression with statsmodels

```python
import statsmodels.api as sm

# Create data
df = pd.DataFrame({
    'y': [10, 15, 20, 25, 30],
    'x1': [1, 2, 3, 4, 5],
    'x2': [2, 3, 4, 5, 6]
})

# Add constant term
X = sm.add_constant(df[['x1', 'x2']])
y = df['y']

# Fit model
model = sm.OLS(y, X).fit()

# Print summary
print(model.summary())

# Predictions
predictions = model.predict(X)

# Coefficients
print(f"Coefficients: {model.params}")
print(f"R-squared: {model.rsquared}")
print(f"Adjusted R-squared: {model.rsquared_adj}")
```

### Regression Diagnostics

```python
# Residuals
residuals = model.resid

# Plot residuals
plt.figure(figsize=(12, 4))

plt.subplot(131)
plt.scatter(predictions, residuals)
plt.axhline(y=0, color='r', linestyle='--')
plt.xlabel('Fitted values')
plt.ylabel('Residuals')
plt.title('Residuals vs Fitted')

plt.subplot(132)
stats.probplot(residuals, dist="norm", plot=plt)
plt.title('Q-Q Plot')

plt.subplot(133)
plt.hist(residuals, bins=10, edgecolor='black')
plt.xlabel('Residuals')
plt.ylabel('Frequency')
plt.title('Histogram of Residuals')

plt.tight_layout()
```

## Practical Workflows

### Complete EDA with Statistics

```python
import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns

def statistical_eda(df):
    """Comprehensive statistical exploration of dataset"""
    
    print("=" * 50)
    print("BASIC INFORMATION")
    print("=" * 50)
    print(f"Shape: {df.shape}")
    print(f"\nData types:\n{df.dtypes}")
    print(f"\nMissing values:\n{df.isnull().sum()}")
    
    print("\n" + "=" * 50)
    print("DESCRIPTIVE STATISTICS")
    print("=" * 50)
    print(df.describe())
    
    # Numeric columns only
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    
    print("\n" + "=" * 50)
    print("SKEWNESS AND KURTOSIS")
    print("=" * 50)
    for col in numeric_cols:
        skewness = stats.skew(df[col].dropna())
        kurt = stats.kurtosis(df[col].dropna())
        print(f"{col}: Skewness={skewness:.3f}, Kurtosis={kurt:.3f}")
    
    print("\n" + "=" * 50)
    print("CORRELATION MATRIX")
    print("=" * 50)
    corr = df[numeric_cols].corr()
    print(corr)
    
    # Visualizations
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    
    # Distributions
    axes[0, 0].set_title('Distributions')
    for col in numeric_cols:
        axes[0, 0].hist(df[col].dropna(), alpha=0.5, label=col)
    axes[0, 0].legend()
    
    # Box plots
    axes[0, 1].set_title('Box Plots')
    df[numeric_cols].boxplot(ax=axes[0, 1])
    
    # Correlation heatmap
    axes[1, 0].set_title('Correlation Heatmap')
    sns.heatmap(corr, annot=True, cmap='coolwarm', ax=axes[1, 0], center=0)
    
    # Pairwise relationships
    axes[1, 1].set_title('Scatter Matrix Sample')
    if len(numeric_cols) >= 2:
        axes[1, 1].scatter(df[numeric_cols[0]], df[numeric_cols[1]])
        axes[1, 1].set_xlabel(numeric_cols[0])
        axes[1, 1].set_ylabel(numeric_cols[1])
    
    plt.tight_layout()
    plt.show()
    
    return df.describe()

# Example usage
df = pd.DataFrame({
    'age': np.random.normal(35, 10, 100),
    'income': np.random.normal(50000, 15000, 100),
    'satisfaction': np.random.randint(1, 6, 100)
})

summary = statistical_eda(df)
```

### A/B Testing Workflow

```python
def ab_test(control, treatment, alpha=0.05):
    """
    Perform A/B test with comprehensive analysis
    """
    print("=" * 50)
    print("A/B TEST ANALYSIS")
    print("=" * 50)
    
    # Sample sizes
    n_control = len(control)
    n_treatment = len(treatment)
    print(f"\nSample sizes:")
    print(f"  Control: {n_control}")
    print(f"  Treatment: {n_treatment}")
    
    # Descriptive statistics
    print(f"\nControl group:")
    print(f"  Mean: {np.mean(control):.4f}")
    print(f"  Std: {np.std(control, ddof=1):.4f}")
    
    print(f"\nTreatment group:")
    print(f"  Mean: {np.mean(treatment):.4f}")
    print(f"  Std: {np.std(treatment, ddof=1):.4f}")
    
    # Effect size
    diff = np.mean(treatment) - np.mean(control)
    pooled_std = np.sqrt((np.var(control, ddof=1) + np.var(treatment, ddof=1)) / 2)
    cohens_d = diff / pooled_std
    
    print(f"\nEffect size:")
    print(f"  Difference: {diff:.4f}")
    print(f"  Cohen's d: {cohens_d:.4f}")
    
    # Check assumptions
    print("\n" + "=" * 50)
    print("ASSUMPTION CHECKS")
    print("=" * 50)
    
    # Normality
    _, p_control = stats.shapiro(control)
    _, p_treatment = stats.shapiro(treatment)
    print(f"Normality test (Shapiro-Wilk):")
    print(f"  Control p-value: {p_control:.4f}")
    print(f"  Treatment p-value: {p_treatment:.4f}")
    
    # Equal variances
    _, p_variance = stats.levene(control, treatment)
    print(f"\nEqual variance test (Levene):")
    print(f"  p-value: {p_variance:.4f}")
    
    # Choose appropriate test
    print("\n" + "=" * 50)
    print("HYPOTHESIS TEST")
    print("=" * 50)
    
    if p_control > 0.05 and p_treatment > 0.05:
        # Both normal - use t-test
        if p_variance > 0.05:
            t_stat, p_value = stats.ttest_ind(control, treatment)
            test_name = "Independent t-test (equal variance)"
        else:
            t_stat, p_value = stats.ttest_ind(control, treatment, equal_var=False)
            test_name = "Welch's t-test (unequal variance)"
    else:
        # Non-normal - use Mann-Whitney
        t_stat, p_value = stats.mannwhitneyu(control, treatment)
        test_name = "Mann-Whitney U test (non-parametric)"
    
    print(f"Test used: {test_name}")
    print(f"Test statistic: {t_stat:.4f}")
    print(f"p-value: {p_value:.4f}")
    
    # Conclusion
    print("\n" + "=" * 50)
    print("CONCLUSION")
    print("=" * 50)
    if p_value < alpha:
        print(f"✓ Significant difference detected (p < {alpha})")
        print(f"  Treatment {'increases' if diff > 0 else 'decreases'} outcome by {abs(diff):.4f}")
    else:
        print(f"✗ No significant difference detected (p >= {alpha})")
    
    # Confidence interval
    ci = stats.t.interval(
        1 - alpha,
        n_control + n_treatment - 2,
        loc=diff,
        scale=stats.sem(np.concatenate([control, treatment]))
    )
    print(f"\n{int((1-alpha)*100)}% Confidence interval for difference:")
    print(f"  ({ci[0]:.4f}, {ci[1]:.4f})")
    
    # Visualization
    plt.figure(figsize=(12, 4))
    
    plt.subplot(131)
    plt.boxplot([control, treatment], labels=['Control', 'Treatment'])
    plt.ylabel('Value')
    plt.title('Distribution Comparison')
    
    plt.subplot(132)
    plt.hist(control, alpha=0.5, label='Control', bins=20)
    plt.hist(treatment, alpha=0.5, label='Treatment', bins=20)
    plt.xlabel('Value')
    plt.ylabel('Frequency')
    plt.legend()
    plt.title('Overlapping Distributions')
    
    plt.subplot(133)
    means = [np.mean(control), np.mean(treatment)]
    errors = [stats.sem(control), stats.sem(treatment)]
    plt.bar(['Control', 'Treatment'], means, yerr=errors, capsize=5)
    plt.ylabel('Mean')
    plt.title('Mean with Error Bars')
    
    plt.tight_layout()
    plt.show()
    
    return {
        'test_name': test_name,
        'statistic': t_stat,
        'p_value': p_value,
        'effect_size': cohens_d,
        'difference': diff,
        'significant': p_value < alpha
    }

# Example usage
np.random.seed(42)
control = np.random.normal(100, 15, 100)
treatment = np.random.normal(105, 15, 100)

results = ab_test(control, treatment)
```

## Best Practices

### Statistical Analysis Workflow

1. **Explore Data**
   - Check distributions
   - Identify outliers
   - Examine missing values
   - Calculate descriptive statistics

2. **Check Assumptions**
   - Normality (Shapiro-Wilk, Q-Q plot)
   - Homogeneity of variance (Levene's test)
   - Independence of observations
   - Sample size adequacy

3. **Choose Appropriate Test**
   - Parametric vs non-parametric
   - Paired vs independent
   - One-tailed vs two-tailed

4. **Perform Analysis**
   - Calculate test statistic
   - Compute p-value
   - Estimate effect size
   - Calculate confidence intervals

5. **Interpret Results**
   - Statistical significance
   - Practical significance
   - Consider context
   - Report findings properly

### Common Pitfalls to Avoid

❌ **Don't**:

- P-hack by trying multiple tests until significance is found
- Ignore assumption violations
- Confuse correlation with causation
- Rely solely on p-values without effect sizes
- Use parametric tests on non-normal data without justification
- Forget to correct for multiple comparisons
- Ignore sample size considerations

✅ **Do**:

- Pre-register analysis plans
- Check and report assumption tests
- Report effect sizes and confidence intervals
- Use appropriate corrections (Bonferroni, Holm, etc.)
- Consider power analysis
- Visualize data and results
- Provide complete reporting

### Statistical Reporting

```python
def report_results(test_name, statistic, p_value, effect_size=None, ci=None):
    """
    Generate standardized statistical report
    """
    report = f"{test_name}: "
    report += f"statistic = {statistic:.3f}, "
    report += f"p = {p_value:.4f}"
    
    if p_value < 0.001:
        report += " ***"
    elif p_value < 0.01:
        report += " **"
    elif p_value < 0.05:
        report += " *"
    
    if effect_size is not None:
        report += f", Cohen's d = {effect_size:.3f}"
    
    if ci is not None:
        report += f", 95% CI [{ci[0]:.3f}, {ci[1]:.3f}]"
    
    return report

# Example
print(report_results("Independent t-test", -2.456, 0.023, effect_size=0.54, ci=(-3.2, -0.5)))
```

## Advanced Topics

### Power Analysis

```python
from statsmodels.stats.power import ttest_power, tt_ind_solve_power

# Calculate required sample size
effect_size = 0.5  # Cohen's d
alpha = 0.05
power = 0.80

n = tt_ind_solve_power(effect_size=effect_size, alpha=alpha, power=power)
print(f"Required sample size per group: {n:.0f}")

# Calculate achieved power
n_per_group = 50
achieved_power = ttest_power(effect_size, n_per_group, alpha)
print(f"Achieved power: {achieved_power:.3f}")
```

### Multiple Comparison Corrections

```python
from statsmodels.stats.multitest import multipletests

# Multiple p-values from multiple tests
p_values = [0.01, 0.04, 0.03, 0.08, 0.001]

# Bonferroni correction
reject, corrected_p, _, _ = multipletests(p_values, method='bonferroni')
print(f"Bonferroni corrected: {corrected_p}")

# Benjamini-Hochberg (FDR)
reject, corrected_p, _, _ = multipletests(p_values, method='fdr_bh')
print(f"FDR corrected: {corrected_p}")
```

### Survival Analysis

```python
from lifelines import KaplanMeierFitter
from lifelines.statistics import logrank_test

# Time to event data
durations = [5, 6, 6, 2.5, 4, 4, 7, 8, 8, 9]
event_observed = [1, 1, 1, 1, 1, 0, 1, 0, 0, 0]

# Fit Kaplan-Meier
kmf = KaplanMeierFitter()
kmf.fit(durations, event_observed)

# Plot survival function
kmf.plot_survival_function()
plt.title('Kaplan-Meier Survival Curve')
plt.show()

# Median survival time
print(f"Median survival time: {kmf.median_survival_time_}")
```

## Tools and Resources

### Recommended Libraries

```bash
# Core statistical libraries
pip install numpy pandas scipy statsmodels

# Visualization
pip install matplotlib seaborn plotly

# Advanced statistics
pip install scikit-learn lifelines pingouin

# Interactive analysis
pip install jupyter ipython
```

### Useful References

- **scipy.stats**: Complete statistical functions
- **statsmodels**: Econometric and statistical models
- **pingouin**: User-friendly statistical tests
- **scikit-learn**: Machine learning with statistical methods

## See Also

- [NumPy for Data Science](numpy.md)
- [pandas for Data Analysis](pandas.md)
- [matplotlib for Visualization](matplotlib.md)
- [seaborn for Statistical Visualization](seaborn.md)
- [Data Science Overview](index.md)

## Additional Resources

### Documentation

- [SciPy Stats Documentation](https://docs.scipy.org/doc/scipy/reference/stats.html)
- [statsmodels Documentation](https://www.statsmodels.org/)
- [NumPy Statistics](https://numpy.org/doc/stable/reference/routines.statistics.html)
- [pandas Statistical Methods](https://pandas.pydata.org/docs/user_guide/computation.html)

### Learning Resources

- [Statistics in Python Tutorial](https://scipy-lectures.org/packages/statistics/index.html)
- [Think Stats (Free Book)](https://greenteapress.com/thinkstats2/)
- [Statistical Thinking for Data Science](https://www.coursera.org/learn/statistical-thinking)

### Community

- [Stack Overflow - Statistics Tag](https://stackoverflow.com/questions/tagged/statistics+python)
- [Cross Validated (Stats Stack Exchange)](https://stats.stackexchange.com/)
- [r/statistics on Reddit](https://www.reddit.com/r/statistics/)
