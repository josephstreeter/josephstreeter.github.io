---
title: Scikit-learn - Machine Learning in Python
description: Comprehensive guide to scikit-learn, the essential Python library for machine learning featuring supervised and unsupervised algorithms, model evaluation, and preprocessing tools
---

Scikit-learn is the most widely-used machine learning library for Python, providing simple and efficient tools for predictive data analysis. Built on NumPy, SciPy, and matplotlib, it offers a consistent API for dozens of machine learning algorithms, making it the go-to choice for practitioners and researchers alike.

## Overview

Scikit-learn (sklearn) has established itself as the standard machine learning library in the Python ecosystem since its initial release in 2007. Developed by a vibrant community and maintained under the BSD license, it emphasizes ease of use, performance, and documentation quality.

The library excels at providing:

- **Unified API**: Consistent interface across all algorithms with fit/predict/transform methods
- **Production-ready algorithms**: Battle-tested implementations of classical machine learning methods
- **Comprehensive tooling**: Complete workflows from preprocessing to model evaluation
- **Educational resources**: Extensive documentation with theory and practical examples
- **Interoperability**: Seamless integration with pandas, NumPy, and the broader scientific Python stack

Scikit-learn deliberately focuses on traditional machine learning algorithms rather than deep learning (use PyTorch or TensorFlow for that), making it ideal for structured/tabular data, feature engineering, and scenarios where interpretability matters.

## Key Features

### Supervised Learning

- **Classification**: Identify which category an object belongs to
  - Support Vector Machines (SVM)
  - Nearest Neighbors
  - Random Forest
  - Logistic Regression
  - Naive Bayes
  - Decision Trees
  - Ensemble methods (AdaBoost, Gradient Boosting, Voting)

- **Regression**: Predict continuous values
  - Linear Regression
  - Ridge, Lasso, Elastic Net
  - Support Vector Regression (SVR)
  - Decision Trees and Random Forest
  - Gradient Boosting Regressors

### Unsupervised Learning

- **Clustering**: Automatic grouping of similar objects
  - K-Means
  - DBSCAN
  - Hierarchical clustering
  - Gaussian Mixture Models
  - Spectral clustering

- **Dimensionality Reduction**: Reduce number of features
  - Principal Component Analysis (PCA)
  - t-SNE
  - Truncated SVD
  - Non-negative Matrix Factorization (NMF)

- **Anomaly Detection**: Identify unusual data points
  - Isolation Forest
  - One-Class SVM
  - Local Outlier Factor

### Model Selection & Evaluation

- **Cross-validation**: Train/test splitting strategies
- **Grid search**: Hyperparameter tuning
- **Metrics**: Accuracy, precision, recall, F1, ROC-AUC, MSE, R²
- **Validation curves**: Model complexity analysis
- **Learning curves**: Training set size impact

### Data Preprocessing

- **Feature scaling**: StandardScaler, MinMaxScaler, RobustScaler
- **Encoding**: LabelEncoder, OneHotEncoder, OrdinalEncoder
- **Imputation**: Handle missing values
- **Feature extraction**: Text (TF-IDF, CountVectorizer), Images
- **Feature selection**: Remove irrelevant features

### Pipeline & Workflow

- **Pipeline**: Chain preprocessing and modeling steps
- **ColumnTransformer**: Apply different preprocessing to different columns
- **FeatureUnion**: Combine multiple feature extraction methods
- **Make_pipeline**: Simplified pipeline creation

## Installation

### Using pip

```bash
# Latest stable version
pip install scikit-learn

# Specific version
pip install scikit-learn==1.4.0

# With plotting capabilities
pip install scikit-learn matplotlib
```

### Using conda

```bash
# Install from conda-forge
conda install -c conda-forge scikit-learn

# Create new environment with scikit-learn
conda create -n ml-env python=3.11 scikit-learn pandas matplotlib jupyter
conda activate ml-env
```

### Using UV (Fastest)

```bash
# Install with UV
uv pip install scikit-learn

# Install with common data science stack
uv pip install scikit-learn pandas numpy matplotlib seaborn jupyter
```

### From Source

```bash
# For development or latest features
git clone https://github.com/scikit-learn/scikit-learn.git
cd scikit-learn
pip install -e .
```

### Verify Installation

```python
import sklearn
print(sklearn.__version__)

# Run built-in tests
sklearn.show_versions()
```

### Dependencies

Scikit-learn requires:

- **Python**: 3.8 or newer
- **NumPy**: ≥1.19.5
- **SciPy**: ≥1.6.0
- **Joblib**: ≥1.1.1
- **Threadpoolctl**: ≥2.0.0

Optional dependencies:

- **matplotlib**: ≥3.1.3 (plotting)
- **pandas**: ≥1.0.5 (DataFrame support)
- **scikit-image**: ≥0.16.2 (image preprocessing)

## Basic Usage

### The Scikit-learn API Pattern

All estimators in scikit-learn follow a consistent API:

```python
from sklearn.some_module import SomeEstimator

# 1. Initialize estimator with hyperparameters
estimator = SomeEstimator(parameter1=value1, parameter2=value2)

# 2. Fit to training data
estimator.fit(X_train, y_train)

# 3. Make predictions
predictions = estimator.predict(X_test)

# 4. Evaluate (for supervised learning)
score = estimator.score(X_test, y_test)
```

### Classification Example

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix

# Load dataset
iris = load_iris()
X, y = iris.data, iris.target

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train model
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train_scaled, y_train)

# Make predictions
y_pred = clf.predict(X_test_scaled)

