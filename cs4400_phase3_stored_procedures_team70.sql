-- CS4400: Introduction to Database Systems (Fall 2024)
-- Project Phase III: Stored Procedures SHELL [v4] Thursday, Nov 7, 2024
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

use business_supply;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date)
sp_main: begin
    -- ensure new owner has a unique username
    IF EXISTS (SELECT * FROM users WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM employees WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO users (username, first_name, last_name, address, birthdate)
    VALUES (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);

    INSERT INTO business_owners (username)
    VALUES (ip_username);
end //
delimiter ;

-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated driver or
worker roles.  A new employee must have a unique username and a unique tax identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer)
sp_main: begin
    -- ensure new owner has a unique username
    -- ensure new employee has a unique tax identifier
	IF EXISTS (SELECT * FROM users WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM employees WHERE taxID = ip_taxID) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO users (username, first_name, last_name, address, birthdate)
    VALUES (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);

    INSERT INTO employees (username, taxID, hired, experience, salary)
    VALUES (ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
end //
delimiter ;

-- [3] add_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the driver role to an existing employee.  The
employee/new driver must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_driver_role;
delimiter //
create procedure add_driver_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_license_type varchar(40), in ip_driver_experience integer)
sp_main: begin
    -- ensure employee exists and is not a worker
    -- ensure new driver has a unique license identifier
	IF NOT EXISTS (SELECT * FROM employees WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM drivers WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM drivers WHERE licenseID = ip_licenseID) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO drivers (username, licenseID, license_type, successful_trips)
    VALUES (ip_username, ip_licenseID, ip_license_type, ip_driver_experience);
end //
delimiter ;

-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40))
sp_main: begin
    -- ensure employee exists and is not a driver
	IF NOT EXISTS (SELECT * FROM employees WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM workers WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO workers (username)
    VALUES (ip_username);
end //
delimiter ;

-- [5] add_product()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new product.  A new product must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_product;
delimiter //
create procedure add_product (in ip_barcode varchar(40), in ip_name varchar(100),
	in ip_weight integer)
sp_main: begin
	-- ensure new product doesn't already exist
	IF EXISTS (SELECT * FROM products WHERE barcode = ip_barcode) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO products (barcode, iname, weight)
    VALUES (ip_barcode, ip_name, ip_weight);
end //
delimiter ;

-- [6] add_van()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new van.  A new van must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be driven
by a valid driver initially (i.e., driver works for the same service). And the van's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_van;
delimiter //
create procedure add_van (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_driven_by varchar(40))
sp_main: begin
	-- ensure new van doesn't already exist
    -- ensure that the delivery service exists
    -- ensure that a valid driver will control the van
    IF EXISTS (SELECT * FROM vans WHERE id = ip_id AND tag = ip_tag) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM delivery_services WHERE id = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF ip_driven_by IS NOT NULL AND NOT EXISTS (SELECT * FROM drivers WHERE username = ip_driven_by) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO vans (id, tag, fuel, capacity, sales, driven_by, located_at)
    VALUES (
        ip_id, 
        ip_tag, 
        ip_fuel, 
        ip_capacity, 
        ip_sales, 
        ip_driven_by, 
        (SELECT home_base FROM delivery_services WHERE id = ip_id)
    );
end //
delimiter ;

-- [7] add_business()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new business.  A new business must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_business;
delimiter //
create procedure add_business (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40))
sp_main: begin
	-- ensure new business doesn't already exist
    -- ensure that the location is valid
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    IF EXISTS (SELECT * FROM businesses WHERE long_name = ip_long_name) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM locations WHERE label = ip_location) THEN
        LEAVE sp_main;
    END IF;

    IF ip_rating < 1 OR ip_rating > 5 THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO businesses (long_name, rating, spent, location)
    VALUES (ip_long_name, ip_rating, ip_spent, ip_location);
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
	in ip_home_base varchar(40), in ip_manager varchar(40))
sp_main: begin
	-- ensure new delivery service doesn't already exist
    -- ensure that the home base location is valid
    -- ensure that the manager is valid
    IF EXISTS (SELECT * FROM delivery_services WHERE id = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM locations WHERE label = ip_home_base) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM workers WHERE username = ip_manager) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM delivery_services WHERE manager = ip_manager) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM work_for WHERE username = ip_manager) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO delivery_services (id, long_name, home_base, manager)
    VALUES (ip_id, ip_long_name, ip_home_base, ip_manager);

    INSERT INTO work_for (username, ID)
    VALUES (ip_manager, ip_id);
end //
delimiter ;

