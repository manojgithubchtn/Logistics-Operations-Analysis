--- 01. OVERALL MAINTENANCE PERFORMANCE
--- Purpose:
--- - Calculate total maintenance expenditure
--- - Analyze maintenance downtime
--- - Identify trucks maintained
--- - Validate maintenance cost calculations

SELECT
    COUNT(*) AS total_maintenance_records,

    COUNT(DISTINCT truck_id) AS trucks_maintained,

    SUM(CASE
        WHEN truck_id IS NULL THEN 1
        ELSE 0
    END) AS unassigned_truck_records,

    MIN(maintenance_date) AS first_maintenance_date,

    MAX(maintenance_date) AS last_maintenance_date,

    CAST(
        SUM(labor_cost) AS DECIMAL(18,2)
    ) AS total_labor_cost,

    CAST(
        SUM(parts_cost) AS DECIMAL(18,2)
    ) AS total_parts_cost,

    CAST(
        SUM(total_cost) AS DECIMAL(18,2)
    ) AS total_maintenance_cost,

    CAST(
        SUM(downtime_hours) AS DECIMAL(18,2)
    ) AS total_downtime_hours,

    CAST(
        AVG(downtime_hours) AS DECIMAL(10,2)
    ) AS average_downtime_per_record,

    SUM(CASE
        WHEN labor_cost IS NULL
          OR parts_cost IS NULL
          OR total_cost IS NULL
        THEN 1
        ELSE 0
    END) AS incomplete_cost_records,

    SUM(CASE
        WHEN labor_cost IS NOT NULL
         AND parts_cost IS NOT NULL
         AND total_cost IS NOT NULL
         AND ABS(
             labor_cost + parts_cost - total_cost
         ) > 0.01
        THEN 1
        ELSE 0
    END) AS cost_mismatch_records

FROM dbo.maintenance_records

WHERE maintenance_date >= '2022-01-01'
  AND maintenance_date < '2025-01-01';


--- 02. MONTHLY MAINTENANCE PERFORMANCE
--- Purpose:
--- - Analyze monthly maintenance expenditure
--- - Track maintenance activity
--- - Monitor downtime trends

SELECT
    YEAR(maintenance_date) AS activity_year,

    MONTH(maintenance_date) AS activity_month,

    COUNT(*) AS maintenance_records,

    COUNT(DISTINCT truck_id) AS trucks_maintained,

    CAST(
        SUM(labor_cost) AS DECIMAL(18,2)
    ) AS total_labor_cost,

    CAST(
        SUM(parts_cost) AS DECIMAL(18,2)
    ) AS total_parts_cost,

    CAST(
        SUM(total_cost) AS DECIMAL(18,2)
    ) AS total_maintenance_cost,

    CAST(
        AVG(total_cost) AS DECIMAL(10,2)
    ) AS average_cost_per_record,

    CAST(
        SUM(downtime_hours) AS DECIMAL(18,2)
    ) AS total_downtime_hours,

    CAST(
        AVG(downtime_hours) AS DECIMAL(10,2)
    ) AS average_downtime_per_record

FROM dbo.maintenance_records

WHERE maintenance_date >= '2022-01-01'
  AND maintenance_date < '2025-01-01'

GROUP BY
    YEAR(maintenance_date),
    MONTH(maintenance_date)

ORDER BY
    activity_year,
    activity_month;


--- 03. TRUCK-LEVEL MAINTENANCE PERFORMANCE
--- Purpose:
--- - Compare maintenance expenditure by truck
--- - Identify trucks with high maintenance costs
--- - Analyze truck downtime

SELECT
    t.truck_id,

    t.unit_number,

    t.make,

    t.model_year,

    COUNT(m.maintenance_id) AS maintenance_records,

    CAST(
        SUM(m.labor_cost) AS DECIMAL(18,2)
    ) AS total_labor_cost,

    CAST(
        SUM(m.parts_cost) AS DECIMAL(18,2)
    ) AS total_parts_cost,

    CAST(
        SUM(m.total_cost) AS DECIMAL(18,2)
    ) AS total_maintenance_cost,

    CAST(
        SUM(m.downtime_hours) AS DECIMAL(18,2)
    ) AS total_downtime_hours,

    CAST(
        AVG(m.downtime_hours) AS DECIMAL(10,2)
    ) AS average_downtime_per_record,

    CAST(
        AVG(m.total_cost) AS DECIMAL(10,2)
    ) AS average_maintenance_cost_per_record

FROM dbo.maintenance_records m

INNER JOIN dbo.trucks t
    ON m.truck_id = t.truck_id

WHERE m.maintenance_date >= '2022-01-01'
  AND m.maintenance_date < '2025-01-01'

GROUP BY
    t.truck_id,
    t.unit_number,
    t.make,
    t.model_year

ORDER BY
    total_maintenance_cost DESC;
