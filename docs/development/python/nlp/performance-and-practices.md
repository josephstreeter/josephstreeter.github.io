---
title: "Performance and Best Practices"
description: "Optimizing NLP pipelines for speed and memory, and the practices that keep results reliable"
author: "Joseph Streeter"
tags: ["nlp", "python", "performance", "optimization", "best practices"]
category: "development"
last_updated: "2026-08-01"
---
## Performance and Best Practices

NLP pipelines are usually bound by model size and per-document overhead. These are
the optimizations that matter, and the practices that keep results reproducible.

## Performance Optimization

Optimize NLP pipelines for speed and efficiency:

```python
import time
import multiprocessing as mp
from functools import partial
import torch

# Batch processing
def process_texts_batch(texts, model, tokenizer, batch_size=32):
    """Process texts in batches for better performance."""
    results = []
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True)
        
        with torch.no_grad():
            outputs = model(**inputs)
        
        results.extend(outputs.logits.argmax(dim=1).tolist())
    
    return results

# Parallel processing with spaCy
import spacy

nlp = spacy.load("en_core_web_sm")

def process_parallel(texts, n_process=4):
    """Process texts in parallel."""
    results = []
    
    for doc in nlp.pipe(texts, n_process=n_process, batch_size=50):
        results.append({
            'text': doc.text,
            'entities': [(ent.text, ent.label_) for ent in doc.ents],
            'tokens': len(doc)
        })
    
    return results

# Test parallel processing
texts = [f"This is test document number {i}" for i in range(1000)]

# Serial processing
start = time.time()
for text in texts:
    doc = nlp(text)
serial_time = time.time() - start

# Parallel processing
start = time.time()
results = process_parallel(texts, n_process=4)
parallel_time = time.time() - start

print(f"Serial processing: {serial_time:.2f}s")
print(f"Parallel processing: {parallel_time:.2f}s")
print(f"Speedup: {serial_time/parallel_time:.2f}x")

# Model quantization
from transformers import AutoModelForSequenceClassification, AutoTokenizer

# Load model
model_name = "distilbert-base-uncased"
model = AutoModelForSequenceClassification.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Dynamic quantization (reduce model size)
quantized_model = torch.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8
)

print(f"\nOriginal model size: {sum(p.numel() for p in model.parameters()) / 1e6:.2f}M parameters")
print(f"Quantized model size: {sum(p.numel() for p in quantized_model.parameters()) / 1e6:.2f}M parameters")

# Caching for repeated operations
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_tokenize(text):
    """Cache tokenization results."""
    return tokenizer(text, return_tensors="pt")

# GPU acceleration
if torch.cuda.is_available():
    device = torch.device("cuda")
    model = model.to(device)
    print(f"\nUsing GPU: {torch.cuda.get_device_name(0)}")
else:
    device = torch.device("cpu")
    print("\nUsing CPU")

# Efficient memory management
def process_large_dataset(texts, batch_size=32):
    """Process large datasets efficiently."""
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = model(**inputs)
        
        # Process batch and clear memory
        predictions = outputs.logits.argmax(dim=1).cpu().numpy()
        
        # Explicitly delete to free memory
        del inputs, outputs
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
        
        yield predictions

# Model pruning
from torch.nn.utils import prune

def prune_model(model, amount=0.3):
    """Prune model weights."""
    for name, module in model.named_modules():
        if isinstance(module, torch.nn.Linear):
            prune.l1_unstructured(module, name='weight', amount=amount)
    return model

# Vocabulary optimization
def optimize_vocabulary(tokenizer, texts, top_k=10000):
    """Reduce vocabulary size based on frequency."""
    from collections import Counter
    
    # Count token frequencies
    token_freq = Counter()
    for text in texts:
        tokens = tokenizer.tokenize(text)
        token_freq.update(tokens)
    
    # Keep most frequent tokens
    top_tokens = [token for token, _ in token_freq.most_common(top_k)]
    
    return top_tokens
```

## Best Practices

Guidelines for production NLP systems:

