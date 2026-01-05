---
title: Pandas - Python Data Analysis Library
description: Comprehensive guide to pandas, the powerful Python library for data manipulation and analysis
author: Joseph Streeter
date: 2026-01-04
keywords: pandas, python, data analysis, dataframe, series, data manipulation, data cleaning, data science
---

## Pandas - Python Data Analysis Library

Pandas is a fast, powerful, flexible, and easy-to-use open source data analysis and manipulation tool built on top of the Python programming language. It provides high-performance, easy-to-use data structures and data analysis tools that have become essential for data science workflows.

## Overview

Pandas is the de facto standard for working with structured data in Python. It offers:

- **Two primary data structures**: Series (1-dimensional) and DataFrame (2-dimensional)
- **Intuitive data manipulation**: Filter, transform, aggregate, and reshape data with ease
- **Flexible I/O**: Read and write data from CSV, Excel, SQL databases, JSON, and more
- **Time series functionality**: Robust date/time handling and analysis
- **Missing data handling**: Built-in methods for detecting and filling missing values
- **High performance**: Optimized operations written in Cython for speed

## Installation

Install pandas using pip:

```bash
pip install pandas
```

Or with conda:

```bash
conda install pandas
```

For optimal performance, install optional dependencies:

```bash
pip install pandas[performance]
```

## Core Data Structures

### Series

A Series is a one-dimensional labeled array that can hold any data type.

```python
import pandas as pd

# Create Series from list
s = pd.Series([10, 20, 30, 40], index=['a', 'b', 'c', 'd'])
print(s)

# Create Series from dictionary
data = {'a': 10, 'b': 20, 'c': 30}
s = pd.Series(data)

# Access elements
print(s['a'])  # 10
print(s.iloc[0])  # 10 (positional indexing)
```

### DataFrame

A DataFrame is a two-dimensional labeled data structure with columns that can be of different types.

```python
import pandas as pd

# Create DataFrame from dictionary
data = {
    'Name': ['Alice', 'Bob', 'Charlie', 'Diana'],
    'Age': [25, 30, 35, 28],
    'City': ['New York', 'London', 'Paris', 'Tokyo']
}
df = pd.DataFrame(data)

# Create DataFrame from list of dictionaries
records = [
    {'Name': 'Alice', 'Age': 25, 'City': 'New York'},
    {'Name': 'Bob', 'Age': 30, 'City': 'London'}
]
df = pd.DataFrame(records)

# Set custom index
df = pd.DataFrame(data, index=['person1', 'person2', 'person3', 'person4'])
```

## Data Loading and Saving

### Reading Data

Pandas supports multiple file formats:

```python
import pandas as pd

# Read CSV file
df = pd.read_csv('data.csv')

# Read CSV with custom options
df = pd.read_csv('data.csv', 
    sep=',', 
    header=0, 
    index_col=0,
    encoding='utf-8',
    na_values=['NA', 'missing']
)

# Read Excel file
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')

# Read JSON file
df = pd.read_json('data.json')

# Read from SQL database
import sqlite3
conn = sqlite3.connect('database.db')
df = pd.read_sql_query('SELECT * FROM table_name', conn)

# Read from clipboard
df = pd.read_clipboard()

# Read from URL
df = pd.read_csv('https://example.com/data.csv')
```

### Writing Data

Save DataFrames to various formats:

```python
# Write to CSV
df.to_csv('output.csv', index=False)

# Write to Excel
df.to_excel('output.xlsx', sheet_name='Data', index=False)

# Write to JSON
df.to_json('output.json', orient='records', indent=4)

# Write to SQL database
df.to_sql('table_name', conn, if_exists='replace', index=False)

# Write to HTML
df.to_html('output.html', index=False)

# Write to clipboard
df.to_clipboard(index=False)
```

## Data Inspection

### Basic Information

```python
# View first/last rows
df.head()  # First 5 rows
df.tail(10)  # Last 10 rows

# Get shape (rows, columns)
rows, cols = df.shape

# Get column names
df.columns

# Get data types
df.dtypes

# Get detailed information
df.info()

# Get summary statistics
df.describe()

# Get value counts for a column
df['City'].value_counts()

# Get unique values
df['City'].unique()

# Get number of unique values
df['City'].nunique()
```

