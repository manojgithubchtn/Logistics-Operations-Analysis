



--- SECTION 01: OVERALL OPERATIONS KPI CARDS
--- View: vw_Dashboard_KPI

--- Purpose:
   ---Calculate total trips and loads
   ---Count customers, trucks and drivers
   ---Calculate total revenue
   ---Calculate fuel and maintenance expenditure
   ---Calculate delivery on-time percentage


CREATE OR ALTER VIEW dbo.vw_Dashboard_KPI
AS

SELECT
    (SELECT COUNT_BIG(*)
     FROM dbo.trips
     WHERE dispatch_date >= '20220101'
       AND dispatch_date < '20250101') AS total_trips,

    (SELECT COUNT_BIG(*)
     FROM dbo.loads
     WHERE load_date >= '20220101'
       AND load_date < '20250101') AS total_loads,

    (SELECT COUNT_BIG(*)
     FROM dbo.customers) AS total_customers,

    (SELECT COUNT_BIG(*)
     FROM dbo.trucks) AS total_trucks,

    (SELECT COUNT_BIG(*)
     FROM dbo.drivers) AS total_drivers,

    (SELECT SUM(CAST(revenue AS DECIMAL(19,2)))
     FROM dbo.loads
     WHERE load_date >= '20220101'
       AND load_date < '20250101') AS total_revenue,

    (SELECT SUM(CAST(total_cost AS DECIMAL(19,2)))
     FROM dbo.fuel_purchases
     WHERE purchase_date >= '20220101'
       AND purchase_date < '20250101') AS total_fuel_cost,

    (SELECT SUM(CAST(total_cost AS DECIMAL(19,2)))
     FROM dbo.maintenance_records
     WHERE maintenance_date >= '20220101'
       AND maintenance_date < '20250101') AS total_maintenance_cost,

    (SELECT
        100.0 * SUM(CAST(on_time_flag AS INT))
        / NULLIF(COUNT_BIG(*), 0)
     FROM dbo.delivery_events
     WHERE event_type = 'Delivery'
       AND scheduled_datetime >= '20220101'
       AND scheduled_datetime < '20250101')
        AS delivery_on_time_percentage;



--- SECTION 02: MONTHLY OPERATIONAL TRENDS
--- View: vw_Dashboard_Monthly_Trends

--- Purpose:
   ---Track monthly trip and load volumes
   ---Analyze monthly revenue
   ---Monitor delivery performance and delays
   ---Track monthly fuel expenditure and consumption
   ---Monitor maintenance costs and downtime


CREATE OR ALTER VIEW dbo.vw_Dashboard_Monthly_Trends
AS

WITH MonthKeys AS
(
    /* Identify all active months across operational tables */

    SELECT DISTINCT
        DATEFROMPARTS(
            YEAR(dispatch_date),
            MONTH(dispatch_date),
            1
        ) AS month_start

    FROM dbo.trips

    WHERE dispatch_date >= '20220101'
      AND dispatch_date < '20250101'

    UNION

    SELECT DISTINCT
        DATEFROMPARTS(
            YEAR(load_date),
            MONTH(load_date),
            1
        )

    FROM dbo.loads

    WHERE load_date >= '20220101'
      AND load_date < '20250101'

    UNION

    SELECT DISTINCT
        DATEFROMPARTS(
            YEAR(scheduled_datetime),
            MONTH(scheduled_datetime),
            1
        )

    FROM dbo.delivery_events

    WHERE scheduled_datetime >= '20220101'
      AND scheduled_datetime < '20250101'

    UNION

    SELECT DISTINCT
        DATEFROMPARTS(
            YEAR(purchase_date),
            MONTH(purchase_date),
            1
        )

    FROM dbo.fuel_purchases

    WHERE purchase_date >= '20220101'
      AND purchase_date < '20250101'

    UNION

    SELECT DISTINCT
        DATEFROMPARTS(
            YEAR(maintenance_date),
            MONTH(maintenance_date),
            1
        )

    FROM dbo.maintenance_records

    WHERE maintenance_date >= '20220101'
      AND maintenance_date < '20250101'
),