# Evaluate
print(f"Accuracy: {clf.score(X_test_scaled, y_test):.3f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=iris.target_names))
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

# Feature importance
for feature, importance in zip(iris.feature_names, clf.feature_importances_):
    print(f"{feature}: {importance:.3f}")
```

### Regression Example

```python
from sklearn.datasets import fetch_california_housing
from sklearn.model_selection import train_test_split
from sklearn.linear_model import Ridge
from sklearn.metrics import mean_squared_error, r2_score
import numpy as np

# Load dataset
housing = fetch_california_housing()
X, y = housing.data, housing.target

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Train model
model = Ridge(alpha=1.0)
model.fit(X_train, y_train)

# Make predictions
y_pred = model.predict(X_test)

# Evaluate
mse = mean_squared_error(y_test, y_pred)
rmse = np.sqrt(mse)
r2 = r2_score(y_test, y_pred)

print(f"RMSE: {rmse:.3f}")
print(f"R² Score: {r2:.3f}")

# Feature coefficients
for feature, coef in zip(housing.feature_names, model.coef_):
    print(f"{feature}: {coef:.3f}")
```

### Clustering Example

```python
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import matplotlib.pyplot as plt

# Generate sample data
X, y_true = make_blobs(n_samples=300, centers=4, random_state=42)

# Train clustering model
kmeans = KMeans(n_clusters=4, random_state=42)
y_pred = kmeans.fit_predict(X)

# Evaluate
silhouette = silhouette_score(X, y_pred)
print(f"Silhouette Score: {silhouette:.3f}")

# Visualize
plt.figure(figsize=(10, 4))

plt.subplot(1, 2, 1)
plt.scatter(X[:, 0], X[:, 1], c=y_true, cmap='viridis')
plt.title('True Labels')

plt.subplot(1, 2, 2)
plt.scatter(X[:, 0], X[:, 1], c=y_pred, cmap='viridis')
plt.scatter(kmeans.cluster_centers_[:, 0], kmeans.cluster_centers_[:, 1], 
            marker='X', s=200, c='red', edgecolors='black', label='Centroids')
plt.title('K-Means Clustering')
plt.legend()
plt.tight_layout()
plt.show()
```

### Working with Pandas DataFrames

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier

# Load data
df = pd.read_csv('data.csv')

# Separate features and target
X = df.drop('target', axis=1)
y = df['target']

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Train model (works directly with DataFrames)
model = GradientBoostingClassifier()
model.fit(X_train, y_train)

# Get feature importance as DataFrame
feature_importance = pd.DataFrame({
    'feature': X.columns,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

print(feature_importance)
```

## Preprocessing and Feature Engineering

### Feature Scaling

```python
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler

# StandardScaler: Mean=0, Std=1 (assumes normal distribution)
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_train)

# MinMaxScaler: Scale to [0, 1] range
scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X_train)

# RobustScaler: Use median and IQR (robust to outliers)
scaler = RobustScaler()
X_scaled = scaler.fit_transform(X_train)

# Always fit on training data, transform both train and test
scaler.fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)
```

### Encoding Categorical Variables

```python
from sklearn.preprocessing import LabelEncoder, OneHotEncoder, OrdinalEncoder
import pandas as pd

# Example data
df = pd.DataFrame({
    'color': ['red', 'blue', 'green', 'red', 'blue'],
    'size': ['small', 'medium', 'large', 'medium', 'small'],
    'quality': ['good', 'excellent', 'poor', 'good', 'excellent']
})

# LabelEncoder: For target variable (single column)
le = LabelEncoder()
df['color_encoded'] = le.fit_transform(df['color'])

# OneHotEncoder: For nominal features (no order)
ohe = OneHotEncoder(sparse_output=False)
color_encoded = ohe.fit_transform(df[['color']])
color_df = pd.DataFrame(
    color_encoded, 
    columns=ohe.get_feature_names_out(['color'])
)

# OrdinalEncoder: For ordinal features (with order)
oe = OrdinalEncoder(categories=[['poor', 'good', 'excellent']])
df['quality_encoded'] = oe.fit_transform(df[['quality']])

# Using pandas get_dummies (alternative)
df_encoded = pd.get_dummies(df, columns=['color', 'size'], drop_first=True)
```

### Handling Missing Values

```python
from sklearn.impute import SimpleImputer, KNNImputer
import numpy as np

# Create data with missing values
X = np.array([[1, 2], [np.nan, 3], [7, 6], [5, np.nan]])

# SimpleImputer: Fill with mean, median, or most frequent
imputer = SimpleImputer(strategy='mean')
X_imputed = imputer.fit_transform(X)

# Different strategies
imputer_median = SimpleImputer(strategy='median')
imputer_most_frequent = SimpleImputer(strategy='most_frequent')
imputer_constant = SimpleImputer(strategy='constant', fill_value=0)

# KNNImputer: Use k-nearest neighbors
knn_imputer = KNNImputer(n_neighbors=2)
X_imputed = knn_imputer.fit_transform(X)
```

### Feature Selection

```python
from sklearn.feature_selection import (
    SelectKBest, f_classif, RFE, SelectFromModel
)
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import Lasso

# SelectKBest: Select top k features using statistical tests
selector = SelectKBest(score_func=f_classif, k=10)
X_selected = selector.fit_transform(X, y)
selected_features = X.columns[selector.get_support()]

# Recursive Feature Elimination (RFE)
estimator = RandomForestClassifier(n_estimators=100)
rfe = RFE(estimator=estimator, n_features_to_select=10)
X_selected = rfe.fit_transform(X, y)
selected_features = X.columns[rfe.get_support()]

# SelectFromModel: Use model-based feature importance
clf = RandomForestClassifier(n_estimators=100)
clf.fit(X, y)
selector = SelectFromModel(clf, prefit=True, threshold='median')
X_selected = selector.transform(X)

# L1-based feature selection (Lasso)
lasso = Lasso(alpha=0.1)
selector = SelectFromModel(lasso)
X_selected = selector.fit_transform(X, y)
```

### Polynomial Features

```python
from sklearn.preprocessing import PolynomialFeatures

# Create polynomial and interaction features
poly = PolynomialFeatures(degree=2, include_bias=False)
X_poly = poly.fit_transform(X)

# Example: [a, b] becomes [a, b, a^2, ab, b^2]
X = np.array([[2, 3]])
poly = PolynomialFeatures(degree=2)
print(poly.fit_transform(X))
# Output: [[1, 2, 3, 4, 6, 9]]  # [1, a, b, a^2, ab, b^2]
```

### Text Feature Extraction

```python
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer

documents = [
    'This is the first document',
    'This document is the second document',
    'And this is the third one',
]

# CountVectorizer: Word counts
vectorizer = CountVectorizer()
X = vectorizer.fit_transform(documents)
print(vectorizer.get_feature_names_out())

# TfidfVectorizer: Term Frequency-Inverse Document Frequency
tfidf = TfidfVectorizer(max_features=100, stop_words='english')
X_tfidf = tfidf.fit_transform(documents)

# Parameters
tfidf = TfidfVectorizer(
    max_features=1000,      # Top 1000 features
    min_df=2,               # Ignore terms in fewer than 2 docs
    max_df=0.8,             # Ignore terms in more than 80% of docs
    ngram_range=(1, 2),     # Unigrams and bigrams
    stop_words='english'    # Remove English stop words
)
```

### Custom Transformers

```python
from sklearn.base import BaseEstimator, TransformerMixin

class LogTransformer(BaseEstimator, TransformerMixin):
    """Apply log transformation to features"""
    
    def __init__(self, offset=1):
        self.offset = offset
    
    def fit(self, X, y=None):
        return self
    
    def transform(self, X):
        return np.log(X + self.offset)

# Use in pipeline
from sklearn.pipeline import Pipeline

pipeline = Pipeline([
    ('log', LogTransformer()),
    ('scaler', StandardScaler()),
    ('classifier', RandomForestClassifier())
])
```

## Model Selection and Evaluation

### Train-Test Split

```python
from sklearn.model_selection import train_test_split

# Basic split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Stratified split (preserve class distribution)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)

# Three-way split (train/validation/test)
X_train, X_temp, y_train, y_temp = train_test_split(
    X, y, test_size=0.3, random_state=42
)
X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp, test_size=0.5, random_state=42
)
```

### Cross-Validation

```python
from sklearn.model_selection import (
    cross_val_score, cross_validate, KFold, StratifiedKFold
)

# Simple cross-validation
scores = cross_val_score(model, X, y, cv=5)
print(f"Accuracy: {scores.mean():.3f} (+/- {scores.std():.3f})")

# Multiple metrics
scoring = ['accuracy', 'precision', 'recall', 'f1']
scores = cross_validate(model, X, y, cv=5, scoring=scoring)
print(f"Accuracy: {scores['test_accuracy'].mean():.3f}")
print(f"F1 Score: {scores['test_f1'].mean():.3f}")

# Custom cross-validation strategy
kfold = KFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=kfold)

# Stratified K-Fold (preserves class distribution)
skfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=skfold)

# Leave-One-Out Cross-Validation
from sklearn.model_selection import LeaveOneOut
loo = LeaveOneOut()
scores = cross_val_score(model, X, y, cv=loo)
```

### Hyperparameter Tuning

```python
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV
from sklearn.ensemble import RandomForestClassifier
from scipy.stats import randint, uniform

# Grid Search: Exhaustive search
param_grid = {
    'n_estimators': [50, 100, 200],
    'max_depth': [None, 10, 20, 30],
    'min_samples_split': [2, 5, 10],
    'min_samples_leaf': [1, 2, 4]
}

grid_search = GridSearchCV(
    RandomForestClassifier(random_state=42),
    param_grid,
    cv=5,
    scoring='accuracy',
    n_jobs=-1,
    verbose=1
)

grid_search.fit(X_train, y_train)

print(f"Best parameters: {grid_search.best_params_}")
print(f"Best score: {grid_search.best_score_:.3f}")

# Use best model
best_model = grid_search.best_estimator_
y_pred = best_model.predict(X_test)

# Randomized Search: Sample from distributions
param_distributions = {
    'n_estimators': randint(50, 500),
    'max_depth': [None] + list(randint(10, 100).rvs(10)),
    'min_samples_split': randint(2, 20),
    'min_samples_leaf': randint(1, 10),
    'max_features': uniform(0.1, 0.9)
}

random_search = RandomizedSearchCV(
    RandomForestClassifier(random_state=42),
    param_distributions,
    n_iter=100,
    cv=5,
    scoring='accuracy',
    n_jobs=-1,
    random_state=42
)

random_search.fit(X_train, y_train)

# View all results
results_df = pd.DataFrame(random_search.cv_results_)
print(results_df[['params', 'mean_test_score', 'std_test_score']].head())
```

### Classification Metrics

```python
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    classification_report, confusion_matrix, roc_auc_score, roc_curve
)
import matplotlib.pyplot as plt

# Basic metrics
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, average='weighted')
recall = recall_score(y_test, y_pred, average='weighted')
f1 = f1_score(y_test, y_pred, average='weighted')

print(f"Accuracy: {accuracy:.3f}")
print(f"Precision: {precision:.3f}")
print(f"Recall: {recall:.3f}")
print(f"F1 Score: {f1:.3f}")

# Detailed classification report
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Confusion matrix
cm = confusion_matrix(y_test, y_pred)
print("\nConfusion Matrix:")
print(cm)

# ROC-AUC for binary classification
y_proba = model.predict_proba(X_test)[:, 1]
roc_auc = roc_auc_score(y_test, y_proba)
print(f"\nROC-AUC: {roc_auc:.3f}")

# Plot ROC curve
fpr, tpr, thresholds = roc_curve(y_test, y_proba)
plt.figure(figsize=(8, 6))
plt.plot(fpr, tpr, label=f'ROC Curve (AUC = {roc_auc:.3f})')
plt.plot([0, 1], [0, 1], 'k--', label='Random Classifier')
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.legend()
plt.show()
```

### Regression Metrics

```python
from sklearn.metrics import (
    mean_squared_error, mean_absolute_error, r2_score,
    mean_absolute_percentage_error, explained_variance_score
)
import numpy as np

# Basic metrics
mse = mean_squared_error(y_test, y_pred)
rmse = np.sqrt(mse)
mae = mean_absolute_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)
mape = mean_absolute_percentage_error(y_test, y_pred)
evs = explained_variance_score(y_test, y_pred)

print(f"MSE: {mse:.3f}")
print(f"RMSE: {rmse:.3f}")
print(f"MAE: {mae:.3f}")
print(f"R² Score: {r2:.3f}")
print(f"MAPE: {mape:.3f}")
print(f"Explained Variance: {evs:.3f}")

# Plot predictions vs actual
plt.figure(figsize=(10, 4))

plt.subplot(1, 2, 1)
plt.scatter(y_test, y_pred, alpha=0.5)
plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--')
plt.xlabel('Actual')
plt.ylabel('Predicted')
plt.title('Predictions vs Actual')

plt.subplot(1, 2, 2)
residuals = y_test - y_pred
plt.scatter(y_pred, residuals, alpha=0.5)
plt.axhline(y=0, color='r', linestyle='--')
plt.xlabel('Predicted')
plt.ylabel('Residuals')
plt.title('Residual Plot')

plt.tight_layout()
plt.show()
```

### Learning Curves

```python
from sklearn.model_selection import learning_curve

# Generate learning curve data
train_sizes, train_scores, val_scores = learning_curve(
    model, X, y,
    train_sizes=np.linspace(0.1, 1.0, 10),
    cv=5,
    scoring='accuracy',
    n_jobs=-1
)

# Calculate mean and std
train_mean = train_scores.mean(axis=1)
train_std = train_scores.std(axis=1)
val_mean = val_scores.mean(axis=1)
val_std = val_scores.std(axis=1)

# Plot learning curve
plt.figure(figsize=(10, 6))
plt.plot(train_sizes, train_mean, label='Training score')
plt.plot(train_sizes, val_mean, label='Validation score')
plt.fill_between(train_sizes, train_mean - train_std, train_mean + train_std, alpha=0.1)
plt.fill_between(train_sizes, val_mean - val_std, val_mean + val_std, alpha=0.1)
plt.xlabel('Training Set Size')
plt.ylabel('Score')
plt.title('Learning Curve')
plt.legend()
plt.grid(True)
plt.show()
```

### Validation Curves

```python
from sklearn.model_selection import validation_curve

# Generate validation curve data
param_range = [1, 5, 10, 20, 50, 100]
train_scores, val_scores = validation_curve(
    RandomForestClassifier(random_state=42),
    X, y,
    param_name='n_estimators',
    param_range=param_range,
    cv=5,
    scoring='accuracy'
)

# Plot validation curve
train_mean = train_scores.mean(axis=1)
train_std = train_scores.std(axis=1)
val_mean = val_scores.mean(axis=1)
val_std = val_scores.std(axis=1)

plt.figure(figsize=(10, 6))
plt.plot(param_range, train_mean, label='Training score')
plt.plot(param_range, val_mean, label='Validation score')
plt.fill_between(param_range, train_mean - train_std, train_mean + train_std, alpha=0.1)
plt.fill_between(param_range, val_mean - val_std, val_mean + val_std, alpha=0.1)
plt.xlabel('n_estimators')
plt.ylabel('Score')
plt.title('Validation Curve')
plt.legend()
plt.grid(True)
plt.show()
```

## Pipelines

### Basic Pipeline

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.linear_model import LogisticRegression

# Create pipeline
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('pca', PCA(n_components=10)),
    ('classifier', LogisticRegression())
])