## Data Selection and Filtering

### Column Selection

```python
# Select single column (returns Series)
ages = df['Age']

# Select multiple columns (returns DataFrame)
subset = df[['Name', 'Age']]

# Select columns by position
subset = df.iloc[:, 0:2]
```

### Row Selection

```python
# Select by label (loc)
row = df.loc['person1']
rows = df.loc['person1':'person3']

# Select by position (iloc)
row = df.iloc[0]
rows = df.iloc[0:3]

# Select specific rows and columns
subset = df.loc['person1':'person3', ['Name', 'Age']]
subset = df.iloc[0:3, 0:2]
```

### Boolean Filtering

```python
# Filter rows based on condition
young_people = df[df['Age'] < 30]

# Multiple conditions
result = df[(df['Age'] > 25) & (df['City'] == 'New York')]
result = df[(df['Age'] < 25) | (df['Age'] > 35)]

# Filter using isin()
cities = df[df['City'].isin(['New York', 'London'])]

# Filter using string methods
name_starts_with_a = df[df['Name'].str.startswith('A')]
name_contains = df[df['Name'].str.contains('li', case=False)]

# Filter using query()
result = df.query('Age > 25 and City == "New York"')
```

## Data Cleaning

### Handling Missing Data

```python
# Check for missing values
df.isnull()  # Returns Boolean DataFrame
df.isnull().sum()  # Count missing values per column

# Drop missing values
df.dropna()  # Drop rows with any missing values
df.dropna(axis=1)  # Drop columns with any missing values
df.dropna(thresh=2)  # Keep rows with at least 2 non-null values

# Fill missing values
df.fillna(0)  # Fill with constant
df.fillna(method='ffill')  # Forward fill
df.fillna(method='bfill')  # Backward fill
df['Age'].fillna(df['Age'].mean())  # Fill with mean

# Replace values
df.replace('NA', 0)
df.replace({'NA': 0, 'missing': 0})
```

### Data Type Conversion

```python
# Convert data types
df['Age'] = df['Age'].astype(int)
df['Date'] = pd.to_datetime(df['Date'])
df['Price'] = pd.to_numeric(df['Price'], errors='coerce')

# Convert to categorical
df['City'] = df['City'].astype('category')
```

### Removing Duplicates

```python
# Check for duplicates
df.duplicated()

# Remove duplicates
df.drop_duplicates()
df.drop_duplicates(subset=['Name'])  # Based on specific column
df.drop_duplicates(keep='last')  # Keep last occurrence
```

### String Operations

```python
# Convert to lowercase/uppercase
df['Name'] = df['Name'].str.lower()
df['Name'] = df['Name'].str.upper()

# Strip whitespace
df['Name'] = df['Name'].str.strip()

# Replace strings
df['City'] = df['City'].str.replace('New York', 'NYC')

# Extract patterns
df['Area_Code'] = df['Phone'].str.extract(r'(\d{3})')

# Split strings
df[['First', 'Last']] = df['Name'].str.split(' ', expand=True)
```

## Data Transformation

### Adding and Modifying Columns

```python
# Add new column
df['Age_Group'] = 'Adult'

# Calculate new column
df['Age_Squared'] = df['Age'] ** 2

# Apply function to column
df['Age_Category'] = df['Age'].apply(lambda x: 'Young' if x < 30 else 'Old')

# Apply function with multiple columns
df['Full_Info'] = df.apply(lambda row: f"{row['Name']} - {row['City']}", axis=1)

# Map values
mapping = {'New York': 'NY', 'London': 'LDN', 'Paris': 'PAR', 'Tokyo': 'TYO'}
df['City_Code'] = df['City'].map(mapping)
```

### Renaming

```python
# Rename columns
df.rename(columns={'Name': 'FullName', 'Age': 'Years'}, inplace=True)

# Rename using function
df.rename(columns=str.lower, inplace=True)

# Rename index
df.rename(index={'person1': 'p1', 'person2': 'p2'}, inplace=True)
```

### Sorting

