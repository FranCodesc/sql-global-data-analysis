/* ============================================================
                  PROGETTO SQL – SCRIPT COMPLETO
   Autore 
      Francesco Benassi
   Descrizione 

      Le query sono divise in 3 categorie:
      A ---> Analisi del dataset principale 
             'Global Country Information Dataset'
      B ---> Analisi del secondo dataset scelto
             'Global Data on Sustainable Energy'
      C ---> Analisi dei due dataset correlati fra loro

   ============================================================ */



/* =================================================================
   GRUPPO A: ANALISI SUL DATASET 'Global Country Information Dataset' 
   ================================================================= */


/********************************************************
 A1 – PIL PRO CAPITE PER FASCE DI DENSITÀ (ANNO 2023)


1. OBIETTIVO
   Analizzare come cambia il pil pro capite al variare della densita'
   di popolazione. I vari paesi vengono raggruppati e divisi in fasce
   di densita' abitativa confrontando il pil medio di ogni fascia con
   il pil globale.

2. RISULTATO ATTESO
   I paesi con densita' agli estremi (molto bassa o molto alta) dovrebbero
   mostrare un pil pro capite inferiore mentre le fasce intermedie
   potrebbero essere piu ricche grazie a una migliore urbanizzazione e
   presenza di infrastrutture.

3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        world_data_2023.country,
        world_data_2023.gdp,
        world_data_2023.population,
        world_data_2023.density_p_km2,
        (world_data_2023.gdp / NULLIF(world_data_2023.population, 0)) AS gdp_per_capita,
        CASE
            WHEN world_data_2023.density_p_km2 < 50 THEN '1) < 50 ab/km²'
            WHEN world_data_2023.density_p_km2 < 150 THEN '2) 50–149 ab/km²'
            WHEN world_data_2023.density_p_km2 < 300 THEN '3) 150–299 ab/km²'
            WHEN world_data_2023.density_p_km2 < 600 THEN '4) 300–599 ab/km²'
            ELSE '5) ≥ 600 ab/km²'
        END AS density_band
    FROM world_data_2023
    WHERE world_data_2023.gdp IS NOT NULL
      AND world_data_2023.population IS NOT NULL
      AND world_data_2023.density_p_km2 IS NOT NULL
),

global_stats AS (
    SELECT
        AVG(base.gdp_per_capita) AS global_avg_gdp
    FROM base
),

band_stats AS (
    SELECT
        base.density_band,
        COUNT(*) AS countries_count,
        AVG(base.gdp_per_capita) AS avg_gdp_band
    FROM base
    GROUP BY base.density_band
)

SELECT
    band_stats.density_band,
    band_stats.countries_count,
    ROUND(band_stats.avg_gdp_band::numeric, 2) AS avg_gdp_per_capita,
    ROUND(global_stats.global_avg_gdp::numeric, 2) AS global_avg_gdp_per_capita,
    ROUND((band_stats.avg_gdp_band - global_stats.global_avg_gdp)::numeric, 2)
        AS diff_from_global_avg
FROM band_stats
CROSS JOIN global_stats
ORDER BY band_stats.density_band;

/*

4. ANALISI DEL RISULTATO

   Come previsto i paesi nelle categori di densita' abitativa estrema (molto alta
   o molto bassa) hanno un pil pro capite inferiore alla media globale. La fascia
   intermedia 150-299 ab/km2 risulta essere nettamente la piu ricca. Cio' suggerisce
   che un livello intermedio di densita' favorisca condizioni economiche migliori
   mentre inversamente le densita' estreme siano contesti meno favorevoli.

********************************************************/