# Fit and predict (all steps applied automatically)
pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)
score = pipeline.score(X_test, y_test)

# Access individual steps
scaler = pipeline.named_steps['scaler']
pca = pipeline.named_steps['pca']
classifier = pipeline.named_steps['classifier']

# Get parameters
print(pipeline.get_params())
```

### Pipeline with GridSearch

```python
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV
from sklearn.ensemble import RandomForestClassifier

# Create pipeline
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('classifier', RandomForestClassifier(random_state=42))
])

# Define parameter grid (use step__parameter syntax)
param_grid = {
    'classifier__n_estimators': [50, 100, 200],
    'classifier__max_depth': [None, 10, 20],
    'classifier__min_samples_split': [2, 5, 10]
}

# Grid search over pipeline
grid_search = GridSearchCV(pipeline, param_grid, cv=5, n_jobs=-1)
grid_search.fit(X_train, y_train)

print(f"Best parameters: {grid_search.best_params_}")
print(f"Best score: {grid_search.best_score_:.3f}")

# Use best pipeline
best_pipeline = grid_search.best_estimator_
y_pred = best_pipeline.predict(X_test)
```

### ColumnTransformer

```python
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer

# Define column types
numeric_features = ['age', 'income', 'credit_score']
categorical_features = ['gender', 'occupation', 'city']