```python
# Sort by column
df.sort_values('Age')
df.sort_values('Age', ascending=False)

# Sort by multiple columns
df.sort_values(['City', 'Age'], ascending=[True, False])

# Sort by index
df.sort_index()
```

### Reshaping

```python
# Pivot table
pivot = df.pivot_table(values='Age', index='City', columns='Name', aggfunc='mean')

# Melt (unpivot)
melted = pd.melt(df, id_vars=['Name'], value_vars=['Age', 'City'])

# Stack and unstack
stacked = df.stack()
unstacked = stacked.unstack()

# Transpose
df_transposed = df.T
```

## Aggregation and Grouping

### Basic Aggregation

```python
# Aggregate functions
df['Age'].sum()
df['Age'].mean()
df['Age'].median()
df['Age'].min()
df['Age'].max()
df['Age'].std()
df['Age'].var()
df['Age'].count()

# Multiple aggregations
df['Age'].agg(['sum', 'mean', 'std'])

# Aggregation on entire DataFrame
df.agg(['sum', 'mean'])
```

### GroupBy Operations

```python
# Group by single column
grouped = df.groupby('City')
grouped.mean()
grouped.sum()
grouped.count()

# Group by multiple columns
grouped = df.groupby(['City', 'Age_Group'])
grouped.mean()

# Apply multiple aggregation functions
result = df.groupby('City').agg({
    'Age': ['mean', 'min', 'max'],
    'Name': 'count'
})

# Custom aggregation function
def age_range(x):
    return x.max() - x.min()

df.groupby('City')['Age'].agg(age_range)

# Apply different functions to different columns
result = df.groupby('City').agg({
    'Age': 'mean',
    'Name': 'count'
})

# Filter groups
grouped = df.groupby('City')
result = grouped.filter(lambda x: x['Age'].mean() > 28)

# Transform (return same shape as input)
df['Age_Centered'] = df.groupby('City')['Age'].transform(lambda x: x - x.mean())
```

## Merging and Joining

### Concatenation

```python
# Concatenate vertically (stack rows)
result = pd.concat([df1, df2])

# Concatenate horizontally (stack columns)
result = pd.concat([df1, df2], axis=1)

# Concatenate with keys
result = pd.concat([df1, df2], keys=['first', 'second'])
```

### Merging (SQL-style joins)

```python
# Inner join (default)
result = pd.merge(df1, df2, on='key')

# Left join
result = pd.merge(df1, df2, on='key', how='left')

# Right join
result = pd.merge(df1, df2, on='key', how='right')

# Outer join
result = pd.merge(df1, df2, on='key', how='outer')

# Join on multiple columns
result = pd.merge(df1, df2, on=['key1', 'key2'])

# Join with different column names
result = pd.merge(df1, df2, left_on='key1', right_on='key2')

# Join on index
result = pd.merge(df1, df2, left_index=True, right_index=True)
```

### Join Method

```python
# Join using DataFrame.join() (index-based)
result = df1.join(df2)
result = df1.join(df2, how='left')
result = df1.join(df2, on='key')
```

## Time Series Analysis

### DateTime Operations

```python
# Convert to datetime
df['Date'] = pd.to_datetime(df['Date'])

# Extract components
df['Year'] = df['Date'].dt.year
df['Month'] = df['Date'].dt.month
df['Day'] = df['Date'].dt.day
df['DayOfWeek'] = df['Date'].dt.dayofweek
df['DayName'] = df['Date'].dt.day_name()

# Date arithmetic
df['Date_Plus_7'] = df['Date'] + pd.Timedelta(days=7)
df['Date_Diff'] = df['Date2'] - df['Date1']

# Set datetime index
df.set_index('Date', inplace=True)
```

### Resampling

```python
# Resample time series (requires datetime index)
df.resample('D').mean()  # Daily mean
df.resample('W').sum()  # Weekly sum
df.resample('M').last()  # Monthly last value
df.resample('Q').max()  # Quarterly maximum

# Downsampling with custom aggregation
df.resample('W').agg({'Sales': 'sum', 'Price': 'mean'})

# Upsampling with interpolation
df.resample('H').interpolate()
```

### Rolling Windows

