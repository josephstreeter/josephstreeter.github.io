---
title: "Real-World Applications"
description: "End-to-end examples applying NLP to practical problems"
author: "Joseph Streeter"
tags: ["nlp", "python", "applications", "examples"]
category: "development"
last_updated: "2026-08-01"
---
## Real-World Applications

Practical NLP applications:

```python
# Customer Support Chatbot
from transformers import pipeline

class SupportChatbot:
    """Customer support chatbot."""
    
    def __init__(self):
        self.intent_classifier = pipeline(
            "zero-shot-classification",
            model="facebook/bart-large-mnli"
        )
        self.qa_system = pipeline(
            "question-answering",
            model="deepset/roberta-base-squad2"
        )
        
        self.intents = [
            "technical_support",
            "billing_inquiry",
            "product_information",
            "complaint",
            "general_inquiry"
        ]
    
    def classify_intent(self, message: str) -> str:
        """Classify user intent."""
        result = self.intent_classifier(message, self.intents)
        return result['labels'][0]
    
    def answer_question(self, question: str, context: str) -> str:
        """Answer question from knowledge base."""
        result = self.qa_system(question=question, context=context)
        return result['answer']
    
    def respond(self, message: str) -> Dict[str, str]:
        """Generate response to user message."""
        intent = self.classify_intent(message)
        
        # Route to appropriate handler
        if intent == "technical_support":
            response = "I'll connect you with our technical team."
        elif intent == "billing_inquiry":
            response = "Let me help you with billing information."
        else:
            response = "How can I assist you today?"
        
        return {
            'intent': intent,
            'response': response
        }

# Content Recommendation System
class ContentRecommender:
    """Recommend similar content based on text."""
    
    def __init__(self):
        from transformers import AutoTokenizer, AutoModel
        import torch
        
        self.tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
        self.model = AutoModel.from_pretrained("bert-base-uncased")
        self.content_embeddings = {}
    
    def add_content(self, content_id: str, text: str):
        """Add content to recommendation system."""
        embedding = self._get_embedding(text)
        self.content_embeddings[content_id] = embedding
    
    def _get_embedding(self, text: str):
        """Get BERT embedding for text."""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True)
        with torch.no_grad():
            outputs = self.model(**inputs)
        return outputs.last_hidden_state.mean(dim=1).numpy()
    
    def recommend(self, query: str, top_k: int = 5) -> List[str]:
        """Recommend similar content."""
        from sklearn.metrics.pairwise import cosine_similarity
        
        query_embedding = self._get_embedding(query)
        
        similarities = {}
        for content_id, embedding in self.content_embeddings.items():
            sim = cosine_similarity(query_embedding, embedding)[0][0]
            similarities[content_id] = sim
        
        # Sort by similarity
        sorted_content = sorted(similarities.items(), key=lambda x: x[1], reverse=True)
        return [content_id for content_id, _ in sorted_content[:top_k]]

# Email Classification
class EmailClassifier:
    """Classify and prioritize emails."""
    
    def __init__(self):
        from transformers import pipeline
        
        self.classifier = pipeline(
            "text-classification",
            model="distilbert-base-uncased"
        )
        self.sentiment_analyzer = pipeline(
            "sentiment-analysis",
            model="distilbert-base-uncased-finetuned-sst-2-english"
        )
    
    def classify_email(self, subject: str, body: str) -> Dict:
        """Classify email content."""
        full_text = f"{subject} {body}"
        
        # Determine urgency
        urgent_keywords = ['urgent', 'immediate', 'asap', 'critical']
        is_urgent = any(keyword in full_text.lower() for keyword in urgent_keywords)
        
        # Analyze sentiment
        sentiment = self.sentiment_analyzer(body[:512])[0]
        
        return {
            'urgent': is_urgent,
            'sentiment': sentiment['label'],
            'confidence': sentiment['score']
        }

# Document Search Engine
class DocumentSearchEngine:
    """Semantic search for documents."""
    
    def __init__(self):
        from transformers import AutoTokenizer, AutoModel
        import torch
        import numpy as np
        
        self.tokenizer = AutoTokenizer.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
        self.model = AutoModel.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
        self.documents = []
        self.embeddings = []
    
    def index_documents(self, documents: List[str]):
        """Index documents for search."""
        self.documents = documents
        self.embeddings = [self._encode(doc) for doc in documents]
    
    def _encode(self, text: str):
        """Encode text to embedding."""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
        with torch.no_grad():
            outputs = self.model(**inputs)
        return outputs.last_hidden_state.mean(dim=1).numpy()
    
    def search(self, query: str, top_k: int = 5) -> List[Dict]:
        """Search for relevant documents."""
        from sklearn.metrics.pairwise import cosine_similarity
        
        query_embedding = self._encode(query)
        
        results = []
        for idx, doc_embedding in enumerate(self.embeddings):
            similarity = cosine_similarity(query_embedding, doc_embedding)[0][0]
            results.append({
                'document': self.documents[idx],
                'score': similarity,
                'rank': idx
            })
        
        # Sort by similarity
        results.sort(key=lambda x: x['score'], reverse=True)
        return results[:top_k]

# Social Media Monitoring
class SocialMediaMonitor:
    """Monitor and analyze social media content."""
    
    def __init__(self):
        from transformers import pipeline
        
        self.sentiment_analyzer = pipeline("sentiment-analysis")
        self.emotion_classifier = pipeline(
            "text-classification",
            model="j-hartmann/emotion-english-distilroberta-base"
        )
    
    def analyze_post(self, text: str) -> Dict:
        """Analyze social media post."""
        sentiment = self.sentiment_analyzer(text)[0]
        emotion = self.emotion_classifier(text)[0]
        
        # Extract hashtags and mentions
        import re
        hashtags = re.findall(r'#\w+', text)
        mentions = re.findall(r'@\w+', text)
        
        return {
            'sentiment': sentiment,
            'emotion': emotion,
            'hashtags': hashtags,
            'mentions': mentions,
            'engagement_score': self._calculate_engagement(text)
        }
    
    def _calculate_engagement(self, text: str) -> float:
        """Calculate engagement score."""
        # Simple heuristic based on length and special characters
        score = min(len(text) / 280, 1.0)  # Normalize by typical post length
        score += 0.1 * (text.count('!') + text.count('?'))
        return min(score, 1.0)

print("Real-world NLP applications ready for deployment!")
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
