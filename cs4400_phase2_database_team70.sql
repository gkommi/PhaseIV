-- CS4400: Introduction to Database Systems (Fall 2024)
-- Phase II: Create Table & Insert Statements [v0] Monday, September 15, 2024 @ 17:00 EST

-- Team 70
-- Gowtam Kommi (gkommi3)
-- Ishaan Bhardwaj (ibhardwaj8)
-- Arihant Birani (abirani3)

SET GLOBAL transaction_isolation = 'SERIALIZABLE';
SET GLOBAL sql_mode = 'ANSI,TRADITIONAL';
SET NAMES utf8mb4;
SET SQL_SAFE_UPDATES = 0;

SET @thisDatabase = 'business_supply';
DROP DATABASE IF EXISTS business_supply;
CREATE DATABASE IF NOT EXISTS business_supply;
USE business_supply;

CREATE TABLE User (
    username VARCHAR(100) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    address VARCHAR(500) NOT NULL,
    birthdate DATE NOT NULL
);

CREATE TABLE Employee (
    taxID CHAR(11) PRIMARY KEY,
    hired DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    experience INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    FOREIGN KEY (username) REFERENCES User(username)
);

CREATE TABLE Owner (
    username VARCHAR(100) PRIMARY KEY,
    FOREIGN KEY (username) REFERENCES User(username)
);

CREATE TABLE Driver (
	licenseID VARCHAR(50) PRIMARY KEY,
	licenseType VARCHAR(255) NOT NULL,
    taxID CHAR(11) NOT NULL,
    successful_trips INT NOT NULL,
    FOREIGN KEY (taxID) REFERENCES Employee(taxID)
);

CREATE TABLE Product (
    barcode VARCHAR(255) PRIMARY KEY,
    iname VARCHAR(255) NOT NULL,
    weight INT NOT NULL
);

CREATE TABLE Location (
    label VARCHAR(100) NOT NULL,
    x_coord DECIMAL(9, 6),
    y_coord DECIMAL(9, 6),
    space INT,
    name VARCHAR(100),
    PRIMARY KEY (label)
);

CREATE TABLE Business (
    name VARCHAR(100) NOT NULL,
    label VARCHAR(100) NOT NULL,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    spent DECIMAL(10, 2) NOT NULL CHECK (spent >= 0),
    PRIMARY KEY (name),
    FOREIGN KEY (label) REFERENCES Location(label)
);

CREATE TABLE Service (
    ID VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
	label VARCHAR(100),
    FOREIGN KEY (label) REFERENCES Location(label)
    
);

CREATE TABLE Worker (
    taxID VARCHAR(11) PRIMARY KEY,
    ID VARCHAR(100),
    FOREIGN KEY (taxID) REFERENCES Employee(taxID),
    FOREIGN KEY (ID) REFERENCES Service(ID)
);

CREATE TABLE Work_For (
    taxID VARCHAR(11) NOT NULL,
    ID VARCHAR(100) NOT NULL,
    PRIMARY KEY (taxID, ID),
    FOREIGN KEY (taxID) REFERENCES Worker(taxID),
    FOREIGN KEY (ID) REFERENCES Service(ID)
);

CREATE TABLE Van (
    tag INT NOT NULL,
    service_ID VARCHAR(100),
    fuel DECIMAL(10, 2) NOT NULL,
    capacity INT NOT NULL,
    sales DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (tag, service_ID),
    FOREIGN KEY (service_ID) REFERENCES Service(ID)
);

CREATE TABLE Control (
    licenseID VARCHAR(50) NOT NULL,
    tag INT NOT NULL,
    service_ID VARCHAR(100) NOT NULL,
    PRIMARY KEY (tag, service_ID),
    FOREIGN KEY (licenseID) REFERENCES Driver(licenseID),
    FOREIGN KEY (tag, service_ID) REFERENCES Van(tag, service_ID)
);

CREATE TABLE Park (
    label VARCHAR(100) NOT NULL,
    tag INT NOT NULL,
    ID VARCHAR(100) NOT NULL,
    PRIMARY KEY (tag, ID),
    FOREIGN KEY (label) REFERENCES Location(label),
    FOREIGN KEY (tag, ID) REFERENCES Van(tag, service_ID)
);

CREATE TABLE Contain (
    barcode VARCHAR(50) NOT NULL,    
    tag INT NOT NULL,
    service_ID VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (barcode, tag, service_ID),
    FOREIGN KEY (barcode) REFERENCES Product(barcode),
    FOREIGN KEY (tag, service_ID) REFERENCES Van(tag, service_ID)
);

