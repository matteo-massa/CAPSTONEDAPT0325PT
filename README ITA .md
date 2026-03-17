# 🏦 Sentiment Analysis 

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-DAX-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![HuggingFace](https://img.shields.io/badge/HuggingFace-BERT-FFD21E?style=for-the-badge&logo=huggingface&logoColor=black)
![spaCy](https://img.shields.io/badge/spaCy-NLP-09A3D5?style=for-the-badge&logo=spacy&logoColor=white)
![CUDA](https://img.shields.io/badge/CUDA-GPU%20Accelerated-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completato-success?style=for-the-badge)
![Epicode](https://img.shields.io/badge/Capstone-Epicode%20Data%20Analytics-FF6B35?style=for-the-badge)

> Analisi del sentiment su **78.000 recensioni reali** di **8 banche italiane** estratte da Google Play Store nel periodo 2022–2024.  
> Pipeline end-to-end: scraping → classificazione NLP → Data Warehouse MySQL → Dashboard Power BI executive a 4 pagine.

---

## 📌 Indice

- [Obiettivo](#-obiettivo)
- [Stack tecnologico](#-stack-tecnologico)
- [Architettura del progetto](#-architettura-del-progetto)
- [Fase 1 — Python: Scraping](#fase-1--python-scraping)
- [Fase 2 — Python: Classificazione NLP con BERT](#fase-2--python-classificazione-nlp-con-bert)
- [Fase 3 — Python: Lemmatizzazione con spaCy](#fase-3--python-lemmatizzazione-con-spacy)
- [Fase 4 — MySQL: Data Warehouse e VIEW](#fase-4--mysql-data-warehouse-e-view)
- [Fase 5 — Power BI: Dashboard Executive](#fase-5--power-bi-dashboard-executive)
- [Risultati principali](#-risultati-principali)
- [Struttura del repository](#-struttura-del-repository)
- [Come replicare il progetto](#-come-replicare-il-progetto)

---

## 🎯 Obiettivo

🏦 Le app bancarie italiane raccolgono migliaia di segnalazioni ogni anno.
Ho analizzato 78.000 recensioni reali di 8 banche italiane per scoprirlo.

Partendo da una domanda semplice:
👉 Cosa rivelano davvero le recensioni degli utenti sul banking digitale italiano?

Le recensioni sugli store digitali sono una fonte di intelligence non strutturata e spesso ignorata dagli istituti bancari. Questo progetto trasforma quei testi grezzi in KPI operativi misurabili, identificando disservizi tecnici ricorrenti, trend temporali e rischio di abbandono cliente.

Le 8 banche analizzate coprono sia il banking tradizionale che il fintech puro:

| Banca | Tipo |
|---|---|
| Intesa Sanpaolo | Tradizionale |
| Unicredit | Tradizionale |
| Credit Agricole | Tradizionale |
| Credem | Tradizionale |
| Fineco | Ibrido |
| BBVA | Digitale |
| Revolut | Fintech |
| Hype | Fintech |

---

## 🛠 Stack tecnologico

| Layer | Tecnologia |
|---|---|
| Scraping | Python · google-play-scraper · SQLAlchemy |
| NLP — Sentiment | HuggingFace Transformers · `neuraly/bert-base-italian-cased-sentiment` · PyTorch · CUDA |
| NLP — Lemmatizzazione | spaCy · `it_core_news_sm` |
| NLP — Frequenze | collections.Counter |
| Data Warehouse | MySQL 8.0 · VIEW · CASE · REGEXP |
| Visualizzazione | Power BI · DAX · Star Schema |

---

## 🏗 Architettura del progetto

```
Google Play Store
        │
        ▼
┌─────────────────────┐
│  FASE 1 — SCRAPING  │  Python · google-play-scraper
│  78.000 recensioni  │  8 banche · 2022-2024
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  FASE 2 — NLP BERT  │  neuraly/bert-base-italian-cased-sentiment
│  Sentiment analysis │  positive / negative / neutral
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  FASE 3 — spaCy     │  Lemmatizzazione recensioni negative
│  Lemmi + Bigrammi   │  Top 20 pattern estratti con Counter
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  FASE 4 — MySQL     │  5 VIEW ingegnerizzate
│  Data Warehouse     │  CASE + REGEXP su bigrammi NLP
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  FASE 5 — POWER BI  │  Star Schema · DAX · 4 pagine executive
│  Dashboard          │  Doppio motore · Time Intelligence
└─────────────────────┘
```

---

## Fase 1 — Python: Scraping

Lo scraper utilizza la libreria `google-play-scraper` per estrarre le recensioni direttamente dagli store digitali senza intermediari.

Il dizionario `banche_google` mappa ogni banca al proprio `app_id` ufficiale su Google Play. Il loop itera su ogni banca, filtra per lingua italiana e anno di pubblicazione (2022–2024), e salva i risultati su MySQL tramite SQLAlchemy.

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

Il dataset grezzo viene deduplicato e salvato nella tabella `recensioni_google` prima di procedere al preprocessing NLP.

---

## Fase 2 — Python: Classificazione NLP con BERT

Il modello utilizzato è [`neuraly/bert-base-italian-cased-sentiment`](https://huggingface.co/neuraly/bert-base-italian-cased-sentiment), un modello BERT fine-tuned specificamente sull'italiano disponibile su HuggingFace.

Il pipeline rileva automaticamente la presenza di GPU (CUDA) e scala l'inferenza di conseguenza. Il batch processing con `batch_size=128` e `truncation=True` gestisce i testi lunghi in modo efficiente.

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

**Risultato della classificazione:**

| Sentiment | Recensioni | % |
|---|---|---|
| positive | 46.000 | 59,6% |
| negative | 22.200 | 28,5% |
| neutral | 9.252 | 11,9% |
| **Totale** | **77.452** | **100%** |

---

## Fase 3 — Python: Lemmatizzazione con spaCy

Le sole recensioni negative vengono processate con spaCy per estrarre i pattern linguistici più ricorrenti. Il modello `it_core_news_sm` esegue lemmatizzazione con filtro su stop-words e token alfabetici con lunghezza minima 3 caratteri.

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

I top 20 lemmi e bigrammi estratti con `collections.Counter` vengono salvati nella tabella `top_20_lemmi_frequenti` su MySQL. Questi pattern diventano la base delle espressioni regolari nella fase SQL successiva.

---

## Fase 4 — MySQL: Data Warehouse e VIEW

Il Data Warehouse è composto da 5 VIEW con ruoli distinti nel modello dati.

### VIEW 1 — `view_classifica_valutazione`
Ranking medio stelle per banca. Hub dimensionale nel modello Power BI.

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
La vista più complessa del progetto. Usa `CASE` + `REGEXP` sui bigrammi NLP per categorizzare automaticamente ogni recensione negativa in 6 macro-aree di disservizio, con sistema di priorità per evitare doppi conteggi.

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
Aggregazione disservizi per banca e categoria. Alimenta la heatmap Power BI.

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
Serie storica mensile con `DATE_FORMAT`. Alimenta i grafici temporali.

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
View intermedia che usa i bigrammi NLP come filtro tramite `JOIN` + `LIKE CONCAT` per identificare i macro-problemi ricorrenti prima della categorizzazione finale.

---

## Fase 5 — Power BI: Dashboard Executive

### Modello dati — Star Schema

Il modello relazionale usa `view_classifica_valutazione` come hub dimensionale su `banca` e `Calendar` come dimensione temporale condivisa tra tutte le tabelle.

```
progetto_banca_sentiment[banca]        →  view_classifica_valutazione[banca]
progetto_banca_sentiment[data]         →  Calendar[Date]
view_disservizio_testo_recensione[banca] →  view_classifica_valutazione[banca]
view_trend_temporale[banca]            →  view_classifica_valutazione[banca]
view_trend_temporale[mese_anno]        →  Calendar[Date]
view_disservizi_frequenti_count[banca] →  view_classifica_valutazione[banca]
```

### Doppio motore DAX

**Motore 1 — Brand Health** (77K righe · `progetto_banca_sentiment`)
Misure sentiment aggregate per Pagina 1.

**Motore 2 — FinTech War Room** (22K righe · `view_disservizio_testo_recensione`)
KPI operativi su disservizi, bug critici e tasso di fuga per Pagine 2, 3, 4.

### Misure DAX principali

```dax
-- Killer metric
Tasso_di_Fuga_% =
DIVIDE([Volume_Abbandoni], [Totale_Disservizi_Rilevati], 0)

-- Bug critici (3 categorie di debito tecnico)
Totale_Bug_Critici =
CALCULATE(
    COUNTROWS('view_disservizio_testo_recensione'),
    'view_disservizio_testo_recensione'[categoria_disservizio]
        IN {"Stabilità e Bug App", "Login e Accesso", "Sicurezza e Notifiche"}
)

-- Ranking contestuale per banca
RankBanca =
RANKX(ALL('progetto_banca_sentiment'[banca]), [PctNegativo], , ASC, DENSE)

-- Time Intelligence MoM
VariazioneMsuM = [PctNegativo] - [PctNegMesePrecedente]

-- YTD
PctNegYTD =
CALCULATE([PctNegativo], DATESYTD(Calendar[Date]))
```

### Le 4 pagine della dashboard

| Pagina | Nome | Contenuto |
|---|---|---|
| 1 | Brand Health & Sentiment | KPI aggregate · Donut chart · Matrice posizionamento reputazionale per banca |
| 2 | FinTech War Room | Heatmap disservizi · Valutazione media stelle · KPI bug critici e tasso di fuga |
| 3 | Trend Temporale | Line chart sentiment 2022–2024 · Bar MoM · Scatter Bug vs Abbandoni · Card PctNegYTD |
| 4 | Dettaglio Drill-through | Tabella testi recensioni reali · Filtri per banca / categoria / valutazione / anno |

---

## 📊 Risultati principali

| KPI | Valore |
|---|---|
| Recensioni totali analizzate | 78.000 |
| Sentiment positivo | 59,6% |
| Sentiment negativo | 28,5% |
| Disservizi rilevati (panel negativo) | 22.201 |
| Tasso di Fuga Globale | 1,79% |
| Clienti a rischio abbandono | 385 |
| Prima categoria di disservizio | Stabilità e Bug App — 4.860 segnalazioni |
| Seconda categoria di disservizio | Login e Accesso — 2.476 segnalazioni |
| Banche con sentiment positivo > 75% | Revolut · Fineco · Credit Agricole · BBVA |
| Picco anomalia negativa | Aprile–Maggio 2024 — trasversale su più player |

---

## 📁 Struttura del repository

```
CAPSTONEDAPT0325PT/
│
├── CapstonePt Scraping .ipynb     # Scraping Google Play Store
├── progetto capstone P2.ipynb     # NLP con BERT + CUDA · Lemmatizzazione spaCy · Frequenze Counter
├── CAPSTONE SQL.sql               # Tutte le VIEW MySQL del Data Warehouse
├── capstone matteo.pbix           # Dashboard Power BI — 4 pagine executive
└── README.md
```

---

## ▶️ Come replicare il progetto

### Requisiti

```bash
pip install google-play-scraper pandas sqlalchemy pymysql
pip install transformers torch tqdm
pip install spacy
python -m spacy download it_core_news_sm
```

### Configurazione connessione MySQL

```python
sqlalchemy_url = f'mysql+pymysql://{USER}:{PASSWORD}@{HOST}/{DATABASE}'
```

### Ordine di esecuzione

```bash
# 1. Scraping Google Play Store
python python/01_scraping.py

# 2. Classificazione sentiment con BERT
python python/02_sentiment_bert.py

# 3. Lemmatizzazione con spaCy
python python/03_lemmatizzazione_spacy.py

# 4. Estrazione frequenze top 20
python python/04_frequenze_counter.py

# 5. Creare le VIEW MySQL nell'ordine:
#    view_classifica_valutazione
#    → view_dettaglio_recensioni_def
#    → view_disservizi_frequenti_def
#    → view_disservizi_frequenti_grezzo
#    → view_trend_temporale

# 6. Aprire capstone_matteo.pbix in Power BI Desktop
#    Aggiornare la stringa di connessione MySQL in Trasforma dati
```

---

## 🎓 Capstone finale

Progetto realizzato come Capstone finale del corso **Data Analytics PT** — Epicode (Marzo 2025).

---

*Per domande sull'architettura o per scambiare due parole sul progetto, contattami su [LinkedIn](https://www.linkedin.com/in/matteo-massa-6a2372397).*
