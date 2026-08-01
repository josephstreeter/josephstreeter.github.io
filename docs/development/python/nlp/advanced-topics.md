---
title: "Advanced Topics"
description: "Transfer learning, fine-tuning pre-trained models, multilingual and low-resource NLP"
author: "Joseph Streeter"
tags: ["nlp", "python", "transfer learning", "fine-tuning", "multilingual"]
category: "development"
last_updated: "2026-08-01"
---
## Advanced Topics

### Transfer Learning

Leverage pre-trained models for new tasks:

```python
from transformers import BertTokenizer, BertForSequenceClassification
from transformers import Trainer, TrainingArguments
import torch
from torch.utils.data import Dataset
import pandas as pd

class TextClassificationDataset(Dataset):
    """Custom dataset for text classification."""
    
    def __init__(self, texts, labels, tokenizer, max_length=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length
    
    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        
        encoding = self.tokenizer(
            text,
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        
        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'labels': torch.tensor(label, dtype=torch.long)
        }

# Sample data
texts = [
    "This product is amazing!",
    "Terrible experience, very disappointed.",
    "Good quality for the price.",
    "Waste of money, do not buy."
]
labels = [1, 0, 1, 0]  # 1=positive, 0=negative

# Load pre-trained model
model_name = "bert-base-uncased"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertForSequenceClassification.from_pretrained(
    model_name,
    num_labels=2  # Binary classification
)

# Create dataset
dataset = TextClassificationDataset(texts, labels, tokenizer)

# Training arguments
training_args = TrainingArguments(
    output_dir='./results',
    num_train_epochs=3,
    per_device_train_batch_size=8,
    warmup_steps=100,
    weight_decay=0.01,
    logging_dir='./logs',
)

# Create trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset
)

# Train (fine-tune)
trainer.train()

# Predict
test_text = "This is fantastic!"
inputs = tokenizer(test_text, return_tensors="pt", padding=True, truncation=True)

with torch.no_grad():
    outputs = model(**inputs)
    prediction = torch.argmax(outputs.logits, dim=1).item()

print(f"Text: {test_text}")
print(f"Prediction: {'Positive' if prediction == 1 else 'Negative'}")
```

### Fine-tuning Pre-trained Models

Adapt models to specific domains:

```python
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer
)
from datasets import load_dataset
import numpy as np
from sklearn.metrics import accuracy_score, f1_score

# Load dataset
dataset = load_dataset("imdb")

# Load model and tokenizer
model_name = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(
    model_name,
    num_labels=2
)

# Tokenize dataset
def tokenize_function(examples):
    return tokenizer(
        examples['text'],
        padding='max_length',
        truncation=True,
        max_length=512
    )

tokenized_datasets = dataset.map(tokenize_function, batched=True)

# Prepare train and validation sets
train_dataset = tokenized_datasets['train'].shuffle(seed=42).select(range(1000))
eval_dataset = tokenized_datasets['test'].shuffle(seed=42).select(range(500))

# Define metrics
def compute_metrics(eval_pred):
    predictions, labels = eval_pred
    predictions = np.argmax(predictions, axis=1)
    
    return {
        'accuracy': accuracy_score(labels, predictions),
        'f1': f1_score(labels, predictions, average='weighted')
    }

# Training arguments
training_args = TrainingArguments(
    output_dir='./results',
    evaluation_strategy='epoch',
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=3,
    weight_decay=0.01,
    save_strategy='epoch',
    load_best_model_at_end=True,
)

# Initialize trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    compute_metrics=compute_metrics,
)

# Fine-tune
trainer.train()

# Evaluate
eval_results = trainer.evaluate()
print(f"Evaluation Results: {eval_results}")

# Save model
model.save_pretrained('./fine_tuned_model')
tokenizer.save_pretrained('./fine_tuned_model')
```

### Multi-lingual NLP

Work with multiple languages:

```python
from transformers import pipeline, AutoTokenizer, AutoModel
import torch

# Multilingual BERT
model_name = "bert-base-multilingual-cased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# Process multiple languages
texts = {
    'English': "Hello, how are you?",
    'Spanish': "Hola, ¿cómo estás?",
    'French': "Bonjour, comment allez-vous?",
    'German': "Hallo, wie geht es dir?",
    'Chinese': "你好，你好吗？"
}

print("Multilingual Embeddings:")
for lang, text in texts.items():
    inputs = tokenizer(text, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs)
    embedding = outputs.last_hidden_state.mean(dim=1)
    print(f"{lang:10} -> Embedding shape: {embedding.shape}")

# Cross-lingual NER
ner_pipeline = pipeline(
    "ner",
    model="xlm-roberta-large-finetuned-conll03-english",
    aggregation_strategy="simple"
)

multilingual_texts = [
    "Apple Inc. was founded by Steve Jobs in California.",
    "Apple Inc. fue fundada por Steve Jobs en California.",
    "Apple Inc. a été fondée par Steve Jobs en Californie."
]

for text in multilingual_texts:
    entities = ner_pipeline(text)
    print(f"\nText: {text}")
    for ent in entities:
        print(f"  {ent['word']} -> {ent['entity_group']} ({ent['score']:.4f})")
```

### Low-Resource Languages

Techniques for languages with limited data:

```python
from transformers import MarianMTModel, MarianTokenizer

# Back-translation for data augmentation
def back_translate(text, src_lang='en', pivot_lang='fr'):
    """Augment data using back-translation."""
    # Translate to pivot language
    forward_model = f'Helsinki-NLP/opus-mt-{src_lang}-{pivot_lang}'
    fwd_tokenizer = MarianTokenizer.from_pretrained(forward_model)
    fwd_model = MarianMTModel.from_pretrained(forward_model)
    
    inputs = fwd_tokenizer(text, return_tensors="pt", padding=True)
    with torch.no_grad():
        translated = fwd_model.generate(**inputs)
    pivot_text = fwd_tokenizer.decode(translated[0], skip_special_tokens=True)
    
    # Translate back to source
    back_model = f'Helsinki-NLP/opus-mt-{pivot_lang}-{src_lang}'
    back_tokenizer = MarianTokenizer.from_pretrained(back_model)
    back_model = MarianMTModel.from_pretrained(back_model)
    
    inputs = back_tokenizer(pivot_text, return_tensors="pt", padding=True)
    with torch.no_grad():
        back_translated = back_model.generate(**inputs)
    final_text = back_tokenizer.decode(back_translated[0], skip_special_tokens=True)
    
    return final_text, pivot_text

original = "Machine learning is fascinating"
back_translated, pivot = back_translate(original)

print(f"Original:        {original}")
print(f"Pivot (French):  {pivot}")
print(f"Back-translated: {back_translated}")

# Cross-lingual transfer
print("\nCross-lingual transfer example:")
print("Train on high-resource language (English)")
print("Test on low-resource language using multilingual model")
```

## Related Topics

- [NLP Overview](index.md)
- [Text Preprocessing](preprocessing.md)
- [Feature Extraction](feature-extraction.md)
- [Core NLP Tasks](core-tasks.md)
- [Text Classification](text-classification.md)
- [Information Extraction](information-extraction.md)
- [Topic Modeling](topic-modeling.md)
- [Language Models](language-models.md)
- [Sequence-to-Sequence Tasks](seq2seq.md)
- [Advanced Topics](advanced-topics.md)
- [Working with Libraries](libraries.md)
- [Performance and Best Practices](performance-and-practices.md)
- [Real-World Applications](applications.md)