-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid van
destination.  A new location must have a unique combination of coordinates. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
	in ip_y_coord integer, in ip_space integer)
sp_main: begin
	-- ensure new location doesn't already exist
    -- ensure that the coordinate combination is distinct
    IF EXISTS (SELECT * FROM locations WHERE label = ip_label) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM locations WHERE x_coord = ip_x_coord AND y_coord = ip_y_coord) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO locations (label, x_coord, y_coord, space)
    VALUES (ip_label, ip_x_coord, ip_y_coord, ip_space);
end //
delimiter ;

-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a business owner to provide funds
to a business. The owner and business must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_amount integer, in ip_long_name varchar(40), in ip_fund_date date)
sp_main: begin
	-- ensure the owner and business are valid
    IF NOT EXISTS (SELECT * FROM business_owners WHERE username = ip_owner) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM businesses WHERE long_name = ip_long_name) THEN
        LEAVE sp_main;
    END IF;

    DELETE FROM fund WHERE business = ip_long_name;

    INSERT INTO fund (username, invested, invested_date, business)
    VALUES (ip_owner, ip_amount, ip_fund_date, ip_long_name);
end //
delimiter ;

-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires a worker to work for a delivery service.
If a worker is actively serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee hasn't already been hired by that service
	-- ensure that the employee and delivery service are valid
    -- ensure that the employee isn't a manager for another service
    IF NOT EXISTS (SELECT * FROM employees WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM delivery_services WHERE id = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM work_for WHERE username = ip_username AND ID = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM delivery_services WHERE manager = ip_username AND id != ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM vans WHERE driven_by = ip_username AND id != ip_id) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO work_for (username, ID)
    VALUES (ip_username, ip_id);
end //
delimiter ;

-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires a worker who is currently working for a delivery
service.  The only restriction is that the employee must not be serving as a manager 
for the service. Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't an active manager
    IF NOT EXISTS (SELECT * FROM work_for WHERE username = ip_username AND ID = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM delivery_services WHERE manager = ip_username AND id = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM vans WHERE driven_by = ip_username AND id = ip_id) THEN
        LEAVE sp_main;
    END IF;

    DELETE FROM work_for WHERE username = ip_username AND ID = ip_id;
end //
delimiter ;

-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints a worker who is currently hired by a delivery
service as the new manager for that service.  The only restrictions is that
the worker must not be working for any other delivery service. Otherwise, the appointment 
to manager is permitted.  The current manager is simply replaced. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't working for any other services
    IF NOT EXISTS (SELECT * FROM work_for WHERE username = ip_username AND ID = ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM vans WHERE driven_by = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM work_for WHERE username = ip_username AND ID != ip_id) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT * FROM workers WHERE username = ip_username) THEN
        INSERT INTO workers (username)
        VALUES (ip_username);
    END IF;

    UPDATE delivery_services
    SET manager = ip_username
    WHERE id = ip_id;
end //
delimiter ;

-- [14] takeover_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid driver to take control of a van owned by 
the same delivery service. The current controller of the van is simply relieved 
of those duties. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_van;
delimiter //
create procedure takeover_van (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer)
sp_main: begin
	-- ensure that the driver is not driving for another service
	-- ensure that the selected van is owned by the same service
    -- ensure that the employee is a valid driver
    IF NOT EXISTS (SELECT 1 FROM vans WHERE id = ip_id AND tag = ip_tag) THEN
        LEAVE sp_main;
    END IF;

    IF ip_username IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM drivers WHERE username = ip_username
        ) THEN
            LEAVE sp_main;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM vans
            WHERE driven_by = ip_username AND id != ip_id
              AND id != (SELECT id FROM vans WHERE driven_by = ip_username)
        ) THEN
            LEAVE sp_main;
        END IF;
    END IF;

    UPDATE vans
    SET driven_by = ip_username
    WHERE id = ip_id AND tag = ip_tag;
end //
delimiter ;

