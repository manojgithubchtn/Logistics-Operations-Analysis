
USE logistics_operations;





--- 01. FUEL PURCHASE DATE COVERAGE

SELECT
    COUNT(*) AS all_purchase_records,

    SUM(CASE
        WHEN purchase_date >= '2022-01-01'
         AND purchase_date < '2025-01-01'
        THEN 1 ELSE 0
    END) AS purchases_2022_2024,

    SUM(CASE
        WHEN purchase_date < '2022-01-01'
          OR purchase_date >= '2025-01-01'
        THEN 1 ELSE 0
    END) AS purchases_outside_period,

    MIN(purchase_date) AS first_purchase_date,

    MAX(purchase_date) AS last_purchase_date

FROM dbo.fuel_purchases;





--- 02. FUEL PURCHASE AND TRIP TRUCK ASSIGNMENT VALIDATION


WITH FuelByTrip AS
(
    SELECT
        trip_id,

        COUNT(*) AS purchase_records,

        COUNT(DISTINCT truck_id) AS distinct_purchase_trucks,

        MAX(truck_id) AS purchase_truck_id

    FROM dbo.fuel_purchases

    WHERE purchase_date >= '2022-01-01'
      AND purchase_date < '2025-01-01'

    GROUP BY trip_id
),

TripAssignments AS
(
    SELECT
        t.trip_id,

        t.truck_id AS trip_truck_id,

        f.purchase_truck_id,

        f.distinct_purchase_trucks,

        f.purchase_records

    FROM dbo.trips t

    INNER JOIN FuelByTrip f
        ON t.trip_id = f.trip_id

    WHERE t.dispatch_date >= '2022-01-01'
      AND t.dispatch_date < '2025-01-01'
)

SELECT
    COUNT(*) AS matched_trips,

    SUM(CASE
        WHEN trip_truck_id IS NULL
        THEN 1 ELSE 0
    END) AS trips_without_assigned_truck,

    SUM(CASE
        WHEN distinct_purchase_trucks = 0
        THEN 1 ELSE 0
    END) AS trips_without_purchase_truck_assignment,

    SUM(CASE
        WHEN distinct_purchase_trucks > 1
        THEN 1 ELSE 0
    END) AS trips_with_multiple_purchase_trucks,

    SUM(CASE
        WHEN trip_truck_id IS NOT NULL
         AND distinct_purchase_trucks = 1
         AND purchase_truck_id <> trip_truck_id
        THEN 1 ELSE 0
    END) AS mismatched_truck_assignments

FROM TripAssignments;