# Create transformers for different column types
numeric_transformer = Pipeline([
    ('imputer', SimpleImputer(strategy='median')),
    ('scaler', StandardScaler())
])

categorical_transformer = Pipeline([
    ('imputer', SimpleImputer(strategy='constant', fill_value='missing')),
    ('onehot', OneHotEncoder(handle_unknown='ignore'))
])

# Combine transformers
preprocessor = ColumnTransformer(
    transformers=[
        ('num', numeric_transformer, numeric_features),
        ('cat', categorical_transformer, categorical_features)
    ])

# Create full pipeline
pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', RandomForestClassifier())
])

# Fit and predict
pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)
```

### FeatureUnion

```python
from sklearn.pipeline import FeatureUnion
from sklearn.decomposition import PCA
from sklearn.feature_selection import SelectKBest

# Combine multiple feature extraction methods
feature_union = FeatureUnion([
    ('pca', PCA(n_components=10)),
    ('select_best', SelectKBest(k=20))
])

# Use in pipeline
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('features', feature_union),
    ('classifier', LogisticRegression())
])

pipeline.fit(X_train, y_train)
```

### make_pipeline (Simplified)

```python
from sklearn.pipeline import make_pipeline

# Automatically names steps
pipeline = make_pipeline(
    StandardScaler(),
    PCA(n_components=10),
    LogisticRegression()
)

# Step names are auto-generated: standardscaler, pca, logisticregression
print(pipeline.named_steps)
```

### Caching Pipeline Steps

```python
from sklearn.pipeline import Pipeline
from tempfile import mkdtemp
from shutil import rmtree

# Cache expensive computations
cachedir = mkdtemp()

pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('pca', PCA(n_components=10)),
    ('classifier', RandomForestClassifier())
], memory=cachedir)

# First fit: All steps executed
pipeline.fit(X_train, y_train)

# Second fit with same scaler/pca params: Reuses cached results
pipeline.set_params(classifier__n_estimators=200)
pipeline.fit(X_train, y_train)  # Only retrains classifier

# Cleanup
rmtree(cachedir)
```

### Custom Pipeline with Feature Engineering

```python
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.pipeline import Pipeline
import numpy as np

class FeatureEngineer(BaseEstimator, TransformerMixin):
    """Add custom features"""
    
    def fit(self, X, y=None):
        return self
    
    def transform(self, X):
        # Add polynomial features
        X_new = X.copy()
        X_new['feature1_squared'] = X['feature1'] ** 2
        X_new['feature1_feature2'] = X['feature1'] * X['feature2']
        X_new['feature_ratio'] = X['feature1'] / (X['feature2'] + 1)
        return X_new

class OutlierRemover(BaseEstimator, TransformerMixin):
    """Remove outliers using IQR method"""
    
    def __init__(self, factor=1.5):
        self.factor = factor
    
    def fit(self, X, y=None):
        Q1 = X.quantile(0.25)
        Q3 = X.quantile(0.75)
        IQR = Q3 - Q1
        self.lower_bound = Q1 - self.factor * IQR
        self.upper_bound = Q3 + self.factor * IQR
        return self
    
    def transform(self, X):
        return X[
            ((X >= self.lower_bound) & (X <= self.upper_bound)).all(axis=1)
        ]

