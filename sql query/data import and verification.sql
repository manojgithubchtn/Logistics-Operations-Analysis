--- SECTION 01: DATABASE CREATION AND SELECTION

CREATE DATABASE Logistics_operations;

USE Logistics_operations;


--- SECTION 02: DATABASE STRUCTURE INSPECTION
--- Purpose:
--- - List all base tables
--- - Check record counts
--- - Identify existing primary keys


--- 02.1 List all database tables 

SELECT
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


--- 02.2 Check record counts for all tables

SELECT
    t.name AS table_name,
    SUM(p.rows) AS total_rows

FROM sys.tables t

INNER JOIN sys.partitions p
    ON t.object_id = p.object_id

WHERE p.index_id IN (0, 1)

GROUP BY
    t.name

ORDER BY
    t.name;


--- 02.3 Identify existing primary key constraints

SELECT
    tc.TABLE_NAME,
    kcu.COLUMN_NAME,
    tc.CONSTRAINT_NAME

FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc

INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA

WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'

ORDER BY
    tc.TABLE_NAME,
    kcu.ORDINAL_POSITION;


--- SECTION 03: PRIMARY KEY CREATION
--- Purpose:
--- - Establish a unique identifier for facilities

ALTER TABLE dbo.facilities
ADD CONSTRAINT PK_facilities
PRIMARY KEY (facility_id);


--- SECTION 04: FOREIGN KEY CREATION
--- Purpose:
--- - Establish relationships between database tables
--- - Maintain referential integrity


--- 04.1 Loads relationships

ALTER TABLE dbo.loads
ADD CONSTRAINT FK_loads_customers
FOREIGN KEY (customer_id)
REFERENCES dbo.customers(customer_id);

ALTER TABLE dbo.loads
ADD CONSTRAINT FK_loads_routes
FOREIGN KEY (route_id)
REFERENCES dbo.routes(route_id);


--- 04.2 Trips relationships

ALTER TABLE dbo.trips
ADD CONSTRAINT FK_trips_loads
FOREIGN KEY (load_id)
REFERENCES dbo.loads(load_id);

ALTER TABLE dbo.trips
ADD CONSTRAINT FK_trips_drivers
FOREIGN KEY (driver_id)
REFERENCES dbo.drivers(driver_id);

ALTER TABLE dbo.trips
ADD CONSTRAINT FK_trips_trucks
FOREIGN KEY (truck_id)
REFERENCES dbo.trucks(truck_id);

ALTER TABLE dbo.trips
ADD CONSTRAINT FK_trips_trailers
FOREIGN KEY (trailer_id)
REFERENCES dbo.trailers(trailer_id);


--- 04.3 Delivery Events relationships

ALTER TABLE dbo.delivery_events
ADD CONSTRAINT FK_delivery_events_loads
FOREIGN KEY (load_id)
REFERENCES dbo.loads(load_id);

ALTER TABLE dbo.delivery_events
ADD CONSTRAINT FK_delivery_events_trips
FOREIGN KEY (trip_id)
REFERENCES dbo.trips(trip_id);

ALTER TABLE dbo.delivery_events
ADD CONSTRAINT FK_delivery_events_facilities
FOREIGN KEY (facility_id)
REFERENCES dbo.facilities(facility_id);


--- 04.4 Fuel Purchases relationships

ALTER TABLE dbo.fuel_purchases
ADD CONSTRAINT FK_fuel_purchases_trips
FOREIGN KEY (trip_id)
REFERENCES dbo.trips(trip_id);

ALTER TABLE dbo.fuel_purchases
ADD CONSTRAINT FK_fuel_purchases_drivers
FOREIGN KEY (driver_id)
REFERENCES dbo.drivers(driver_id);

ALTER TABLE dbo.fuel_purchases
ADD CONSTRAINT FK_fuel_purchases_trucks
FOREIGN KEY (truck_id)
REFERENCES dbo.trucks(truck_id);


--- 04.5 Maintenance Records relationships

ALTER TABLE dbo.maintenance_records
ADD CONSTRAINT FK_maintenance_records_trucks
FOREIGN KEY (truck_id)
REFERENCES dbo.trucks(truck_id);


--- 04.6 Safety Incidents relationships

ALTER TABLE dbo.safety_incidents
ADD CONSTRAINT FK_safety_incidents_trips
FOREIGN KEY (trip_id)
REFERENCES dbo.trips(trip_id);

ALTER TABLE dbo.safety_incidents
ADD CONSTRAINT FK_safety_incidents_drivers
FOREIGN KEY (driver_id)
REFERENCES dbo.drivers(driver_id);

ALTER TABLE dbo.safety_incidents
ADD CONSTRAINT FK_safety_incidents_trucks
FOREIGN KEY (truck_id)
REFERENCES dbo.trucks(truck_id);


--- 04.7 Driver Monthly Metrics relationships

ALTER TABLE dbo.driver_monthly_metrics
ADD CONSTRAINT FK_driver_monthly_metrics_drivers
FOREIGN KEY (driver_id)
REFERENCES dbo.drivers(driver_id);


--- 04.8 Truck Utilization Metrics relationships

