---
title: Machine Learning with Python
description: Comprehensive guide to machine learning in Python, covering scikit-learn, TensorFlow, PyTorch, model development, training, evaluation, and deployment strategies
---

Machine learning in Python has revolutionized data science and artificial intelligence, providing accessible yet powerful tools for building predictive models, neural networks, and intelligent systems. Python's rich ecosystem of libraries, combined with its simplicity and extensive community support, makes it the dominant language for machine learning research and production applications.

## Overview

Python's machine learning ecosystem offers solutions for every stage of the ML lifecycle, from data preprocessing and exploratory analysis to model training, evaluation, hyperparameter tuning, and deployment. The landscape is anchored by three major frameworks: **scikit-learn** for traditional machine learning, **TensorFlow** for production-scale deep learning, and **PyTorch** for research and dynamic neural networks.

This guide covers the fundamental concepts, practical implementations, best practices, and real-world workflows for building machine learning systems in Python.

## Core Machine Learning Libraries

### Scikit-learn

**Scikit-learn** is the foundational library for traditional machine learning in Python, offering simple and efficient tools for data mining and analysis.

#### Scikit-learn Key Features

- **Consistent API**: All algorithms follow the fit/predict pattern
- **Comprehensive algorithms**: Classification, regression, clustering, dimensionality reduction
- **Model selection**: Cross-validation, grid search, metrics
- **Preprocessing**: Scaling, encoding, feature extraction
- **Pipeline support**: Chain transformers and estimators
- **Well-documented**: Extensive examples and user guide

#### Installing Scikit-learn

```bash
pip install scikit-learn
# or with UV for faster installation
uv pip install scikit-learn
```

#### Basic Example - Classification

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

# Load dataset
iris = load_iris()
X, y = iris.data, iris.target

# Split data
XTrain, XTest, yTrain, yTest = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Train model
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(XTrain, yTrain)

# Predict and evaluate
yPred = clf.predict(XTest)
print(f"Accuracy: {accuracy_score(yTest, yPred):.3f}")
print(classification_report(yTest, yPred, target_names=iris.target_names))
```

#### Common Algorithms

**Classification**:

- Logistic Regression
- Support Vector Machines (SVM)
- Decision Trees
- Random Forests
- Gradient Boosting (XGBoost, LightGBM)
- Naive Bayes
- K-Nearest Neighbors (KNN)

**Regression**:

- Linear Regression
- Ridge/Lasso Regression
- Support Vector Regression
- Decision Tree Regressor
- Random Forest Regressor
- Gradient Boosting Regressor

**Clustering**:

- K-Means
- DBSCAN
- Hierarchical Clustering
- Gaussian Mixture Models

**Dimensionality Reduction**:

- Principal Component Analysis (PCA)
- t-SNE
- UMAP
- Linear Discriminant Analysis (LDA)

### TensorFlow and Keras

**TensorFlow** is Google's open-source deep learning framework, with **Keras** as its high-level API for building and training neural networks.

#### TensorFlow Key Features

- **Production-ready**: Industry-standard for deployment
- **TensorFlow Serving**: Model serving infrastructure
- **TensorFlow Lite**: Mobile and embedded deployment
- **TensorFlow.js**: Browser-based machine learning
- **Distributed training**: Multi-GPU and TPU support
- **TensorBoard**: Visualization and monitoring
- **Keras API**: Simple, intuitive model building

#### Installing TensorFlow

```bash
pip install tensorflow
# or with UV
uv pip install tensorflow
```

#### TensorFlow Basic Example

```python
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np

# Load dataset
(XTrain, yTrain), (XTest, yTest) = keras.datasets.mnist.load_data()

# Normalize pixel values
XTrain = XTrain.astype("float32") / 255.0
XTest = XTest.astype("float32") / 255.0

# Build model
model = keras.Sequential([
    layers.Flatten(input_shape=(28, 28)),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.2),
    layers.Dense(10, activation="softmax")
])

# Compile model
model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

# Train model
history = model.fit(
    XTrain, yTrain,
    epochs=5,
    validation_split=0.1,
    batch_size=32,
    verbose=1
)

