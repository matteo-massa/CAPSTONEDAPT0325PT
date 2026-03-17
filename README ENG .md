# 🏦 Sentiment Analysis

> Sentiment analysis on **78,000 real reviews** of **8 Italian banks** extracted from the Google Play Store between 2022–2024.  
> End-to-end pipeline: scraping → NLP classification → MySQL Data Warehouse → 4-page executive Power BI Dashboard.

-----

## 📌 Table of Contents

  - [Objective](https://www.google.com/search?q=%23-objective)
  - [Tech Stack](https://www.google.com/search?q=%23-tech-stack)
  - [Project Architecture](https://www.google.com/search?q=%23-project-architecture)
  - [Phase 1 — Python: Scraping](https://www.google.com/search?q=%23phase-1--python-scraping)
  - [Phase 2 — Python: NLP Classification with BERT](https://www.google.com/search?q=%23phase-2--python-nlp-classification-with-bert)
  - [Phase 3 — Python: Lemmatization with spaCy](https://www.google.com/search?q=%23phase-3--python-lemmatization-with-spacy)
  - [Phase 4 — MySQL: Data Warehouse and VIEWs](https://www.google.com/search?q=%23phase-4--mysql-data-warehouse-and-views)
  - [Phase 5 — Power BI: Executive Dashboard](https://www.google.com/search?q=%23phase-5--power-bi-executive-dashboard)
  - [Key Results](https://www.google.com/search?q=%23-key-results)
  - [Repository Structure](https://www.google.com/search?q=%23-repository-structure)
  - [How to Replicate the Project](https://www.google.com/search?q=%23-how-to-replicate-the-project)

-----

## 🎯 Objective

🏦 Italian banking apps collect thousands of user reports every year. I analyzed 78,000 real reviews of 8 Italian banks to uncover them.

Starting with a simple question:
👉 What do user reviews really reveal about digital banking in Italy?

Digital store reviews are an unstructured source of competitor intelligence often ignored by banking institutions. This project transforms raw text into measurable operational KPIs, identifying recurring technical bugs, temporal trends, and customer churn risk.

The 8 analyzed banks cover both traditional banking and pure fintech:

| Bank | Type |
|---|---|
| Intesa Sanpaolo | Traditional |
| Unicredit | Traditional |
| Credit Agricole | Traditional |
| Credem | Traditional |
| Fineco | Hybrid |
| BBVA | Digital |
| Revolut | Fintech |
| Hype | Fintech |

-----

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Scraping | Python · google-play-scraper · SQLAlchemy |
| NLP — Sentiment | HuggingFace Transformers · `neuraly/bert-base-italian-cased-sentiment` · PyTorch · CUDA |
| NLP — Lemmatization | spaCy · `it_core_news_sm` |
| NLP — Frequencies | collections.Counter |
| Data Warehouse | MySQL 8.0 · VIEW · CASE · REGEXP |
| Visualization | Power BI · DAX · Star Schema |

-----

## 🏗 Project Architecture

```text
Google Play Store
        │
        ▼
┌─────────────────────┐
│  PHASE 1 — SCRAPING │  Python · google-play-scraper
│  78,000 reviews     │  8 banks · 2022-2024
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  PHASE 2 — NLP BERT │  neuraly/bert-base-italian-cased-sentiment
│  Sentiment analysis │  positive / negative / neutral
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  PHASE 3 — spaCy    │  Lemmatization of negative reviews
│  Lemmas + Bigrams   │  Top 20 patterns extracted with Counter
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  PHASE 4 — MySQL    │  5 engineered VIEWs
│  Data Warehouse     │  CASE + REGEXP on NLP bigrams
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  PHASE 5 — POWER BI │  Star Schema · DAX · 4 executive pages
│  Dashboard          │  Dual engine · Time Intelligence
└─────────────────────┘
```

-----

## Phase 1 — Python: Scraping

The scraper uses the `google-play-scraper` library to extract reviews directly from digital stores without intermediaries.

The `banche_google` dictionary maps each bank to its official `app_id` on Google Play. The loop iterates over each bank, filters for the Italian language and publication year (2022–2024), and saves the results to MySQL via SQLAlchemy.

```python
banche_google = {
    'Intesa': 'com.latuabancaperandroid',
    'Unicredit': 'com.unicredit',
    'Credem': 'com.CredemMobile',
    'Credit Agricole': 'it.caitalia.apphub',
    'Fineco': 'com.fineco.it',
    'BBVA': 'com.bbva.italy',
    'Revolut': 'com.revolut.revolut',
    'Hype': 'it.hype.app'
}

ANNO_TARGET = (2024, 2023, 2022)
max_reviews = 100000

for banca, app_id in banche_google.items():
    recensioni_android, _ = google_reviews(app_id, lang='it', country='it',
                                           sort=Sort.NEWEST, count=max_reviews)
    for recensione in recensioni_android:
        data_recensione = recensione['at']
        if data_recensione.year in ANNO_TARGET:
            dati_raccolti.append({
                'banca': banca,
                'data': data_recensione,
                'testo': recensione['content'],
                'valutazione': recensione['score']
            })
        elif data_recensione.year < 2022:
            break
```

The raw dataset is deduplicated and saved in the `recensioni_google` table before proceeding with NLP preprocessing.

-----

## Phase 2 — Python: NLP Classification with BERT

The model used is [`neuraly/bert-base-italian-cased-sentiment`](https://www.google.com/search?q=%5Bhttps://huggingface.co/neuraly/bert-base-italian-cased-sentiment%5D\(https://huggingface.co/neuraly/bert-base-italian-cased-sentiment\)), a BERT model fine-tuned specifically for Italian available on HuggingFace.

The pipeline automatically detects the presence of a GPU (CUDA) and scales inference accordingly. Batch processing with `batch_size=128` and `truncation=True` handles long texts efficiently.

```python
if torch.cuda.is_available():
    device = 0  # GPU
else:
    device = -1  # CPU

sentiment_pipeline = pipeline(
    "text-classification",
    model="neuraly/bert-base-italian-cased-sentiment",
    device=device
)

testi = df['testo'].tolist()
batch_size = 128
risultati = []

for output in tqdm(sentiment_pipeline(testi, batch_size=batch_size,
                   truncation=True, max_length=512), total=len(testi)):
    risultati.append(output)

df['sentiment_feelit'] = [res['label'] for res in risultati]
df['sentiment_score']  = [round(res['score'], 4) for res in risultati]
```

**Classification Results:**

| Sentiment | Reviews | % |
|---|---|---|
| positive | 46,000 | 59.6% |
| negative | 22,200 | 28.5% |
| neutral | 9,252 | 11.9% |
| **Total** | **77,452** | **100%** |

### Exposing the Noise: Why We Dropped the 'Neutral' Sentiment

Following the initial classification, a database exploration in Python was conducted to validate the quality of the segmented data. This analysis revealed a crucial insight: the 'neutral' sentiment category introduced a significant amount of noise. Neutral reviews were largely comprised of ambiguous statements, unhelpful commentary, or non-actionable observations that diluted the data quality.

To maintain strict focus on competitor intelligence, lost revenue estimation, and identifying actual technical bugs for the War Room dashboard, the deliberate choice was made to filter out 'neutral' sentiments from the subsequent NLP and Data Warehouse phases.

-----

## Phase 3 — Python: Lemmatization with spaCy

Only negative reviews are processed with spaCy to extract the most recurrent linguistic patterns. The `it_core_news_sm` model performs lemmatization with a filter on stop-words and alphabetical tokens with a minimum length of 3 characters.

```python
import spacy
nlp = spacy.load("it_core_news_sm", disable=["ner", "parser"])

for doc in nlp.pipe(df_neg['testo'], batch_size=50):
    lemmi = [t.lemma_.lower() for t in doc
             if t.is_alpha and not t.is_stop and len(t.text) > 2]

    testo_lemmatizzato.append(" ".join(lemmi))
    lemmi_totali.append(",".join(lemmi))

    bigrams = [f"{lemmi[i]} {lemmi[i+1]}" for i in range(len(lemmi)-1)
               if len(lemmi) >= 2]
    bigrammi_totali.append(", ".join(bigrams))
```

The top 20 lemmas and bigrams extracted with `collections.Counter` are saved in the `top_20_lemmi_frequenti` table on MySQL. These patterns become the foundation for the regular expressions in the subsequent SQL phase.

-----

## Phase 4 — MySQL: Data Warehouse and VIEWs

The Data Warehouse consists of 5 VIEWs with distinct roles in the data model.

### VIEW 1 — `view_classifica_valutazione`

Average star rating ranking by bank. Dimensional hub in the Power BI model.

```sql
CREATE VIEW view_classifica_valutazione AS
SELECT
    banca,
    ROUND(AVG(valutazione), 2) AS media_valutazione,
    COUNT(*) AS totale_recensioni
FROM progetto_banca
GROUP BY banca
ORDER BY media_valutazione DESC;
```

### VIEW 2 — `view_dettaglio_recensioni_def`

The most complex view in the project. It uses `CASE` + `REGEXP` on NLP bigrams to automatically categorize each negative review into 6 macro-areas of service disruption, using a priority system to avoid double counting.

```sql
CREATE VIEW view_dettaglio_recensioni_def AS
SELECT banca, data, testo, valutazione,
CASE
    WHEN bigrammi_totali REGEXP 'riesco accedere|accedere app|aprire app|entrare app'
        OR testo REGEXP 'impossibile accedere|non si apre|non entra|impossibile entrare'
        THEN 'Login e Accesso'

    WHEN bigrammi_totali REGEXP 'app funzionare|problema tecnico|aggiornamento app|app bloccare'
        OR testo REGEXP 'si blocca|schermata bianca|funziona mai|lentissima|peggiorata'
        THEN 'Stabilità e Bug App'

    WHEN bigrammi_totali REGEXP 'impronta digitale|arrivare notifica|notifica push'
        OR testo REGEXP 'nessuna notifica|sms non arriva|otp non arriva|face id|token|impronta'
        THEN 'Sicurezza e Notifiche'

    WHEN bigrammi_totali REGEXP 'carta credito'
        OR testo REGEXP 'pagamento non|transazione fallita|bonifico non parte|saldo non aggiornato'
        THEN 'Carte e Pagamenti'

    WHEN bigrammi_totali REGEXP 'servizio cliente'
        OR testo REGEXP 'assistenza|call center|operatore'
        THEN 'Customer Care'

    WHEN testo REGEXP 'cambio banca|chiudo il conto|passo a|vado via|lascio'
        THEN 'Rischio Abbandono / Churn'

    ELSE 'Altro / Segnalazioni Generiche'
END AS categoria_disservizio
FROM progetto_banca_defsql
WHERE sentiment_feelit = 'negative';
```

### VIEW 3 — `view_disservizi_frequenti_def`

Aggregation of pain points by bank and category. Feeds the Power BI heatmap.

```sql
CREATE VIEW view_disservizi_frequenti_def AS
SELECT
    banca,
    categoria_disservizio,
    COUNT(*) AS totale_segnalazioni
FROM view_dettaglio_recensioni_def
GROUP BY banca, categoria_disservizio
ORDER BY banca, totale_segnalazioni DESC;
```

### VIEW 4 — `view_trend_temporale`

Monthly time series using `DATE_FORMAT`. Feeds temporal charts.

```sql
CREATE VIEW view_trend_temporale AS
SELECT
    banca,
    DATE_FORMAT(data, '%Y-%m') AS mese_anno,
    COUNT(*) AS totale_recensioni,
    SUM(CASE WHEN sentiment_feelit = 'negative' THEN 1 ELSE 0 END) AS recensioni_negative
FROM progetto_banca_sentiment
GROUP BY banca, mese_anno
ORDER BY banca, mese_anno;
```

### VIEW 5 — `view_disservizi_frequenti_grezzo`

Intermediate view using NLP bigrams as a filter via `JOIN` + `LIKE CONCAT` to identify recurring macro-problems prior to the final categorization.

-----

## Phase 5 — Power BI: Executive Dashboard

### Data Model — Star Schema

The relational model uses `view_classifica_valutazione` as the dimensional hub on `banca` and `Calendar` as a shared time dimension across all tables.

```text
progetto_banca_sentiment[banca]        →  view_classifica_valutazione[banca]
progetto_banca_sentiment[data]         →  Calendar[Date]
view_disservizio_testo_recensione[banca] →  view_classifica_valutazione[banca]
view_trend_temporale[banca]            →  view_classifica_valutazione[banca]
view_trend_temporale[mese_anno]        →  Calendar[Date]
view_disservizi_frequenti_count[banca] →  view_classifica_valutazione[banca]
```

### Dual DAX Engine

**Engine 1 — Brand Health** (77K rows · `progetto_banca_sentiment`)
Aggregated sentiment measures for Page 1.

**Engine 2 — FinTech War Room** (22K rows · `view_disservizio_testo_recensione`)
Operational KPIs on disruptions, critical bugs, and churn rate for Pages 2, 3, 4.

### Main DAX Measures

```dax
-- Killer metric
Churn_Rate_% =
DIVIDE([Volume_Abbandoni], [Totale_Disservizi_Rilevati], 0)

-- Critical bugs (3 technical debt categories)
Totale_Bug_Critici =
CALCULATE(
    COUNTROWS('view_disservizio_testo_recensione'),
    'view_disservizio_testo_recensione'[categoria_disservizio]
        IN {"Stabilità e Bug App", "Login e Accesso", "Sicurezza e Notifiche"}
)

-- Contextual ranking by bank
RankBanca =
RANKX(ALL('progetto_banca_sentiment'[banca]), [PctNegativo], , ASC, DENSE)

-- Time Intelligence MoM
VariazioneMsuM = [PctNegativo] - [PctNegMesePrecedente]

-- YTD
PctNegYTD =
CALCULATE([PctNegativo], DATESYTD(Calendar[Date]))
```

### The 4 Dashboard Pages

| Page | Name | Content |
|---|---|---|
| 1 | Brand Health & Sentiment | Aggregated KPIs · Donut chart · Reputational positioning matrix by bank |
| 2 | FinTech War Room | Pain points heatmap · Average star rating · KPIs on critical bugs and churn rate |
| 3 | Temporal Trend | 2022–2024 sentiment line chart · MoM Bar chart · Scatter chart: Bugs vs Churn · PctNegYTD Card |
| 4 | Drill-through Detail | Real review text table · Filters by bank / category / rating / year |

-----

## 📊 Key Results

| KPI | Value |
|---|---|
| Total reviews analyzed | 78,000 |
| Positive sentiment | 59.6% |
| Negative sentiment | 28.5% |
| Service disruptions detected (negative panel) | 22,201 |
| Global Churn Rate | 1.79% |
| Customers at risk of churn | 385 |
| Top pain point category | Stability and App Bugs — 4,860 reports |
| Second pain point category | Login and Access — 2,476 reports |
| Banks with positive sentiment \> 75% | Revolut · Fineco · Credit Agricole · BBVA |
| Negative anomaly peak | April–May 2024 — transversal across multiple players |

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