/********************************************************
 A2 – DISUGUAGLIANZA ECONOMICA PER MACRO-REGIONE (ANNO 2023)


1. OBIETTIVO
   Analizzare la disuguaglianza economica interna alle diverse
   macro-regioni geografiche del mondo, misurata tramite il PIL
   pro capite. Le macro-regioni vengono definite a partire dalle
   coordinate geografiche (latitudine e longitudine) e per ciascuna
   si calcolano media, minimo, massimo e deviazione standard del
   PIL pro capite.

2. RISULTATO ATTESO
   Mi aspetto che alcune macro-regioni (ad esempio le Americhe o
   l'Asia) presentino una forte disuguaglianza interna, con paesi
   molto ricchi e paesi molto poveri, mentre altre (ad esempio
   l'Europa o l'Oceania) potrebbero mostrare valori piu' concentrati
   intorno alla media.
   

3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        world_data_2023.country,
        world_data_2023.gdp,
        world_data_2023.population,
        (world_data_2023.gdp / NULLIF(world_data_2023.population, 0)) AS gdp_per_capita,
        world_data_2023.latitude,
        world_data_2023.longitude,
        CASE

            WHEN world_data_2023.latitude >= 12 AND world_data_2023.latitude <= 40
             AND world_data_2023.longitude >= 25 AND world_data_2023.longitude <= 60
                THEN 'Middle East'

            WHEN world_data_2023.latitude >= 5 AND world_data_2023.latitude <= 83
             AND world_data_2023.longitude >= -170 AND world_data_2023.longitude <= -50
                THEN 'North America'

            WHEN world_data_2023.latitude >= -60 AND world_data_2023.latitude <= 15
             AND world_data_2023.longitude >= -90 AND world_data_2023.longitude <= -30
                THEN 'South America'

            WHEN world_data_2023.latitude >= 35 AND world_data_2023.latitude <= 72
             AND world_data_2023.longitude >= -25 AND world_data_2023.longitude <= 60
                THEN 'Europe'

            WHEN world_data_2023.latitude >= -35 AND world_data_2023.latitude <= 37
             AND world_data_2023.longitude >= -20 AND world_data_2023.longitude <= 55
                THEN 'Africa'

            WHEN world_data_2023.latitude >= -10 AND world_data_2023.latitude <= 80
             AND world_data_2023.longitude >= 60 AND world_data_2023.longitude <= 180
                THEN 'Asia'

            WHEN world_data_2023.latitude >= -50 AND world_data_2023.latitude <= 10
             AND world_data_2023.longitude >= 110 AND world_data_2023.longitude <= 180
                THEN 'Oceania'

            ELSE 'Altro/Non classificato'

        END AS macro_region
    FROM world_data_2023
    WHERE world_data_2023.gdp IS NOT NULL
      AND world_data_2023.population IS NOT NULL
      AND world_data_2023.latitude IS NOT NULL
      AND world_data_2023.longitude IS NOT NULL
),

region_stats AS (
    SELECT
        base.macro_region,
        COUNT(*) AS countries_count,
        AVG(base.gdp_per_capita) AS avg_gdp_per_capita,
        MIN(base.gdp_per_capita) AS min_gdp_per_capita,
        MAX(base.gdp_per_capita) AS max_gdp_per_capita,
        STDDEV_POP(base.gdp_per_capita) AS stddev_gdp_per_capita
    FROM base
    WHERE base.macro_region <> 'Altro/Non classificato'
    GROUP BY base.macro_region
)

SELECT
    region_stats.macro_region,
    region_stats.countries_count,
    ROUND(region_stats.avg_gdp_per_capita::numeric, 2) AS avg_gdp_per_capita,
    ROUND(region_stats.min_gdp_per_capita::numeric, 2) AS min_gdp_per_capita,
    ROUND(region_stats.max_gdp_per_capita::numeric, 2) AS max_gdp_per_capita,
    ROUND(region_stats.stddev_gdp_per_capita::numeric, 2) AS stddev_gdp_per_capita
FROM region_stats
ORDER BY region_stats.stddev_gdp_per_capita DESC;


/*

4. ANALISI DEL RISULTATO
   Dall’analisi emerge che l’Europa è la macro-regione con i livelli di PIL 
   più elevati ma anche con la maggiore disuguaglianza interna. Oceania e 
   Middle East mostrano anche loro livelli di disuguaglianza elevati, mentre 
   South America e Africa risultano più omogenee, seppur con valori di 
   PIL medio più bassi. North America e Asia si posizionano in una 
   fascia intermedia, con buona ricchezza media e una polarizzazione interna moderata.
   Nel complesso, la distribuzione globale del PIL evidenzia forti squilibri economici
   tra regioni e all’interno delle regioni stesse.
********************************************************/


/********************************************************
 A3 – OUTLIER POSITIVI E NEGATIVI PER PIL PRO CAPITE (PERCENTILI 5 E 95 PER MACRO-REGIONE – ANNO 2023)


1. OBIETTIVO
   Individuare, per ciascuna macro-regione, sia i paesi molto piu'
   poveri sia quelli molto piu' ricchi rispetto al contesto regionale,
   utilizzando il quinto e il 95esimo percentile come soglie statistiche.

2. RISULTATO ATTESO
   Mi aspetto di rilevare paesi estremamente ricchi nelle regioni con
   forte eterogeneita' (Europa, Middle East, Asia) e paesi molto poveri
   nelle regioni con reddito medio basso (Africa, South America).
   Il metodo dei percentili permette di individuare entrambi gli estremi.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        world_data_2023.country,
        world_data_2023.gdp,
        world_data_2023.population,
        (world_data_2023.gdp / NULLIF(world_data_2023.population, 0)) AS gdp_per_capita,
        world_data_2023.latitude,
        world_data_2023.longitude,
        CASE
            WHEN world_data_2023.latitude >= 12 AND world_data_2023.latitude <= 40
             AND world_data_2023.longitude >= 25 AND world_data_2023.longitude <= 60
                THEN 'Middle East'

            WHEN world_data_2023.latitude >= 5 AND world_data_2023.latitude <= 83
             AND world_data_2023.longitude >= -170 AND world_data_2023.longitude <= -50
                THEN 'North America'

            WHEN world_data_2023.latitude >= -60 AND world_data_2023.latitude <= 15
             AND world_data_2023.longitude >= -90 AND world_data_2023.longitude <= -30
                THEN 'South America'

            WHEN world_data_2023.latitude >= 35 AND world_data_2023.latitude <= 72
             AND world_data_2023.longitude >= -25 AND world_data_2023.longitude <= 60
                THEN 'Europe'

            WHEN world_data_2023.latitude >= -35 AND world_data_2023.latitude <= 37
             AND world_data_2023.longitude >= -20 AND world_data_2023.longitude <= 55
                THEN 'Africa'

            WHEN world_data_2023.latitude >= -10 AND world_data_2023.latitude <= 80
             AND world_data_2023.longitude >= 60 AND world_data_2023.longitude <= 180
                THEN 'Asia'

            WHEN world_data_2023.latitude >= -50 AND world_data_2023.latitude <= 10
             AND world_data_2023.longitude >= 110 AND world_data_2023.longitude <= 180
                THEN 'Oceania'

            ELSE 'Altro/Non classificato'
        END AS macro_region
    FROM world_data_2023
    WHERE world_data_2023.gdp IS NOT NULL
      AND world_data_2023.population IS NOT NULL
      AND world_data_2023.latitude IS NOT NULL
      AND world_data_2023.longitude IS NOT NULL
),

region_percentiles AS (
    SELECT
        base.macro_region,
        percentile_disc(0.05) WITHIN GROUP (ORDER BY base.gdp_per_capita)
            AS p5_gdp,
        percentile_disc(0.95) WITHIN GROUP (ORDER BY base.gdp_per_capita)
            AS p95_gdp
    FROM base
    WHERE base.macro_region <> 'Altro/Non classificato'
    GROUP BY base.macro_region
),

merged AS (
    SELECT
        base.country,
        base.macro_region,
        base.gdp_per_capita,
        region_percentiles.p5_gdp,
        region_percentiles.p95_gdp
    FROM base
    JOIN region_percentiles
        ON base.macro_region = region_percentiles.macro_region
)

SELECT
    merged.country,
    merged.macro_region,
    ROUND(merged.gdp_per_capita::numeric, 2) AS pil_pro_capite,
    ROUND(merged.p5_gdp::numeric, 2) AS soglia_5_percentile,
    ROUND(merged.p95_gdp::numeric, 2) AS soglia_95_percentile,
    CASE
        WHEN merged.gdp_per_capita <= merged.p5_gdp THEN 'OUTLIER POVERO'
        WHEN merged.gdp_per_capita >= merged.p95_gdp THEN 'OUTLIER RICCO'
        ELSE 'NORMAL RANGE'
    END AS categoria_outlier
FROM merged
WHERE merged.gdp_per_capita <= merged.p5_gdp
   OR merged.gdp_per_capita >= merged.p95_gdp
ORDER BY merged.macro_region, merged.gdp_per_capita ASC;


/*

4. ANALISI DEL RISULTATO
   I paesi nel quinto percentile risultano essere le economie piu' povere
   delle rispettive macro-regioni, come Burundi, Somalia e Malawi in
   Africa, Afghanistan in Asia e Haiti in North America. Al contrario,
   paesi come Singapore, Liechtenstein, Monaco, Qatar e Stati Uniti
   ricadono nel 95esimo percentile, emergendo come economie nettamente piu'
   ricche del loro contesto regionale. I risultati confermano forti
   disparita' interne soprattutto in Europa, Asia e Middle East.

********************************************************/