/* Monthly trip volume */

TripMonthly AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(dispatch_date),
            MONTH(dispatch_date),
            1
        ) AS month_start,

        COUNT_BIG(*) AS total_trips

    FROM dbo.trips

    WHERE dispatch_date >= '20220101'
      AND dispatch_date < '20250101'

    GROUP BY
        DATEFROMPARTS(
            YEAR(dispatch_date),
            MONTH(dispatch_date),
            1
        )
),

/* Monthly load volume and revenue */

LoadMonthly AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(load_date),
            MONTH(load_date),
            1
        ) AS month_start,

        COUNT_BIG(*) AS total_loads,

        SUM(CAST(revenue AS DECIMAL(19,2)))
            AS total_revenue

    FROM dbo.loads

    WHERE load_date >= '20220101'
      AND load_date < '20250101'

    GROUP BY
        DATEFROMPARTS(
            YEAR(load_date),
            MONTH(load_date),
            1
        )
),

/* Monthly delivery performance */

DeliveryMonthly AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(scheduled_datetime),
            MONTH(scheduled_datetime),
            1
        ) AS month_start,

        COUNT_BIG(*) AS delivery_events,

        SUM(CAST(on_time_flag AS INT))
            AS on_time_deliveries,

        AVG(
            CAST(
                DATEDIFF(
                    SECOND,
                    scheduled_datetime,
                    actual_datetime
                ) AS DECIMAL(19,2)
            ) / 60.0
        ) AS average_delay_minutes

    FROM dbo.delivery_events

    WHERE event_type = 'Delivery'
      AND scheduled_datetime >= '20220101'
      AND scheduled_datetime < '20250101'

    GROUP BY
        DATEFROMPARTS(
            YEAR(scheduled_datetime),
            MONTH(scheduled_datetime),
            1
        )
),

/* Monthly fuel expenditure and consumption */

FuelMonthly AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(purchase_date),
            MONTH(purchase_date),
            1
        ) AS month_start,

        SUM(CAST(gallons AS DECIMAL(19,2)))
            AS total_fuel_gallons,

        SUM(CAST(total_cost AS DECIMAL(19,2)))
            AS total_fuel_cost

    FROM dbo.fuel_purchases

    WHERE purchase_date >= '20220101'
      AND purchase_date < '20250101'

    GROUP BY
        DATEFROMPARTS(
            YEAR(purchase_date),
            MONTH(purchase_date),
            1
        )
),

/* Monthly maintenance expenditure and downtime */

MaintenanceMonthly AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(maintenance_date),
            MONTH(maintenance_date),
            1
        ) AS month_start,

        COUNT_BIG(*) AS maintenance_records,

        SUM(CAST(total_cost AS DECIMAL(19,2)))
            AS total_maintenance_cost,

        SUM(CAST(downtime_hours AS DECIMAL(19,2)))
            AS total_downtime_hours

    FROM dbo.maintenance_records

    WHERE maintenance_date >= '20220101'
      AND maintenance_date < '20250101'

    GROUP BY
        DATEFROMPARTS(
            YEAR(maintenance_date),
            MONTH(maintenance_date),
            1
        )
)

/* Combine all monthly operational metrics */