# Use custom transformers in pipeline
pipeline = Pipeline([
    ('engineer', FeatureEngineer()),
    ('outliers', OutlierRemover(factor=1.5)),
    ('scaler', StandardScaler()),
    ('model', RandomForestClassifier())
])
```

## Common Algorithms

### Linear Models

```python
from sklearn.linear_model import (
    LinearRegression, Ridge, Lasso, ElasticNet,
    LogisticRegression, SGDClassifier
)

# Linear Regression
lr = LinearRegression()
lr.fit(X_train, y_train)

# Ridge Regression (L2 regularization)
ridge = Ridge(alpha=1.0)
ridge.fit(X_train, y_train)

# Lasso Regression (L1 regularization)
lasso = Lasso(alpha=0.1)
lasso.fit(X_train, y_train)

# ElasticNet (L1 + L2 regularization)
elastic = ElasticNet(alpha=0.1, l1_ratio=0.5)
elastic.fit(X_train, y_train)

# Logistic Regression
log_reg = LogisticRegression(
    penalty='l2',
    C=1.0,
    max_iter=1000,
    solver='lbfgs'
)
log_reg.fit(X_train, y_train)

# Stochastic Gradient Descent
sgd = SGDClassifier(
    loss='hinge',  # 'log_loss', 'modified_huber', 'squared_hinge'
    penalty='l2',
    max_iter=1000
)
sgd.fit(X_train, y_train)
```

### Tree-Based Models

```python
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.ensemble import (
    RandomForestClassifier, RandomForestRegressor,
    GradientBoostingClassifier, GradientBoostingRegressor,
    AdaBoostClassifier, ExtraTreesClassifier
)

# Decision Tree
dt = DecisionTreeClassifier(
    max_depth=10,
    min_samples_split=5,
    min_samples_leaf=2,
    criterion='gini'  # or 'entropy'
)
dt.fit(X_train, y_train)

# Random Forest
rf = RandomForestClassifier(
    n_estimators=100,
    max_depth=None,
    min_samples_split=2,
    n_jobs=-1,
    random_state=42
)
rf.fit(X_train, y_train)

# Gradient Boosting
gb = GradientBoostingClassifier(
    n_estimators=100,
    learning_rate=0.1,
    max_depth=3,
    subsample=0.8,
    random_state=42
)
gb.fit(X_train, y_train)

# AdaBoost
ada = AdaBoostClassifier(
    estimator=DecisionTreeClassifier(max_depth=1),
    n_estimators=50,
    learning_rate=1.0
)
ada.fit(X_train, y_train)

# Extra Trees
et = ExtraTreesClassifier(
    n_estimators=100,
    max_depth=None,
    n_jobs=-1,
    random_state=42
)
et.fit(X_train, y_train)

# Feature importance
importance_df = pd.DataFrame({
    'feature': feature_names,
    'importance': rf.feature_importances_
}).sort_values('importance', ascending=False)
```

### Support Vector Machines

```python
from sklearn.svm import SVC, SVR, LinearSVC

# SVM Classification
svc = SVC(
    kernel='rbf',  # 'linear', 'poly', 'rbf', 'sigmoid'
    C=1.0,
    gamma='scale',
    probability=True  # Enable probability estimates
)
svc.fit(X_train, y_train)

# Linear SVM (faster for linear kernel)
linear_svc = LinearSVC(
    C=1.0,
    max_iter=1000,
    dual=True
)
linear_svc.fit(X_train, y_train)

# SVM Regression
svr = SVR(
    kernel='rbf',
    C=1.0,
    epsilon=0.1
)
svr.fit(X_train, y_train)

# Probability predictions
y_proba = svc.predict_proba(X_test)
```

### Nearest Neighbors

```python
from sklearn.neighbors import (
    KNeighborsClassifier, KNeighborsRegressor,
    RadiusNeighborsClassifier
)

# K-Nearest Neighbors Classification
knn = KNeighborsClassifier(
    n_neighbors=5,
    weights='uniform',  # or 'distance'
    metric='minkowski',  # or 'euclidean', 'manhattan'
    p=2
)
knn.fit(X_train, y_train)

# K-Nearest Neighbors Regression
knn_reg = KNeighborsRegressor(
    n_neighbors=5,
    weights='distance'
)
knn_reg.fit(X_train, y_train)

# Radius Neighbors
rn = RadiusNeighborsClassifier(
    radius=1.0,
    weights='distance'
)
rn.fit(X_train, y_train)

# Get neighbors
distances, indices = knn.kneighbors(X_test[:5])
```

### Naive Bayes

```python
from sklearn.naive_bayes import (
    GaussianNB, MultinomialNB, BernoulliNB
)

# Gaussian Naive Bayes (continuous features)
gnb = GaussianNB()
gnb.fit(X_train, y_train)

# Multinomial Naive Bayes (count features, text classification)
mnb = MultinomialNB(alpha=1.0)  # Laplace smoothing
mnb.fit(X_train, y_train)

# Bernoulli Naive Bayes (binary features)
bnb = BernoulliNB(alpha=1.0)
bnb.fit(X_train, y_train)

# Predict log probabilities
log_proba = gnb.predict_log_proba(X_test)
```

### Clustering Algorithms

```python
from sklearn.cluster import (
    KMeans, DBSCAN, AgglomerativeClustering,
    MeanShift, SpectralClustering
)
from sklearn.mixture import GaussianMixture

# K-Means
kmeans = KMeans(
    n_clusters=3,
    init='k-means++',
    n_init=10,
    max_iter=300,
    random_state=42
)
labels = kmeans.fit_predict(X)
centers = kmeans.cluster_centers_

# DBSCAN (density-based)
dbscan = DBSCAN(
    eps=0.5,
    min_samples=5,
    metric='euclidean'
)
labels = dbscan.fit_predict(X)

# Hierarchical Clustering
agg = AgglomerativeClustering(
    n_clusters=3,
    linkage='ward'  # 'complete', 'average', 'single'
)
labels = agg.fit_predict(X)

# Gaussian Mixture Model
gmm = GaussianMixture(
    n_components=3,
    covariance_type='full',
    random_state=42
)
labels = gmm.fit_predict(X)
proba = gmm.predict_proba(X)

# Mean Shift
ms = MeanShift(bandwidth=2.0)
labels = ms.fit_predict(X)