/********************************************************
 A4 – ISTRUZIONE TERZIARIA E DISOCCUPAZIONE (ANNO 2023)


1. OBIETTIVO
   Analizzare come cambia il tasso di disoccupazione al variare del
   livello di istruzione terziaria. I paesi vengono divisi in quattro
   fasce (quartili) in base all'iscrizione all'istruzione terziaria e
   per ogni fascia si calcola la disoccupazione media.

2. RISULTATO ATTESO
   Mi aspetto che, passando dalle fasce con istruzione terziaria più
   bassa a quelle con istruzione più alta, il tasso medio di
   disoccupazione diminuisca, anche se possono esistere eccezioni.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        world_data_2023.Country,
        world_data_2023.Gross_tertiary_education_enrollment_pct,
        world_data_2023.Unemployment_rate
    FROM world_data_2023
    WHERE world_data_2023.Gross_tertiary_education_enrollment_pct IS NOT NULL
      AND world_data_2023.Unemployment_rate IS NOT NULL
),

quartiles AS (
    SELECT
        percentile_disc(0.25) WITHIN GROUP
            (ORDER BY base.Gross_tertiary_education_enrollment_pct) AS q1_edu,
        percentile_disc(0.50) WITHIN GROUP
            (ORDER BY base.Gross_tertiary_education_enrollment_pct) AS q2_edu,
        percentile_disc(0.75) WITHIN GROUP
            (ORDER BY base.Gross_tertiary_education_enrollment_pct) AS q3_edu
    FROM base
),

edu_bands AS (
    SELECT
        base.Country,
        base.Gross_tertiary_education_enrollment_pct,
        base.Unemployment_rate,
        quartiles.q1_edu,
        quartiles.q2_edu,
        quartiles.q3_edu,
        CASE
            WHEN base.Gross_tertiary_education_enrollment_pct < quartiles.q1_edu
                THEN '1) Istruzione terziaria molto bassa'
            WHEN base.Gross_tertiary_education_enrollment_pct < quartiles.q2_edu
                THEN '2) Istruzione terziaria bassa-media'
            WHEN base.Gross_tertiary_education_enrollment_pct < quartiles.q3_edu
                THEN '3) Istruzione terziaria medio-alta'
            ELSE '4) Istruzione terziaria molto alta'
        END AS education_band
    FROM base
    CROSS JOIN quartiles
),

band_stats AS (
    SELECT
        edu_bands.education_band,
        COUNT(*) AS countries_count,
        AVG(edu_bands.Gross_tertiary_education_enrollment_pct) AS avg_tertiary_enrollment,
        AVG(edu_bands.Unemployment_rate) AS avg_unemployment
    FROM edu_bands
    GROUP BY edu_bands.education_band
)

SELECT
    band_stats.education_band,
    band_stats.countries_count,
    ROUND(band_stats.avg_tertiary_enrollment::numeric, 2) AS avg_tertiary_enrollment,
    ROUND(band_stats.avg_unemployment::numeric, 2) AS avg_unemployment
FROM band_stats
ORDER BY band_stats.education_band;


/*

4. ANALISI DEL RISULTATO
   La disoccupazione non mostra una riduzione lineare con l'aumentare
   dell'istruzione terziaria. Le fasce con istruzione molto bassa e
   molto alta hanno livelli simili di disoccupazione (circa 6–6.5%),
   mentre la fascia bassa-media è quella con il tasso più elevato
   (7.6%). La fascia medio-alta mostra un valore intermedio. Il rapporto
   tra istruzione terziaria e disoccupazione risulta quindi non
   direttamente proporzionale.
********************************************************/