CREATE TABLE Fund (
    username VARCHAR(255),
    name VARCHAR(255),
    invested DECIMAL(10, 2) NOT NULL,
    date DATE NOT NULL,
    PRIMARY KEY (username, name),
    FOREIGN KEY (username) REFERENCES Owner(username),
    FOREIGN KEY (name) REFERENCES Business(name)
);



INSERT INTO User (username, first_name, last_name, address, birthdate) VALUES
('agarcia7', 'Alejandro', 'Garcia', '710 Living Water Drive', '1966-10-29'),
('awilson5', 'Aaron', 'Wilson', '220 Peachtree Street', '1963-11-11'),
('bsummers4', 'Brie', 'Summers', '5105 Dragon Star Circle', '1976-02-09'),
('cjordan5', 'Clark', 'Jordan', '77 Infinite Stars Road', '1966-06-05'),
('ckann5', 'Carrot', 'Kann', '64 Knights Square Trail', '1972-09-01'),
('csoares8', 'Claire', 'Soares', '706 Living Stone Way', '1965-09-03'),
('echarles19', 'Ella', 'Charles', '22 Peachtree Street', '1974-05-06'),
('eross10', 'Erica', 'Ross', '22 Peachtree Street', '1975-04-02'),
('fprefontaine6', 'Ford', 'Prefontaine', '10 Hitch Hikers Lane', '1961-01-28'),
('hstark16', 'Harmon', 'Stark', '53 Tanker Top Lane', '1971-10-27'),
('jstone5', 'Jared', 'Stone', '101 Five Finger Way', '1961-01-06'),
('lrodriguez5', 'Lina', 'Rodriguez', '360 Corkscrew Circle', '1975-04-02'),
('mrobot1', 'Mister', 'Robot', '10 Autonomy Trace', '1988-11-02'),
('mrobot2', 'Mister', 'Robot', '10 Clone Me Circle', '1988-11-02'),
('rlopez6', 'Radish', 'Lopez', '8 Queens Route', '1999-09-03'),
('sprince6', 'Sarah', 'Prince', '22 Peachtree Street', '1968-06-15'),
('tmccall5', 'Trey', 'McCall', '360 Corkscrew Circle', '1973-03-19');


INSERT INTO Employee (taxID, hired, salary, experience, username) VALUES
('999-99-9999', '2019-03-17', 41000, 24, 'agarcia7'),
('111-11-1111', '2020-03-15', 46000, 9, 'awilson5'),
('000-00-0000', '2018-12-06', 35000, 17, 'bsummers4'),
('640-81-2357', '2019-08-03', 46000, 27, 'ckann5'),
('888-88-8888', '2019-02-25', 57000, 26, 'csoares8'),

('777-77-7777', '2021-01-02', 27000, 3, 'echarles19'),
('444-44-4444', '2020-04-17', 61000, 10, 'eross10'),
('121-21-2121', '2020-04-19', 20000, 5, 'fprefontaine6'),

('555-55-5555', '2018-07-23', 59000, 20, 'hstark16'),
('222-22-2222', '2019-04-15', 58000, 20, 'lrodriguez5'),
('101-01-0101', '2015-05-27', 38000, 8, 'mrobot1'),

('010-10-1010', '2015-05-27', 38000, 8, 'mrobot2'),
('123-58-1321', '2017-02-05', 64000, 51, 'rlopez6'),
('333-33-3333', '2018-10-17', 33000, 29, 'tmccall5');


INSERT INTO Driver (taxID, licenseID, successful_trips, licenseType) VALUES
('999-99-9999', '610623', 38, 'CDL'),
('111-11-1111', '314159', 41, 'commercial'),
('000-00-0000', '411911', 35, 'private'),
('888-88-8888', '343563', 7, 'commercial'),
('121-21-2121', '657483', 2, 'private'),
('222-22-2222', '287182', 67, 'CDL'),
('101-01-0101', '101010', 18, 'CDL'),
('123-58-1321', '235711', 58, 'private');


INSERT INTO Worker(taxID) VALUES
('640-81-2357'),
('777-77-7777'),
('444-44-4444'),
('555-55-5555'),
('333-33-3333'),
('010-10-1010');