# Evaluate
testLoss, testAcc = model.evaluate(XTest, yTest, verbose=0)
print(f"Test accuracy: {testAcc:.4f}")
```

#### Advanced Model Architectures

```python
# Convolutional Neural Network for image classification
def CreateCNN():
    model = keras.Sequential([
        layers.Conv2D(32, (3, 3), activation="relu", input_shape=(28, 28, 1)),
        layers.MaxPooling2D((2, 2)),
        layers.Conv2D(64, (3, 3), activation="relu"),
        layers.MaxPooling2D((2, 2)),
        layers.Conv2D(64, (3, 3), activation="relu"),
        layers.Flatten(),
        layers.Dense(64, activation="relu"),
        layers.Dense(10, activation="softmax")
    ])
    return model

# Recurrent Neural Network for sequence data
def CreateRNN():
    model = keras.Sequential([
        layers.LSTM(128, return_sequences=True, input_shape=(None, 1)),
        layers.LSTM(64),
        layers.Dense(1)
    ])
    return model

# Transfer Learning with pre-trained model
baseModel = keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)
baseModel.trainable = False

model = keras.Sequential([
    baseModel,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(10, activation="softmax")
])
```

### PyTorch

**PyTorch** is Facebook's deep learning framework, favored by researchers for its dynamic computation graphs and Pythonic design.

#### Key Features

- **Dynamic computation graphs**: Define-by-run paradigm
- **Pythonic**: Feels natural to Python developers
- **Research-friendly**: Rapid prototyping and experimentation
- **TorchScript**: Production deployment
- **Strong GPU acceleration**: Seamless CUDA integration
- **Active community**: Cutting-edge research implementations
- **PyTorch Lightning**: High-level training framework

#### Installation

```bash
pip install torch torchvision torchaudio
# or with UV
uv pip install torch torchvision torchaudio
```

#### PyTorch Basic Example

```python
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms

# Define model
class NeuralNet(nn.Module):
    def __init__(self):
        super(NeuralNet, self).__init__()
        self.flatten = nn.Flatten()
        self.linearRelu = nn.Sequential(
            nn.Linear(28*28, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, 10)
        )
    
    def forward(self, x):
        x = self.flatten(x)
        logits = self.linearRelu(x)
        return logits

# Load data
transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize((0.5,), (0.5,))
])

trainData = datasets.MNIST(
    root="data",
    train=True,
    download=True,
    transform=transform
)

trainLoader = DataLoader(trainData, batch_size=32, shuffle=True)

# Initialize model, loss, optimizer
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = NeuralNet().to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Training loop
model.train()
for epoch in range(5):
    runningLoss = 0.0
    for inputs, labels in trainLoader:
        inputs, labels = inputs.to(device), labels.to(device)
        
        # Forward pass
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        
        # Backward pass and optimization
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        runningLoss += loss.item()
    
    print(f"Epoch {epoch+1}, Loss: {runningLoss/len(trainLoader):.4f}")
```

#### Advanced PyTorch Patterns

```python
# Custom dataset
class CustomDataset(torch.utils.data.Dataset):
    def __init__(self, data, labels, transform=None):
        self.data = data
        self.labels = labels
        self.transform = transform
    
    def __len__(self):
        return len(self.data)
    
    def __getitem__(self, idx):
        sample = self.data[idx]
        label = self.labels[idx]
        
        if self.transform:
            sample = self.transform(sample)
        
        return sample, label

# Learning rate scheduling
scheduler = optim.lr_scheduler.ReduceLROnPlateau(
    optimizer,
    mode="min",
    factor=0.1,
    patience=5
)

# Early stopping
class EarlyStopping:
    def __init__(self, patience=7, min_delta=0):
        self.patience = patience
        self.min_delta = min_delta
        self.counter = 0
        self.bestLoss = None
        self.earlystop = False
    
    def __call__(self, valLoss):
        if self.bestLoss is None:
            self.bestLoss = valLoss
        elif valLoss > self.bestLoss - self.min_delta:
            self.counter += 1
            if self.counter >= self.patience:
                self.earlystop = True
        else:
            self.bestLoss = valLoss
            self.counter = 0