/********************************************************
 A5 – PROFILI AMBIENTALI (CO2 PRO CAPITE E COPERTURA FORESTALE) ANNO 2023


1. OBIETTIVO
   Classificare i paesi in quattro profili ambientali combinando
   le emissioni di CO2 pro capite e la percentuale di territorio
   coperto da foreste, confrontati con le mediane globali. L'obiettivo
   e' distinguere paesi ad alta emissione e scarsa foresta, paesi
   ad alta foresta con basse emissioni e gruppi intermedi.


2. RISULTATO ATTESO
   Mi aspetto che i paesi con basse emissioni e alta foresta siano
   concentrati in regioni con ampie superfici boschive, mentre i paesi
   con alte emissioni e bassa copertura forestale siano tipicamente
   industrializzati o con forte uso di combustibili fossili.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        world_data_2023.Country,
        world_data_2023.Forested_Area_pct,
        world_data_2023.Co2_Emissions
    FROM world_data_2023
    WHERE world_data_2023.Forested_Area_pct IS NOT NULL
      AND world_data_2023.Co2_Emissions IS NOT NULL
),

global_medians AS (
    SELECT
        percentile_disc(0.5) WITHIN GROUP (ORDER BY base.Forested_Area_pct)
            AS median_forest,
        percentile_disc(0.5) WITHIN GROUP (ORDER BY base.Co2_Emissions)
            AS median_co2
    FROM base
),

profiles AS (
    SELECT
        base.Country,
        base.Forested_Area_pct,
        base.Co2_Emissions,
        global_medians.median_forest,
        global_medians.median_co2,
        CASE
            WHEN base.Co2_Emissions >= global_medians.median_co2
             AND base.Forested_Area_pct < global_medians.median_forest
                THEN 'Alta CO2 - Bassa foresta'
            WHEN base.Co2_Emissions >= global_medians.median_co2
             AND base.Forested_Area_pct >= global_medians.median_forest
                THEN 'Alta CO2 - Alta foresta'
            WHEN base.Co2_Emissions < global_medians.median_co2
             AND base.Forested_Area_pct < global_medians.median_forest
                THEN 'Bassa CO2 - Bassa foresta'
            ELSE
                'Bassa CO2 - Alta foresta'
        END AS environmental_profile
    FROM base
    CROSS JOIN global_medians
)

SELECT
    profiles.environmental_profile,
    COUNT(*) AS countries_count,
    ROUND(AVG(profiles.Forested_Area_pct)::numeric, 2) AS avg_forest_pct,
    ROUND(AVG(profiles.Co2_Emissions)::numeric, 2) AS avg_co2_emissions
FROM profiles
GROUP BY profiles.environmental_profile
ORDER BY profiles.environmental_profile;


/*


5. ANALISI DEL RISULTATO

   I paesi con “Alta CO2 – Bassa foresta” rappresentano il gruppo
   ambientalmente più problematico: emissioni molto elevate e scarsa
   capacità di assorbimento naturale. Al contrario, il profilo “Bassa CO2 –
   Alta foresta” è il più sostenibile, combinando basse emissioni con un’elevata
   copertura boschiva. *RILEVANTE* I gruppi intermedi mostrano che un’alta foresta 
   non garantisce necessariamente basse emissioni, segnalando economie ricche ma
   ad alto impatto climatico. La distribuzione finale evidenzia forti differenze
   strutturali nei modelli di sviluppo dei paesi.
********************************************************/

/* =================================================================
   GRUPPO B: ANALISI SUL DATASET 'Global Data on Sustainable Energy Dataset' 
   ================================================================= */

/********************************************************
 B1 – EVOLUZIONE DELL'ACCESSO ALL'ELETTRICITÀ PER MACRO-REGIONE (2000–2020)


1. OBIETTIVO
   Analizzare come e' cambiata la percentuale di popolazione con
   accesso all'elettricita' nelle diverse macro-regioni del mondo tra
   il 2000 e il 2020, confrontando il livello iniziale e quello finale
   e misurando il miglioramento complessivo.

2. RISULTATO ATTESO
   Mi aspetto che tutte le macro-regioni mostrino un aumento
   dell'accesso all'elettricita', con progressi piu' marcati in Africa
   e Asia meridionale, partite da valori iniziali piu' bassi.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        energy_data.Entity,
        energy_data.Year,
        energy_data.Access_to_electricity_pct_of_population,
        energy_data.Latitude,
        energy_data.Longitude,
        CASE
            WHEN energy_data.Latitude >= 12 AND energy_data.Latitude <= 40
             AND energy_data.Longitude >= 25 AND energy_data.Longitude <= 60
                THEN 'Middle East'

            WHEN energy_data.Latitude >= 5 AND energy_data.Latitude <= 83
             AND energy_data.Longitude >= -170 AND energy_data.Longitude <= -50
                THEN 'North America'

            WHEN energy_data.Latitude >= -60 AND energy_data.Latitude <= 15
             AND energy_data.Longitude >= -90 AND energy_data.Longitude <= -30
                THEN 'South America'

            WHEN energy_data.Latitude >= 35 AND energy_data.Latitude <= 72
             AND energy_data.Longitude >= -25 AND energy_data.Longitude <= 60
                THEN 'Europe'

            WHEN energy_data.Latitude >= -35 AND energy_data.Latitude <= 37
             AND energy_data.Longitude >= -20 AND energy_data.Longitude <= 55
                THEN 'Africa'

            WHEN energy_data.Latitude >= -10 AND energy_data.Latitude <= 80
             AND energy_data.Longitude >= 60 AND energy_data.Longitude <= 180
                THEN 'Asia'

            WHEN energy_data.Latitude >= -50 AND energy_data.Latitude <= 10
             AND energy_data.Longitude >= 110 AND energy_data.Longitude <= 180
                THEN 'Oceania'

            ELSE 'Altro/Non classificato'
        END AS macro_region
    FROM energy_data
    WHERE energy_data.Access_to_electricity_pct_of_population IS NOT NULL
      AND energy_data.Year BETWEEN 2000 AND 2020
),

region_year AS (
    SELECT
        base.macro_region,
        base.Year,
        AVG(base.Access_to_electricity_pct_of_population) AS avg_access_electricity
    FROM base
    WHERE base.macro_region <> 'Altro/Non classificato'
    GROUP BY base.macro_region, base.Year
),

region_change AS(
    SELECT
        region_year.macro_region,
        MAX(CASE WHEN region_year.Year = 2000 THEN region_year.avg_access_electricity END) AS access_2000,
        MAX(CASE WHEN region_year.Year = 2020 THEN region_year.avg_access_electricity END) AS access_2020
    FROM region_year
    GROUP BY region_year.macro_region
)

SELECT
    region_change.macro_region,
    ROUND(region_change.access_2000::numeric, 2) AS avg_access_2000,
    ROUND(region_change.access_2020::numeric, 2) AS avg_access_2020,
    ROUND((region_change.access_2020 - region_change.access_2000)::numeric, 2)
        AS improvement_2000_2020
FROM region_change
ORDER BY improvement_2000_2020 DESC;


/*

4. ANALISI DEL RISULTATO
   Asia e Africa (hanno quasi raddoppiato il suo accesso all'elettricita')
   mostrano i progressi più significativi nell'accesso
   all'elettricità tra 2000 e 2020, recuperando parte del divario con
   le regioni sviluppate. Tuttavia, nel 2020 l’Africa rimane ancora
   molto distante dagli altri continenti, con valori medi pari a circa
   metà di quelli asiatici. Europa e Nord America partivano già da
   livelli prossimi al 100% e registrano miglioramenti minimi.
   L'analisi conferma un processo di unformita' verso la totale copertura
   elettrica, ma con forti gap strutturali ancora presenti.
********************************************************/