SELECT
    m.month_start,

    YEAR(m.month_start) AS activity_year,

    MONTH(m.month_start) AS activity_month,

    COALESCE(t.total_trips, 0) AS total_trips,

    COALESCE(l.total_loads, 0) AS total_loads,

    COALESCE(l.total_revenue, 0) AS total_revenue,

    COALESCE(d.delivery_events, 0) AS delivery_events,

    COALESCE(d.on_time_deliveries, 0) AS on_time_deliveries,

    100.0 * d.on_time_deliveries
        / NULLIF(d.delivery_events, 0)
        AS on_time_delivery_percentage,

    d.average_delay_minutes,

    COALESCE(f.total_fuel_gallons, 0)
        AS total_fuel_gallons,

    COALESCE(f.total_fuel_cost, 0)
        AS total_fuel_cost,

    COALESCE(mt.maintenance_records, 0)
        AS maintenance_records,

    COALESCE(mt.total_maintenance_cost, 0)
        AS total_maintenance_cost,

    COALESCE(mt.total_downtime_hours, 0)
        AS total_downtime_hours

FROM MonthKeys m

LEFT JOIN TripMonthly t
    ON m.month_start = t.month_start

LEFT JOIN LoadMonthly l
    ON m.month_start = l.month_start

LEFT JOIN DeliveryMonthly d
    ON m.month_start = d.month_start

LEFT JOIN FuelMonthly f
    ON m.month_start = f.month_start

LEFT JOIN MaintenanceMonthly mt
    ON m.month_start = mt.month_start;




--- SECTION 03: DELIVERY PERFORMANCE BY ROUTE
--- View: vw_Dashboard_Delivery_Routes

--- Purpose:
   ---Compare delivery performance across routes
   ---Calculate route-level revenue
   ---Measure on-time delivery percentage
   ---Analyze average delays and detention time


CREATE OR ALTER VIEW dbo.vw_Dashboard_Delivery_Routes
AS

/* Aggregate delivery events at load level */

WITH DeliveryByLoad AS
(
    SELECT
        load_id,

        COUNT_BIG(*) AS delivery_events,

        SUM(CAST(on_time_flag AS INT))
            AS on_time_events,

        AVG(
            CAST(
                DATEDIFF(
                    SECOND,
                    scheduled_datetime,
                    actual_datetime
                ) AS DECIMAL(19,2)
            ) / 60.0
        ) AS average_delay_minutes,

        AVG(
            CAST(detention_minutes AS DECIMAL(19,2))
        ) AS average_detention_minutes

    FROM dbo.delivery_events

    WHERE event_type = 'Delivery'
      AND scheduled_datetime >= '20220101'
      AND scheduled_datetime < '20250101'

    GROUP BY
        load_id
)

/* Combine delivery performance with route information */

SELECT
    r.route_id,

    r.origin_city,

    r.origin_state,

    r.destination_city,

    r.destination_state,

    COUNT_BIG(l.load_id) AS total_loads,

    SUM(CAST(l.revenue AS DECIMAL(19,2)))
        AS total_revenue,

    SUM(COALESCE(d.delivery_events, 0))
        AS delivery_events,

    SUM(COALESCE(d.on_time_events, 0))
        AS on_time_deliveries,

    100.0 * SUM(COALESCE(d.on_time_events, 0))
        / NULLIF(
            SUM(COALESCE(d.delivery_events, 0)),
            0
        ) AS on_time_percentage,

    AVG(d.average_delay_minutes)
        AS average_delay_minutes,

    AVG(d.average_detention_minutes)
        AS average_detention_minutes

FROM dbo.loads l

INNER JOIN dbo.routes r
    ON l.route_id = r.route_id

LEFT JOIN DeliveryByLoad d
    ON l.load_id = d.load_id

WHERE l.load_date >= '20220101'
  AND l.load_date < '20250101'

GROUP BY
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state;





---SECTION 04: CUSTOMER PERFORMANCE
---View: vw_Dashboard_Customer_Performance
---Purpose:
   ----Analyze revenue by customer
   ----Calculate average revenue per load
   ----Compare customer delivery reliability
   ----Measure delivery delays and detention time


CREATE OR ALTER VIEW dbo.vw_Dashboard_Customer_Performance
AS

/* Aggregate delivery events at load level */

