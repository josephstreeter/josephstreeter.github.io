---
title: "Language Models"
description: "N-gram models, transformers, BERT and its variants, and GPT-family models"
author: "Joseph Streeter"
tags: ["nlp", "python", "language models", "transformers", "bert", "gpt"]
category: "development"
last_updated: "2026-08-01"
---
## Language Models

### N-gram Models

Statistical language models based on word sequences:

```python
from nltk import ngrams
from nltk.tokenize import word_tokenize
from collections import Counter, defaultdict
import random

# Sample text corpus
text = """
Natural language processing is a subfield of artificial intelligence.
Machine learning algorithms learn from data and improve over time.
Deep learning models use neural networks with multiple layers.
Natural language understanding is a key component of NLP.
"""

# Tokenize
tokens = word_tokenize(text.lower())

# Generate n-grams
bigrams = list(ngrams(tokens, 2))
trigrams = list(ngrams(tokens, 3))

print("Sample Bigrams:")
for bg in bigrams[:10]:
    print(f"  {bg}")

print("\nSample Trigrams:")
for tg in trigrams[:10]:
    print(f"  {tg}")

# Build n-gram model
class NGramModel:
    def __init__(self, n):
        self.n = n
        self.ngram_freq = Counter()
        self.context_freq = Counter()
        
    def train(self, tokens):
        """Train n-gram model on tokens."""
        for i in range(len(tokens) - self.n + 1):
            ngram = tuple(tokens[i:i + self.n])
            context = ngram[:-1]
            
            self.ngram_freq[ngram] += 1
            self.context_freq[context] += 1
    
    def probability(self, ngram):
        """Calculate probability of n-gram."""
        if len(ngram) != self.n:
            raise ValueError(f"Expected {self.n}-gram")
        
        context = ngram[:-1]
        
        if self.context_freq[context] == 0:
            return 0
        
        return self.ngram_freq[ngram] / self.context_freq[context]
    
    def generate_next(self, context, num_words=5):
        """Generate next words given context."""
        candidates = []
        
        for ngram, count in self.ngram_freq.items():
            if ngram[:-1] == context:
                candidates.append((ngram[-1], count))
        
        if not candidates:
            return None
        
        # Sort by frequency
        candidates.sort(key=lambda x: x[1], reverse=True)
        return [word for word, _ in candidates[:num_words]]

# Train bigram model
bigram_model = NGramModel(2)
bigram_model.train(tokens)

# Calculate probabilities
test_bigrams = [('natural', 'language'), ('machine', 'learning'), ('deep', 'learning')]

print("\nBigram Probabilities:")
for bg in test_bigrams:
    prob = bigram_model.probability(bg)
    print(f"  P({bg[1]}|{bg[0]}) = {prob:.4f}")

# Generate next words
context = ('natural',)
next_words = bigram_model.generate_next(context)
print(f"\nPossible words after '{context[0]}': {next_words}")

# Text generation
def generate_text(model, start_word, length=10):
    """Generate text using n-gram model."""
    result = [start_word]
    
    for _ in range(length - 1):
        context = tuple(result[-(model.n-1):])
        next_words = model.generate_next(context)
        
        if not next_words:
            break
        
        result.append(next_words[0])
    
    return ' '.join(result)

generated = generate_text(bigram_model, 'natural', length=15)
print(f"\nGenerated text: {generated}")
```

Smoothing for better probability estimates:

