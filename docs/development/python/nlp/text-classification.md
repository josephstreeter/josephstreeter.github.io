---
title: "Text Classification"
description: "Sentiment analysis, spam detection, and intent classification with classical and neural models"
author: "Joseph Streeter"
tags: ["nlp", "python", "classification", "sentiment analysis"]
category: "development"
last_updated: "2026-08-01"
---
## Text Classification

### Sentiment Analysis

Determine the emotional tone or opinion expressed in text:

```python
from textblob import TextBlob
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer

# Simple sentiment with TextBlob
def analyze_sentiment_textblob(text):
    """Analyze sentiment using TextBlob."""
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity  # -1 to 1
    subjectivity = blob.sentiment.subjectivity  # 0 to 1
    
    if polarity > 0:
        sentiment = "Positive"
    elif polarity < 0:
        sentiment = "Negative"
    else:
        sentiment = "Neutral"
    
    return {
        'sentiment': sentiment,
        'polarity': polarity,
        'subjectivity': subjectivity
    }

# Test examples
reviews = [
    "This product is absolutely amazing! I love it!",
    "Terrible quality. Waste of money.",
    "It's okay, nothing special.",
]

for review in reviews:
    result = analyze_sentiment_textblob(review)
    print(f"Review: {review}")
    print(f"Result: {result}\n")

# Output:
# Review: This product is absolutely amazing! I love it!
# Result: {'sentiment': 'Positive', 'polarity': 0.625, 'subjectivity': 0.7}
```

VADER sentiment analysis (better for social media):

```python
# Download VADER lexicon
nltk.download('vader_lexicon')

sia = SentimentIntensityAnalyzer()

def analyze_sentiment_vader(text):
    """Analyze sentiment using VADER."""
    scores = sia.polarity_scores(text)
    
    # Compound score: -1 (most negative) to 1 (most positive)
    if scores['compound'] >= 0.05:
        sentiment = 'Positive'
    elif scores['compound'] <= -0.05:
        sentiment = 'Negative'
    else:
        sentiment = 'Neutral'
    
    return {
        'sentiment': sentiment,
        'scores': scores
    }

# Test with social media text
tweets = [
    "I love this product! 😍 #amazing",
    "This is terrible 😡 Very disappointed!!!",
    "It's okay I guess...",
    "BEST PURCHASE EVER!!!"
]

for tweet in tweets:
    result = analyze_sentiment_vader(tweet)
    print(f"Tweet: {tweet}")
    print(f"Sentiment: {result['sentiment']}")
    print(f"Scores: {result['scores']}\n")
```

Machine learning-based sentiment analysis:

```python
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
import pandas as pd

# Sample dataset
data = {
    'text': [
        "This movie is fantastic! Best I've seen",
        "Absolutely loved it. Highly recommend",
        "Great acting and storyline",
        "Terrible movie, waste of time",
        "Boring and predictable",
        "Worst movie ever made",
        "It was okay, not great not bad",
        "Mediocre at best"
    ],
    'sentiment': ['positive', 'positive', 'positive', 'negative', 
                  'negative', 'negative', 'neutral', 'neutral']
}

df = pd.DataFrame(data)

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    df['text'], df['sentiment'], test_size=0.2, random_state=42
)

# Vectorize text
vectorizer = TfidfVectorizer(max_features=100)
X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# Train classifier
classifier = MultinomialNB()
classifier.fit(X_train_vec, y_train)

# Predict
y_pred = classifier.predict(X_test_vec)

# Evaluate
print(f"Accuracy: {accuracy_score(y_test, y_pred):.2f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Predict new text
new_reviews = ["This is an excellent product!", "I hate this so much"]
new_vec = vectorizer.transform(new_reviews)
predictions = classifier.predict(new_vec)

for review, pred in zip(new_reviews, predictions):
    print(f"Review: {review}")
    print(f"Predicted sentiment: {pred}\n")
```

Deep learning sentiment analysis with transformers:

```python
from transformers import pipeline

# Load pre-trained sentiment analysis model
sentiment_analyzer = pipeline(
    "sentiment-analysis",
    model="distilbert-base-uncased-finetuned-sst-2-english"
)

# Analyze sentiment
texts = [
    "I absolutely love this product!",
    "This is the worst thing I've ever bought.",
    "It's alright, I guess."
]

results = sentiment_analyzer(texts)

for text, result in zip(texts, results):
    print(f"Text: {text}")
    print(f"Sentiment: {result['label']} (confidence: {result['score']:.4f})\n")

# Output:
# Text: I absolutely love this product!
# Sentiment: POSITIVE (confidence: 0.9998)
#
# Text: This is the worst thing I've ever bought.
# Sentiment: NEGATIVE (confidence: 0.9997)
```

### Spam Detection

Classify messages as spam or legitimate:

```python
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import pandas as pd

# Sample spam dataset
spam_data = {
    'message': [
        "Congratulations! You've won $1000. Click here to claim",
        "Hi, can we meet for coffee tomorrow?",
        "URGENT: Your account will be suspended. Verify now!",
        "Thanks for your help yesterday",
        "FREE MONEY!!! Click now to get rich quick!!!",
        "Meeting at 3pm in conference room B",
        "Act now! Limited time offer. Buy now!",
        "Happy birthday! Hope you have a great day",
    ],
    'label': ['spam', 'ham', 'spam', 'ham', 'spam', 'ham', 'spam', 'ham']
}

df = pd.DataFrame(spam_data)

# Feature engineering
def extract_features(text):
    """Extract features for spam detection."""
    features = {
        'length': len(text),
        'num_caps': sum(1 for c in text if c.isupper()),
        'num_exclamation': text.count('!'),
        'num_question': text.count('?'),
        'has_currency': any(symbol in text for symbol in ['$', '£', '€']),
        'num_words': len(text.split())
    }
    return features

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    df['message'], df['label'], test_size=0.25, random_state=42
)

# Vectorize with TF-IDF
vectorizer = TfidfVectorizer(
    max_features=500,
    min_df=1,
    max_df=0.8,
    stop_words='english',
    ngram_range=(1, 2)
)

X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# Train classifier
spam_classifier = MultinomialNB(alpha=0.1)
spam_classifier.fit(X_train_vec, y_train)

# Predict
y_pred = spam_classifier.predict(X_test_vec)

# Evaluate
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Predict new messages
new_messages = [
    "You've won a free iPhone! Click here!",
    "See you at the meeting tomorrow"
]

new_vec = vectorizer.transform(new_messages)
predictions = spam_classifier.predict(new_vec)
probabilities = spam_classifier.predict_proba(new_vec)

for msg, pred, proba in zip(new_messages, predictions, probabilities):
    print(f"\nMessage: {msg}")
    print(f"Prediction: {pred}")
    print(f"Probability: {proba}")
```

### Intent Classification

Classify user intents in conversational AI:

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline
import numpy as np

# Intent training data
intent_data = {
    'text': [
        "What's the weather like today?",
        "Tell me the weather forecast",
        "Is it going to rain?",
        "Set an alarm for 7am",
        "Wake me up at 6:30",
        "Create an alarm for tomorrow morning",
        "Play some music",
        "I want to listen to jazz",
        "Play my favorite playlist",
        "What time is it?",
        "Tell me the current time",
        "What's the time right now?"
    ],
    'intent': [
        'weather', 'weather', 'weather',
        'set_alarm', 'set_alarm', 'set_alarm',
        'play_music', 'play_music', 'play_music',
        'get_time', 'get_time', 'get_time'
    ]
}

df_intents = pd.DataFrame(intent_data)

# Create pipeline
intent_classifier = Pipeline([
    ('tfidf', TfidfVectorizer(ngram_range=(1, 2))),
    ('clf', SVC(kernel='linear', probability=True))
])

# Train model
intent_classifier.fit(df_intents['text'], df_intents['intent'])

# Test intent classification
test_queries = [
    "Will it be sunny tomorrow?",
    "Set alarm for 8am please",
    "Put on some rock music",
    "What is the time?"
]

for query in test_queries:
    predicted_intent = intent_classifier.predict([query])[0]
    probabilities = intent_classifier.predict_proba([query])[0]
    confidence = max(probabilities)
    
    print(f"\nQuery: {query}")
    print(f"Intent: {predicted_intent}")
    print(f"Confidence: {confidence:.4f}")
```

Multi-label classification:

```python
from sklearn.multioutput import MultiOutputClassifier
from sklearn.ensemble import RandomForestClassifier

# Multi-label data (text can have multiple categories)
multilabel_data = {
    'text': [
        "Machine learning tutorial for beginners",
        "Python data science and visualization",
        "Web development with React and Node.js",
        "Deep learning for computer vision",
    ],
    'category_ml': [1, 1, 0, 1],      # Machine Learning
    'category_python': [1, 1, 0, 1],   # Python
    'category_web': [0, 0, 1, 0],      # Web Development
    'category_viz': [0, 1, 0, 0]       # Data Visualization
}

df_multi = pd.DataFrame(multilabel_data)

# Prepare features and labels
X = df_multi['text']
y = df_multi[['category_ml', 'category_python', 'category_web', 'category_viz']]

# Vectorize
vectorizer = TfidfVectorizer()
X_vec = vectorizer.fit_transform(X)

# Train multi-label classifier
multi_clf = MultiOutputClassifier(RandomForestClassifier())
multi_clf.fit(X_vec, y)

# Predict
test_text = ["Python tutorial on neural networks"]
test_vec = vectorizer.transform(test_text)
predictions = multi_clf.predict(test_vec)

print(f"Text: {test_text[0]}")
print("Predicted categories:")
categories = ['Machine Learning', 'Python', 'Web Development', 'Data Visualization']
for cat, pred in zip(categories, predictions[0]):
    if pred == 1:
        print(f"  - {cat}")
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