WITH DeliveryByLoad AS
(
    SELECT
        load_id,

        COUNT_BIG(*) AS delivery_events,

        SUM(CAST(on_time_flag AS INT))
            AS on_time_events,

        AVG(
            CAST(
                DATEDIFF(
                    SECOND,
                    scheduled_datetime,
                    actual_datetime
                ) AS DECIMAL(19,2)
            ) / 60.0
        ) AS average_delay_minutes,

        AVG(
            CAST(detention_minutes AS DECIMAL(19,2))
        ) AS average_detention_minutes

    FROM dbo.delivery_events

    WHERE event_type = 'Delivery'
      AND scheduled_datetime >= '20220101'
      AND scheduled_datetime < '20250101'

    GROUP BY
        load_id
)

/* Combine delivery performance with customer information */

SELECT
    c.customer_id,

    c.customer_name,

    COUNT_BIG(l.load_id) AS total_loads,

    SUM(CAST(l.revenue AS DECIMAL(19,2)))
        AS total_revenue,

    AVG(CAST(l.revenue AS DECIMAL(19,2)))
        AS average_revenue_per_load,

    SUM(COALESCE(d.delivery_events, 0))
        AS delivery_events,

    SUM(COALESCE(d.on_time_events, 0))
        AS on_time_deliveries,

    100.0 * SUM(COALESCE(d.on_time_events, 0))
        / NULLIF(
            SUM(COALESCE(d.delivery_events, 0)),
            0
        ) AS on_time_percentage,

    AVG(d.average_delay_minutes)
        AS average_delay_minutes,

    AVG(d.average_detention_minutes)
        AS average_detention_minutes

FROM dbo.loads l

INNER JOIN dbo.customers c
    ON l.customer_id = c.customer_id

LEFT JOIN DeliveryByLoad d
    ON l.load_id = d.load_id

WHERE l.load_date >= '20220101'
  AND l.load_date < '20250101'

GROUP BY
    c.customer_id,
    c.customer_name;




  
---SECTION 05: MONTHLY FUEL PERFORMANCE
---View: vw_Dashboard_Fuel_Performance

---Purpose:
   ----Track monthly fuel purchases
   ----Calculate total gallons purchased
   ----Calculate total fuel expenditure
   ----Calculate weighted average fuel price per gallon


CREATE OR ALTER VIEW dbo.vw_Dashboard_Fuel_Performance
AS

SELECT
    DATEFROMPARTS(
        YEAR(purchase_date),
        MONTH(purchase_date),
        1
    ) AS month_start,

    COUNT_BIG(*) AS total_purchases,

    COUNT(DISTINCT trip_id)
        AS trips_with_fuel_purchases,

    SUM(CAST(gallons AS DECIMAL(19,2)))
        AS total_gallons,

    SUM(CAST(total_cost AS DECIMAL(19,2)))
        AS total_fuel_cost,

    SUM(CAST(total_cost AS DECIMAL(19,2)))
        / NULLIF(
            SUM(CAST(gallons AS DECIMAL(19,2))),
            0
        ) AS weighted_average_price_per_gallon

FROM dbo.fuel_purchases

WHERE purchase_date >= '20220101'
  AND purchase_date < '20250101'

GROUP BY
    DATEFROMPARTS(
        YEAR(purchase_date),
        MONTH(purchase_date),
        1
    );





---SECTION 06: MONTHLY MAINTENANCE PERFORMANCE
---View: vw_Dashboard_Maintenance_Performance

---Purpose:
   ----Monitor monthly maintenance records
   ----Calculate labor and parts expenditure
   ----Track total maintenance cost
   ----Analyze maintenance downtime


CREATE OR ALTER VIEW dbo.vw_Dashboard_Maintenance_Performance
AS