```python
import math

class SmoothedNGramModel:
    """N-gram model with Laplace smoothing."""
    
    def __init__(self, n, vocabulary_size, smoothing=1.0):
        self.n = n
        self.vocabulary_size = vocabulary_size
        self.smoothing = smoothing  # Laplace smoothing parameter
        self.ngram_freq = Counter()
        self.context_freq = Counter()
    
    def train(self, tokens):
        for i in range(len(tokens) - self.n + 1):
            ngram = tuple(tokens[i:i + self.n])
            context = ngram[:-1]
            self.ngram_freq[ngram] += 1
            self.context_freq[context] += 1
    
    def probability(self, ngram):
        """Calculate smoothed probability."""
        context = ngram[:-1]
        
        numerator = self.ngram_freq[ngram] + self.smoothing
        denominator = self.context_freq[context] + (self.smoothing * self.vocabulary_size)
        
        return numerator / denominator
    
    def perplexity(self, test_tokens):
        """Calculate perplexity on test data."""
        log_prob_sum = 0
        n = 0
        
        for i in range(len(test_tokens) - self.n + 1):
            ngram = tuple(test_tokens[i:i + self.n])
            prob = self.probability(ngram)
            
            if prob > 0:
                log_prob_sum += math.log2(prob)
                n += 1
        
        if n == 0:
            return float('inf')
        
        return 2 ** (-log_prob_sum / n)

# Train with smoothing
vocab_size = len(set(tokens))
smoothed_model = SmoothedNGramModel(2, vocab_size, smoothing=1.0)
smoothed_model.train(tokens)

# Compare probabilities
test_bg = ('natural', 'language')
prob_unsmoothed = bigram_model.probability(test_bg)
prob_smoothed = smoothed_model.probability(test_bg)

print(f"\nUnsmoothed P({test_bg}): {prob_unsmoothed:.4f}")
print(f"Smoothed P({test_bg}): {prob_smoothed:.4f}")
```

### Transformer Models

State-of-the-art neural language models:

```python
from transformers import AutoTokenizer, AutoModel, AutoModelForCausalLM
import torch

# Load pre-trained transformer
model_name = "gpt2"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)

# Generate text
def generate_text(prompt, max_length=50, temperature=0.7):
    """Generate text using transformer model."""
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            temperature=temperature,
            num_return_sequences=1,
            no_repeat_ngram_size=2,
            do_sample=True,
            top_k=50,
            top_p=0.95
        )
    
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return generated_text

prompt = "Natural language processing is"
generated = generate_text(prompt, max_length=50)
print(f"Prompt: {prompt}")
print(f"Generated: {generated}")

# Calculate perplexity
def calculate_perplexity(text):
    """Calculate perplexity of text under model."""
    encodings = tokenizer(text, return_tensors="pt")
    
    max_length = model.config.n_positions
    stride = 512
    
    nlls = []
    for i in range(0, encodings.input_ids.size(1), stride):
        begin_loc = max(i + stride - max_length, 0)
        end_loc = min(i + stride, encodings.input_ids.size(1))
        trg_len = end_loc - i
        
        input_ids = encodings.input_ids[:, begin_loc:end_loc]
        target_ids = input_ids.clone()
        target_ids[:, :-trg_len] = -100
        
        with torch.no_grad():
            outputs = model(input_ids, labels=target_ids)
            neg_log_likelihood = outputs.loss * trg_len
        
        nlls.append(neg_log_likelihood)
    
    ppl = torch.exp(torch.stack(nlls).sum() / end_loc)
    return ppl.item()

test_text = "The quick brown fox jumps over the lazy dog"
perplexity = calculate_perplexity(test_text)
print(f"\nPerplexity of '{test_text}': {perplexity:.2f}")
```

### BERT and Variants

Bidirectional encoder for language understanding:

