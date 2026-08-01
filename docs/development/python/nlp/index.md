---
title: "Natural Language Processing"
description: "Natural language processing in Python: preprocessing, feature extraction, core tasks, language models, and the spaCy/Transformers/NLTK ecosystem"
author: "Joseph Streeter"
tags: ["nlp", "python", "machine learning", "text"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-08-01"
---
## Natural Language Processing

Natural language processing covers everything from splitting a string into words to running a transformer over a document. This section works up from preprocessing to language models, with runnable examples throughout.

| Page | Covers |
|------|--------|
| [Text Preprocessing](preprocessing.md) | Cleaning and normalization, tokenization, stopword removal, stemming and lemmatization |
| [Feature Extraction](feature-extraction.md) | Bag of words, TF-IDF, word2vec/GloVe and other embeddings |
| [Core NLP Tasks](core-tasks.md) | POS tagging, NER, dependency parsing, coreference resolution |
| [Text Classification](text-classification.md) | Sentiment analysis, spam detection, intent classification |
| [Information Extraction](information-extraction.md) | Entity extraction, relationship extraction, event extraction |
| [Topic Modeling](topic-modeling.md) | Latent Dirichlet Allocation, non-negative matrix factorization |
| [Language Models](language-models.md) | N-gram models, transformer architecture, BERT variants, GPT models |
| [Sequence-to-Sequence Tasks](seq2seq.md) | Machine translation, summarization, question answering |
| [Advanced Topics](advanced-topics.md) | Transfer learning, fine-tuning, multilingual NLP, low-resource languages |
| [Working with Libraries](libraries.md) | spaCy pipelines, Transformers, NLTK |
| [Performance and Best Practices](performance-and-practices.md) | Batching, caching, model size trade-offs, and general best practices |
| [Real-World Applications](applications.md) | Worked applications combining the techniques from the preceding pages |

## Overview

Natural Language Processing (NLP) is a field of artificial intelligence that focuses on the interaction between computers and human language. Python has become the dominant language for NLP due to its rich ecosystem of libraries and frameworks for text processing, linguistic analysis, and language understanding.

## Key Concepts

- **Tokenization**: Breaking text into words, sentences, or subwords
- **Part-of-Speech Tagging**: Identifying grammatical roles of words
- **Named Entity Recognition**: Extracting entities like people, places, organizations
- **Sentiment Analysis**: Determining emotional tone of text
- **Topic Modeling**: Discovering abstract topics in document collections
- **Language Models**: Predicting and generating natural language text

## Popular NLP Libraries

### Core Libraries

- **NLTK**: Natural Language Toolkit for fundamental NLP tasks
- **spaCy**: Industrial-strength NLP with pre-trained models
- **Transformers**: Hugging Face library for state-of-the-art models
- **Gensim**: Topic modeling and document similarity
- **TextBlob**: Simplified API for common NLP tasks

### Deep Learning Frameworks

- **PyTorch**: Flexible framework for custom NLP models
- **TensorFlow**: Comprehensive ML platform with Keras integration
- **JAX**: High-performance numerical computing

## Getting Started

### Installation

Install the essential NLP libraries:

```bash
# Core NLP libraries
pip install nltk spacy textblob

# Deep learning and transformers
pip install transformers torch

# Topic modeling and similarity
pip install gensim

# Data manipulation
pip install pandas numpy scikit-learn
```

Download required language models:

```python
# Download NLTK data
import nltk
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('maxent_ne_chunker')
nltk.download('words')
nltk.download('stopwords')
nltk.download('wordnet')

# Download spaCy English model
# Run in terminal:
# python -m spacy download en_core_web_sm
```

### Basic Text Processing

Start with fundamental text operations:

```python
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize

# Sample text
text = """Natural language processing (NLP) is a subfield of linguistics, 
computer science, and artificial intelligence. It focuses on the interactions 
between computers and human language."""

# Sentence tokenization
sentences = sent_tokenize(text)
print(f"Sentences: {len(sentences)}")
# Output: Sentences: 2

# Word tokenization
words = word_tokenize(text)
print(f"Words: {len(words)}")
# Output: Words: 28

# Basic statistics
print(f"Characters: {len(text)}")
print(f"Unique words: {len(set(words))}")
```

Simple text cleaning:

```python
import re
import string

def clean_text(text):
    """Clean and normalize text."""
    # Convert to lowercase
    text = text.lower()
    
    # Remove URLs
    text = re.sub(r'http\S+|www\S+', '', text)
    
    # Remove email addresses
    text = re.sub(r'\S+@\S+', '', text)
    
    # Remove punctuation
    text = text.translate(str.maketrans('', '', string.punctuation))
    
    # Remove extra whitespace
    text = ' '.join(text.split())
    
    return text

# Example usage
raw_text = "Check out https://example.com! Email: user@example.com"
cleaned = clean_text(raw_text)
print(cleaned)
# Output: check out email
```

Working with spaCy for advanced processing:

```python
import spacy

# Load English model
nlp = spacy.load("en_core_web_sm")

# Process text
doc = nlp("Apple is looking at buying U.K. startup for $1 billion")

# Extract tokens and their properties
for token in doc:
    print(f"{token.text:12} {token.pos_:8} {token.dep_:10} {token.lemma_}")

# Output:
# Apple        PROPN    nsubj      Apple
# is           AUX      aux        be
# looking      VERB     ROOT       look
# at           ADP      prep       at
# buying       VERB     pcomp      buy
# U.K.         PROPN    dobj       U.K.
# startup      NOUN     dobj       startup
# for          ADP      prep       for
# $            SYM      quantmod   $
# 1            NUM      compound   1
# billion      NUM      pobj       billion
```

## See Also

- [Python Overview](../index.md)
- [Machine Learning](../machine-learning/index.md)
- [Neural Networks](../algorithms/neural-networks.md)
- [Deep Learning](../deep-learning/index.md)

## Resources

- [spaCy Documentation](https://spacy.io/)
- [Hugging Face Transformers](https://huggingface.co/docs/transformers/)
- [NLTK Documentation](https://www.nltk.org/)
- [Stanford NLP Course](https://web.stanford.edu/class/cs224n/)