```

## Data Preprocessing

### Data Loading and Exploration

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Load data
df = pd.read_csv("data.csv")

# Explore data
print(df.info())
print(df.describe())
print(df.isnull().sum())

# Visualize distributions
df.hist(figsize=(12, 10))
plt.tight_layout()
plt.show()

# Correlation heatmap
plt.figure(figsize=(10, 8))
sns.heatmap(df.corr(), annot=True, cmap="coolwarm")
plt.show()
```

### Feature Engineering

```python
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.impute import SimpleImputer

# Handle missing values
imputer = SimpleImputer(strategy="mean")
dfImputed = pd.DataFrame(
    imputer.fit_transform(df),
    columns=df.columns
)

# Encode categorical variables
le = LabelEncoder()
df["category_encoded"] = le.fit_transform(df["category"])

# Or use one-hot encoding
dfEncoded = pd.get_dummies(df, columns=["category"], prefix="cat")

# Scale features
scaler = StandardScaler()
XScaled = scaler.fit_transform(X)

# Create new features
df["feature_ratio"] = df["feature1"] / (df["feature2"] + 1)
df["feature_interaction"] = df["feature1"] * df["feature2"]
df["feature_log"] = np.log1p(df["feature1"])
```

### Data Splitting

```python
from sklearn.model_selection import train_test_split

# Basic split
XTrain, XTest, yTrain, yTest = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y  # Maintain class distribution
)

# Train/validation/test split
XTrain, XTemp, yTrain, yTemp = train_test_split(
    X, y, test_size=0.3, random_state=42
)
XVal, XTest, yVal, yTest = train_test_split(
    XTemp, yTemp, test_size=0.5, random_state=42
)
```

## Model Training

### Cross-Validation

```python
from sklearn.model_selection import cross_val_score, KFold

# K-Fold cross-validation
kfold = KFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(
    model,
    X,
    y,
    cv=kfold,
    scoring="accuracy"
)

print(f"Cross-validation scores: {scores}")
print(f"Mean accuracy: {scores.mean():.3f} (+/- {scores.std()*2:.3f})")

# Stratified K-Fold for imbalanced data
from sklearn.model_selection import StratifiedKFold

skfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=skfold)
```

### Hyperparameter Tuning

```python
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV

# Grid search
paramGrid = {
    "n_estimators": [50, 100, 200],
    "max_depth": [None, 10, 20, 30],
    "min_samples_split": [2, 5, 10],
    "min_samples_leaf": [1, 2, 4]
}

gridSearch = GridSearchCV(
    RandomForestClassifier(random_state=42),
    paramGrid,
    cv=5,
    scoring="accuracy",
    n_jobs=-1,
    verbose=1
)

gridSearch.fit(XTrain, yTrain)
print(f"Best parameters: {gridSearch.best_params_}")
print(f"Best score: {gridSearch.best_score_:.3f}")

# Randomized search (faster for large parameter spaces)
from scipy.stats import randint, uniform

paramDist = {
    "n_estimators": randint(50, 500),
    "max_depth": [None] + list(range(10, 50)),
    "min_samples_split": randint(2, 20),
    "min_samples_leaf": randint(1, 10)
}

randomSearch = RandomizedSearchCV(
    RandomForestClassifier(random_state=42),
    paramDist,
    n_iter=100,
    cv=5,
    scoring="accuracy",
    n_jobs=-1,
    random_state=42
)

randomSearch.fit(XTrain, yTrain)
```

### Pipeline Creation

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.feature_selection import SelectKBest, f_classif

# Create pipeline
pipeline = Pipeline([
    ("imputer", SimpleImputer(strategy="mean")),
    ("scaler", StandardScaler()),
    ("feature_selection", SelectKBest(f_classif, k=10)),
    ("classifier", RandomForestClassifier(random_state=42))
])

# Fit pipeline
pipeline.fit(XTrain, yTrain)

