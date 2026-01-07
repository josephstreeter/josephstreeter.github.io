---
title: Data Processing with Python
description: Techniques for cleaning, transforming, and processing data in Python
author: Joseph Streeter
date: 2026-01-04
tags: [python, data-processing, etl, pandas, data-cleaning]
---

## Overview

Data processing involves cleaning, transforming, and preparing data for analysis. This guide covers essential techniques using Python libraries.

## Data Cleaning

### Handling Missing Values

```python
import pandas as pd
import numpy as np

df = pd.read_csv('data.csv')

# Check for missing values
print(df.isnull().sum())

# Drop rows with missing values
df_clean = df.dropna()

# Fill missing values
df['column'] = df['column'].fillna(df['column'].mean())

# Forward fill
df['column'] = df['column'].ffill()
```

### Removing Duplicates

```python
# Check for duplicates
print(df.duplicated().sum())

# Remove duplicates
df_unique = df.drop_duplicates()

# Remove duplicates based on specific columns
df_unique = df.drop_duplicates(subset=['id'])
```

### Data Type Conversion

```python
# Convert data types
df['date'] = pd.to_datetime(df['date'])
df['price'] = pd.to_numeric(df['price'], errors='coerce')
df['category'] = df['category'].astype('category')
```

## Data Transformation

### String Operations

```python
# String cleaning
df['name'] = df['name'].str.strip()
df['name'] = df['name'].str.lower()
df['name'] = df['name'].str.replace('[^a-zA-Z]', '', regex=True)

# Split strings
df[['first_name', 'last_name']] = df['full_name'].str.split(' ', expand=True)
```

### Numerical Transformations

```python
# Normalization (Min-Max scaling)
from sklearn.preprocessing import MinMaxScaler

scaler = MinMaxScaler()
df['normalized'] = scaler.fit_transform(df[['value']])

# Standardization (Z-score)
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
df['standardized'] = scaler.fit_transform(df[['value']])

# Log transformation
df['log_value'] = np.log1p(df['value'])
```

### Feature Engineering

```python
# Create new features
df['total'] = df['quantity'] * df['price']
df['year'] = df['date'].dt.year
df['month'] = df['date'].dt.month
df['day_of_week'] = df['date'].dt.dayofweek

# Binning
df['age_group'] = pd.cut(df['age'], bins=[0, 18, 35, 60, 100], labels=['Child', 'Young Adult', 'Adult', 'Senior'])
```

## Data Aggregation

### Grouping and Aggregating

```python
# Group by and aggregate
summary = df.groupby('category').agg({
    'sales': ['sum', 'mean', 'count'],
    'profit': 'sum'
})

# Pivot tables
pivot = df.pivot_table(
    values='sales',
    index='region',
    columns='product',
    aggfunc='sum',
    fill_value=0
)
```

### Merging and Joining

```python
# Merge dataframes
merged = pd.merge(df1, df2, on='id', how='left')

# Concatenate
combined = pd.concat([df1, df2], axis=0, ignore_index=True)
```

## Performance Optimization

### Efficient Data Types

```python
# Use categorical for low-cardinality string columns
df['category'] = df['category'].astype('category')

# Use smaller numeric types
df['small_int'] = df['large_int'].astype('int32')
```

### Chunking Large Files

```python
# Process large files in chunks
chunk_size = 10000
chunks = []

for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    processed_chunk = process_data(chunk)
    chunks.append(processed_chunk)

df = pd.concat(chunks, ignore_index=True)
```

### Vectorization

```python
# Use vectorized operations instead of loops
# ❌ Slow
for i in range(len(df)):
    df.loc[i, 'result'] = df.loc[i, 'a'] * df.loc[i, 'b']

# ✅ Fast
df['result'] = df['a'] * df['b']
```

## Data Validation

### Schema Validation

```python
from pandera import Column, DataFrameSchema, Check

schema = DataFrameSchema({
    'user_id': Column(int, Check.greater_than(0)),
    'email': Column(str, Check.str_matches(r'^\S+@\S+\.\S+$')),
    'age': Column(int, Check.in_range(0, 120)),
})

# Validate dataframe
validated_df = schema.validate(df)
```

### Quality Checks

```python
def validate_data_quality(df):
    """Perform data quality checks."""
    issues = []
    
    # Check for missing values
    missing = df.isnull().sum()
    if missing.any():
        issues.append(f"Missing values found: {missing[missing > 0].to_dict()}")
    
    # Check for duplicates
    duplicates = df.duplicated().sum()
    if duplicates > 0:
        issues.append(f"Found {duplicates} duplicate rows")
    
    # Check for outliers
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    for col in numeric_cols:
        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)
        iqr = q3 - q1
        outliers = ((df[col] < (q1 - 1.5 * iqr)) | (df[col] > (q3 + 1.5 * iqr))).sum()
        if outliers > 0:
            issues.append(f"Found {outliers} outliers in {col}")
    
    return issues
```

## Best Practices

- Always validate input data
- Document transformation logic
- Create reproducible pipelines
- Handle errors gracefully
- Profile performance for large datasets
- Version control data processing scripts
- Test with sample data before full processing

## See Also

- [Pandas](../python/data-science/pandas.md)
- [NumPy](../python/data-science/numpy.md)
- [Testing](../python/testing/index.md)
