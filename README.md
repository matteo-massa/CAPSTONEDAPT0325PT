
# 🏦 Sentiment Analysis

-----

## 📁 Repository Structure

```text
CAPSTONEDAPT0325PT/
│
├── CapstonePt Scraping .ipynb     # Google Play Store Scraping
├── progetto capstone P2.ipynb     # NLP with BERT + CUDA · spaCy Lemmatization · Counter Frequencies
├── CAPSTONE SQL.sql               # All MySQL VIEWs of the Data Warehouse
├── capstone matteo.pbix           # Power BI Dashboard — 4 executive pages
└── README.md
```

-----

## ▶️ How to Replicate the Project

### Requirements

```bash
pip install google-play-scraper pandas sqlalchemy pymysql
pip install transformers torch tqdm
pip install spacy
python -m spacy download it_core_news_sm
```

### MySQL Connection Configuration

```python
sqlalchemy_url = f'mysql+pymysql://{USER}:{PASSWORD}@{HOST}/{DATABASE}'
```

### Execution Order

```bash
# 1. Google Play Store Scraping
python python/01_scraping.py

# 2. Sentiment classification with BERT
python python/02_sentiment_bert.py

# 3. Lemmatization with spaCy
python python/03_lemmatizzazione_spacy.py

# 4. Top 20 frequencies extraction
python python/04_frequenze_counter.py

# 5. Create MySQL VIEWs in order:
#    view_classifica_valutazione
#    → view_dettaglio_recensioni_def
#    → view_disservizi_frequenti_def
#    → view_disservizi_frequenti_grezzo
#    → view_trend_temporale

# 6. Open capstone_matteo.pbix in Power BI Desktop
#    Update the MySQL connection string in Transform Data
```

-----

## 🎓 Final Capstone

Project created as the final Capstone for the **Data Analytics PT** course — Epicode (March 2025).

-----

*For questions about the architecture or to chat about the project, contact me on [LinkedIn](https://www.linkedin.com/in/matteo-massa-6a2372397).*