# Predict
yPred = pipeline.predict(XTest)

# Can also use grid search with pipeline
pipelineParams = {
    "feature_selection__k": [5, 10, 15],
    "classifier__n_estimators": [50, 100, 200],
    "classifier__max_depth": [None, 10, 20]
}

gridSearch = GridSearchCV(pipeline, pipelineParams, cv=5)
gridSearch.fit(XTrain, yTrain)
```

## Model Evaluation

### Classification Metrics

```python
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix,
    classification_report,
    roc_auc_score,
    roc_curve
)

# Basic metrics
accuracy = accuracy_score(yTest, yPred)
precision = precision_score(yTest, yPred, average="weighted")
recall = recall_score(yTest, yPred, average="weighted")
f1 = f1_score(yTest, yPred, average="weighted")

print(f"Accuracy: {accuracy:.3f}")
print(f"Precision: {precision:.3f}")
print(f"Recall: {recall:.3f}")
print(f"F1-Score: {f1:.3f}")

# Confusion matrix
cm = confusion_matrix(yTest, yPred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.title("Confusion Matrix")
plt.show()

# Classification report
print(classification_report(yTest, yPred))

# ROC curve and AUC
yPredProba = model.predict_proba(XTest)[:, 1]
fpr, tpr, thresholds = roc_curve(yTest, yPredProba)
auc = roc_auc_score(yTest, yPredProba)

plt.figure(figsize=(8, 6))
plt.plot(fpr, tpr, label=f"AUC = {auc:.3f}")
plt.plot([0, 1], [0, 1], "k--")
plt.xlabel("False Positive Rate")
plt.ylabel("True Positive Rate")
plt.title("ROC Curve")
plt.legend()
plt.show()
```

### Regression Metrics

```python
from sklearn.metrics import (
    mean_squared_error,
    mean_absolute_error,
    r2_score,
    mean_absolute_percentage_error
)

# Calculate metrics
mse = mean_squared_error(yTest, yPred)
rmse = np.sqrt(mse)
mae = mean_absolute_error(yTest, yPred)
r2 = r2_score(yTest, yPred)
mape = mean_absolute_percentage_error(yTest, yPred)

print(f"MSE: {mse:.3f}")
print(f"RMSE: {rmse:.3f}")
print(f"MAE: {mae:.3f}")
print(f"R² Score: {r2:.3f}")
print(f"MAPE: {mape:.3f}")

# Residual plot
residuals = yTest - yPred
plt.figure(figsize=(10, 6))
plt.scatter(yPred, residuals, alpha=0.5)
plt.axhline(y=0, color="r", linestyle="--")
plt.xlabel("Predicted Values")
plt.ylabel("Residuals")
plt.title("Residual Plot")
plt.show()

# Actual vs Predicted
plt.figure(figsize=(10, 6))
plt.scatter(yTest, yPred, alpha=0.5)
plt.plot([yTest.min(), yTest.max()], [yTest.min(), yTest.max()], "r--", lw=2)
plt.xlabel("Actual Values")
plt.ylabel("Predicted Values")
plt.title("Actual vs Predicted")
plt.show()
```

## Advanced Techniques

### Ensemble Methods

```python
from sklearn.ensemble import (
    VotingClassifier,
    BaggingClassifier,
    AdaBoostClassifier,
    StackingClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC

# Voting ensemble
clf1 = LogisticRegression(random_state=42)
clf2 = RandomForestClassifier(random_state=42)
clf3 = SVC(probability=True, random_state=42)

votingClf = VotingClassifier(
    estimators=[("lr", clf1), ("rf", clf2), ("svc", clf3)],
    voting="soft"
)
votingClf.fit(XTrain, yTrain)

# Bagging
baggingClf = BaggingClassifier(
    DecisionTreeClassifier(),
    n_estimators=100,
    max_samples=0.8,
    random_state=42
)
baggingClf.fit(XTrain, yTrain)

# Boosting (AdaBoost)
adaClf = AdaBoostClassifier(
    n_estimators=100,
    learning_rate=1.0,
    random_state=42
)
adaClf.fit(XTrain, yTrain)

# Stacking
baseEstimators = [
    ("rf", RandomForestClassifier(n_estimators=10, random_state=42)),
    ("svc", SVC(random_state=42))
]
stackingClf = StackingClassifier(
    estimators=baseEstimators,
    final_estimator=LogisticRegression()
)
stackingClf.fit(XTrain, yTrain)
```

### Feature Importance

```python
import matplotlib.pyplot as plt

# For tree-based models
importance = model.feature_importances_
indices = np.argsort(importance)[::-1]

plt.figure(figsize=(10, 6))
plt.title("Feature Importances")
plt.bar(range(X.shape[1]), importance[indices])
plt.xticks(range(X.shape[1]), [featureNames[i] for i in indices], rotation=90)
plt.tight_layout()
plt.show()

# Permutation importance (model-agnostic)
from sklearn.inspection import permutation_importance

perm_importance = permutation_importance(
    model, XTest, yTest,
    n_repeats=10,
    random_state=42
)

sortedIdx = perm_importance.importances_mean.argsort()[::-1]
plt.figure(figsize=(10, 6))
plt.barh(range(len(sortedIdx)), perm_importance.importances_mean[sortedIdx])
plt.yticks(range(len(sortedIdx)), [featureNames[i] for i in sortedIdx])
plt.xlabel("Permutation Importance")
plt.tight_layout()
plt.show()
```

### Handling Imbalanced Data

```python
from imblearn.over_sampling import SMOTE, ADASYN
from imblearn.under_sampling import RandomUnderSampler
from imblearn.combine import SMOTETomek

# SMOTE (Synthetic Minority Over-sampling)
smote = SMOTE(random_state=42)
XResampled, yResampled = smote.fit_resample(XTrain, yTrain)

# ADASYN (Adaptive Synthetic Sampling)
adasyn = ADASYN(random_state=42)
XResampled, yResampled = adasyn.fit_resample(XTrain, yTrain)

# Combined approach
smt = SMOTETomek(random_state=42)
XResampled, yResampled = smt.fit_resample(XTrain, yTrain)

# Class weights
from sklearn.utils.class_weight import compute_class_weight

classWeights = compute_class_weight(
    "balanced",
    classes=np.unique(yTrain),
    y=yTrain
)
classWeightDict = dict(enumerate(classWeights))

model = RandomForestClassifier(
    class_weight=classWeightDict,
    random_state=42
)
```

### Dimensionality Reduction

```python
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
import umap

# PCA
pca = PCA(n_components=0.95)  # Retain 95% variance
XPca = pca.fit_transform(XScaled)
print(f"Original dimensions: {X.shape[1]}")
print(f"Reduced dimensions: {XPca.shape[1]}")

# Visualize explained variance
plt.figure(figsize=(10, 6))
plt.plot(np.cumsum(pca.explained_variance_ratio_))
plt.xlabel("Number of Components")
plt.ylabel("Cumulative Explained Variance")
plt.title("PCA Explained Variance")
plt.grid()
plt.show()

# t-SNE for visualization
tsne = TSNE(n_components=2, random_state=42)
XTsne = tsne.fit_transform(XScaled)

plt.figure(figsize=(10, 8))
plt.scatter(XTsne[:, 0], XTsne[:, 1], c=y, cmap="viridis", alpha=0.6)
plt.colorbar()
plt.title("t-SNE Visualization")
plt.show()

# UMAP (faster alternative to t-SNE)
reducer = umap.UMAP(random_state=42)
XUmap = reducer.fit_transform(XScaled)

plt.figure(figsize=(10, 8))
plt.scatter(XUmap[:, 0], XUmap[:, 1], c=y, cmap="viridis", alpha=0.6)
plt.colorbar()
plt.title("UMAP Visualization")
plt.show()
```

## Deep Learning Advanced Topics

### Custom Training Loops (PyTorch)

```python
def Train(model, trainLoader, valLoader, criterion, optimizer, epochs=10):
    history = {"train_loss": [], "val_loss": [], "val_acc": []}
    
    for epoch in range(epochs):
        # Training phase
        model.train()
        trainLoss = 0.0
        
        for inputs, labels in trainLoader:
            inputs, labels = inputs.to(device), labels.to(device)
            
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            trainLoss += loss.item()
        
        # Validation phase
        model.eval()
        valLoss = 0.0
        correct = 0
        total = 0
        
        with torch.no_grad():
            for inputs, labels in valLoader:
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                loss = criterion(outputs, labels)
                valLoss += loss.item()
                
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()
        
        # Record metrics
        avgTrainLoss = trainLoss / len(trainLoader)
        avgValLoss = valLoss / len(valLoader)
        valAccuracy = 100 * correct / total
        
        history["train_loss"].append(avgTrainLoss)
        history["val_loss"].append(avgValLoss)
        history["val_acc"].append(valAccuracy)
        
        print(f"Epoch {epoch+1}/{epochs}")
        print(f"Train Loss: {avgTrainLoss:.4f}")
        print(f"Val Loss: {avgValLoss:.4f}, Val Acc: {valAccuracy:.2f}%")
    
    return history
```

### Transfer Learning

```python
# TensorFlow/Keras
baseModel = keras.applications.ResNet50(
    weights="imagenet",
    include_top=False,
    input_shape=(224, 224, 3)
)

# Freeze base model layers
baseModel.trainable = False

# Add custom layers
model = keras.Sequential([
    baseModel,
    layers.GlobalAveragePooling2D(),
    layers.Dense(256, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(numClasses, activation="softmax")
])

# Compile and train
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

# Fine-tuning: Unfreeze some layers after initial training
baseModel.trainable = True
for layer in baseModel.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.0001),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)
```

### Data Augmentation

```python
# TensorFlow/Keras
dataAugmentation = keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.2),
    layers.RandomZoom(0.2),
    layers.RandomTranslation(0.1, 0.1),
    layers.RandomContrast(0.2)
])