/********************************************************
 B2 – CRESCITA DELLE ENERGIE RINNOVABILI PER MACRO-REGIONE (DAL PRIMO ALL'ULTIMO ANNO DISPONIBILE 2000–2020)


1. OBIETTIVO
   Analizzare come e' variata la quota di energia da fonti rinnovabili
   nelle diverse macro-regioni, confrontando il primo e l'ultimo anno
   disponibile(ci sono diversi valori null nel 2020) nel periodo
   2000–2020 per ciascuna regione.

2. RISULTATO ATTESO
   Mi aspetto un aumento generale delle rinnovabili, con progressi
   piu' marcati in alcune regioni (ad esempio Europa e Asia) rispetto
   alle aree piu' dipendenti dai combustibili fossili.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        energy_data.entity,
        energy_data.year,
        energy_data.renewable_energy_share_in_total_final_energy_consumption_pct,
        energy_data.latitude,
        energy_data.longitude,
        CASE
            WHEN energy_data.latitude >= 12 AND energy_data.latitude <= 40
             AND energy_data.longitude >= 25 AND energy_data.longitude <= 60
                THEN 'Middle East'

            WHEN energy_data.latitude >= 5 AND energy_data.latitude <= 83
             AND energy_data.longitude >= -170 AND energy_data.longitude <= -50
                THEN 'North America'

            WHEN energy_data.latitude >= -60 AND energy_data.latitude <= 15
             AND energy_data.longitude >= -90 AND energy_data.longitude <= -30
                THEN 'South America'

            WHEN energy_data.latitude >= 35 AND energy_data.latitude <= 72
             AND energy_data.longitude >= -25 AND energy_data.longitude <= 60
                THEN 'Europe'

            WHEN energy_data.latitude >= -35 AND energy_data.latitude <= 37
             AND energy_data.longitude >= -20 AND energy_data.longitude <= 55
                THEN 'Africa'

            WHEN energy_data.latitude >= -10 AND energy_data.latitude <= 80
             AND energy_data.longitude >= 60 AND energy_data.longitude <= 180
                THEN 'Asia'

            WHEN energy_data.latitude >= -50 AND energy_data.latitude <= 10
             AND energy_data.longitude >= 110 AND energy_data.longitude <= 180
                THEN 'Oceania'

            ELSE 'Altro/Non classificato'
        END AS macro_region
    FROM energy_data
    WHERE energy_data.renewable_energy_share_in_total_final_energy_consumption_pct IS NOT NULL
      AND energy_data.year BETWEEN 2000 AND 2020
),

region_year AS (
    SELECT
        base.macro_region,
        base.year,
        AVG(base.renewable_energy_share_in_total_final_energy_consumption_pct)
            AS avg_renewables_pct
    FROM base
    WHERE base.macro_region <> 'Altro/Non classificato'
    GROUP BY base.macro_region, base.year
),

region_bounds AS (
    SELECT
        region_year.macro_region,
        MIN(region_year.year) AS start_year,
        MAX(region_year.year) AS end_year
    FROM region_year
    GROUP BY region_year.macro_region
),

region_change AS (
    SELECT
        region_bounds.macro_region,
        region_bounds.start_year,
        region_bounds.end_year,
        start_values.avg_renewables_pct AS renewables_start,
        end_values.avg_renewables_pct AS renewables_end
    FROM region_bounds
    JOIN region_year AS start_values
        ON start_values.macro_region = region_bounds.macro_region
       AND start_values.year = region_bounds.start_year
    JOIN region_year AS end_values
        ON end_values.macro_region = region_bounds.macro_region
       AND end_values.year = region_bounds.end_year
)

SELECT
    region_change.macro_region,
    region_change.start_year,
    ROUND(region_change.renewables_start::numeric, 2) AS renewables_start,
    region_change.end_year,
    ROUND(region_change.renewables_end::numeric, 2) AS renewables_end,
    ROUND((region_change.renewables_end - region_change.renewables_start)::numeric, 2)
        AS improvement_period
FROM region_change
ORDER BY improvement_period DESC;


/*

4. ANALISI DEL RISULTATO
   L’Africa è la macro-regione con il maggiore aumento della quota di
   energia rinnovabile (+14.9 punti), mentre l’Europa registra una crescita
   moderata ma costante (+8.6). Al contrario, Asia, Oceania e Nord America
   mostrano un arretramento nella quota di rinnovabili, suggerendo una
   maggiore dipendenza da fonti fossili negli ultimi anni disponibili.
   Anche il Middle East rimane stabile su valori molto bassi. Nel complesso,
   emergono traiettorie molto diverse tra regioni in via di sviluppo e aree
   ad alto reddito.
********************************************************/