ALTER TABLE dbo.truck_utilization_metrics
ADD CONSTRAINT FK_truck_utilization_metrics_trucks
FOREIGN KEY (truck_id)
REFERENCES dbo.trucks(truck_id);


--- SECTION 05: RELATIONSHIP VERIFICATION
--- Purpose:
--- - Inspect foreign key relationships
--- - Verify foreign key constraint status


--- 05.1 List all foreign key relationships

SELECT
    OBJECT_NAME(fk.parent_object_id) AS child_table,

    COL_NAME(
        fkc.parent_object_id,
        fkc.parent_column_id
    ) AS foreign_key_column,

    OBJECT_NAME(fk.referenced_object_id) AS parent_table,

    COL_NAME(
        fkc.referenced_object_id,
        fkc.referenced_column_id
    ) AS referenced_column,

    fk.name AS constraint_name

FROM sys.foreign_keys fk

INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id

ORDER BY
    child_table,
    foreign_key_column;


--- 05.2 Check foreign key constraint status

SELECT
    name AS foreign_key_name,

    OBJECT_NAME(parent_object_id) AS child_table,

    is_disabled,

    is_not_trusted

FROM sys.foreign_keys

ORDER BY
    child_table,
    name;


--- SECTION 06: TRIP AND LOAD RELATIONSHIP VALIDATION
--- Purpose:
--- - Verify trip-to-load relationships
--- - Check trip and load uniqueness


--- 06.1 Identify loads associated with an unexpected
---      number of trip records

SELECT
    load_id,
    COUNT(*) AS total_trips

FROM dbo.trips

GROUP BY
    load_id

HAVING COUNT(*) <> 1;


--- 06.2 Verify total trips, unique loads and unique trips

SELECT
    COUNT(*) AS total_trips,

    COUNT(DISTINCT load_id) AS unique_loads,

    COUNT(DISTINCT trip_id) AS unique_trips

FROM dbo.trips;


--- SECTION 07: DELIVERY EVENT RELATIONSHIP VALIDATION
--- Purpose:
--- - Check pickup and delivery event counts
--- - Validate event-to-trip and event-to-load relationships
--- - Inspect delivery-event distribution


--- 07.1 Verify one pickup and one delivery event per trip

SELECT
    trip_id,

    COUNT(*) AS total_events,

    SUM(CASE
        WHEN event_type = 'Pickup' THEN 1
        ELSE 0
    END) AS pickup_events,

    SUM(CASE
        WHEN event_type = 'Delivery' THEN 1
        ELSE 0
    END) AS delivery_events

FROM dbo.delivery_events

GROUP BY
    trip_id

HAVING
    COUNT(*) <> 2

    OR SUM(CASE
        WHEN event_type = 'Pickup' THEN 1
        ELSE 0
    END) <> 1

    OR SUM(CASE
        WHEN event_type = 'Delivery' THEN 1
        ELSE 0
    END) <> 1;


--- 07.2 Verify delivery-event counts per load

SELECT
    load_id,

    COUNT(*) AS total_events

FROM dbo.delivery_events

GROUP BY
    load_id

HAVING COUNT(*) <> 2;


--- 07.3 Analyze delivery-event distribution

SELECT
    event_type,

    COUNT(*) AS total_events,

    COUNT(DISTINCT trip_id) AS unique_trips,

    COUNT(DISTINCT load_id) AS unique_loads

FROM dbo.delivery_events

GROUP BY
    event_type;


--- 07.4 Verify trip and delivery-event join results

SELECT
    COUNT(*) AS joined_rows,

    COUNT(DISTINCT t.trip_id) AS unique_trips,

    COUNT(DISTINCT t.load_id) AS unique_loads

FROM dbo.trips t

INNER JOIN dbo.delivery_events de
    ON t.trip_id = de.trip_id;


--- SECTION 08: FUEL PURCHASE RELATIONSHIP VALIDATION
--- Purpose:
--- - Analyze fuel purchase frequency per trip
--- - Calculate average purchases per trip
--- - Examine the distribution of purchase counts


--- 08.1 Identify trips with multiple fuel purchases

SELECT
    trip_id,

    COUNT(*) AS total_fuel_purchases

FROM dbo.fuel_purchases

GROUP BY
    trip_id

HAVING COUNT(*) > 1

ORDER BY
    total_fuel_purchases DESC;


--- 08.2 Calculate average fuel purchases per trip

SELECT
    COUNT(*) AS total_fuel_records,

    COUNT(DISTINCT trip_id) AS trips_with_fuel_records,

    COUNT(*) * 1.0 /
        NULLIF(COUNT(DISTINCT trip_id), 0)
        AS avg_purchases_per_trip

FROM dbo.fuel_purchases;


--- 08.3 Analyze distribution of fuel purchases per trip

WITH FuelCount AS
(
    SELECT
        trip_id,

        COUNT(*) AS total_purchases

    FROM dbo.fuel_purchases

    GROUP BY
        trip_id
)

SELECT
    total_purchases,

    COUNT(*) AS number_of_trips

FROM FuelCount

GROUP BY
    total_purchases

ORDER BY
    total_purchases;