SELECT
    DATEFROMPARTS(
        YEAR(maintenance_date),
        MONTH(maintenance_date),
        1
    ) AS month_start,

    COUNT_BIG(*) AS maintenance_records,

    COUNT(DISTINCT truck_id)
        AS trucks_maintained,

    SUM(CAST(labor_cost AS DECIMAL(19,2)))
        AS total_labor_cost,

    SUM(CAST(parts_cost AS DECIMAL(19,2)))
        AS total_parts_cost,

    SUM(CAST(total_cost AS DECIMAL(19,2)))
        AS total_maintenance_cost,

    AVG(CAST(total_cost AS DECIMAL(19,2)))
        AS average_cost_per_record,

    SUM(CAST(downtime_hours AS DECIMAL(19,2)))
        AS total_downtime_hours,

    AVG(CAST(downtime_hours AS DECIMAL(19,2)))
        AS average_downtime_per_record

FROM dbo.maintenance_records

WHERE maintenance_date >= '20220101'
  AND maintenance_date < '20250101'

GROUP BY
    DATEFROMPARTS(
        YEAR(maintenance_date),
        MONTH(maintenance_date),
        1
    );





 
---SECTION 07: MAINTENANCE PERFORMANCE BY TRUCK
---View: vw_Dashboard_Truck_Maintenance

---Purpose:
   ----Compare maintenance expenditure by truck
   ----Identify maintenance frequency
   ----Analyze truck downtime
   ----Calculate average maintenance cost per record


CREATE OR ALTER VIEW dbo.vw_Dashboard_Truck_Maintenance
AS

SELECT
    t.truck_id,

    t.unit_number,

    t.make,

    t.model_year,

    COUNT_BIG(m.maintenance_id)
        AS maintenance_records,

    SUM(CAST(m.labor_cost AS DECIMAL(19,2)))
        AS total_labor_cost,

    SUM(CAST(m.parts_cost AS DECIMAL(19,2)))
        AS total_parts_cost,

    SUM(CAST(m.total_cost AS DECIMAL(19,2)))
        AS total_maintenance_cost,

    SUM(CAST(m.downtime_hours AS DECIMAL(19,2)))
        AS total_downtime_hours,

    AVG(CAST(m.downtime_hours AS DECIMAL(19,2)))
        AS average_downtime_per_record,

    AVG(CAST(m.total_cost AS DECIMAL(19,2)))
        AS average_maintenance_cost_per_record

FROM dbo.trucks t

LEFT JOIN dbo.maintenance_records m
    ON t.truck_id = m.truck_id
   AND m.maintenance_date >= '20220101'
   AND m.maintenance_date < '20250101'

GROUP BY
    t.truck_id,
    t.unit_number,
    t.make,
    t.model_year;




--- SECTION 08: DASHBOARD VIEW LISTING
--- Purpose: Verify that all dashboard views have been created


SELECT
    TABLE_NAME AS view_name

FROM INFORMATION_SCHEMA.VIEWS

WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'vw_Dashboard%'

ORDER BY
    TABLE_NAME;





--- SECTION 09: DASHBOARD VIEW VERIFICATION
--- Purpose: Execute each dashboard view and inspect its output



/* Overall operational KPI cards */

SELECT *
FROM dbo.vw_Dashboard_KPI;


/* Monthly operational trends */

SELECT *
FROM dbo.vw_Dashboard_Monthly_Trends

ORDER BY
    month_start;


/* Delivery performance by route */

SELECT TOP 10 *
FROM dbo.vw_Dashboard_Delivery_Routes

ORDER BY
    on_time_percentage ASC;


/* Customer performance */

SELECT TOP 10 *
FROM dbo.vw_Dashboard_Customer_Performance

ORDER BY
    total_revenue DESC;


/* Monthly fuel performance */

SELECT *
FROM dbo.vw_Dashboard_Fuel_Performance

ORDER BY
    month_start;


/* Monthly maintenance performance */

SELECT *
FROM dbo.vw_Dashboard_Maintenance_Performance

ORDER BY
    month_start;


/* Truck-level maintenance performance */

SELECT TOP 10 *
FROM dbo.vw_Dashboard_Truck_Maintenance

ORDER BY
    total_maintenance_cost DESC;



