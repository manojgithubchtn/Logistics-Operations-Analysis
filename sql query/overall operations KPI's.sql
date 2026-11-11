
USE logistics_operations;






--- 01. OVERALL OPERATIONAL KPIs
--- Purpose:
   ---Count trips, loads, customers, trucks and drivers
   ---Calculate overall revenue


SELECT
    (SELECT COUNT(DISTINCT trip_id)
     FROM dbo.trips) AS total_trips,

    (SELECT COUNT(DISTINCT load_id)
     FROM dbo.loads) AS total_loads,

    (SELECT COUNT(DISTINCT customer_id)
     FROM dbo.customers) AS total_customers,

    (SELECT COUNT(DISTINCT truck_id)
     FROM dbo.trucks) AS total_trucks,

    (SELECT COUNT(DISTINCT driver_id)
     FROM dbo.drivers) AS total_drivers,

    (SELECT COALESCE(SUM(revenue), 0)
     FROM dbo.loads) AS total_revenue;






--- 02. OPERATIONAL DATA DATE COVERAGE
--- Purpose:
   ---Identify the available date range
   ---Measure the number of active dates
   ---Compare coverage across operational tables


SELECT
    'Trips' AS data_source,

    MIN(TRY_CONVERT(DATETIME2, dispatch_date))
        AS first_date,

    MAX(TRY_CONVERT(DATETIME2, dispatch_date))
        AS last_date,

    COUNT(DISTINCT CAST(dispatch_date AS DATE))
        AS active_days

FROM dbo.trips

UNION ALL

SELECT
    'Loads',

    MIN(TRY_CONVERT(DATETIME2, load_date)),

    MAX(TRY_CONVERT(DATETIME2, load_date)),

    COUNT(DISTINCT CAST(load_date AS DATE))

FROM dbo.loads

UNION ALL

SELECT
    'Delivery Events',

    MIN(TRY_CONVERT(DATETIME2, actual_datetime)),

    MAX(TRY_CONVERT(DATETIME2, actual_datetime)),

    COUNT(DISTINCT CAST(
        TRY_CONVERT(DATETIME2, actual_datetime) AS DATE
    ))

FROM dbo.delivery_events;






--- 03. DELIVERY EVENT DATE VALIDATION
--- Purpose:
   ---Identify scheduled and actual date coverage
   ---Count events with actual dates in 2025 or later
   ---Count events scheduled in 2025 or later
   ---Identify invalid or missing datetime values


WITH EventDates AS
(
    SELECT
        TRY_CONVERT(DATETIME2, scheduled_datetime)
            AS scheduled_dt,

        TRY_CONVERT(DATETIME2, actual_datetime)
            AS actual_dt

    FROM dbo.delivery_events
)

SELECT
    COUNT(*) AS total_events,

    MIN(scheduled_dt) AS first_scheduled_date,

    MAX(scheduled_dt) AS last_scheduled_date,

    MIN(actual_dt) AS first_actual_date,

    MAX(actual_dt) AS last_actual_date,

    SUM(CASE
        WHEN actual_dt >= '2025-01-01'
        THEN 1 ELSE 0
    END) AS events_actual_in_2025_or_later,

    SUM(CASE
        WHEN scheduled_dt >= '2025-01-01'
        THEN 1 ELSE 0
    END) AS events_scheduled_in_2025_or_later,

    SUM(CASE
        WHEN scheduled_dt IS NULL
          OR actual_dt IS NULL
        THEN 1 ELSE 0
    END) AS unparsed_datetime_records

FROM EventDates;






--- 04. DELIVERY EVENTS CROSSING INTO 2025
--- Purpose:
   ---Identify events scheduled before 2025
   ---but actually completed in 2025 or later
   ---Investigate cross-year delivery delays


WITH EventDates AS
(
    SELECT
        event_id,
        trip_id,
        load_id,
        event_type,
        scheduled_datetime,
        actual_datetime,

        TRY_CONVERT(DATETIME2, scheduled_datetime)
            AS scheduled_dt,

        TRY_CONVERT(DATETIME2, actual_datetime)
            AS actual_dt

    FROM dbo.delivery_events
)

SELECT
    event_id,
    trip_id,
    load_id,
    event_type,

    scheduled_datetime,
    actual_datetime,

    DATEDIFF(
        MINUTE,
        scheduled_dt,
        actual_dt
    ) AS delay_minutes

FROM EventDates

WHERE actual_dt >= '2025-01-01'
  AND scheduled_dt < '2025-01-01'
  AND scheduled_dt IS NOT NULL

ORDER BY
    actual_dt,
    event_id;