```python
# Rolling mean
df['Rolling_Mean'] = df['Value'].rolling(window=7).mean()

# Rolling sum
df['Rolling_Sum'] = df['Value'].rolling(window=7).sum()

# Rolling with custom function
df['Rolling_Custom'] = df['Value'].rolling(window=7).apply(lambda x: x.max() - x.min())

# Expanding window (cumulative)
df['Cumulative_Mean'] = df['Value'].expanding().mean()
```

### Time-based Selection

```python
# Select date range
df.loc['2024-01-01':'2024-12-31']

# Select by year
df.loc['2024']

# Select by month
df.loc['2024-01']
```

## Advanced Operations

### Apply and Mapping

```python
# Apply function to each element
df['Age_Doubled'] = df['Age'].apply(lambda x: x * 2)

# Apply with custom function
def categorize_age(age):
    if age < 25:
        return 'Young'
    elif age < 35:
        return 'Middle'
    else:
        return 'Senior'

df['Category'] = df['Age'].apply(categorize_age)

# Apply to entire DataFrame
df.apply(lambda x: x.max() - x.min())

# Applymap (element-wise on DataFrame) - deprecated, use map
df.map(lambda x: x * 2)
```

### Window Functions

```python
# Cumulative operations
df['Cumulative_Sum'] = df['Value'].cumsum()
df['Cumulative_Max'] = df['Value'].cummax()
df['Cumulative_Min'] = df['Value'].cummin()

# Shift operations
df['Previous'] = df['Value'].shift(1)
df['Next'] = df['Value'].shift(-1)

# Percentage change
df['Pct_Change'] = df['Value'].pct_change()

# Rank
df['Rank'] = df['Value'].rank()
df['Rank_Dense'] = df['Value'].rank(method='dense')
```

### MultiIndex (Hierarchical Indexing)

```python
# Create MultiIndex
arrays = [
    ['A', 'A', 'B', 'B'],
    ['one', 'two', 'one', 'two']
]
index = pd.MultiIndex.from_arrays(arrays, names=['first', 'second'])
df = pd.DataFrame({'data': [1, 2, 3, 4]}, index=index)

# Select from MultiIndex
df.loc['A']
df.loc[('A', 'one')]
df.loc['A', 'one']

# Cross-section
df.xs('one', level='second')

# Stack and unstack
df.unstack()
df.stack()
```

### Categorical Data

```python
# Create categorical
df['Category'] = pd.Categorical(df['Category'], 
    categories=['Low', 'Medium', 'High'], 
    ordered=True
)

# Add categories
df['Category'] = df['Category'].cat.add_categories(['Very High'])

# Rename categories
df['Category'] = df['Category'].cat.rename_categories({
    'Low': 'L', 
    'Medium': 'M', 
    'High': 'H'
})

# Get categories
df['Category'].cat.categories
```

## Performance Optimization

### Memory Optimization

```python
# Check memory usage
df.memory_usage(deep=True)

# Optimize data types
df['Age'] = df['Age'].astype('int8')  # If values fit in range
df['Category'] = df['Category'].astype('category')

# Read large files in chunks
chunk_size = 10000
chunks = []
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    processed_chunk = chunk[chunk['Age'] > 25]
    chunks.append(processed_chunk)
result = pd.concat(chunks)
```

### Vectorization

```python
# Use vectorized operations instead of loops
# ❌ Avoid
for i in range(len(df)):
    df.loc[i, 'New_Column'] = df.loc[i, 'Age'] * 2

# ✅ Good
df['New_Column'] = df['Age'] * 2

# Use built-in methods
# ❌ Avoid
df['Age'].apply(lambda x: x ** 2)

# ✅ Good
df['Age'] ** 2
```

### Query Performance

```python
# Use query() for complex filters
result = df.query('Age > 25 and City == "New York"')

# Use eval() for column assignments
df.eval('Age_Doubled = Age * 2', inplace=True)

# Set index for faster lookups
df.set_index('Name', inplace=True)
result = df.loc['Alice']
```

## Common Patterns and Best Practices

### Method Chaining

```python
# Chain multiple operations
result = (df
    .query('Age > 25')
    .groupby('City')
    .agg({'Age': 'mean'})
    .reset_index()
    .sort_values('Age', ascending=False)
)
```

### Copy vs View

