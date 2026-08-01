---
title: "Sequence-to-Sequence Tasks"
description: "Machine translation, text summarization, and question answering"
author: "Joseph Streeter"
tags: ["nlp", "python", "seq2seq", "translation", "summarization"]
category: "development"
last_updated: "2026-08-01"
---
## Sequence-to-Sequence Tasks

### Machine Translation

Translate text between languages:

```python
from transformers import MarianMTModel, MarianTokenizer
import torch

class Translator:
    """Machine translation using MarianMT models."""
    
    def __init__(self, source_lang, target_lang):
        model_name = f'Helsinki-NLP/opus-mt-{source_lang}-{target_lang}'
        self.tokenizer = MarianTokenizer.from_pretrained(model_name)
        self.model = MarianMTModel.from_pretrained(model_name)
    
    def translate(self, texts, max_length=512):
        """Translate texts from source to target language."""
        if isinstance(texts, str):
            texts = [texts]
        
        # Tokenize
        inputs = self.tokenizer(texts, return_tensors="pt", padding=True, truncation=True)
        
        # Generate translations
        with torch.no_grad():
            translated = self.model.generate(**inputs, max_length=max_length)
        
        # Decode
        translations = [self.tokenizer.decode(t, skip_special_tokens=True) 
                       for t in translated]
        
        return translations if len(translations) > 1 else translations[0]

# English to French
en_fr_translator = Translator('en', 'fr')

english_texts = [
    "Hello, how are you?",
    "Natural language processing is fascinating.",
    "Machine learning models can translate text."
]

french_translations = en_fr_translator.translate(english_texts)

for en, fr in zip(english_texts, french_translations):
    print(f"EN: {en}")
    print(f"FR: {fr}\n")

# English to German
en_de_translator = Translator('en', 'de')
german = en_de_translator.translate("Machine learning is powerful.")
print(f"EN: Machine learning is powerful.")
print(f"DE: {german}")

# Back translation for data augmentation
fr_en_translator = Translator('fr', 'en')
back_translated = fr_en_translator.translate(french_translations)

print("\nBack Translation:")
for original, back in zip(english_texts, back_translated):
    print(f"Original:  {original}")
    print(f"Back:      {back}\n")
```

Using the translation pipeline:

```python
from transformers import pipeline

# Create translation pipeline
translator = pipeline("translation", model="Helsinki-NLP/opus-mt-en-es")

# Translate
results = translator([
    "Hello, world!",
    "How are you today?",
    "Machine learning is amazing."
], max_length=100)

for result in results:
    print(result['translation_text'])

# Output:
# ¡Hola mundo!
# ¿Cómo estás hoy?
# El aprendizaje automático es increíble.
```

### Text Summarization

Generate concise summaries of long texts:

```python
from transformers import pipeline

# Extractive summarization (selects important sentences)
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lsa import LsaSummarizer
from sumy.summarizers.luhn import LuhnSummarizer

def extractive_summarization(text, sentence_count=3):
    """Extract key sentences from text."""
    parser = PlaintextParser.from_string(text, Tokenizer("english"))
    summarizer = LsaSummarizer()
    summary = summarizer(parser.document, sentence_count)
    
    return ' '.join([str(sentence) for sentence in summary])

long_text = """
Artificial intelligence (AI) is intelligence demonstrated by machines, 
in contrast to natural intelligence displayed by animals including humans. 
AI research has been defined as the field of study of intelligent agents, 
which refers to any system that perceives its environment and takes actions 
that maximize its chance of achieving its goals. The term "artificial intelligence" 
was coined by John McCarthy in 1956. AI applications include advanced web search 
engines, recommendation systems, understanding human speech, self-driving cars, 
automated decision-making, and competing at the highest level in strategic game 
systems. As machines become increasingly capable, tasks considered to require 
intelligence are often removed from the definition of AI, a phenomenon known as 
the AI effect. Deep learning has dramatically improved the performance of programs 
in many important subfields of artificial intelligence.
"""

extract_summary = extractive_summarization(long_text, sentence_count=2)
print("Extractive Summary:")
print(extract_summary)

# Abstractive summarization (generates new text)
summarizer = pipeline("summarization", model="facebook/bart-large-cnn")

def abstractive_summarization(text, max_length=130, min_length=30):
    """Generate abstractive summary."""
    summary = summarizer(text, max_length=max_length, min_length=min_length, do_sample=False)
    return summary[0]['summary_text']

abstract_summary = abstractive_summarization(long_text)
print("\nAbstractive Summary:")
print(abstract_summary)

# Summarize articles
article = """
Machine learning is a method of data analysis that automates analytical model building. 
It is a branch of artificial intelligence based on the idea that systems can learn from data, 
identify patterns and make decisions with minimal human intervention. Machine learning algorithms 
are used in a wide variety of applications, such as in medicine, email filtering, speech recognition, 
and computer vision, where it is difficult or unfeasible to develop conventional algorithms to perform 
the needed tasks. The learning process begins with observations or data, such as examples, direct 
experience, or instruction, in order to look for patterns in data and make better decisions in the 
future based on the examples that we provide.
"""

summary_result = summarizer(
    article,
    max_length=50,
    min_length=25,
    do_sample=False
)

print("\nArticle Summary:")
print(summary_result[0]['summary_text'])
```