```python
import logging
from typing import List, Dict, Optional
from dataclasses import dataclass
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Type annotations and data classes
@dataclass
class ProcessedDocument:
    """Structured document representation."""
    text: str
    tokens: List[str]
    entities: List[Dict[str, str]]
    sentiment: Optional[str] = None
    metadata: Dict = None

class NLPPipeline:
    """Production-ready NLP pipeline."""
    
    def __init__(self, model_name: str):
        """Initialize pipeline with model."""
        self.model_name = model_name
        self.model = None
        self.tokenizer = None
        self._load_model()
    
    def _load_model(self) -> None:
        """Load model with error handling."""
        try:
            from transformers import AutoModelForSequenceClassification, AutoTokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForSequenceClassification.from_pretrained(self.model_name)
            logger.info(f"Successfully loaded model: {self.model_name}")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def process(self, text: str) -> ProcessedDocument:
        """Process single document."""
        if not text or not isinstance(text, str):
            raise ValueError("Input must be non-empty string")
        
        try:
            # Tokenize
            tokens = self.tokenizer.tokenize(text)
            
            # Process
            result = ProcessedDocument(
                text=text,
                tokens=tokens,
                entities=[],
                metadata={'processed_by': self.model_name}
            )
            
            logger.debug(f"Processed document with {len(tokens)} tokens")
            return result
            
        except Exception as e:
            logger.error(f"Error processing document: {e}")
            raise
    
    def process_batch(self, texts: List[str], batch_size: int = 32) -> List[ProcessedDocument]:
        """Process multiple documents efficiently."""
        results = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            try:
                batch_results = [self.process(text) for text in batch]
                results.extend(batch_results)
            except Exception as e:
                logger.error(f"Error processing batch {i//batch_size}: {e}")
                continue
        
        return results

# Input validation
def validate_text_input(text: str, max_length: int = 512) -> bool:
    """Validate text input."""
    if not text or not isinstance(text, str):
        return False
    
    if len(text) > max_length:
        logger.warning(f"Text exceeds max length: {len(text)} > {max_length}")
        return False
    
    return True

# Error handling
class NLPError(Exception):
    """Base exception for NLP errors."""
    pass

class TokenizationError(NLPError):
    """Error during tokenization."""
    pass

class ModelError(NLPError):
    """Error related to model operations."""
    pass

def safe_process(text: str, processor) -> Optional[Dict]:
    """Process text with error handling."""
    try:
        return processor(text)
    except TokenizationError as e:
        logger.error(f"Tokenization failed: {e}")
        return None
    except ModelError as e:
        logger.error(f"Model error: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return None

# Configuration management
class Config:
    """Configuration management."""
    
    def __init__(self, config_path: str):
        self.config = self._load_config(config_path)
    
    def _load_config(self, path: str) -> Dict:
        """Load configuration from file."""
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning(f"Config file not found: {path}. Using defaults.")
            return self._default_config()
    
    def _default_config(self) -> Dict:
        """Default configuration."""
        return {
            'model_name': 'bert-base-uncased',
            'max_length': 512,
            'batch_size': 32,
            'device': 'cpu'
        }
    
    def get(self, key: str, default=None):
        """Get configuration value."""
        return self.config.get(key, default)

# Testing
import unittest

class TestNLPPipeline(unittest.TestCase):
    """Test NLP pipeline."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.pipeline = NLPPipeline('distilbert-base-uncased')
    
    def test_process_valid_text(self):
        """Test processing valid text."""
        text = "This is a test."
        result = self.pipeline.process(text)
        self.assertIsInstance(result, ProcessedDocument)
        self.assertEqual(result.text, text)
    
    def test_process_empty_text(self):
        """Test processing empty text."""
        with self.assertRaises(ValueError):
            self.pipeline.process("")
    
    def test_batch_processing(self):
        """Test batch processing."""
        texts = ["Text 1", "Text 2", "Text 3"]
        results = self.pipeline.process_batch(texts)
        self.assertEqual(len(results), len(texts))

# Documentation
def process_document(text: str, 
                    options: Dict[str, any] = None) -> ProcessedDocument:
    """
    Process a text document through NLP pipeline.
    
    Args:
        text (str): Input text to process
        options (Dict[str, any], optional): Processing options
            - max_length (int): Maximum text length
            - include_entities (bool): Extract named entities
            - include_sentiment (bool): Analyze sentiment
    
    Returns:
        ProcessedDocument: Processed document with annotations
    
    Raises:
        ValueError: If text is empty or invalid
        ModelError: If model processing fails
    
    Examples:
        >>> doc = process_document("Hello world")
        >>> print(doc.tokens)
        ['hello', 'world']
    """
    pass
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