/********************************************************
 B3 – CAMBIAMENTO DELLA QUOTA DI ELETTRICITÀ LOW-CARBON PER GRUPPI DI PAESE (2000–2020)


1. OBIETTIVO
   Analizzare l'evoluzione della percentuale di elettricita' prodotta da
   fonti low-carbon (rinnovabili e nucleare), classificando i paesi in
   quattro gruppi in base al miglioramento o peggioramento registrato
   tra il primo e l'ultimo anno disponibile.

2. RISULTATO ATTESO
   Mi aspetto che molti paesi mostrino un aumento della quota low-carbon,
   mentre altri potrebbero mostrare stabilita' o riduzioni legate al
   maggiore utilizzo di fonti fossili.


3. QUERY SQL
--------------------------------------------------------*/

WITH base AS (
    SELECT
        energy_data.entity AS country,
        energy_data.year,
        energy_data.low_carbon_electricity_pct AS low_carbon_pct
    FROM energy_data
    WHERE energy_data.low_carbon_electricity_pct IS NOT NULL
      AND energy_data.year BETWEEN 2000 AND 2020
),

year_bounds AS (
    SELECT
        base.country,
        MIN(base.year) AS start_year,
        MAX(base.year) AS end_year
    FROM base
    GROUP BY base.country
),

change_calc AS (
    SELECT
        year_bounds.country,
        year_bounds.start_year,
        start_values.low_carbon_pct AS pct_start,
        year_bounds.end_year,
        end_values.low_carbon_pct AS pct_end,
        (end_values.low_carbon_pct - start_values.low_carbon_pct) AS change_abs,
        ((end_values.low_carbon_pct - start_values.low_carbon_pct)
         / NULLIF(start_values.low_carbon_pct, 0) * 100.0) AS change_pct
    FROM year_bounds
    JOIN base AS start_values
        ON start_values.country = year_bounds.country
       AND start_values.year = year_bounds.start_year
    JOIN base AS end_values
        ON end_values.country = year_bounds.country
       AND end_values.year = year_bounds.end_year
),

grouping AS (
    SELECT
        change_calc.country,
        change_calc.pct_start,
        change_calc.pct_end,
        change_calc.change_pct,
        CASE
            WHEN change_calc.change_pct >= 20
                THEN 'Forte aumento (>= +20%)'
            WHEN change_calc.change_pct >= 5
                THEN 'Aumento moderato (+5% / +20%)'
            WHEN change_calc.change_pct > -5
                THEN 'Stabile (-5% / +5%)'
            ELSE 'Diminuzione (< -5%)'
        END AS transition_group
    FROM change_calc
)

SELECT
    grouping.transition_group,
    COUNT(*) AS countries_count,
    ROUND(AVG(grouping.pct_start)::numeric, 2) AS avg_lowcarbon_start,
    ROUND(AVG(grouping.pct_end)::numeric, 2) AS avg_lowcarbon_end,
    ROUND(AVG(grouping.change_pct)::numeric, 2) AS avg_change_pct
FROM grouping
GROUP BY grouping.transition_group
ORDER BY avg_change_pct DESC;


/*

4. ANALISI DEL RISULTATO
   La transizione low-carbon non è omogenea: circa la metà dei paesi ha
   ridotto la quota di elettricità low-carbon, con un calo medio del 33%.
   Esiste però un gruppo numeroso di paesi (+20%) che registra aumenti
   molto forti, partendo però da livelli iniziali molto più bassi.
   I paesi stabili sono pochi e già vicini a valori elevati, mentre il
   cluster dell’aumento moderato rappresenta una via intermedia. Questi
   pattern mostrano una crescente estremizzazione tra sistemi elettrici
   sempre più low-carbon e paesi ancora dipendenti da fonti fossili.

********************************************************/


/* =================================================================
   GRUPPO C: ANALISI SUI DUE DATASET CORRELATI
   ================================================================= */

/********************************************************
 C1 – SPERANZA DI VITA E ACCESSO ALL'ELETTRICITÀ


1. OBIETTIVO
   Analizzare la relazione tra speranza di vita (world_data_2023)
   e accesso all'elettricita' (energy_data). I paesi vengono raggruppati
   in tre fasce di speranza di vita per confrontare i livelli medi
   di accesso all'elettricita'.

2. RISULTATO ATTESO
   Mi aspetto che i paesi con speranza di vita piu' alta presentino
   un accesso all'elettricita' quasi universale, mentre nei paesi
   con speranza di vita piu' bassa l'accesso possa risultare molto
   piu' limitato.


3. QUERY SQL
--------------------------------------------------------*/

WITH electricity_access AS (
    SELECT
        energy_data.country_id,
        AVG(energy_data.access_to_electricity_pct_of_population)
            AS avg_access_electricity
    FROM
        energy_data
    WHERE
        energy_data.access_to_electricity_pct_of_population IS NOT NULL
        AND energy_data.year BETWEEN 2000 AND 2020
    GROUP BY
        energy_data.country_id
),

base AS (
    SELECT
        world_data_2023.id,
        world_data_2023.country,
        world_data_2023.life_expectancy,
        electricity_access.avg_access_electricity
    FROM
        world_data_2023
    JOIN
        electricity_access
        ON electricity_access.country_id = world_data_2023.id
    WHERE
        world_data_2023.life_expectancy IS NOT NULL
        AND electricity_access.avg_access_electricity IS NOT NULL
),

life_bands AS (
    SELECT
        base.country,
        base.life_expectancy,
        base.avg_access_electricity,
        CASE
            WHEN base.life_expectancy < 65
                THEN '1) Bassa speranza di vita (< 65 anni)'
            WHEN base.life_expectancy < 75
                THEN '2) Media speranza di vita (65–75 anni)'
            ELSE
                '3) Alta speranza di vita (> 75 anni)'
        END AS life_band
    FROM
        base
)

