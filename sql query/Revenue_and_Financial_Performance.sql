
USE logistics_operations;





--- 01. MONTHLY REVENUE PERFORMANCE


SELECT
    YEAR(load_date) AS activity_year,
    MONTH(load_date) AS activity_month,

    COUNT(DISTINCT load_id) AS total_loads,

    SUM(revenue) AS total_revenue,

    CAST(
        AVG(CAST(revenue AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS average_revenue_per_load,

    SUM(fuel_surcharge) AS total_fuel_surcharge,

    SUM(accessorial_charges) AS total_accessorial_charges

FROM dbo.loads

WHERE load_date >= '2022-01-01'
  AND load_date < '2025-01-01'

GROUP BY
    YEAR(load_date),
    MONTH(load_date)

ORDER BY
    activity_year,
    activity_month;





--- 02. REVENUE BREAKDOWN
--- Purpose: Analyze revenue after deducting the two specified charge components


SELECT
    COUNT(*) AS total_loads,

    SUM(revenue) AS total_revenue,

    SUM(fuel_surcharge) AS total_fuel_surcharge,

    SUM(accessorial_charges) AS total_accessorial_charges,

    SUM(
        revenue - fuel_surcharge - accessorial_charges
    ) AS revenue_less_surcharges_and_accessorials,

    CAST(
        AVG(
            revenue - fuel_surcharge - accessorial_charges
        )
        AS DECIMAL(18,2)
    ) AS average_remaining_revenue_per_load

FROM dbo.loads

WHERE load_date >= '2022-01-01'
  AND load_date < '2025-01-01';





--- 03. TOP 10 CUSTOMERS BY REVENUE


SELECT TOP 10
    c.customer_id,
    c.customer_name,

    COUNT(l.load_id) AS total_loads,

    SUM(l.revenue) AS total_revenue,

    CAST(
        AVG(CAST(l.revenue AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS average_revenue_per_load

FROM dbo.loads l

INNER JOIN dbo.customers c
    ON l.customer_id = c.customer_id

WHERE l.load_date >= '2022-01-01'
  AND l.load_date < '2025-01-01'

GROUP BY
    c.customer_id,
    c.customer_name

ORDER BY
    total_revenue DESC;





--- 04. TOP 10 ROUTES BY REVENUE


SELECT TOP 10
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,

    COUNT(l.load_id) AS total_loads,

    SUM(l.revenue) AS total_revenue,

    CAST(
        AVG(CAST(l.revenue AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS average_revenue_per_load

FROM dbo.loads l

INNER JOIN dbo.routes r
    ON l.route_id = r.route_id

WHERE l.load_date >= '2022-01-01'
  AND l.load_date < '2025-01-01'

GROUP BY
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state

ORDER BY
    total_revenue DESC;





--- 05. EXPECTED BASE REVENUE VS ACTUAL REVENUE
--- Purpose:
   --- Compare estimated base route revenue with actual average revenue per load
   --- Analyze fuel surcharge and accessorial charges


SELECT
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,

    r.typical_distance_miles,
    r.base_rate_per_mile,

    CAST(
        r.typical_distance_miles * r.base_rate_per_mile
        AS DECIMAL(18,2)
    ) AS expected_base_revenue,

    COUNT(l.load_id) AS total_loads,

    CAST(
        AVG(CAST(l.revenue AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS actual_average_revenue,

    CAST(
        AVG(CAST(l.fuel_surcharge AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS average_fuel_surcharge,

    CAST(
        AVG(CAST(l.accessorial_charges AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS average_accessorial_charges

FROM dbo.routes r

INNER JOIN dbo.loads l
    ON r.route_id = l.route_id

WHERE l.load_date >= '2022-01-01'
  AND l.load_date < '2025-01-01'

GROUP BY
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,
    r.typical_distance_miles,
    r.base_rate_per_mile

ORDER BY
    actual_average_revenue DESC;
