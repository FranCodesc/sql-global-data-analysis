# 🌍 Progetto SQL – Analisi Integrata Socio-Economica ed Energetica

Autore: **Francesco Benassi**  
DBMS: **PostgreSQL (pgAdmin 4)**

Dataset utilizzati:  
- **Global Country Information Dataset** (world_data_2023) → indicatori socio‑economici, demografici, sanitari, ambientali  
- **Global Data on Sustainable Energy Dataset** (energy_data) → indicatori energetici, rinnovabili, consumi, emissioni  

---

# 📌 Obiettivo del progetto
Costruire un database relazionale integrando due dataset globali e realizzare analisi statistiche avanzate per identificare relazioni non banali tra:
- condizioni socio‑economiche,
- pressioni demografiche,
- struttura territoriale,
- dinamiche energetiche e ambientali,
- evoluzione temporale dei principali indicatori (2000–2020).

Il progetto evita semplici classifiche e si concentra su **cluster, fasce, indicatori derivati, confronti temporali e analisi interpretativa**, come richiesto nelle correzioni del docente.

---

# 🧩 Fase 1 – Analisi preliminare
- Esame della struttura dei dataset originali.  
- Identificazione delle colonne rilevanti, valori mancanti e normalizzazioni necessarie.  
- Uniformazione dei nomi delle colonne per l’importazione nel DBMS.  

---

# ❓ Fase 2 – Domande di analisi

## 🔵 **GRUPPO A – Analisi Global Country Information Dataset**
1. **A1 – Relazione tra densità demografica e PIL pro capite**  
2. **A2 – Differenze territoriali del PIL tramite macro‑regioni**  
3. **A3 – Identificazione outlier economici tramite z‑score**  
4. **A4 – Istruzione terziaria e disoccupazione: esiste un pattern?**  
5. **A5 – Relazione tra area forestale e emissioni pro capite (profilazione ambientale)**  

---

## 🟢 **GRUPPO B – Analisi Global Data on Sustainable Energy Dataset**
1. **B1 – Evoluzione dell’accesso all’elettricità (2000–2020)**  
2. **B2 – Transizione energetica per fasce di PIL pro capite**  
3. **B3 – Cambiamento della quota di elettricità low‑carbon nel tempo (cluster di transizione)**  

---

## 🔴 **GRUPPO C – Analisi relazionale (integrazione tra dataset)**
1. **C1 – Speranza di vita e accesso all’elettricità**  
2. **C2 – Urbanizzazione, tassazione e impatto crisi 2008 sull’efficienza energetica**  
3. **C3 – Pressione demografica e stabilità del mix energetico (2000–2020)**  

---

# 🧹 Fase 3 – Pulizia dei dati  
- Ho importato i dataset in **Google Sheets**.  
- Ho corretto valori mancanti, formati incoerenti e intestazioni.  
- Ho uniformato nomi delle colonne per permettere un'importazione pulita in PostgreSQL.  
- Ho utilizzato strumenti di supporto AI per generare formule e automatizzare la pulizia (come Code Interpreter di ChatGPT).
- Ho inserito poi i dataset puliti nella cartella allegata `Dataset_clean`.  

---

# 🗄️ Fase 4 – Creazione del database, importazione dataset e modello relazionale

## **4.1 – Creazione tabella `world_data_2023`**

```sql
CREATE TABLE world_data_2023 (
    Country TEXT,
    Density_P_Km2 NUMERIC,
    Abbreviation TEXT,
    Agricultural_Land_pct NUMERIC,
    Land_AreaKm2 NUMERIC,
    Armed_Forces_size NUMERIC,
    Birth_Rate NUMERIC,
    Calling_Code NUMERIC,
    Capital_Major_City TEXT,
    Co2_Emissions NUMERIC,
    CPI NUMERIC,
    CPI_Change_pct NUMERIC,
    Currency_Code TEXT,
    Fertility_Rate NUMERIC,
    Forested_Area_pct NUMERIC,
    Gasoline_Price NUMERIC,
    GDP NUMERIC,
    Gross_primary_education_enrollment_pct NUMERIC,
    Gross_tertiary_education_enrollment_pct NUMERIC,
    Infant_mortality NUMERIC,
    Largest_city TEXT,
    Life_expectancy NUMERIC,
    Maternal_mortality_ratio NUMERIC,
    Minimum_wage NUMERIC,
    Official_language TEXT,
    Out_of_pocket_health_expenditure NUMERIC,
    Physicians_per_thousand NUMERIC,
    Population NUMERIC,
    Population_Labor_force_participation_pct NUMERIC,
    Tax_revenue_pct NUMERIC,
    Total_tax_rate NUMERIC,
    Unemployment_rate NUMERIC,
    Urban_population NUMERIC,
    Latitude NUMERIC,
    Longitude NUMERIC
);
```