```python
# Create explicit copy
df_copy = df.copy()

# View (changes affect original)
view = df.loc[:, 'Age']  # May be a view
view[0] = 100  # May modify original df

# Use .copy() to avoid warnings
df_filtered = df[df['Age'] > 25].copy()
df_filtered['New_Column'] = 0  # Safe
```

### Avoiding SettingWithCopyWarning

```python
# ❌ Avoid chained assignment
df[df['Age'] > 25]['City'] = 'Unknown'

# ✅ Good - Use loc
df.loc[df['Age'] > 25, 'City'] = 'Unknown'
```

### Handling Large Datasets

```python
# Use appropriate data types
dtypes = {
    'id': 'int32',
    'category': 'category',
    'value': 'float32'
}
df = pd.read_csv('data.csv', dtype=dtypes)

# Use date parsing during read
df = pd.read_csv('data.csv', parse_dates=['date_column'])

# Use specific columns
df = pd.read_csv('data.csv', usecols=['col1', 'col2', 'col3'])
```

## Integration with Other Libraries

### NumPy Integration

```python
import numpy as np

# Convert to NumPy array
array = df.values
array = df['Age'].to_numpy()

# Create DataFrame from NumPy array
df = pd.DataFrame(np.random.randn(4, 3), columns=['A', 'B', 'C'])

# Use NumPy functions
df['Log_Age'] = np.log(df['Age'])
df['Sqrt_Age'] = np.sqrt(df['Age'])
```

### Matplotlib Integration

```python
import matplotlib.pyplot as plt

# Plot from DataFrame
df.plot(kind='line', x='Date', y='Value')
df['Age'].plot(kind='hist', bins=20)
df.plot(kind='scatter', x='Age', y='Salary')
df.plot(kind='box')
df.plot(kind='bar')

# Direct plotting
df.plot()
plt.show()
```

### Scikit-learn Integration

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Prepare data for machine learning
X = df[['Age', 'Salary']]
y = df['Target']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
df_scaled = pd.DataFrame(X_scaled, columns=X.columns)
```

## Common Errors and Solutions

### KeyError

```python
# Problem: Column doesn't exist
# df['NonExistent']

# Solution: Check if column exists
if 'Column' in df.columns:
    value = df['Column']

# Or use get() with default
value = df.get('Column', pd.Series([]))
```

### ValueError

```python
# Problem: Shape mismatch in assignment
# df['New'] = [1, 2]  # If df has 4 rows

# Solution: Ensure correct length
df['New'] = [1, 2, 3, 4]

# Or use scalar
df['New'] = 0
```

### MemoryError

```python
# Problem: File too large for memory

# Solution: Use chunking
chunks = []
for chunk in pd.read_csv('large_file.csv', chunksize=10000):
    # Process chunk
    processed = process_chunk(chunk)
    chunks.append(processed)
result = pd.concat(chunks)

# Or use Dask for larger-than-memory datasets
```

## Resources and Further Learning

### Official Documentation

- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [API Reference](https://pandas.pydata.org/docs/reference/index.html)
- [User Guide](https://pandas.pydata.org/docs/user_guide/index.html)

### Tutorials and Courses

- [10 Minutes to Pandas](https://pandas.pydata.org/docs/user_guide/10min.html)
- [Pandas Cookbook](https://pandas.pydata.org/docs/user_guide/cookbook.html)
- [Real Python Pandas Tutorials](https://realpython.com/learning-paths/pandas-data-science/)

### Books

- "Python for Data Analysis" by Wes McKinney (creator of Pandas)
- "Pandas in Action" by Boris Paskhaver
- "Effective Pandas" by Matt Harrison

### Community

- [Stack Overflow - Pandas Tag](https://stackoverflow.com/questions/tagged/pandas)
- [Pandas GitHub Repository](https://github.com/pandas-dev/pandas)
- [Pandas Discussions](https://github.com/pandas-dev/pandas/discussions)

## Related Topics

- [NumPy](./numpy.md) - Numerical computing foundation
- [Matplotlib](./matplotlib.md) - Data visualization
- [Scikit-learn](../machine-learning/scikit-learn.md) - Machine learning
- [Data Science](./index.md) - Data science overview