SELECT
    life_bands.life_band,
    COUNT(*) AS countries_count,
    ROUND(AVG(life_bands.life_expectancy)::numeric, 2) AS avg_life_expectancy,
    ROUND(AVG(life_bands.avg_access_electricity)::numeric, 2) AS avg_access_electricity
FROM
    life_bands
GROUP BY
    life_bands.life_band
ORDER BY
    life_bands.life_band;


/*
4. ANALISI DEL RISULTATO
   L’accesso medio all’elettricita' aumenta chiaramente passando dai
   paesi con bassa speranza di vita (circa 32%) a quelli con speranza
   di vita media (circa 79%) e alta (oltre 98%). Questo suggerisce una
   forte associazione tra infrastrutture elettriche e condizioni di
   salute: nei paesi con bassa longevita' l’elettricita' non e' ancora
   universale, mentre nei paesi piu' longevi risulta praticamente
   garantita.

********************************************************/


/********************************************************
 C2 – URBANIZZAZIONE, LAVORO E IMPATTO DELLA CRISI 2008 SULL'EFFICIENZA ENERGETICA (2000–2020)


1. OBIETTIVO
   Analizzare come il livello di urbanizzazione dei paesi (world_data_2023)
   sia associato alla variazione dell'intensita' energetica (energy_data)
   prima e dopo la crisi del 2008, integrando anche indicatori di forza
   del mercato del lavoro e capacita' fiscale come variabili di contesto.

   DEFINIZIONE DI INTENSITA' ENERGETICA
   L'intensita' energetica misura quanta energia e' necessaria per
   generare una unita' di PIL (MJ per unita' di PIL). Valori piu' alti
   indicano un sistema economico meno efficiente, che richiede piu'
   energia per produrre ricchezza. Una sua diminuzione nel tempo e'
   indice di miglioramento dell'efficienza energetica di un paese.

2. RISULTATO ATTESO
   Mi aspetto che i paesi con livelli di urbanizzazione piu' elevati e
   migliori condizioni economico-sociali (disoccupazione piu' bassa e
   maggiore capacita' fiscale) mostrino una riduzione piu' marcata
   dell'intensita' energetica dopo la crisi rispetto ai paesi meno
   urbanizzati e piu' fragili.


3. QUERY SQL
--------------------------------------------------------*/

WITH social_structure AS (
    SELECT
        world_data_2023.id,
        world_data_2023.country,
        world_data_2023.urban_population,
        world_data_2023.unemployment_rate,
        world_data_2023.tax_revenue_pct
    FROM
        world_data_2023
    WHERE
        world_data_2023.urban_population IS NOT NULL
        AND world_data_2023.unemployment_rate IS NOT NULL
        AND world_data_2023.tax_revenue_pct IS NOT NULL
),

urban_bands AS (
    SELECT
        social_structure.*,
        NTILE(3) OVER (ORDER BY social_structure.urban_population)
            AS urban_band
    FROM
        social_structure
),

energy_intensity AS (
    SELECT
        energy_data.country_id,
        energy_data.year,
        energy_data.energy_intensity_level_of_primary_energy_mj_per_gdp AS intensity
    FROM
        energy_data
    WHERE
        energy_data.energy_intensity_level_of_primary_energy_mj_per_gdp IS NOT NULL
        AND energy_data.year BETWEEN 2000 AND 2020
),

joined AS (
    SELECT
        urban_bands.urban_band,
        urban_bands.country,
        urban_bands.unemployment_rate,
        urban_bands.tax_revenue_pct,
        CASE
            WHEN energy_intensity.year BETWEEN 2000 AND 2007
                THEN '2000–2007'
            ELSE
                '2008–2020'
        END AS period,
        energy_intensity.intensity
    FROM
        urban_bands
    JOIN
        energy_intensity
        ON energy_intensity.country_id = urban_bands.id
),

period_stats AS (
    SELECT
        urban_band,
        period,
        COUNT(DISTINCT country) AS countries_count,
        ROUND(AVG(intensity)::numeric, 2) AS avg_intensity,
        ROUND(AVG(unemployment_rate)::numeric, 2) AS avg_unemployment,
        ROUND(AVG(tax_revenue_pct)::numeric, 2) AS avg_tax_revenue
    FROM
        joined
    GROUP BY
        urban_band,
        period
)

SELECT
    CASE
        WHEN urban_band = 1 THEN '1) Bassa urbanizzazione'
        WHEN urban_band = 2 THEN '2) Media urbanizzazione'
        ELSE '3) Alta urbanizzazione'
    END AS urban_band_label,
    period,
    countries_count,
    avg_intensity,
    avg_unemployment,
    avg_tax_revenue
FROM
    period_stats
ORDER BY
    urban_band,
    period;


/*
4. ANALISI DEL RISULTATO
   L'intensita' energetica diminuisce in tutti i gruppi dopo la crisi del
   2008, ma la riduzione e' piu' marcata nei paesi altamente urbanizzati,
   che passano in media da 6.50 a 4.94 MJ per unita' di PIL. I paesi meno
   urbanizzati migliorano anch'essi, ma in misura inferiore, suggerendo
   una minore capacita' di ristrutturare consumi e tecnologie dopo uno
   shock economico. Inoltre, i gruppi ad alta urbanizzazione presentano
   livelli fiscali piu' elevati, che potrebbero aver sostenuto
   investimenti in efficienza. Nel complesso emerge una divergenza
   strutturale: i paesi con sistemi socio-economici piu' forti reagiscono
   alla crisi accelerando il proprio progresso energetico, mentre gli
   altri rallentano.

********************************************************/