# PyTorch
import torchvision.transforms as transforms

transform = transforms.Compose([
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(20),
    transforms.ColorJitter(brightness=0.2, contrast=0.2),
    transforms.RandomResizedCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
```

### Callbacks and Monitoring

```python
# TensorFlow/Keras callbacks
from tensorflow.keras.callbacks import (
    EarlyStopping,
    ModelCheckpoint,
    ReduceLROnPlateau,
    TensorBoard
)

callbacks = [
    EarlyStopping(
        monitor="val_loss",
        patience=10,
        restore_best_weights=True
    ),
    ModelCheckpoint(
        filepath="best_model.h5",
        monitor="val_accuracy",
        save_best_only=True
    ),
    ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=5,
        min_lr=1e-7
    ),
    TensorBoard(log_dir="./logs")
]

history = model.fit(
    XTrain, yTrain,
    validation_data=(XVal, yVal),
    epochs=100,
    callbacks=callbacks
)
```

## Model Deployment

### Model Serialization

```python
# Scikit-learn with joblib
import joblib

# Save model
joblib.dump(model, "model.pkl")

# Load model
loadedModel = joblib.load("model.pkl")

# TensorFlow/Keras
# Save entire model
model.save("model.h5")

# Load model
loadedModel = keras.models.load_model("model.h5")

# Save weights only
model.save_weights("model_weights.h5")

# PyTorch
# Save model
torch.save(model.state_dict(), "model.pth")

# Load model
model = NeuralNet()
model.load_state_dict(torch.load("model.pth"))
model.eval()
```

### Flask API

```python
from flask import Flask, request, jsonify
import joblib
import numpy as np

app = Flask(__name__)

# Load model at startup
model = joblib.load("model.pkl")

@app.route("/predict", methods=["POST"])
def Predict():
    try:
        data = request.get_json()
        features = np.array(data["features"]).reshape(1, -1)
        
        prediction = model.predict(features)
        probability = model.predict_proba(features)
        
        return jsonify({
            "prediction": int(prediction[0]),
            "probability": probability[0].tolist()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=5000)
```

### FastAPI (Modern Alternative)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import numpy as np

app = FastAPI()

# Load model
model = joblib.load("model.pkl")

class PredictionInput(BaseModel):
    features: list[float]

class PredictionOutput(BaseModel):
    prediction: int
    probability: list[float]

@app.post("/predict", response_model=PredictionOutput)
async def Predict(input_data: PredictionInput):
    try:
        features = np.array(input_data.features).reshape(1, -1)
        prediction = model.predict(features)
        probability = model.predict_proba(features)
        
        return PredictionOutput(
            prediction=int(prediction[0]),
            probability=probability[0].tolist()
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model and application
COPY model.pkl .
COPY app.py .

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### ONNX Export

```python
# PyTorch to ONNX
dummyInput = torch.randn(1, 3, 224, 224).to(device)

torch.onnx.export(
    model,
    dummyInput,
    "model.onnx",
    export_params=True,
    opset_version=11,
    input_names=["input"],
    output_names=["output"]
)

# Load and run ONNX model
import onnxruntime as ort

session = ort.InferenceSession("model.onnx")
input_name = session.get_inputs()[0].name
output = session.run(None, {input_name: dummyInput.cpu().numpy()})
```

## Best Practices

### Project Structure

```text
ml-project/
├── data/
│   ├── raw/
│   ├── processed/
│   └── external/
├── notebooks/
│   ├── 01-exploration.ipynb
│   ├── 02-feature-engineering.ipynb
│   └── 03-modeling.ipynb
├── src/
│   ├── __init__.py
│   ├── data/
│   │   ├── __init__.py
│   │   └── preprocessing.py
│   ├── features/
│   │   ├── __init__.py
│   │   └── engineering.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── train.py
│   │   └── predict.py
│   └── utils/
│       ├── __init__.py
│       └── helpers.py
├── tests/
│   └── test_models.py
├── models/
│   └── trained_model.pkl
├── requirements.txt
├── setup.py
└── README.md
```

### Version Control

```python
# Track model versions with MLflow
import mlflow

mlflow.start_run()

# Log parameters
mlflow.log_params({
    "n_estimators": 100,
    "max_depth": 10,
    "learning_rate": 0.01
})

# Log metrics
mlflow.log_metrics({
    "accuracy": accuracy,
    "f1_score": f1
})

# Log model
mlflow.sklearn.log_model(model, "model")

mlflow.end_run()
```

### Code Quality

```python
# Type hints
from typing import Tuple, List
import numpy.typing as npt

def PreprocessData(
    data: pd.DataFrame,
    targetColumn: str
) -> Tuple[npt.NDArray, npt.NDArray]:
    """
    Preprocess raw data for modeling.
    
    Parameters
    ----------
    data : pd.DataFrame
        Raw input data
    targetColumn : str
        Name of target column
    
    Returns
    -------
    Tuple[npt.NDArray, npt.NDArray]
        Features and target arrays
    """
    X = data.drop(columns=[targetColumn]).values
    y = data[targetColumn].values
    return X, y

# Unit tests
import pytest

def TestModelPrediction():
    model = LoadModel("model.pkl")
    testInput = np.array([[1.0, 2.0, 3.0]])
    prediction = model.predict(testInput)
    
    assert prediction is not None
    assert len(prediction) == 1
```

### Reproducibility

```python
# Set random seeds
import random
import numpy as np
import torch
import tensorflow as tf

def SetSeeds(seed: int = 42):
    """Set random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    tf.random.set_seed(seed)
    
    # Additional PyTorch settings
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

SetSeeds(42)
```

## Performance Optimization

### GPU Acceleration

```python
# TensorFlow GPU configuration
gpus = tf.config.list_physical_devices("GPU")
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(e)

# PyTorch GPU usage
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)

# Check CUDA availability
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"Device count: {torch.cuda.device_count()}")
```

### Mixed Precision Training

```python
# TensorFlow
from tensorflow.keras import mixed_precision

policy = mixed_precision.Policy("mixed_float16")
mixed_precision.set_global_policy(policy)

# PyTorch
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for inputs, labels in trainLoader:
    optimizer.zero_grad()
    
    with autocast():
        outputs = model(inputs)
        loss = criterion(outputs, labels)
    
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

### Model Quantization

```python
# TensorFlow Lite quantization
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tfliteModel = converter.convert()

with open("model.tflite", "wb") as f:
    f.write(tfliteModel)

# PyTorch quantization
quantizedModel = torch.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8
)
```

## Common Pitfalls

### Data Leakage

```python
# ❌ Avoid - scaling before splitting
XScaled = scaler.fit_transform(X)
XTrain, XTest = train_test_split(XScaled, test_size=0.2)

# ✅ Correct - fit on training data only
XTrain, XTest = train_test_split(X, test_size=0.2)
XTrain = scaler.fit_transform(XTrain)
XTest = scaler.transform(XTest)
```

### Overfitting

```python
# Signs of overfitting
# - High training accuracy, low validation accuracy
# - Large gap between train and validation loss

# Solutions:
# 1. Regularization
model = RandomForestClassifier(
    max_depth=10,  # Limit tree depth
    min_samples_leaf=5,  # Require minimum samples per leaf
    max_features="sqrt"  # Random feature subset
)

# 2. Dropout (neural networks)
model = keras.Sequential([
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(64, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(10, activation="softmax")
])

# 3. Early stopping
# 4. More training data
# 5. Cross-validation
```

## Resources and References

### Essential Libraries

- **[scikit-learn](https://scikit-learn.org/)**: Traditional ML algorithms
- **[TensorFlow](https://www.tensorflow.org/)**: Deep learning framework
- **[PyTorch](https://pytorch.org/)**: Research-focused deep learning
- **[XGBoost](https://xgboost.readthedocs.io/)**: Gradient boosting
- **[LightGBM](https://lightgbm.readthedocs.io/)**: Fast gradient boosting
- **[CatBoost](https://catboost.ai/)**: Categorical data boosting

### Data Processing

- **[pandas](https://pandas.pydata.org/)**: Data manipulation
- **[NumPy](https://numpy.org/)**: Numerical computing
- **[Polars](https://www.pola.rs/)**: Fast DataFrame library
- **[Dask](https://dask.org/)**: Parallel computing for large datasets

### Visualization

- **[Matplotlib](https://matplotlib.org/)**: Basic plotting
- **[Seaborn](https://seaborn.pydata.org/)**: Statistical visualization
- **[Plotly](https://plotly.com/python/)**: Interactive plots
- **[Altair](https://altair-viz.github.io/)**: Declarative visualization

### Model Tracking

- **[MLflow](https://mlflow.org/)**: ML lifecycle management
- **[Weights & Biases](https://wandb.ai/)**: Experiment tracking
- **[Neptune.ai](https://neptune.ai/)**: ML metadata store
- **[DVC](https://dvc.org/)**: Data version control

### AutoML

- **[Auto-sklearn](https://automl.github.io/auto-sklearn/)**: Automated sklearn
- **[TPOT](https://epistasislab.github.io/tpot/)**: Genetic programming AutoML
- **[H2O AutoML](https://docs.h2o.ai/h2o/latest-stable/h2o-docs/automl.html)**: Enterprise AutoML
- **[PyCaret](https://pycaret.org/)**: Low-code ML library

### Learning Resources

- **[Machine Learning Mastery](https://machinelearningmastery.com/)**: Practical tutorials
- **[Kaggle Learn](https://www.kaggle.com/learn)**: Interactive courses
- **[Fast.ai](https://www.fast.ai/)**: Deep learning for coders
- **[Coursera ML Courses](https://www.coursera.org/browse/data-science/machine-learning)**: University courses
- **[Papers with Code](https://paperswithcode.com/)**: Latest research with implementations

## See Also

- [Python Data Science](../data-science/index.md)
- [NumPy and Scientific Computing](../data-science/numpy.md)
- [Pandas for Data Analysis](../data-science/pandas.md)
- [Python Virtual Environments](../package-management/virtualenv.md)
- [Package Management with UV](../package-management/uv.md)