Custom summarization with T5:

```python
from transformers import T5Tokenizer, T5ForConditionalGeneration

model_name = "t5-small"
tokenizer = T5Tokenizer.from_pretrained(model_name)
model = T5ForConditionalGeneration.from_pretrained(model_name)

def t5_summarize(text, max_length=150):
    """Summarize using T5 model."""
    # T5 requires task prefix
    input_text = f"summarize: {text}"
    inputs = tokenizer(input_text, return_tensors="pt", max_length=512, truncation=True)
    
    with torch.no_grad():
        summary_ids = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            num_beams=4,
            length_penalty=2.0,
            early_stopping=True
        )
    
    summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)
    return summary

t5_summary = t5_summarize(long_text)
print("\nT5 Summary:")
print(t5_summary)
```

### Question Answering

Build systems that answer questions from context:

```python
from transformers import pipeline

# Load QA pipeline
qa_pipeline = pipeline(
    "question-answering",
    model="distilbert-base-cased-distilled-squad"
)

context = """
The Transformer is a deep learning model introduced in 2017, used primarily in 
the field of natural language processing. Like recurrent neural networks, 
transformers are designed to handle sequential data, such as natural language, 
for tasks such as translation and text summarization. However, unlike RNNs, 
transformers do not require that the sequential data be processed in order. 
The Transformer was proposed in the paper "Attention Is All You Need" by 
Vaswani et al. from Google Brain.
"""

questions = [
    "When was the Transformer model introduced?",
    "What is the Transformer used for?",
    "Who proposed the Transformer?",
    "What is the main difference from RNNs?"
]

print("Question Answering:")
for question in questions:
    result = qa_pipeline(question=question, context=context)
    print(f"\nQ: {question}")
    print(f"A: {result['answer']}")
    print(f"   Confidence: {result['score']:.4f}")

# Output:
# Q: When was the Transformer model introduced?
# A: 2017
#    Confidence: 0.9842
#
# Q: What is the Transformer used for?
# A: natural language processing
#    Confidence: 0.5321
```

Multiple-choice QA:

```python
from transformers import AutoTokenizer, AutoModelForMultipleChoice
import torch

def answer_multiple_choice(question, context, choices):
    """Answer multiple choice question."""
    model_name = "bert-base-uncased"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForMultipleChoice.from_pretrained(model_name)
    
    # Format inputs
    inputs = []
    for choice in choices:
        prompt = f"{question} {choice}"
        inputs.append(tokenizer(prompt, context, return_tensors="pt", 
                               padding=True, truncation=True))
    
    # Get predictions
    with torch.no_grad():
        outputs = [model(**inp).logits for inp in inputs]
        scores = torch.cat(outputs, dim=0)
        predicted_idx = scores.argmax().item()
    
    return choices[predicted_idx], predicted_idx

question = "What is the capital of France?"
context = "France is a country in Europe. Paris is its capital and largest city."
choices = ["London", "Paris", "Berlin", "Madrid"]

answer, idx = answer_multiple_choice(question, context, choices)
print(f"Question: {question}")
print(f"Answer: {answer}")
```

Open-domain QA (no context provided):

```python
from transformers import pipeline

# Using RAG (Retrieval-Augmented Generation)
qa_system = pipeline("question-answering", 
                     model="deepset/roberta-base-squad2")

# Questions without specific context
questions = [
    "What is Python?",
    "Who invented the transformer architecture?",
    "When was BERT released?"
]

# Note: For true open-domain QA, you'd need a retrieval system
# to fetch relevant context first
general_context = """
Python is a high-level programming language. BERT was released by Google in 2018.
The Transformer architecture was invented by researchers at Google in 2017.
"""

for question in questions:
    result = qa_system(question=question, context=general_context)
    print(f"\nQ: {question}")
    print(f"A: {result['answer']}")
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