/********************************************************
 C3 – PRESSIONE DEMOGRAFICA E STABILITA' DEL MIX ENERGETICO (VOLATILITA' 2000–2020 PER FASCE DEMOGRAFICHE)


1. OBIETTIVO
   Analizzare come la pressione demografica dei paesi, approssimata
   tramite tasso di fertilita' e densita' della popolazione
   (world_data_2023), sia associata al livello medio e alla
   stabilita' del mix elettrico rinnovabili/fossili (energy_data)
   nel periodo 2000–2020.

   DEFINIZIONE DI MIX ENERGETICO E VOLATILITA'
   Il mix energetico qui considerato e' dato dalla quota di elettricita'
   prodotta da fonti rinnovabili rispetto alla somma tra rinnovabili e
   fonti fossili (% rinnovabili sul totale elettrico). La volatilita'
   del mix nel tempo viene misurata tramite la deviazione standard della
   quota di rinnovabili tra il 2000 e il 2020: valori piu' alti indicano
   un mix piu' instabile e soggetto a variazioni, valori piu' bassi
   indicano maggiore stabilita'.

2. RISULTATO ATTESO
   Mi aspetto che i paesi con maggiore pressione demografica (fertilita'
   e densita' piu' elevate) mostrino un mix energetico mediamente meno
   orientato alle rinnovabili e piu' volatile nel tempo, mentre i paesi
   con pressione demografica piu' bassa potrebbero avere traiettorie
   piu' stabili e livelli medi di rinnovabili piu' elevati.


3. QUERY SQL
--------------------------------------------------------*/

WITH demographic AS (
    SELECT
        world_data_2023.id,
        world_data_2023.country,
        world_data_2023.fertility_rate,
        world_data_2023.density_p_km2,
        world_data_2023.urban_population,
        /* Indice semplice di pressione demografica:
           combina fertilita' e densita' (piu' alto = maggiore pressione) */
        (world_data_2023.fertility_rate
         + world_data_2023.density_p_km2) AS demographic_pressure_index
    FROM
        world_data_2023
    WHERE
        world_data_2023.fertility_rate IS NOT NULL
        AND world_data_2023.density_p_km2 IS NOT NULL
        AND world_data_2023.urban_population IS NOT NULL
),

demographic_bands AS (
    SELECT
        demographic.*,
        NTILE(3) OVER (ORDER BY demographic.demographic_pressure_index)
            AS pressure_band
    FROM
        demographic
),

energy_mix AS (
    SELECT
        energy_data.country_id,
        energy_data.year,
        energy_data.electricity_from_renewables_twh      AS renewables_twh,
        energy_data.electricity_from_fossil_fuels_twh    AS fossil_twh,
        (energy_data.electricity_from_renewables_twh
         + energy_data.electricity_from_fossil_fuels_twh) AS total_twh
    FROM
        energy_data
    WHERE
        energy_data.electricity_from_renewables_twh IS NOT NULL
        AND energy_data.electricity_from_fossil_fuels_twh IS NOT NULL
        AND energy_data.year BETWEEN 2000 AND 2020
),

renewable_share AS (
    SELECT
        energy_mix.country_id,
        energy_mix.year,
        CASE
            WHEN energy_mix.total_twh > 0
                THEN (energy_mix.renewables_twh
                     / energy_mix.total_twh) * 100.0
            ELSE
                NULL
        END AS renewables_share_pct
    FROM
        energy_mix
),

country_volatility AS (
    SELECT
        renewable_share.country_id,
        AVG(renewable_share.renewables_share_pct) AS avg_renewables_share,
        STDDEV_SAMP(renewable_share.renewables_share_pct) AS volatility_renewables
    FROM
        renewable_share
    WHERE
        renewable_share.renewables_share_pct IS NOT NULL
    GROUP BY
        renewable_share.country_id
),

joined AS (
    SELECT
        demographic_bands.pressure_band,
        demographic_bands.country,
        demographic_bands.fertility_rate,
        demographic_bands.density_p_km2,
        demographic_bands.urban_population,
        country_volatility.avg_renewables_share,
        country_volatility.volatility_renewables
    FROM
        demographic_bands
    JOIN
        country_volatility
        ON country_volatility.country_id = demographic_bands.id
),

band_stats AS (
    SELECT
        pressure_band,
        COUNT(DISTINCT country) AS countries_count,
        ROUND(AVG(fertility_rate)::numeric, 2) AS avg_fertility_rate,
        ROUND(AVG(density_p_km2)::numeric, 2) AS avg_density_p_km2,
        ROUND(AVG(urban_population)::numeric, 2) AS avg_urban_population,
        ROUND(AVG(avg_renewables_share)::numeric, 2) AS avg_renewables_share,
        ROUND(AVG(volatility_renewables)::numeric, 2) AS avg_volatility_renewables
    FROM
        joined
    GROUP BY
        pressure_band
)

SELECT
    CASE
        WHEN pressure_band = 1 THEN '1) Bassa pressione demografica'
        WHEN pressure_band = 2 THEN '2) Pressione demografica intermedia'
        ELSE '3) Alta pressione demografica'
    END AS pressure_band_label,
    countries_count,
    avg_fertility_rate,
    avg_density_p_km2,
    avg_urban_population,
    avg_renewables_share,
    avg_volatility_renewables
FROM
    band_stats
ORDER BY
    pressure_band;


/*
4. ANALISI DEL RISULTATO
   I paesi con bassa pressione demografica mostrano la quota più alta di
   energia rinnovabile (circa 42%) e un livello di stabilità maggiore,
   cioè il mix energetico cambia poco nel tempo. Nei paesi con pressione
   demografica intermedia la quota di rinnovabili scende leggermente e la
   volatilità aumenta, indicando un mix energetico meno stabile. Nei paesi
   con alta pressione demografica la quota media di rinnovabili scende
   ulteriormente (circa 25%), pur con una volatilità non eccessiva. In
   sintesi, maggiore pressione demografica è associata a sistemi meno
   basati sulle rinnovabili e, in alcuni casi, più soggetti a variazioni.


********************************************************/