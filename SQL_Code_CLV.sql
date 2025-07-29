--Cohorts Analysis
WITH t1 AS (
    SELECT
        -- Format the event_date string to a proper DATE type
        CAST(CONCAT(
            SUBSTR(event_date, 1, 4), '-',
            SUBSTR(event_date, 5, 2), '-',
            SUBSTR(event_date, 7, 2)
        ) AS DATE) AS event_date_1,
        *
    From raw_events
),
-- First, find the first timestamp for each user (to identify their cohort)
cohort_items AS (
    SELECT
        user_pseudo_id,
        MIN(DATE_TRUNC(event_date_1, WEEK)) AS cohort_week
    FROM t1
    GROUP BY user_pseudo_id
),
-- Calculate revenue data for each user per week
revenue_data AS (
    SELECT
        user_pseudo_id,
        DATE_TRUNC(event_date_1, WEEK) AS activity_week,
        SUM(CAST(event_value_in_usd AS FLOAT64)) as revenue
    FROM t1
    GROUP BY user_pseudo_id, DATE_TRUNC(event_date_1, WEEK)
),
-- Calculate the size of each cohort (number of users who joined in that week)
cohort_size AS (
    SELECT 
        cohort_week,
        COUNT(DISTINCT user_pseudo_id) as cohort_size
    FROM cohort_items
    GROUP BY cohort_week
),
-- Calculate total revenue for each cohort by week since joining
revenue_by_cohort AS (
    SELECT 
        c.cohort_week,
        r.activity_week,
        DATE_DIFF(r.activity_week, c.cohort_week, WEEK) as week_number,
        SUM(r.revenue) as total_revenue,
        cs.cohort_size
    FROM cohort_items c
    LEFT JOIN revenue_data r ON c.user_pseudo_id = r.user_pseudo_id
    JOIN cohort_size cs ON c.cohort_week = cs.cohort_week
    WHERE c.cohort_week <= DATE '2021-01-24' 
    AND r.activity_week >= c.cohort_week
    GROUP BY c.cohort_week, r.activity_week, cs.cohort_size
),
-- Calculate per-user revenue and cumulative revenue for each cohort by week
cumulative_revenue AS (
    SELECT 
        cohort_week,
        cohort_size,
        week_number,
        total_revenue/cohort_size as revenue_per_user,
        SUM(total_revenue/cohort_size) OVER (
            PARTITION BY cohort_week 
            ORDER BY week_number
        ) as cumulative_revenue_per_user
    FROM revenue_by_cohort
    WHERE week_number >= 0 
    AND week_number <= 12
)
-- Final query to format results into a cohort analysis table
SELECT 
    cr.cohort_week,
    cr.cohort_size as total_users,
    -- Revenue per user by week (weeks 0-12)
    round(MAX(CASE WHEN cr.week_number = 0 THEN cr.revenue_per_user  END),5) as revenue_week_0,
    round(MAX(CASE WHEN cr.week_number = 1 THEN cr.revenue_per_user  END),5) as revenue_week_1,
    round(MAX(CASE WHEN cr.week_number = 2 THEN cr.revenue_per_user  END),5) as revenue_week_2,
    round(MAX(CASE WHEN cr.week_number = 3 THEN cr.revenue_per_user  END),5) as revenue_week_3,
    round(MAX(CASE WHEN cr.week_number = 4 THEN cr.revenue_per_user  END),5) as revenue_week_4,
    round(MAX(CASE WHEN cr.week_number = 5 THEN cr.revenue_per_user  END),5) as revenue_week_5,
    round(MAX(CASE WHEN cr.week_number = 6 THEN cr.revenue_per_user  END),5) as revenue_week_6,
    round(MAX(CASE WHEN cr.week_number = 7 THEN cr.revenue_per_user  END),5) as revenue_week_7,
    round(MAX(CASE WHEN cr.week_number = 8 THEN cr.revenue_per_user  END),5) as revenue_week_8,
    round(MAX(CASE WHEN cr.week_number = 9 THEN cr.revenue_per_user  END),5) as revenue_week_9,
    round(MAX(CASE WHEN cr.week_number = 10 THEN cr.revenue_per_user  END),5) as revenue_week_10,
    round(MAX(CASE WHEN cr.week_number = 11 THEN cr.revenue_per_user  END),5) as revenue_week_11,
    round(MAX(CASE WHEN cr.week_number = 12 THEN cr.revenue_per_user  END),5) as revenue_week_12,
    -- Cumulative revenue per user by week (weeks 0-12)
    round(MAX(CASE WHEN cr.week_number = 0 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_0,
    round(MAX(CASE WHEN cr.week_number = 1 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_1,
    round(MAX(CASE WHEN cr.week_number = 2 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_2,
    round(MAX(CASE WHEN cr.week_number = 3 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_3,
    round(MAX(CASE WHEN cr.week_number = 4 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_4,
    round(MAX(CASE WHEN cr.week_number = 5 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_5,
    round(MAX(CASE WHEN cr.week_number = 6 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_6,
    round(MAX(CASE WHEN cr.week_number = 7 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_7,
    round(MAX(CASE WHEN cr.week_number = 8 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_8,
    round(MAX(CASE WHEN cr.week_number = 9 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_9,
    round(MAX(CASE WHEN cr.week_number = 10 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_10,
    round(MAX(CASE WHEN cr.week_number = 11 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_11,
    round(MAX(CASE WHEN cr.week_number = 12 THEN cr.cumulative_revenue_per_user END),3) as cum_revenue_week_12
FROM cumulative_revenue cr
GROUP BY cr.cohort_week, cr.cohort_size
ORDER BY cr.cohort_week; 


--Calculating Averages
WITH t1 AS (
    SELECT
        -- Format the event_date string to a proper DATE type
        CAST(CONCAT(
            SUBSTR(event_date, 1, 4), '-',
            SUBSTR(event_date, 5, 2), '-',
            SUBSTR(event_date, 7, 2)
        ) AS DATE) AS event_date_1,
        *
    From  raw_events
),
-- First, find the first timestamp for each user
cohort_items AS (
    SELECT
        user_pseudo_id,
        MIN(DATE_TRUNC(event_date_1, WEEK)) AS cohort_week
    FROM t1
    GROUP BY user_pseudo_id
),
-- Calculate revenue data for each user per week
revenue_data AS (
    SELECT
        user_pseudo_id,
        DATE_TRUNC(event_date_1, WEEK) AS activity_week,
        SUM(CAST(event_value_in_usd AS FLOAT64)) as revenue
    FROM t1
    GROUP BY user_pseudo_id, DATE_TRUNC(event_date_1, WEEK)
),
-- Calculate the size of each cohort (number of users who joined in that week)
cohort_size AS (
    SELECT 
        cohort_week,
        COUNT(DISTINCT user_pseudo_id) as cohort_size
    FROM cohort_items
    GROUP BY cohort_week
),
-- Calculate total revenue for each cohort by week since joining
revenue_by_cohort AS (
    SELECT 
        c.cohort_week,
        r.activity_week,
        DATE_DIFF(r.activity_week, c.cohort_week, WEEK) as week_number,
        SUM(r.revenue) as total_revenue,
        cs.cohort_size
    FROM cohort_items c
    LEFT JOIN revenue_data r ON c.user_pseudo_id = r.user_pseudo_id
    JOIN cohort_size cs ON c.cohort_week = cs.cohort_week
    WHERE c.cohort_week <= DATE '2021-01-24' 
    AND r.activity_week >= c.cohort_week
    GROUP BY c.cohort_week, r.activity_week, cs.cohort_size
),
-- Calculate per-user revenue and cumulative revenue for each cohort by week
cumulative_revenue AS (
    SELECT 
        cohort_week,
        cohort_size,
        week_number,
        total_revenue/cohort_size as revenue_per_user,
        SUM(total_revenue/cohort_size) OVER (
            PARTITION BY cohort_week 
            ORDER BY week_number
        ) as cumulative_revenue_per_user
    FROM revenue_by_cohort
    WHERE week_number >= 0 
    AND week_number <= 12
),
-- Calculate average weekly and cumulative metrics across all cohorts
weekly_averages AS (
    SELECT 
        week_number,
        AVG(revenue_per_user) as avg_revenue_per_user,
        AVG(cumulative_revenue_per_user) as avg_cumulative_revenue_per_user,
        -- Calculate growth percentage for cumulative revenue
        (AVG(cumulative_revenue_per_user) - LAG(AVG(cumulative_revenue_per_user)) OVER (ORDER BY week_number)) / 
        NULLIF(LAG(AVG(cumulative_revenue_per_user)) OVER (ORDER BY week_number), 0) as c_growth_percentage
    FROM cumulative_revenue
    GROUP BY week_number
),
-- Calculate cumulative average of weekly revenues
cumulative_avg AS (
    SELECT 
        week_number,
        avg_revenue_per_user,
        avg_cumulative_revenue_per_user,
        c_growth_percentage,
        SUM(avg_revenue_per_user) OVER (ORDER BY week_number) as cumulative_avg_revenue
    FROM weekly_averages
),
-- Calculate week-over-week growth percentage for the cumulative average
growth_calc AS (
    SELECT 
        week_number,
        avg_revenue_per_user,
        avg_cumulative_revenue_per_user,
        c_growth_percentage,
        cumulative_avg_revenue,
        LAG(cumulative_avg_revenue) OVER (ORDER BY week_number) as prev_cumulative_revenue,
        CASE 
            WHEN LAG(cumulative_avg_revenue) OVER (ORDER BY week_number) IS NOT NULL THEN
                (cumulative_avg_revenue - LAG(cumulative_avg_revenue) OVER (ORDER BY week_number)) / 
                NULLIF(LAG(cumulative_avg_revenue) OVER (ORDER BY week_number), 0) 
            ELSE 0
        END as growth_percentage
    FROM cumulative_avg
)    
-- Final query to display all calculated metrics by week
SELECT 
    week_number,
    avg_revenue_per_user,
    cumulative_avg_revenue,
    growth_percentage,
    avg_cumulative_revenue_per_user,
    c_growth_percentage
FROM growth_calc 
GROUP BY ALL
ORDER BY week_number;