### Importazione CSV (pgAdmin 4)
- Tasto destro sulla tabella → “Import/Export”  
- Format: CSV – Header: Yes – Delimiter: , – Encoding: UTF8  
- Import del file pulito  

### Aggiunta Primary Key
```sql
ALTER TABLE world_data_2023
ADD COLUMN id SERIAL PRIMARY KEY;
```

---

## **4.2 – Creazione tabella `energy_data`**

```sql
CREATE TABLE energy_data (
    Entity TEXT,
    Year INT,
    Access_to_electricity_pct_of_population NUMERIC,
    Access_to_clean_fuels_for_cooking NUMERIC,
    Renewable_electricity_generating_capacity_per_capita NUMERIC,
    Financial_flows_to_developing_countries_usd NUMERIC,
    Renewable_energy_share_in_total_final_energy_consumption_pct NUMERIC,
    Electricity_from_fossil_fuels_TWh NUMERIC,
    Electricity_from_nuclear_TWh NUMERIC,
    Electricity_from_renewables_TWh NUMERIC,
    Low_carbon_electricity_pct NUMERIC,
    Primary_energy_consumption_per_capita_kWh NUMERIC,
    Energy_intensity_level_of_primary_energy_MJ_per_GDP NUMERIC,
    Co2_emissions_kt_by_country NUMERIC,
    Renewables_equivalent_primary_energy_pct NUMERIC,
    gdp_growth NUMERIC,
    gdp_per_capita NUMERIC,
    Density_P_Km2 NUMERIC,
    Land_AreaKm2 NUMERIC,
    Latitude NUMERIC,
    Longitude NUMERIC
);
```

Import identico alla tabella precedente.

---

## **4.3 – Collegamento relazionale tra i due dataset**

### Aggiunta FK
```sql
ALTER TABLE energy_data
ADD COLUMN country_id INT;
```

### Popolamento FK
```sql
UPDATE energy_data
SET country_id = world_data_2023.id
FROM world_data_2023
WHERE energy_data.Entity = world_data_2023.Country;
```

### Identificazione valori non collegati
```sql
SELECT DISTINCT Entity
FROM energy_data
WHERE country_id IS NULL;
```

### Correzioni nomi (esempi)
```sql
UPDATE energy_data SET Entity = 'Czech Republic' WHERE Entity = 'Czechia';
UPDATE energy_data SET Entity = 'The Bahamas' WHERE Entity = 'Bahamas';
UPDATE energy_data SET Entity = 'The Gambia' WHERE Entity = 'Gambia';
```

### Riassegnazione FK
```sql
UPDATE energy_data
SET country_id = world_data_2023.id
FROM world_data_2023
WHERE energy_data.Entity = world_data_2023.Country
  AND energy_data.country_id IS NULL;
```

### Creazione vincolo relazionale
```sql
ALTER TABLE energy_data
ADD CONSTRAINT fk_country
FOREIGN KEY (country_id)
REFERENCES world_data_2023(id);
```

---

## **4.4 – Verifica JOIN**
```sql
SELECT 
    world_data_2023.Country,
    GDP,
    Co2_emissions_kt_by_country,
    year
FROM world_data_2023
JOIN energy_data
ON energy_data.country_id = world_data_2023.id
WHERE GDP IS NOT NULL
  AND Co2_emissions_kt_by_country IS NOT NULL
  AND year = 2019
ORDER BY GDP DESC;
```

---

# 🧠 Fase 5 – Esecuzione analisi
Le query complete del progetto (A1–A5, B1–B3, C1–C3) sono contenute nel file:

📄 **SCRIPT_SQL.sql**

Ogni query contiene:
- Obiettivo  
- Risultato atteso  
- SQL  
- Analisi del risultato

Gli screenshoot dei risultati delle query sono contenuti nella cartella allegata `Risultati_Query`. 

---

# 🎯 Conclusioni
Il progetto mostra che:

- indicatori socio‑economici, demografici, ambientali ed energetici generano pattern complessi;  
- molte dinamiche (transizione low‑carbon, volatilità del mix, impatti della crisi 2008) emergono solo tramite analisi temporali e segmentazioni;  
- la relazione tra dataset consente insight avanzati su resilienza, sviluppo, pressione demografica e qualità dei sistemi pubblici;  
- tutte le analisi rispettano le correzioni del docente e superano il livello di semplice descrizione statistica.

---

# ✔️ Fine README.md
