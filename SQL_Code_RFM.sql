WITH 
--Compute for F &amp; M
t1 AS (
    SELECT  
    CustomerID,
    Country,
    MAX(DATE_TRUNC(DATE(InvoiceDate), DAY)) AS last_purchase_date,
    COUNT(distinct InvoiceNo) AS frequency,
    Round(SUM(UnitPrice),2) as monetary  
    FROM `rfm`
    WHERE 
      DATE_TRUNC(DATE(InvoiceDate), DAY) BETWEEN '2010-12-01' AND '2011-12-01' and
      CustomerID is not null
    GROUP BY all
    Order by
       CustomerID
),
--Compute for R
t2 AS (
    SELECT *,
    DATE_DIFF('2011-12-01', last_purchase_date, DAY) AS recency
    FROM (
        SELECT  *
        FROM t1
    )  
),

t3 AS (
SELECT 
    a.*,
    --All percentiles for MONETARY
    b.percentiles[offset(25)] AS m25, 
    b.percentiles[offset(50)] AS m50,
    b.percentiles[offset(75)] AS m75,
    b.percentiles[offset(100)] AS m100,    
    --All percentiles for FREQUENCY
    c.percentiles[offset(25)] AS f25, 
    c.percentiles[offset(50)] AS f50,
    c.percentiles[offset(75)] AS f75,
    c.percentiles[offset(100)] AS f100,    
    --All percentiles for RECENCY
    d.percentiles[offset(25)] AS r25, 
    d.percentiles[offset(50)] AS r50,
    d.percentiles[offset(75)] AS r75,
    d.percentiles[offset(100)] AS r100
FROM 
    t2 a,
    (SELECT APPROX_QUANTILES(monetary, 100) percentiles 
    FROM t2) b,
    (SELECT APPROX_QUANTILES(frequency, 100) percentiles 
    FROM t2) c,
    (SELECT APPROX_QUANTILES(recency, 100) percentiles 
    FROM t2) d
),

t4 AS (
    SELECT *, 
    CAST(ROUND((F + M) / 2, 0) AS INT64) AS fm_score
    FROM (
        SELECT *, 
        CASE WHEN monetary <= m25 THEN 1
            WHEN monetary <= m50 AND monetary > m25 THEN 2 
            WHEN monetary <= m75 AND monetary > m50 THEN 3 
            WHEN monetary <= m100 AND monetary > m75 THEN 4
        END AS M,
        CASE WHEN frequency <= f25 THEN 1
            WHEN frequency <= f50 AND frequency > f25 THEN 2 
            WHEN frequency <= f75 AND frequency > f50 THEN 3 
            WHEN frequency <= f100 AND frequency > f75 THEN 4 
        END AS F,
        --Recency scoring is reversed
        CASE WHEN recency <= r25 THEN 4
            WHEN recency <= r50 AND recency > r25 THEN 3 
            WHEN recency <= r75 AND recency > r50 THEN 2 
            WHEN recency <= r100 AND recency > r75 THEN 1
        END AS R,
        FROM t3
        )
)
SELECT 
        M,
        F,
        R,
        frequency,
        monetary,
        recency,
        CONCAT(R,',',F,',',M) as rfm_cell,
        Round((R+F+M)/3,2) as rfm_score,
        Count(Round((R+F+M)/3,2)) as n,
         CASE
    -- Best Customers
    WHEN (R = 4 AND F IN (3, 4) AND M IN (3, 4))
    THEN 'Best Customers'
    
    -- Loyal Customers
    WHEN (R = 4 AND F IN (3, 4) AND M IN (1, 2))
         OR (R = 3 AND F = 4 AND M IN (2, 3, 4))
         OR (R = 3 AND F = 3 AND M = 1)
         OR (R = 3 AND F = 3 AND M = 2)  
         OR (R = 4 AND F = 2 AND M IN (1, 2, 3))  
         OR (R = 3 AND F = 2 AND M IN (1, 2))  
    THEN 'Loyal Customers'
    
    -- At Risk
    WHEN (R = 2 AND F IN (3, 4) AND M IN (3, 4))
         OR (R = 1 AND F IN (3, 4) AND M IN (2, 3, 4))
         OR (R = 2 AND F = 3 AND M IN (1, 2))  
         OR (R = 2 AND F = 4 AND M IN (1, 2))  
    THEN 'At Risk'
    
    -- Lost Customers
    WHEN (R = 1 AND F IN (1, 2))
         OR (R = 2 AND F = 1)
         OR (R = 2 AND F = 2 AND M IN (1, 2))
         OR (R = 1 AND F = 3 AND M = 1)
         OR (R = 3 AND F = 4 AND M = 1)  
    THEN 'Lost Customers'
    
    -- Big Spenders
    WHEN (M = 4 AND F IN (2, 3, 4) AND R IN (2, 3, 4))
         OR (M = 3 AND F IN (3, 4) AND R IN (2, 3, 4))
         OR (R = 3 AND F = 2 AND M IN (3, 4))
         OR (R = 2 AND F = 2 AND M IN (3, 4))
         OR (R = 4 AND F = 1 AND M = 3)  
         OR (R = 4 AND F = 1 AND M = 4)  
    THEN 'Big Spenders'
    
    -- New Customers
    WHEN (R = 4 AND F = 1 AND M IN (1, 2))
         OR (R = 3 AND F = 1)
    THEN 'New Customers'
END AS customer_segment
    FROM t4
group by all    
order by 
     rfm_score