```python
from transformers import BertTokenizer, BertModel, BertForMaskedLM
import torch
import numpy as np

# Load BERT
model_name = "bert-base-uncased"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertModel.from_pretrained(model_name)

# Get contextualized embeddings
def get_bert_embeddings(text):
    """Get BERT embeddings for text."""
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True)
    
    with torch.no_grad():
        outputs = model(**inputs)
    
    # Use [CLS] token embedding as sentence representation
    cls_embedding = outputs.last_hidden_state[:, 0, :]
    
    # Or use mean pooling
    mean_embedding = outputs.last_hidden_state.mean(dim=1)
    
    return {
        'cls': cls_embedding.numpy(),
        'mean': mean_embedding.numpy(),
        'all_tokens': outputs.last_hidden_state.numpy()
    }

text = "Natural language processing with BERT"
embeddings = get_bert_embeddings(text)

print(f"CLS embedding shape: {embeddings['cls'].shape}")
print(f"Mean embedding shape: {embeddings['mean'].shape}")

# Masked language modeling
masked_lm_model = BertForMaskedLM.from_pretrained(model_name)

def predict_masked_word(text):
    """Predict masked word in text."""
    inputs = tokenizer(text, return_tensors="pt")
    mask_token_index = torch.where(inputs["input_ids"] == tokenizer.mask_token_id)[1]
    
    with torch.no_grad():
        outputs = masked_lm_model(**inputs)
    
    logits = outputs.logits
    mask_token_logits = logits[0, mask_token_index, :]
    
    # Get top predictions
    top_tokens = torch.topk(mask_token_logits, 5, dim=1).indices[0].tolist()
    
    predictions = [tokenizer.decode([token]) for token in top_tokens]
    return predictions

masked_text = "The capital of France is [MASK]."
predictions = predict_masked_word(masked_text)

print(f"\nText: {masked_text}")
print(f"Top predictions: {predictions}")

# Sentence similarity
from sklearn.metrics.pairwise import cosine_similarity

def calculate_similarity(text1, text2):
    """Calculate semantic similarity between texts."""
    emb1 = get_bert_embeddings(text1)['cls']
    emb2 = get_bert_embeddings(text2)['cls']
    
    similarity = cosine_similarity(emb1, emb2)[0][0]
    return similarity

sentences = [
    "The cat sits on the mat",
    "A feline rests on a rug",
    "Dogs are playing in the park"
]

print("\nSentence Similarities:")
for i, sent1 in enumerate(sentences):
    for j, sent2 in enumerate(sentences):
        if i < j:
            sim = calculate_similarity(sent1, sent2)
            print(f"  '{sent1}' <-> '{sent2}': {sim:.4f}")
```

### GPT Models

Generative pre-trained transformers:

```python
from transformers import GPT2LMHeadModel, GPT2Tokenizer, pipeline
import torch

# Load GPT-2
model_name = "gpt2"
tokenizer = GPT2Tokenizer.from_pretrained(model_name)
model = GPT2LMHeadModel.from_pretrained(model_name)

# Text generation with control
def generate_with_control(prompt, max_length=100, temperature=0.8, top_p=0.9):
    """Generate text with generation parameters."""
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            temperature=temperature,  # Higher = more random
            top_p=top_p,  # Nucleus sampling
            do_sample=True,
            num_return_sequences=3  # Generate multiple outputs
        )
    
    generated_texts = [tokenizer.decode(output, skip_special_tokens=True)
                      for output in outputs]
    return generated_texts

prompt = "In the future, artificial intelligence will"
generated_texts = generate_with_control(prompt, max_length=50)

print(f"Prompt: {prompt}\n")
for i, text in enumerate(generated_texts, 1):
    print(f"Generation {i}:")
    print(f"{text}\n")

# Using pipeline for convenience
generator = pipeline('text-generation', model='gpt2')
results = generator(
    "Natural language processing is",
    max_length=50,
    num_return_sequences=2,
    temperature=0.7
)

print("\nPipeline Results:")
for i, result in enumerate(results, 1):
    print(f"{i}. {result['generated_text']}")

# Conditional generation
def generate_continuation(context, next_phrase, max_length=50):
    """Generate text conditioned on context."""
    prompt = f"{context} {next_phrase}"
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            num_beams=5,  # Beam search
            early_stopping=True,
            no_repeat_ngram_size=3
        )
    
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

context = "Machine learning is a field of study that"
continuation = generate_continuation(context, "focuses on")
print(f"\nContext: {context}")
print(f"Continuation: {continuation}")
```

Compare language model performance:

```python
import matplotlib.pyplot as plt
from transformers import pipeline

# Load multiple models
models = {
    'GPT-2 Small': 'gpt2',
    'GPT-2 Medium': 'gpt2-medium',
    'DistilGPT-2': 'distilgpt2'
}

prompt = "Artificial intelligence is\"

print("Comparing Language Models:")

for model_name, model_id in models.items():
    generator = pipeline('text-generation', model=model_id)
    result = generator(prompt, max_length=30, num_return_sequences=1)[0]
    
    print(f"{model_name}:")
    print(f"  {result['generated_text']}")
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