-- [15] load_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific product to a van's payload so that we can sell them for some
specific price to other businesses.  The van can only be loaded if it's located
at its delivery service's home base, and the van must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the product already loaded onto the van as applicable.  And if the product
already exists on the van, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_van;
delimiter //
create procedure load_van (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer)
sp_main: begin
	-- ensure that the van being loaded is owned by the service
	-- ensure that the product is valid
    -- ensure that the van is located at the service home base
	-- ensure that the quantity of new packages is greater than zero
	-- ensure that the van has sufficient capacity to carry the new packages
    -- add more of the product to the van
    IF NOT EXISTS (
        SELECT 1 
        FROM vans 
        WHERE id = ip_id AND tag = ip_tag
    ) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM products 
        WHERE barcode = ip_barcode
    ) THEN
        LEAVE sp_main;
    END IF;

    IF ip_more_packages <= 0 THEN
        LEAVE sp_main;
    END IF;

    SET @current_quantity = IFNULL(
        (SELECT SUM(c.quantity)
         FROM contain c
         WHERE c.id = ip_id AND c.tag = ip_tag), 0
    );

    SET @van_capacity = (SELECT capacity FROM vans WHERE id = ip_id AND tag = ip_tag);
    IF (@current_quantity + ip_more_packages) > @van_capacity THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (
        SELECT 1 
        FROM contain 
        WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode
    ) THEN
        UPDATE contain
        SET quantity = quantity + ip_more_packages
        WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode;
    ELSE
        INSERT INTO contain (id, tag, barcode, price, quantity)
        VALUES (ip_id, ip_tag, ip_barcode, ip_price, ip_more_packages);
    END IF;
end //
delimiter ;

-- [16] refuel_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a van. The van can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_van;
delimiter //
create procedure refuel_van (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer)
sp_main: begin
	-- ensure that the van being switched is valid and owned by the service
    -- ensure that the van is located at the service home base
    IF NOT EXISTS (SELECT * FROM vans WHERE id = ip_id AND tag = ip_tag) THEN
        LEAVE sp_main;
    END IF;

    SET @home_base = (SELECT home_base FROM delivery_services WHERE id = ip_id);
    IF (SELECT located_at FROM vans WHERE id = ip_id AND tag = ip_tag) != @home_base THEN
        LEAVE sp_main;
    END IF;

    UPDATE vans
    SET fuel = fuel + ip_more_fuel
    WHERE id = ip_id AND tag = ip_tag;
end //
delimiter ;

-- [17] drive_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single van to a new
location (i.e., destination). This will also update the respective driver's 
experience and van's fuel. The main constraints on the van(s) being able to 
move to a new  location are fuel and space.  A van can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a van can only move to a destination if there's enough
space remaining at the destination. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;

drop procedure if exists drive_van;
delimiter //
create procedure drive_van (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40))
sp_main: begin
    -- ensure that the destination is a valid location
    -- ensure that the van isn't already at the location
    -- ensure that the van has enough fuel to reach the destination and (then) home base
    -- ensure that the van has enough space at the destination for the trip
    -- ONLY EDIT THE CODE BELOW WITHIN THIS PROCEDURE, EVERYTHING ABOVE (WITHIN THIS PROCEDURE) IS ALREADY CORRECT
    IF NOT EXISTS (
        SELECT 1 FROM vans
        WHERE id = ip_id AND tag = ip_tag AND driven_by IS NOT NULL
    ) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM locations WHERE label = ip_destination) THEN
        LEAVE sp_main;
    END IF;

    IF (SELECT located_at FROM vans WHERE id = ip_id AND tag = ip_tag) = ip_destination THEN
        LEAVE sp_main;
    END IF;

    SET @fuel_to_destination = fuel_required(
        (SELECT located_at FROM vans WHERE id = ip_id AND tag = ip_tag),
        ip_destination
    );

    SET @home_base = (SELECT home_base FROM delivery_services WHERE id = ip_id);
    SET @fuel_to_home = fuel_required(ip_destination, @home_base);
    SET @total_fuel_needed = @fuel_to_destination + @fuel_to_home;

    SET @current_fuel = (SELECT fuel FROM vans WHERE id = ip_id AND tag = ip_tag);
    IF @current_fuel < @total_fuel_needed THEN
        LEAVE sp_main;
    END IF;

    SET @vans_at_destination = (SELECT COUNT(*) FROM vans WHERE located_at = ip_destination);
    SET @destination_space = (SELECT space FROM locations WHERE label = ip_destination);
    
    IF @vans_at_destination >= @destination_space THEN
        LEAVE sp_main;
    END IF;

    UPDATE vans
    SET fuel = fuel - @fuel_to_destination,
        located_at = ip_destination
    WHERE id = ip_id AND tag = ip_tag;

    SET @driver_username = (SELECT driven_by FROM vans WHERE id = ip_id AND tag = ip_tag);
    UPDATE drivers
    SET successful_trips = successful_trips + 1
    WHERE username = @driver_username;
end //
delimiter ;