INSERT INTO Location (label, x_coord, y_coord, space, name) VALUES
('airport', 5, -6, 15, 'Aircraft Electrical Svc'),
('downtown', -4, -3, 10, 'Homestead Insurance'),
('springs', 7, 10, 8, 'Jones and Associates'),
('buckhead', 7, 10, 8, 'Prime Solutions'),
('avalon', 2, 15, 12, 'Innovative Ventures'),
('mercedes', -8, 5, NULL, 'Blue Horizon Enterprises'),
('highlands', 2, 1, 7, 'Peak Performance Group'),
('southside', 1, -16, 5, 'Summit Strategies'),
('midtown', 2, 1, 7, 'Elevate Consulting'),
('highpoint', NULL, NULL, NULL, NULL),
('plaza', -4, -3, 10, 'Pinnacle Partners');


INSERT INTO Business(name, rating, spent, label) VALUES
('Aircraft Electrical Svc', 5, 10, 'airport'),
('Homestead Insurance', 5, 30, 'downtown'),
('Jones and Associates', 3, 0, 'springs'),
('Prime Solutions', 4, 30, 'buckhead'),
('Innovative Ventures', 4, 0, 'avalon'),
('Blue Horizon Enterprises', 4, 10, 'mercedes'),
('Peak Performance Group', 5, 20, 'highlands'),
('Summit Strategies', 2, 0, 'southside'),
('Elevate Consulting', 5, 30, 'midtown'),
('Pinnacle Partners', 4, 10, 'plaza');
  

INSERT INTO Product (barcode, iname, weight) VALUES
('gc_4C6B9R', 'glass cleaner', 4),
('pn_2D7Z6C', 'pens', 5),
('sd_6J5S8H', 'screwdrivers', 4),
('pt_16WEF6', 'paper towels', 6),
('st_2D4E6L', 'shipping tape', 3),
('hm_5E7L23M', 'hammer', 3);


INSERT INTO Service(ID, name, label) VALUES
('mbm', 'Metro Business Mall', 'southside'),
('lcc', 'Local Commerce Center', 'plaza'),
('pbl', 'Pro Business Logistics', 'avalon');


INSERT INTO Van (tag, service_ID, fuel, capacity, sales) VALUES
(1, 'mbm', 100, 6, 0),
(5, 'mbm', 27, 7, 100),
(8, 'mbm', 100, 8, 0),
(11, 'mbm', 25, 10, 0),
(16, 'mbm', 17, 5, 40),
(1, 'lcc', 100, 9, 0),
(2, 'lcc', 75, 7, 0),
(3, 'pbl', 100, 5, 50),
(7, 'pbl', 53, 5, 100),
(8, 'pbl', 100, 6, 0),
(11, 'pbl', 90, 6, 0);


INSERT INTO Contain (barcode, tag, service_ID, price, quantity) VALUES
('pn_2D7Z6C', '3', 'pbl', 28, 2),
('pn_2D7Z6C', '5', 'mbm', 30, 1),
('pt_16WEF6', '1', 'lcc', 20, 5),
('pt_16WEF6', '8', 'mbm', 18, 4),
('st_2D4E6L', '1', 'lcc', 23, 3),
('st_2D4E6L', '11', 'mbm', 19, 3),
('st_2D4E6L', '1', 'mbm', 27, 6),
('hm_5E7L23M', '2', 'lcc', 14, 7),
('hm_5E7L23M', '3', 'pbl', 15, 2),
('hm_5E7L23M', '5', 'mbm', 17, 4);


INSERT INTO Control(licenseID, tag, service_ID) VALUES
('657483', 1, 'mbm'),
('657483', 5, 'mbm'),
('657483', 16, 'mbm'),
('411911', 8, 'mbm'),
('314159', 1, 'lcc'),
('610623', 3, 'pbl'),
('610623', 7, 'pbl'),
('610623', 8, 'pbl');


INSERT INTO Owner (username) VALUES
('jstone5'),
('sprince6');


INSERT INTO Fund (username, name, invested, date) VALUES
('jstone5', 'Jones and Associates', 20, '2022-10-25'),
('sprince6', 'Blue Horizon Enterprises', 10, '2022-03-06'),
('jstone5', 'Peak Performance Group', 30, '2022-09-08'),
('jstone5', 'Elevate Consulting', 5, '2022-07-25');


INSERT INTO Park (label, tag, ID) VALUES
('southside', '1', 'mbm'),
('buckhead', '5', 'mbm'),
('southside', '8', 'mbm'),
('buckhead', '11', 'mbm'),
('buckhead', '16', 'mbm'),
('airport', '1', 'lcc'),
('airport', '2', 'lcc'),
('avalon', '3', 'pbl'),
('avalon', '7', 'pbl'),
('highpoint', '8', 'pbl'),
('highpoint', '11', 'pbl');