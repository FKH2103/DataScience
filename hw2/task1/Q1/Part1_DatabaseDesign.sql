-- CREATING THE DATABASE
DROP DATABASE IF EXISTS ashpaz_db;

CREATE DATABASE ashpaz_db;

USE ashpaz_db;

-- LOCATIONS TABLE
CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,

    address TEXT NOT NULL,

    neighborhood VARCHAR(255),

    city VARCHAR(255)
);

-- RESTAURANTS TABLE
CREATE TABLE restaurants (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(255),

    phone VARCHAR(255),

    rest_type VARCHAR(100),

    location_id INT,

    FOREIGN KEY (location_id)
    REFERENCES locations(location_id)
);

-- SERVICES METRICS TABLE 
CREATE TABLE services_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    online_order ENUM('Yes','No'),
    book_table ENUM('Yes','No'),
    rate DECIMAL(3,1),
    votes INT UNSIGNED,
    approx_cost INT UNSIGNED,
    listed_in_type VARCHAR(100),
    cuisines TEXT,     
    menu_item TEXT,    
    restaurant_id INT,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);
