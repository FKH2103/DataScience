-- RAW STAGING TABLE
CREATE TABLE zomato_raw (
    address TEXT,
    name TEXT,
    online_order TEXT,
    book_table TEXT,
    rate TEXT,
    votes TEXT,
    phone TEXT,
    location TEXT,
    rest_type TEXT,
    cuisines TEXT,
    approx_cost TEXT,
    menu_item TEXT,
    listed_in_type TEXT,
    listed_in_city TEXT
);

USE ashpaz_db;

-- LOAD RAW CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zomato_cleaned.csv'
INTO TABLE zomato_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- INSERT LOCATIONS
INSERT INTO locations (
    address,
    neighborhood,
    city
)

SELECT DISTINCT
    address,
    location,
    listed_in_city
FROM zomato_raw
WHERE address IS NOT NULL
  AND location IS NOT NULL
  AND listed_in_city IS NOT NULL;


-- INSERT RESTAURANTS
INSERT INTO restaurants (
    name,
    phone,
    rest_type,
    location_id
)

SELECT DISTINCT
    z.name,
    z.phone,
    z.rest_type,
    l.location_id
FROM zomato_raw z
JOIN locations l
  ON z.address = l.address
 AND z.location = l.neighborhood
 AND z.listed_in_city = l.city;


-- INSERT SERVICES METRICS
INSERT INTO services_metrics (
    online_order,
    book_table,
    rate,
    votes,
    approx_cost,
    listed_in_type,
    cuisines,       
    menu_item,      
    restaurant_id
)
SELECT
    z.online_order,
    z.book_table,
    CASE
        WHEN z.rate REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(z.rate AS DECIMAL(3,1))
        ELSE NULL
    END,
    CASE
        WHEN z.votes REGEXP '^[0-9]+$'
        THEN CAST(z.votes AS UNSIGNED)
        ELSE NULL
    END,
    CASE
        WHEN z.approx_cost IS NULL OR z.approx_cost = ''
        THEN NULL
        ELSE CAST(
            REPLACE(SUBSTRING_INDEX(z.approx_cost,'.',1),',','') 
            AS UNSIGNED
        )
    END,
    
    z.listed_in_type,
    z.cuisines,     
    z.menu_item,    
    r.restaurant_id
FROM zomato_raw z
JOIN locations l
  ON z.address = l.address
 AND z.location = l.neighborhood
 AND z.listed_in_city = l.city
JOIN restaurants r
  ON z.name = r.name
 AND z.phone <=> r.phone
 AND z.rest_type <=> r.rest_type
 AND r.location_id = l.location_id;
