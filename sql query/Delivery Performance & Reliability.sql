--- 01. MONTHLY DELIVERY PERFORMANCE BY EVENT TYPE
--- Purpose:
--- - Analyze monthly delivery-event volume
--- - Calculate on-time performance
--- - Identify average delays
--- - Measure average detention time

WITH DeliveryData AS
(
    SELECT
        de.event_id,
        de.event_type,
        de.detention_minutes,
        dt.scheduled_date,
        DATEDIFF(
            SECOND,
            dt.scheduled_date,
            dt.actual_date
        ) AS delay_seconds

    FROM dbo.delivery_events de

    CROSS APPLY
    (
        SELECT
            TRY_CONVERT(DATETIME2, de.scheduled_datetime)
                AS scheduled_date,
            TRY_CONVERT(DATETIME2, de.actual_datetime)
                AS actual_date
    ) dt

    WHERE dt.scheduled_date >= '2022-01-01'
      AND dt.scheduled_date < '2025-01-01'
)

SELECT
    YEAR(scheduled_date) AS activity_year,
    MONTH(scheduled_date) AS activity_month,
    event_type,

    COUNT(*) AS total_events,

    SUM(CASE
        WHEN delay_seconds IS NOT NULL
         AND ABS(delay_seconds) <= 7200
        THEN 1 ELSE 0
    END) AS calculated_on_time_events,

    CAST(
        100.0 * SUM(CASE
            WHEN delay_seconds IS NOT NULL
             AND ABS(delay_seconds) <= 7200
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS calculated_on_time_percentage,

    CAST(
        AVG(delay_seconds / 60.0)
        AS DECIMAL(10,2)
    ) AS average_delay_minutes,

    CAST(
        AVG(CAST(detention_minutes AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS average_detention_minutes

FROM DeliveryData

GROUP BY
    YEAR(scheduled_date),
    MONTH(scheduled_date),
    event_type

ORDER BY
    activity_year,
    activity_month,
    event_type;


--- 02. DELIVERY PERFORMANCE BY ROUTE
--- Purpose:
--- - Compare route-level delivery reliability
--- - Identify routes with the highest delay
--- - Analyze average detention time

WITH DeliveryData AS
(
    SELECT
        de.event_id,
        de.detention_minutes,
        l.route_id,
        r.origin_city,
        r.origin_state,
        r.destination_city,
        r.destination_state,

        DATEDIFF(
            SECOND,
            dt.scheduled_date,
            dt.actual_date
        ) AS delay_seconds

    FROM dbo.delivery_events de

    INNER JOIN dbo.loads l
        ON de.load_id = l.load_id

    INNER JOIN dbo.routes r
        ON l.route_id = r.route_id

    CROSS APPLY
    (
        SELECT
            TRY_CONVERT(DATETIME2, de.scheduled_datetime)
                AS scheduled_date,
            TRY_CONVERT(DATETIME2, de.actual_datetime)
                AS actual_date
    ) dt

    WHERE de.event_type = 'Delivery'
      AND dt.scheduled_date >= '2022-01-01'
      AND dt.scheduled_date < '2025-01-01'
)

SELECT
    route_id,
    origin_city,
    origin_state,
    destination_city,
    destination_state,

    COUNT(*) AS total_deliveries,

    SUM(CASE
        WHEN delay_seconds IS NOT NULL
         AND ABS(delay_seconds) <= 7200
        THEN 1 ELSE 0
    END) AS on_time_deliveries,

    CAST(
        100.0 * SUM(CASE
            WHEN delay_seconds IS NOT NULL
             AND ABS(delay_seconds) <= 7200
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS on_time_percentage,

    CAST(
        AVG(delay_seconds / 60.0)
        AS DECIMAL(10,2)
    ) AS average_delay_minutes,

    CAST(
        AVG(CAST(detention_minutes AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS average_detention_minutes

FROM DeliveryData

GROUP BY
    route_id,
    origin_city,
    origin_state,
    destination_city,
    destination_state

ORDER BY
    on_time_percentage ASC;


--- 03. DELIVERY PERFORMANCE BY CUSTOMER
--- Purpose:
--- - Compare customer-level delivery reliability
--- - Identify customers with the lowest on-time rates
--- - Analyze average delays and detention time

WITH CustomerDelivery AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        de.event_id,
        de.detention_minutes,

        DATEDIFF(
            SECOND,
            dt.scheduled_date,
            dt.actual_date
        ) AS delay_seconds

    FROM dbo.delivery_events de

    INNER JOIN dbo.loads l
        ON de.load_id = l.load_id

    INNER JOIN dbo.customers c
        ON l.customer_id = c.customer_id

    CROSS APPLY
    (
        SELECT
            TRY_CONVERT(DATETIME2, de.scheduled_datetime)
                AS scheduled_date,
            TRY_CONVERT(DATETIME2, de.actual_datetime)
                AS actual_date
    ) dt

    WHERE de.event_type = 'Delivery'
      AND dt.scheduled_date >= '2022-01-01'
      AND dt.scheduled_date < '2025-01-01'
)

SELECT TOP 10
    customer_id,
    customer_name,

    COUNT(*) AS total_deliveries,

    SUM(CASE
        WHEN delay_seconds IS NOT NULL
         AND ABS(delay_seconds) <= 7200
        THEN 1 ELSE 0
    END) AS on_time_deliveries,

    CAST(
        100.0 * SUM(CASE
            WHEN delay_seconds IS NOT NULL
             AND ABS(delay_seconds) <= 7200
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS on_time_percentage,

    CAST(
        AVG(delay_seconds / 60.0)
        AS DECIMAL(10,2)
    ) AS average_delay_minutes,

    CAST(
        AVG(CAST(detention_minutes AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS average_detention_minutes

FROM CustomerDelivery

GROUP BY
    customer_id,
    customer_name

ORDER BY
    on_time_percentage ASC,
    total_deliveries DESC;


--- PROJECT: LOGISTICS OPERATIONS
--- FILE: DELIVERY DATA QUALITY
--- PURPOSE: Validate original on-time flags against
---          calculated delivery delays
--- PERIOD: 2022-2024


--- 01. ON-TIME FLAG VALIDATION SUMMARY
--- Purpose:
--- - Compare original and calculated on-time performance
--- - Identify mismatched records by event type
--- - Measure the percentage of mismatches

WITH EventData AS
(
    SELECT
        event_id,
        event_type,
        on_time_flag,

        DATEDIFF(
            SECOND,
            dt.scheduled_date,
            dt.actual_date
        ) AS delay_seconds

    FROM dbo.delivery_events de

    CROSS APPLY
    (
        SELECT
            TRY_CONVERT(DATETIME2, de.scheduled_datetime)
                AS scheduled_date,
            TRY_CONVERT(DATETIME2, de.actual_datetime)
                AS actual_date
    ) dt

    WHERE dt.scheduled_date >= '2022-01-01'
      AND dt.scheduled_date < '2025-01-01'
),
CalculatedData AS
(
    SELECT *,
        CASE
            WHEN delay_seconds IS NOT NULL
             AND ABS(delay_seconds) <= 7200
            THEN 1
            ELSE 0
        END AS calculated_flag

    FROM EventData
)

SELECT
    event_type,

    COUNT(*) AS total_events,

    SUM(CASE
        WHEN on_time_flag = 1 THEN 1
        ELSE 0
    END) AS original_on_time_events,

    SUM(calculated_flag) AS calculated_on_time_events,

    CAST(
        100.0 * SUM(CASE
            WHEN on_time_flag = 1 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS original_on_time_percentage,

    CAST(
        100.0 * SUM(calculated_flag) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS calculated_on_time_percentage,

    SUM(CASE
        WHEN ISNULL(on_time_flag, -1) <> calculated_flag
        THEN 1 ELSE 0
    END) AS mismatched_records,

    CAST(
        100.0 * SUM(CASE
            WHEN ISNULL(on_time_flag, -1) <> calculated_flag
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS mismatch_percentage

FROM CalculatedData

GROUP BY event_type

ORDER BY event_type;


--- 02. DETAILED ON-TIME FLAG MISMATCH INVESTIGATION
--- Purpose:
--- - Identify individual mismatched delivery records
--- - Compare original and calculated flags
--- - Investigate actual delivery delays

WITH EventData AS
(
    SELECT
        event_id,
        trip_id,
        load_id,
        event_type,
        scheduled_datetime,
        actual_datetime,
        on_time_flag,

        DATEDIFF(
            SECOND,
            dt.scheduled_date,
            dt.actual_date
        ) AS delay_seconds

    FROM dbo.delivery_events de

    CROSS APPLY
    (
        SELECT
            TRY_CONVERT(DATETIME2, de.scheduled_datetime)
                AS scheduled_date,
            TRY_CONVERT(DATETIME2, de.actual_datetime)
                AS actual_date
    ) dt

    WHERE dt.scheduled_date >= '2022-01-01'
      AND dt.scheduled_date < '2025-01-01'
),
CalculatedData AS
(
    SELECT *,
        CASE
            WHEN delay_seconds IS NOT NULL
             AND ABS(delay_seconds) <= 7200
            THEN 1
            ELSE 0
        END AS calculated_flag

    FROM EventData
)

SELECT
    event_id,
    trip_id,
    load_id,
    event_type,
    scheduled_datetime,
    actual_datetime,

    delay_seconds,

    CAST(
        delay_seconds / 60.0
        AS DECIMAL(10,2)
    ) AS delay_minutes,

    on_time_flag AS original_flag,

    calculated_flag

FROM CalculatedData

WHERE ISNULL(on_time_flag, -1) <> calculated_flag

ORDER BY
    event_type,
    event_id;
