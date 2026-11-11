
USE logistics_operations;





--- 01. MONTHLY FUEL EXPENDITURE AND PRICE TRENDS


SELECT
    YEAR(purchase_date) AS activity_year,
    MONTH(purchase_date) AS activity_month,

    COUNT(*) AS total_purchases,

    COUNT(DISTINCT trip_id) AS trips_with_fuel_purchases,

    CAST(
        SUM(gallons) AS DECIMAL(18,2)
    ) AS total_gallons,

    CAST(
        SUM(total_cost) AS DECIMAL(18,2)
    ) AS total_fuel_cost,

    CAST(
        SUM(total_cost) / NULLIF(SUM(gallons), 0)
        AS DECIMAL(10,3)
    ) AS weighted_average_price_per_gallon

FROM dbo.fuel_purchases

WHERE purchase_date >= '2022-01-01'
  AND purchase_date < '2025-01-01'

GROUP BY
    YEAR(purchase_date),
    MONTH(purchase_date)

ORDER BY
    activity_year,
    activity_month;





--- 02. OVERALL FUEL EXPENDITURE AND CONSUMPTION


SELECT
    COUNT(*) AS total_fuel_purchases,

    COUNT(DISTINCT trip_id) AS trips_with_fuel_purchases,

    SUM(gallons) AS total_gallons_purchased,

    SUM(total_cost) AS total_fuel_expenditure,

    CAST(
        SUM(total_cost) / NULLIF(SUM(gallons), 0)
        AS DECIMAL(10,3)
    ) AS weighted_average_price_per_gallon,

    CAST(
        SUM(total_cost) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS average_cost_per_purchase

FROM dbo.fuel_purchases

WHERE purchase_date >= '2022-01-01'
  AND purchase_date < '2025-01-01';





--- 03. TRIP-LEVEL FUEL RECONCILIATION
--- Purpose:
   ---Compare purchased fuel with recorded consumption
   ---Calculate operational and purchase-based MPG
   ---Calculate fuel cost per mile
   ---Identify differences in purchased gallons


WITH FuelByTrip AS
(
    SELECT
        trip_id,

        SUM(gallons) AS purchased_gallons,

        SUM(total_cost) AS purchased_fuel_cost

    FROM dbo.fuel_purchases

    WHERE purchase_date >= '2022-01-01'
      AND purchase_date < '2025-01-01'

    GROUP BY
        trip_id
),

TripComparison AS
(
    SELECT
        t.trip_id,
        t.actual_distance_miles,
        t.fuel_gallons_used,
        t.average_mpg,

        f.purchased_gallons,
        f.purchased_fuel_cost

    FROM dbo.trips t

    INNER JOIN FuelByTrip f
        ON t.trip_id = f.trip_id

    WHERE t.dispatch_date >= '2022-01-01'
      AND t.dispatch_date < '2025-01-01'
)

SELECT
    COUNT(*) AS matched_trips,

    SUM(actual_distance_miles) AS total_trip_miles,

    SUM(fuel_gallons_used) AS recorded_trip_fuel_gallons,

    SUM(purchased_gallons) AS purchased_fuel_gallons,

    CAST(
        SUM(actual_distance_miles) /
        NULLIF(SUM(fuel_gallons_used), 0)
        AS DECIMAL(10,2)
    ) AS operational_mpg,

    CAST(
        SUM(actual_distance_miles) /
        NULLIF(SUM(purchased_gallons), 0)
        AS DECIMAL(10,2)
    ) AS purchase_based_mpg,

    CAST(
        SUM(purchased_fuel_cost) /
        NULLIF(SUM(actual_distance_miles), 0)
        AS DECIMAL(10,3)
    ) AS fuel_cost_per_mile,

    CAST(
        SUM(purchased_gallons) -
        SUM(fuel_gallons_used)
        AS DECIMAL(18,2)
    ) AS difference_in_gallons,

    CAST(
        AVG(average_mpg)
        AS DECIMAL(10,2)
    ) AS average_recorded_trip_mpg

FROM TripComparison;





--- 04. TRUCK-LEVEL FUEL EFFICIENCY
--- Purpose:
   ---Compare operational MPG by truck
   ---Analyze total fuel expenditure by truck
   ---Calculate fuel purchase cost per mile


WITH FuelByTrip AS
(
    SELECT
        trip_id,

        MAX(truck_id) AS purchase_truck_id,

        COUNT(DISTINCT truck_id) AS distinct_purchase_trucks,

        SUM(gallons) AS purchased_gallons,

        SUM(total_cost) AS fuel_purchase_cost

    FROM dbo.fuel_purchases

    WHERE purchase_date >= '2022-01-01'
      AND purchase_date < '2025-01-01'

    GROUP BY
        trip_id
),

TruckTripData AS
(
    SELECT
        t.trip_id,
        t.truck_id,
        t.actual_distance_miles,
        t.fuel_gallons_used,

        f.purchased_gallons,
        f.fuel_purchase_cost

    FROM dbo.trips t

    INNER JOIN FuelByTrip f
        ON t.trip_id = f.trip_id

    WHERE t.dispatch_date >= '2022-01-01'
      AND t.dispatch_date < '2025-01-01'
      AND t.truck_id IS NOT NULL
      AND f.distinct_purchase_trucks = 1
      AND f.purchase_truck_id = t.truck_id
)

SELECT
    tr.truck_id,
    tr.unit_number,
    tr.make,
    tr.model_year,

    COUNT(*) AS total_trips,

    SUM(tt.actual_distance_miles) AS total_miles,

    CAST(
        SUM(tt.fuel_gallons_used)
        AS DECIMAL(18,2)
    ) AS recorded_fuel_gallons,

    CAST(
        SUM(tt.actual_distance_miles) /
        NULLIF(SUM(tt.fuel_gallons_used), 0)
        AS DECIMAL(10,2)
    ) AS operational_mpg,

    CAST(
        SUM(tt.fuel_purchase_cost)
        AS DECIMAL(18,2)
    ) AS total_fuel_purchase_cost,

    CAST(
        SUM(tt.purchased_gallons)
        AS DECIMAL(18,2)
    ) AS purchased_gallons,

    CAST(
        SUM(tt.fuel_purchase_cost) /
        NULLIF(SUM(tt.actual_distance_miles), 0)
        AS DECIMAL(10,3)
    ) AS purchase_cost_per_mile

FROM TruckTripData tt

INNER JOIN dbo.trucks tr
    ON tt.truck_id = tr.truck_id

GROUP BY
    tr.truck_id,
    tr.unit_number,
    tr.make,
    tr.model_year

ORDER BY
    operational_mpg DESC;