-- [18] purchase_product()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a business to purchase products from a van
at its current location.  The van must have the desired quantity of the product
being purchased.  And the business must have enough money to purchase the
products.  If the transaction is otherwise valid, then the van and business
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_product;
delimiter //
create procedure purchase_product (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer)
sp_main: begin
	-- ensure that the business is valid
    -- ensure that the van is valid and exists at the business's location
	-- ensure that the van has enough of the requested product
	-- update the van's payload
    -- update the monies spent and gained for the van and business
    -- ensure all quantities in the contain table are greater than zero
    IF NOT EXISTS (SELECT * FROM businesses WHERE long_name = ip_long_name) THEN
        LEAVE sp_main;
    END IF;

    SET @business_location = (SELECT location FROM businesses WHERE long_name = ip_long_name);
    IF NOT EXISTS (
        SELECT * FROM vans
        WHERE id = ip_id AND tag = ip_tag AND located_at = @business_location
    ) THEN
        LEAVE sp_main;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM contain
        WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode AND quantity >= ip_quantity
    ) THEN
        LEAVE sp_main;
    END IF;

    SET @price = (SELECT price FROM contain WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode LIMIT 1);

    IF @price IS NULL THEN
        LEAVE sp_main;
    END IF;

    UPDATE contain
    SET quantity = quantity - ip_quantity
    WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode;

    DELETE FROM contain
    WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode AND quantity = 0;

    UPDATE vans
    SET sales = IFNULL(sales, 0) + (@price * ip_quantity)
    WHERE id = ip_id AND tag = ip_tag;

    UPDATE businesses
    SET spent = IFNULL(spent, 0) + (@price * ip_quantity)
    WHERE long_name = ip_long_name;

    IF EXISTS (SELECT * FROM contain WHERE id = ip_id AND tag = ip_tag AND quantity < 0) THEN
        LEAVE sp_main;
    END IF;
end //
delimiter ;

-- [19] remove_product()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a product from the system.  The removal can
occur if, and only if, the product is not being carried by any vans. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_product;
delimiter //
create procedure remove_product (in ip_barcode varchar(40))
sp_main: begin
	-- ensure that the product exists
    -- ensure that the product is not being carried by any vans
    IF NOT EXISTS (SELECT * FROM products WHERE barcode = ip_barcode) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM contain WHERE barcode = ip_barcode) THEN
        LEAVE sp_main;
    END IF;

    DELETE FROM products WHERE barcode = ip_barcode;
end //
delimiter ;

-- [20] remove_van()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a van from the system.  The removal can
occur if, and only if, the van is not carrying any products.*/
-- -----------------------------------------------------------------------------
drop procedure if exists remove_van;
delimiter //
create procedure remove_van (in ip_id varchar(40), in ip_tag integer)
sp_main: begin
	-- ensure that the van exists
    -- ensure that the van is not carrying any products
    IF NOT EXISTS (SELECT * FROM vans WHERE id = ip_id AND tag = ip_tag) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM contain WHERE id = ip_id AND tag = ip_tag) THEN
        LEAVE sp_main;
    END IF;

    DELETE FROM vans WHERE id = ip_id AND tag = ip_tag;
end //
delimiter ;

-- [21] remove_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a driver from the system.  The removal can
occur if, and only if, the driver is not controlling any vans.  
The driver's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_driver_role;
delimiter //
create procedure remove_driver_role (in ip_username varchar(40))
sp_main: begin
	-- ensure that the driver exists
    -- ensure that the driver is not controlling any vans
    -- remove all remaining information
    IF NOT EXISTS (SELECT * FROM drivers WHERE username = ip_username) THEN
        LEAVE sp_main;
    END IF;

    IF EXISTS (SELECT * FROM vans WHERE driven_by = ip_username) THEN
        LEAVE sp_main;
    END IF;

    SET @is_worker = (SELECT COUNT(*) FROM workers WHERE username = ip_username);

    DELETE FROM drivers WHERE username = ip_username;

    IF @is_worker = 0 THEN
        DELETE FROM work_for WHERE username = ip_username;
        DELETE FROM employees WHERE username = ip_username;
        DELETE FROM users WHERE username = ip_username;
    END IF;
end //
delimiter ;

-- [22] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
businesses for which they provide funds and the number of different places where
those businesses are located.  It also includes the highest and lowest ratings
for each of those businesses, as well as the total amount of debt based on the
monies spent purchasing products by all of those businesses. And if an owner
doesn't fund any businesses then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
SELECT 
    u.username, 
    u.first_name, 
    u.last_name, 
    u.address,
    COUNT(DISTINCT f.business) AS num_business_funded,
    COUNT(DISTINCT b.location) AS num_locations_funded,
    COALESCE(MAX(b.rating), 0) AS max_rating,
    COALESCE(MIN(b.rating), 0) AS min_rating,
    COALESCE(SUM(b.spent), 0) AS total_debt
