








CREATE  VIEW view_classifica_valutazione AS
SELECT 
    banca,
    ROUND(AVG(valutazione), 2) AS media_valutazione,
    COUNT(*) AS totale_recensioni
FROM progetto_banca
GROUP BY banca
ORDER BY media_valutazione DESC;

CREATE VIEW view_trend_temporale AS
SELECT 
    banca,
    DATE_FORMAT(data, '%Y-%m') AS mese_anno,
    COUNT(*) AS totale_recensioni,
    SUM(CASE WHEN sentiment_feelit = 'negative' THEN 1 ELSE 0 END) AS recensioni_negative
FROM progetto_banca_sentiment
GROUP BY banca, mese_anno
ORDER BY banca, mese_anno;

CREATE VIEW view_disservizi_frequenti_grezzo AS

-- 1. Creiamo il filtro estraendo SOLO i 20 bigrammi
WITH FiltroBigrammi AS (
    SELECT parola_chiave 
    FROM top_20_lemmi_frequenti 
    WHERE tipo = 'bigramma'
)

-- 2. Usiamo il filtro sul DB principale (def)
SELECT 
    DB.banca,
    F.parola_chiave AS macro_problema,
    COUNT(*) as numero_segnalazioni
FROM progetto_banca_defsql DB
JOIN FiltroBigrammi F 
    -- Il JOIN agisce da filtro: collega la riga solo se il bigramma è contenuto nel testo/bigrammi totali
    ON DB.bigrammi_totali LIKE CONCAT('%', F.parola_chiave, '%') 
WHERE DB.sentiment_feelit = 'negative'
GROUP BY DB.banca, F.parola_chiave
ORDER BY DB.banca, numero_segnalazioni DESC;

CREATE VIEW view_disservizi_frequenti_def AS
SELECT 
    banca,
    categoria_disservizio,
    COUNT(*) AS totale_segnalazioni
FROM view_dettaglio_recensioni_def
GROUP BY 
    banca, 
    categoria_disservizio
ORDER BY 
    banca, 
    totale_segnalazioni DESC;
    
    CREATE VIEW view_dettaglio_recensioni_def AS
SELECT 
    banca,
    data,
    testo,
    valutazione,
    CASE 
        -- Priorità 1: Accesso e Login
        WHEN bigrammi_totali REGEXP 'riesco accedere|riesco entrare|accedere app|aprire app|entrare app|home banking' 
             OR testo REGEXP 'impossibile accedere|non si apre|non entra|impossibile entrare' 
            THEN 'Login e Accesso'
        
        -- Priorità 2: Stabilità e Bug App
        WHEN bigrammi_totali REGEXP 'app funzionare|problema tecnico|risolvere problema|aggiornamento app|app bloccare|aggiornare app' 
             OR testo REGEXP 'si blocca|si chiude|schermata bianca|schermata nera|arresto anomalo|funziona mai|funzionamento|lenta|lentissima|peggiorata' 
            THEN 'Stabilità e Bug App'
        
        -- Priorità 3: Sicurezza e Notifiche
        WHEN bigrammi_totali REGEXP 'impronta digitale|arrivare notifica|notifica push' 
             OR testo REGEXP 'nessuna notifica|sms non arriva|otp non arriva|face id|riconoscimento facciale|token|impronta' 
            THEN 'Sicurezza e Notifiche'
        
        -- Priorità 4: Carte e Pagamenti
        WHEN bigrammi_totali REGEXP 'carta credito' 
             OR testo REGEXP 'pagamento non|transazione fallita|bonifico non parte|saldo non aggiornato' 
            THEN 'Carte e Pagamenti'
        
        -- Priorità 5: Customer Care
        WHEN bigrammi_totali REGEXP 'servizio cliente' 
             OR testo REGEXP 'assistenza|call center|operatore'
            THEN 'Customer Care'
            
        -- Priorità 6: Rischio Abbandono )
        WHEN bigrammi_totali REGEXP 'cambiare banca|altro banca|chiudere conto' 
             OR testo REGEXP 'cambiare banca|altra banca|chiudere conto|chiudo il conto' 
            THEN 'Rischio Abbandono / Churn'
        
        ELSE 'Altro / Segnalazioni Generiche'
    END AS categoria_disservizio
FROM progetto_banca_defsql
WHERE sentiment_feelit = 'negative';