# Spectral Clustering
sc = SpectralClustering(
    n_clusters=3,
    affinity='rbf',
    random_state=42
)
labels = sc.fit_predict(X)
```

### Dimensionality Reduction

```python
from sklearn.decomposition import PCA, TruncatedSVD, NMF, FastICA
from sklearn.manifold import TSNE, MDS, Isomap

# Principal Component Analysis
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X)
print(f"Explained variance: {pca.explained_variance_ratio_}")

# Truncated SVD (works with sparse matrices)
svd = TruncatedSVD(n_components=10)
X_svd = svd.fit_transform(X)

# Non-negative Matrix Factorization
nmf = NMF(n_components=10, init='random', random_state=42)
X_nmf = nmf.fit_transform(X)

# Independent Component Analysis
ica = FastICA(n_components=10, random_state=42)
X_ica = ica.fit_transform(X)

# t-SNE (visualization)
tsne = TSNE(
    n_components=2,
    perplexity=30,
    random_state=42,
    n_jobs=-1
)
X_tsne = tsne.fit_transform(X)

# Multi-dimensional Scaling
mds = MDS(n_components=2, random_state=42)
X_mds = mds.fit_transform(X)

# Isomap
isomap = Isomap(n_components=2, n_neighbors=5)
X_isomap = isomap.fit_transform(X)
```

## Advanced Topics

### Ensemble Methods

```python
from sklearn.ensemble import VotingClassifier, StackingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier

# Voting Classifier (combine multiple models)
voting = VotingClassifier(
    estimators=[
        ('lr', LogisticRegression()),
        ('rf', RandomForestClassifier()),
        ('svc', SVC(probability=True))
    ],
    voting='soft'  # or 'hard' for majority vote
)
voting.fit(X_train, y_train)

# Stacking Classifier (use meta-learner)
stacking = StackingClassifier(
    estimators=[
        ('rf', RandomForestClassifier(n_estimators=100)),
        ('svc', SVC(probability=True))
    ],
    final_estimator=LogisticRegression(),
    cv=5
)
stacking.fit(X_train, y_train)
```

### Imbalanced Datasets

```python
from sklearn.utils.class_weight import compute_class_weight
from imblearn.over_sampling import SMOTE
from imblearn.under_sampling import RandomUnderSampler
from imblearn.pipeline import Pipeline as ImbPipeline

# Class weights
class_weights = compute_class_weight(
    'balanced',
    classes=np.unique(y_train),
    y=y_train
)
class_weight_dict = dict(enumerate(class_weights))

# Use class weights in model
rf = RandomForestClassifier(class_weight='balanced')
rf.fit(X_train, y_train)

# SMOTE (Synthetic Minority Over-sampling)
smote = SMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)

# Combined over/under sampling
pipeline = ImbPipeline([
    ('over', SMOTE(sampling_strategy=0.5)),
    ('under', RandomUnderSampler(sampling_strategy=0.8)),
    ('classifier', RandomForestClassifier())
])
```

### Multi-output and Multi-label Classification

```python
from sklearn.multioutput import MultiOutputClassifier
from sklearn.multiclass import OneVsRestClassifier
from sklearn.preprocessing import MultiLabelBinarizer

# Multi-output (multiple targets)
multi_output = MultiOutputClassifier(RandomForestClassifier())
multi_output.fit(X_train, y_train_multiple)

# Multi-label (each sample can have multiple labels)
mlb = MultiLabelBinarizer()
y_train_binary = mlb.fit_transform(y_train_labels)

ovr = OneVsRestClassifier(LogisticRegression())
ovr.fit(X_train, y_train_binary)

# Predict
y_pred_binary = ovr.predict(X_test)
y_pred_labels = mlb.inverse_transform(y_pred_binary)
```

### Calibration

```python
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
import matplotlib.pyplot as plt

# Calibrate probabilities
calibrated = CalibratedClassifierCV(
    base_estimator=RandomForestClassifier(),
    method='sigmoid',  # or 'isotonic'
    cv=5
)
calibrated.fit(X_train, y_train)

# Plot calibration curve
y_proba = model.predict_proba(X_test)[:, 1]
fraction_of_positives, mean_predicted_value = calibration_curve(
    y_test, y_proba, n_bins=10
)

plt.figure(figsize=(10, 6))
plt.plot(mean_predicted_value, fraction_of_positives, marker='o', label='Model')
plt.plot([0, 1], [0, 1], 'k--', label='Perfect calibration')
plt.xlabel('Mean Predicted Probability')
plt.ylabel('Fraction of Positives')
plt.title('Calibration Curve')
plt.legend()
plt.show()
```

### Partial Fitting (Online Learning)

```python
from sklearn.linear_model import SGDClassifier
from sklearn.preprocessing import StandardScaler

# Initialize model
scaler = StandardScaler()
sgd = SGDClassifier(loss='log_loss', random_state=42)

# Fit in batches
batch_size = 1000
for i in range(0, len(X_train), batch_size):
    X_batch = X_train[i:i+batch_size]
    y_batch = y_train[i:i+batch_size]
    
    # First batch: fit
    if i == 0:
        scaler.fit(X_batch)
        X_scaled = scaler.transform(X_batch)
        sgd.partial_fit(X_scaled, y_batch, classes=np.unique(y_train))
    # Subsequent batches: partial_fit
    else:
        X_scaled = scaler.transform(X_batch)
        sgd.partial_fit(X_scaled, y_batch)
```

### Saving and Loading Models

```python
import joblib
import pickle

# Save model with joblib (recommended)
joblib.dump(model, 'model.joblib')

# Load model
model = joblib.load('model.joblib')

# Save with pickle (alternative)
with open('model.pkl', 'wb') as f:
    pickle.dump(model, f)

# Load with pickle
with open('model.pkl', 'rb') as f:
    model = pickle.load(f)

# Save pipeline
joblib.dump(pipeline, 'pipeline.joblib')

# Save with compression
joblib.dump(model, 'model.joblib', compress=3)
```

### Feature Importance and Interpretability

```python
from sklearn.inspection import permutation_importance, partial_dependence
import shap

# Tree-based feature importance
rf = RandomForestClassifier()
rf.fit(X_train, y_train)

feature_importance = pd.DataFrame({
    'feature': feature_names,
    'importance': rf.feature_importances_
}).sort_values('importance', ascending=False)

# Permutation importance (works for any model)
perm_importance = permutation_importance(
    rf, X_test, y_test,
    n_repeats=10,
    random_state=42
)