FROM users u
JOIN business_owners bo ON u.username = bo.username
LEFT JOIN fund f ON bo.username = f.username
LEFT JOIN businesses b ON f.business = b.long_name
GROUP BY u.username, u.first_name, u.last_name, u.address;

-- [23] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, salary, hiring date and
experience level, along with license identifer and driving experience (if applicable,
'n/a' if not), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
create or replace view display_employee_view as
SELECT 
    e.username, 
    e.taxID, 
    e.salary,
    e.hired, 
    e.experience AS employee_experience, 
    IFNULL(d.licenseID, 'n/a') AS licenseID,
    IFNULL(CAST(d.successful_trips AS CHAR), 'n/a') AS driving_experience,
    CASE 
        WHEN EXISTS (SELECT 1 FROM delivery_services WHERE manager = e.username) THEN 'Yes' 
        ELSE 'No' 
    END AS manager_status
FROM employees e
LEFT JOIN drivers d ON e.username = d.username;

-- [24] display_driver_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a driver.
For each driver, it includes the username, licenseID and drivering experience, along
with the number of vans that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_driver_view as
SELECT
    d.username, 
    d.licenseID, 
    d.successful_trips,
    COUNT(v.id) AS num_vans_controlled
FROM drivers d
LEFT JOIN vans v ON d.username = v.driven_by
GROUP BY d.username, d.licenseID, d.successful_trips;

-- [25] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
name of the business or service at that location, the number of vans as well as 
the identifiers of the vans at the location (sorted by the tag), and both the 
total and remaining capacity at the location.
*/
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
SELECT
    l.label AS label,
    COALESCE(b.long_name, ds.long_name) AS long_name,
    l.x_coord AS x_coord,
    l.y_coord AS y_coord,
    IFNULL(l.space, 0) AS space,
    COUNT(DISTINCT CONCAT(v.id, v.tag)) AS num_vans,
    GROUP_CONCAT(DISTINCT CONCAT(v.id, v.tag) ORDER BY v.tag SEPARATOR ', ') AS van_ids,
    GREATEST(IFNULL(l.space, 0) - COUNT(DISTINCT CONCAT(v.id, v.tag)), 0) AS remaining_capacity
FROM
    locations l
    LEFT JOIN businesses b ON l.label = b.location
    LEFT JOIN delivery_services ds ON l.label = ds.home_base
    LEFT JOIN vans v ON v.located_at = l.label
WHERE
    b.long_name IS NOT NULL OR ds.long_name IS NOT NULL
GROUP BY
    l.label, long_name, l.x_coord, l.y_coord, l.space
HAVING
    COUNT(DISTINCT CONCAT(v.id, v.tag)) > 0;

-- [26] display_product_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the products.
For each product that is being carried by at least one van, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the product is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_product_view as
SELECT
    p.iname AS product_name,
    l.label AS location,
    SUM(c.quantity) AS total_packages,
    MIN(c.price) AS lowest_price,
    MAX(c.price) AS highest_price
FROM products p
JOIN contain c ON p.barcode = c.barcode
JOIN vans v ON c.id = v.id AND c.tag = v.tag
JOIN locations l ON v.located_at = l.label
GROUP BY p.iname, l.label;

-- [27] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the vans.  It must also include the number
of unique products along with the total cost and weight of those products being
carried by the vans. */
-- -----------------------------------------------------------------------------
create or replace view display_service_view as
SELECT 
    ds.id, 
    ds.long_name, 
    ds.home_base, 
    ds.manager,
    IFNULL((
        SELECT SUM(v2.sales)
        FROM vans v2
        WHERE v2.id = ds.id
    ), 0) AS total_sales,
    IFNULL((
        SELECT COUNT(DISTINCT c2.barcode)
        FROM vans v2
        JOIN contain c2 ON v2.id = c2.id AND v2.tag = c2.tag
        WHERE v2.id = ds.id
    ), 0) AS num_unique_products,
    IFNULL((
        SELECT SUM(c2.price * c2.quantity)
        FROM vans v2
        JOIN contain c2 ON v2.id = c2.id AND v2.tag = c2.tag
        WHERE v2.id = ds.id
    ), 0) AS total_cost,
    IFNULL((
        SELECT SUM(p2.weight * c2.quantity)
        FROM vans v2
        JOIN contain c2 ON v2.id = c2.id AND v2.tag = c2.tag
        JOIN products p2 ON c2.barcode = p2.barcode
        WHERE v2.id = ds.id
    ), 0) AS total_weight
FROM delivery_services ds;
