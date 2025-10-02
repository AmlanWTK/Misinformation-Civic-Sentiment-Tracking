# Python Script to Train Naive Bayes and Export Model
# train_naive_bayes.py

import pandas as pd
import numpy as np
import json
import pickle
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import re
import os

class BengaliNaiveBayesTrainer:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(max_features=1000, stop_words=None)
        self.classifier = MultinomialNB()
        self.bengali_stopwords = [
            'আর', 'এর', 'যে', 'যা', 'তা', 'এই', 'ও', 'তার', 'করে', 'হয়',
            'থেকে', 'দিয়ে', 'না', 'নেই', 'আছে', 'করা', 'হল', 'হবে', 'ছিল',
            'একটি', 'সে', 'তিনি', 'আমি', 'আমরা', 'তারা', 'কি', 'কেন', 'কীভাবে'
        ]
    
    def preprocess_text(self, text):
        """Basic Bengali text preprocessing"""
        if pd.isna(text):
            return ""
        
        # Convert to string and lowercase
        text = str(text).lower().strip()
        
        # Remove punctuation but keep Bengali characters
        text = re.sub(r'[।,\.\?\!\;\:\"\'\(\)\[\]{}]', ' ', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove numbers
        text = re.sub(r'[0-9]+', '', text)
        
        return text.strip()
    
    def load_and_prepare_data(self, csv_path):
        """Load CSV data and prepare for training"""
        print(f"📁 Loading data from {csv_path}")
        
        # Try different CSV structures
        try:
            df = pd.read_csv(csv_path)
            print(f"✅ Loaded {len(df)} rows")
            print(f"📊 Columns: {list(df.columns)}")
            
            # Detect text and label columns
            text_col = None
            label_col = None
            
            for col in df.columns:
                if 'text' in col.lower() or 'content' in col.lower() or 'news' in col.lower():
                    text_col = col
                if 'label' in col.lower() or 'class' in col.lower() or 'category' in col.lower():
                    label_col = col
            
            # If not found, use first two columns
            if text_col is None:
                text_col = df.columns[0]
                print(f"⚠️ Using first column as text: {text_col}")
            
            if label_col is None:
                label_col = df.columns[1]
                print(f"⚠️ Using second column as label: {label_col}")
            
            # Extract and preprocess
            texts = df[text_col].apply(self.preprocess_text)
            labels = df[label_col].apply(self.normalize_label)
            
            # Remove empty texts
            valid_idx = texts.str.len() > 0
            texts = texts[valid_idx]
            labels = labels[valid_idx]
            
            print(f"📝 Final dataset: {len(texts)} valid examples")
            print(f"🏷️ Label distribution: {labels.value_counts().to_dict()}")
            
            return texts.tolist(), labels.tolist()
            
        except Exception as e:
            print(f"❌ Error loading CSV: {e}")
            return self.create_sample_data()
    
    def normalize_label(self, label):
        """Normalize different label formats"""
        if pd.isna(label):
            return 'neutral'
            
        label_str = str(label).lower().strip()
        
        # Rumor/Fake indicators
        if any(word in label_str for word in ['fake', 'false', 'rumor', 'rumour', 'misinformation', '0', 'ভুয়া', 'মিথ্যা', 'গুজব']):
            return 'rumor'
        
        # Credible/Real indicators  
        if any(word in label_str for word in ['real', 'true', 'authentic', '1', 'সত্য', 'সঠিক', 'নির্ভরযোগ্য']):
            return 'credible'
        
        return 'neutral'
    
    def create_sample_data(self):
        """Create sample Bengali data if CSV loading fails"""
        print("🔄 Creating sample training data...")
        
        rumor_texts = [
            'শোনা যাচ্ছে যে সরকার গোপনে নতুন কর বসাতে চাইছে',
            'গুজব রটেছে যে আগামীকাল সব দোকান বন্ধ থাকবে',
            'দাবি করা হচ্ছে যে খাবারে বিষ মেশানো হয়েছে',
            'সন্দেহজনক তথ্য পেয়েছি যে নির্বাচন বাতিল হবে',
            'চাঞ্চল্যকর খবর যে বন্যা আরো বাড়বে',
            'অনিশ্চিত খবর পাওয়া যাচ্ছে যে দাম আরো বাড়বে',
            'ভুয়া খবর ছড়ানো হচ্ছে করোনা আবার বাড়ছে',
            'মিথ্যা দাবি করা হচ্ছে সকল স্কুল বন্ধ',
            'বানোয়াট তথ্য দিয়ে বলা হচ্ছে অর্থনীতি ভেঙে পড়বে',
            'জাল নিউজ ছড়াচ্ছে সরকার পদত্যাগ করবে'
        ]
        
        credible_texts = [
            'সরকারি ঘোষণা অনুযায়ী নতুন নীতিমালা প্রকাশিত',
            'অফিসিয়াল সূত্রে জানা গেছে নির্বাচনের তারিখ ঠিক',
            'নির্ভরযোগ্য সূত্রে নিশ্চিত হওয়া গেছে বাজেট পাস',
            'বিশেষজ্ঞদের মতে অর্থনৈতিক অবস্থা উন্নতি',
            'গবেষণায় প্রমাণিত হয়েছে শিক্ষার মান বাড়ছে',
            'যাচাইকৃত তথ্য অনুযায়ী স্বাস্থ্যসেবা উন্নত',
            'সত্যায়িত রিপোর্টে বলা হয়েছে পরিবেশ রক্ষা',
            'প্রমাণিত তথ্য মতে কৃষি উৎপাদন বেড়েছে',
            'নিশ্চিত সূত্রে জানা যায় শিল্প খাতে উন্নতি',
            'বিশ্বস্ত সংস্থার রিপোর্ট অনুযায়ী দুর্নীতি কমেছে'
        ]
        
        neutral_texts = [
            'আজকের আবহাওয়া রিপোর্ট অনুযায়ী বৃষ্টি হতে পারে',
            'স্পোর্টস নিউজে বলা হয়েছে টুর্নামেন্ট শুরু হবে',
            'বিনোদন জগতের খবরে নতুন ছবি মুক্তি পাবে',
            'প্রযুক্তি বিষয়ক সংবাদে নতুন অ্যাপ লঞ্চ',
            'শিক্ষা সংক্রান্ত খবরে পরীক্ষার রুটিন প্রকাশিত',
            'স্বাস্থ্য টিপসে বলা হয়েছে নিয়মিত ব্যায়াম',
            'ভ্রমণ গাইডে উল্লেখ করা হয়েছে নতুন স্থান',
            'রান্নার রেসিপিতে দেওয়া হয়েছে স্বাস্থ্যকর খাবার',
            'ফ্যাশন নিউজে বলা হয়েছে নতুন ট্রেন্ড',
            'লাইফস্টাইল টিপসে দেওয়া হয়েছে জীবনযাত্রার পরামর্শ'
        ]
        
        texts = rumor_texts + credible_texts + neutral_texts
        labels = ['rumor'] * len(rumor_texts) + ['credible'] * len(credible_texts) + ['neutral'] * len(neutral_texts)
        
        return texts, labels
    
    def train_model(self, texts, labels):
        """Train the Naive Bayes model"""
        print("🤖 Training Naive Bayes model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            texts, labels, test_size=0.2, random_state=42, stratify=labels
        )
        
        # Vectorize text
        X_train_vec = self.vectorizer.fit_transform(X_train)
        X_test_vec = self.vectorizer.transform(X_test)
        
        # Train classifier
        self.classifier.fit(X_train_vec, y_train)
        
        # Evaluate
        y_pred = self.classifier.predict(X_test_vec)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"✅ Training completed!")
        print(f"📊 Accuracy: {accuracy:.2%}")
        print(f"📈 Classification Report:")
        print(classification_report(y_test, y_pred))
        
        return accuracy
    

    
    
    def export_model_for_flutter(self, output_path='flutter_naive_bayes_model.json'):
        """Export model parameters for Flutter"""
        print(f"💾 Exporting model to {output_path}")
        folder = os.path.dirname(output_path)
        if folder and not os.path.exists(folder):
             
             os.makedirs(folder)
        
        # Get feature names and their indices
        feature_names = self.vectorizer.get_feature_names_out().tolist()
        vocabulary = {k: int(v) for k, v in self.vectorizer.vocabulary_.items()}
        
        # Get class information
        classes = self.classifier.classes_.tolist()
        class_log_prior = self.classifier.class_log_prior_.tolist()
        feature_log_prob = self.classifier.feature_log_prob_.tolist()
        
        # Create model export
        model_data = {
            'model_type': 'MultinomialNB',
            'classes': classes,
            'class_log_prior': class_log_prior,
            'feature_log_prob': feature_log_prob,
            'vocabulary': vocabulary,
            'feature_names': feature_names,
            'vectorizer_params': {
                'max_features': 1000,
                'min_df': 1,
                'max_df': 1.0
            },
            'metadata': {
                'training_samples': len(classes),
                'feature_count': len(feature_names),
                'bengali_stopwords': self.bengali_stopwords
            }
        }
        
        # Save to JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(model_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Model exported successfully!")
        print(f"📦 Classes: {classes}")
        print(f"🔤 Features: {len(feature_names)}")
        print(f"📁 File size: {len(json.dumps(model_data))} characters")
        
        return model_data
    


def main():
    """Main training function"""
    print("🚀 Starting Bengali Naive Bayes Training...")
    
    trainer = BengaliNaiveBayesTrainer()
    
    # Load your CSV data (update path as needed)
    csv_path = r"C:\Users\Asus\Videos\Misinformation & Civic Sentiment Tracking\assets\data\bengali_fake_news.csv"

    texts, labels = trainer.load_and_prepare_data(csv_path)
    
    # Train model
    accuracy = trainer.train_model(texts, labels)
    
    # Export for Flutter
    model_data = trainer.export_model_for_flutter('assets/models/naive_bayes_model.json')
    
    print(f"🎉 Training complete! Model ready for Flutter integration.")
    print(f"📋 Next steps:")
    print(f"   1. Copy 'assets/models/naive_bayes_model.json' to your Flutter project")
    print(f"   2. Add the JSON file to pubspec.yaml assets")
    print(f"   3. Use the Flutter inference code to load and run the model")

if __name__ == "__main__":
    main()