perm_importance_df = pd.DataFrame({
    'feature': feature_names,
    'importance': perm_importance.importances_mean,
    'std': perm_importance.importances_std
}).sort_values('importance', ascending=False)

# Partial dependence plots
from sklearn.inspection import PartialDependenceDisplay

fig, ax = plt.subplots(figsize=(12, 4))
PartialDependenceDisplay.from_estimator(
    rf, X_train, features=[0, 1, (0, 1)],
    ax=ax
)
plt.tight_layout()
plt.show()

# SHAP values (requires shap library)
# pip install shap
explainer = shap.TreeExplainer(rf)
shap_values = explainer.shap_values(X_test)

# Summary plot
shap.summary_plot(shap_values, X_test, feature_names=feature_names)
```

## Best Practices

### Data Splitting Strategy

```python
# Always split before any preprocessing
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# For time series: Don't shuffle
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, shuffle=False
)

# Use cross-validation for small datasets
from sklearn.model_selection import cross_val_score
scores = cross_val_score(model, X, y, cv=10)
```

### Preprocessing Best Practices

```python
# 1. Fit scaler on training data only
scaler = StandardScaler()
scaler.fit(X_train)  # Learn from training data
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)  # Apply to test data

# 2. Use pipelines to prevent data leakage
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('classifier', RandomForestClassifier())
])
# Cross-validation applies scaling within each fold
scores = cross_val_score(pipeline, X, y, cv=5)

# 3. Handle missing values before scaling
pipeline = Pipeline([
    ('imputer', SimpleImputer(strategy='median')),
    ('scaler', StandardScaler()),
    ('classifier', RandomForestClassifier())
])
```

### Feature Engineering

```python
# 1. Create domain-specific features
df['date_time'] = pd.to_datetime(df['timestamp'])
df['hour'] = df['date_time'].dt.hour
df['day_of_week'] = df['date_time'].dt.dayofweek
df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)

# 2. Interaction features
df['feature1_x_feature2'] = df['feature1'] * df['feature2']

# 3. Polynomial features for non-linear relationships
from sklearn.preprocessing import PolynomialFeatures
poly = PolynomialFeatures(degree=2, include_bias=False)
X_poly = poly.fit_transform(X)

# 4. Binning continuous features
df['age_group'] = pd.cut(df['age'], bins=[0, 18, 35, 50, 100], 
                          labels=['child', 'young', 'middle', 'senior'])
```

### Hyperparameter Tuning Strategy

```python
# 1. Start with default parameters
model = RandomForestClassifier(random_state=42)
model.fit(X_train, y_train)
baseline_score = model.score(X_test, y_test)

# 2. Use RandomizedSearchCV for initial exploration
from scipy.stats import randint, uniform

param_dist = {
    'n_estimators': randint(50, 500),
    'max_depth': [None] + list(randint(5, 50).rvs(10)),
    'min_samples_split': randint(2, 20),
    'min_samples_leaf': randint(1, 10)
}

random_search = RandomizedSearchCV(
    RandomForestClassifier(random_state=42),
    param_dist, n_iter=100, cv=5, n_jobs=-1
)
random_search.fit(X_train, y_train)

# 3. Fine-tune with GridSearchCV
param_grid = {
    'n_estimators': [180, 200, 220],
    'max_depth': [18, 20, 22],
    'min_samples_split': [2, 3, 4]
}

grid_search = GridSearchCV(
    RandomForestClassifier(random_state=42),
    param_grid, cv=5, n_jobs=-1
)
grid_search.fit(X_train, y_train)
```

### Dealing with Overfitting

```python
# 1. Use regularization
from sklearn.linear_model import Ridge, Lasso

# Ridge (L2)
ridge = Ridge(alpha=1.0)

# Lasso (L1)
lasso = Lasso(alpha=0.1)

# 2. Reduce model complexity
rf = RandomForestClassifier(
    max_depth=10,  # Limit tree depth
    min_samples_split=10,  # Increase minimum samples
    min_samples_leaf=5  # Increase minimum leaf size
)

# 3. Use cross-validation
scores = cross_val_score(model, X, y, cv=10)

# 4. Get more data or use data augmentation

# 5. Feature selection
from sklearn.feature_selection import SelectKBest
selector = SelectKBest(k=20)
X_selected = selector.fit_transform(X, y)

# 6. Ensemble methods
from sklearn.ensemble import BaggingClassifier
bagging = BaggingClassifier(
    estimator=DecisionTreeClassifier(),
    n_estimators=10
)
```

### Performance Optimization

```python
# 1. Use n_jobs=-1 for parallel processing
rf = RandomForestClassifier(n_estimators=100, n_jobs=-1)

# 2. Use warm_start for iterative training
rf = RandomForestClassifier(n_estimators=10, warm_start=True)
rf.fit(X_train, y_train)
rf.n_estimators = 50
rf.fit(X_train, y_train)  # Continues from previous trees

# 3. Reduce dataset size for prototyping
X_sample, _, y_sample, _ = train_test_split(
    X, y, train_size=0.1, stratify=y
)

# 4. Use sparse matrices for high-dimensional data
from scipy.sparse import csr_matrix
X_sparse = csr_matrix(X)

# 5. Pipeline caching
from tempfile import mkdtemp
cachedir = mkdtemp()
pipeline = Pipeline([...], memory=cachedir)
```

### Model Validation

```python
# 1. Use multiple metrics
from sklearn.metrics import make_scorer, f1_score

scoring = {
    'accuracy': 'accuracy',
    'precision': 'precision_weighted',
    'recall': 'recall_weighted',
    'f1': 'f1_weighted',
    'roc_auc': 'roc_auc_ovr_weighted'
}

scores = cross_validate(model, X, y, cv=5, scoring=scoring)

# 2. Check for overfitting
train_score = model.score(X_train, y_train)
test_score = model.score(X_test, y_test)
print(f"Train: {train_score:.3f}, Test: {test_score:.3f}")

# 3. Use learning curves
from sklearn.model_selection import learning_curve

train_sizes, train_scores, val_scores = learning_curve(
    model, X, y, cv=5, train_sizes=np.linspace(0.1, 1.0, 10)
)

# 4. Stratified sampling for imbalanced data
from sklearn.model_selection import StratifiedKFold
skf = StratifiedKFold(n_splits=5)
for train_idx, val_idx in skf.split(X, y):
    X_train, X_val = X[train_idx], X[val_idx]
    y_train, y_val = y[train_idx], y[val_idx]
```

## Real-World Examples

### Text Classification

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

# Load data
texts = ["sample text 1", "sample text 2", ...]
labels = [0, 1, ...]

# Create pipeline
text_clf = Pipeline([
    ('tfidf', TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        stop_words='english'
    )),
    ('clf', MultinomialNB())
])

# Train and evaluate
text_clf.fit(texts_train, labels_train)
accuracy = text_clf.score(texts_test, labels_test)
```

### Image Classification with Feature Extraction

```python
from sklearn.decomposition import PCA
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline

# Flatten images
X_train_flat = X_train_images.reshape(len(X_train_images), -1)
X_test_flat = X_test_images.reshape(len(X_test_images), -1)

# Pipeline with PCA and SVM
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('pca', PCA(n_components=100)),
    ('svm', SVC(kernel='rbf'))
])

pipeline.fit(X_train_flat, y_train)
accuracy = pipeline.score(X_test_flat, y_test)
```

### Time Series Forecasting

```python
from sklearn.ensemble import RandomForestRegressor

# Create lag features
def create_lag_features(df, n_lags=5):
    for i in range(1, n_lags + 1):
        df[f'lag_{i}'] = df['value'].shift(i)
    return df.dropna()

# Prepare data
df = create_lag_features(time_series_df)
X = df.drop('value', axis=1)
y = df['value']

# Train model
model = RandomForestRegressor(n_estimators=100)
model.fit(X_train, y_train)

# Forecast
y_pred = model.predict(X_test)
```

### Anomaly Detection

```python
from sklearn.ensemble import IsolationForest
from sklearn.covariance import EllipticEnvelope
from sklearn.neighbors import LocalOutlierFactor

# Isolation Forest
iso_forest = IsolationForest(
    contamination=0.1,  # Expected proportion of outliers
    random_state=42
)
outliers = iso_forest.fit_predict(X)  # -1 for outliers, 1 for inliers

# Elliptic Envelope (assumes Gaussian distribution)
envelope = EllipticEnvelope(contamination=0.1)
outliers = envelope.fit_predict(X)

# Local Outlier Factor
lof = LocalOutlierFactor(n_neighbors=20, contamination=0.1)
outliers = lof.fit_predict(X)
```

## Common Pitfalls

### Data Leakage

```python
# ❌ Wrong: Scaling before split
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
X_train, X_test = train_test_split(X_scaled, y)

# ✅ Correct: Scaling after split
X_train, X_test, y_train, y_test = train_test_split(X, y)
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# ✅ Best: Use pipeline
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('model', RandomForestClassifier())
])
```

### Imbalanced Classes

```python
# ❌ Wrong: Ignore class imbalance
model = RandomForestClassifier()
model.fit(X_train, y_train)

# ✅ Correct: Use class weights
model = RandomForestClassifier(class_weight='balanced')
model.fit(X_train, y_train)

# ✅ Alternative: Resample data
from imblearn.over_sampling import SMOTE
smote = SMOTE()
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)
```

### Not Scaling Features

```python
# ❌ Wrong: Not scaling for distance-based algorithms
knn = KNeighborsClassifier()
knn.fit(X_train, y_train)  # Features have different scales

# ✅ Correct: Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
knn.fit(X_train_scaled, y_train)
```

### Random State

```python
# ❌ Wrong: No random state (non-reproducible results)
model = RandomForestClassifier()

# ✅ Correct: Set random state
model = RandomForestClassifier(random_state=42)
```

## Troubleshooting

### ConvergenceWarning

```python
# Issue: Model didn't converge
# Solution: Increase max_iter or scale features
from sklearn.linear_model import LogisticRegression

model = LogisticRegression(max_iter=1000)  # Increase iterations
# Or use scaling
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('model', LogisticRegression())
])
```

### Memory Error

```python
# Issue: Dataset too large for memory
# Solution: Use batch processing or sampling

# Batch processing with SGD
from sklearn.linear_model import SGDClassifier
sgd = SGDClassifier()
for batch in batches:
    sgd.partial_fit(X_batch, y_batch, classes=np.unique(y))

# Sample data
X_sample, _, y_sample, _ = train_test_split(X, y, train_size=0.1)
```

### Poor Performance

```python
# Checklist:
# 1. Check for data leakage
# 2. Verify feature scaling
# 3. Handle missing values
# 4. Address class imbalance
# 5. Try different algorithms
# 6. Tune hyperparameters
# 7. Add more features
# 8. Get more data
# 9. Check for outliers
# 10. Validate data quality
```

## See Also

- [Official Documentation](https://scikit-learn.org/stable/)
- [User Guide](https://scikit-learn.org/stable/user_guide.html)
- [API Reference](https://scikit-learn.org/stable/modules/classes.html)
- [Examples Gallery](https://scikit-learn.org/stable/auto_examples/index.html)
- [Tutorials](https://scikit-learn.org/stable/tutorial/index.html)
- [NumPy Documentation](../data-science/numpy.md)
- [Pandas Documentation](../data-science/pandas.md)
- [Machine Learning Overview](index.md)

## Additional Resources

### Books

- [Hands-On Machine Learning with Scikit-Learn, Keras, and TensorFlow](https://www.oreilly.com/library/view/hands-on-machine-learning/9781492032632/)
- [Python Machine Learning](https://www.packtpub.com/product/python-machine-learning-third-edition/9781789955750)
- [Introduction to Machine Learning with Python](https://www.oreilly.com/library/view/introduction-to-machine/9781449369880/)

### Online Courses

- [Coursera: Machine Learning with Python](https://www.coursera.org/learn/machine-learning-with-python)
- [DataCamp: Supervised Learning with scikit-learn](https://www.datacamp.com/courses/supervised-learning-with-scikit-learn)
- [Kaggle: Intermediate Machine Learning](https://www.kaggle.com/learn/intermediate-machine-learning)

### Community

- [Scikit-learn GitHub](https://github.com/scikit-learn/scikit-learn)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/scikit-learn)
- [Scikit-learn Mailing List](https://mail.python.org/mailman/listinfo/scikit-learn)
- [Twitter: @scikit_learn](https://twitter.com/scikit_learn)

### Related Tools

- [imbalanced-learn](https://imbalanced-learn.org/) - Handling imbalanced datasets
- [SHAP](https://github.com/slundberg/shap) - Model interpretability
- [scikit-optimize](https://scikit-optimize.github.io/) - Hyperparameter optimization
- [TPOT](http://epistasislab.github.io/tpot/) - Automated machine learning
- [MLflow](https://mlflow.org/) - ML lifecycle management
