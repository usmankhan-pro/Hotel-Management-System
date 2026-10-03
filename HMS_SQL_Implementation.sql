-- ============================================================
--  Hotel Management System -- SQL Implementation
--  University of Malakand | Database Systems Project
--  Group Leader : Usman Khan
--  Members      : Syed Hamza | Shah Islam | Zaid Ferman
--  Instructor   : Dr. Shah Khalid
--  Normalised to 3NF | MySQL 8.0
-- ============================================================

-- ============================================================
--  SECTION 1 -- DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS hotel_management_db;

CREATE DATABASE hotel_management_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hotel_management_db;

-- ============================================================
--  SECTION 2 -- DDL : TABLE CREATION (3NF Compliant)
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 PERSON (Supertype for Guest and Staff)
-- ------------------------------------------------------------
CREATE TABLE Person (
  person_id     INT           NOT NULL AUTO_INCREMENT,
  first_name    VARCHAR(50)   NOT NULL,
  last_name     VARCHAR(50)   NOT NULL,
  email         VARCHAR(100)  NOT NULL,
  date_of_birth DATE,
  gender        VARCHAR(10),
  city          VARCHAR(50),
  CONSTRAINT PK_Person    PRIMARY KEY (person_id),
  CONSTRAINT UQ_Person_Email UNIQUE  (email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.2 GUEST (Subtype of Person)
-- ------------------------------------------------------------
CREATE TABLE Guest (
  person_id      INT          NOT NULL,
  loyalty_points INT          DEFAULT 0,
  guest_type     VARCHAR(30)  NOT NULL DEFAULT 'Regular',
  CONSTRAINT PK_Guest        PRIMARY KEY (person_id),
  CONSTRAINT FK_Guest_Person FOREIGN KEY (person_id)
    REFERENCES Person(person_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT CHK_Guest_Type CHECK (
    guest_type IN ('Regular', 'VIP', 'Corporate', 'Loyalty')
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.3 STAFF (Subtype of Person)
-- ------------------------------------------------------------
CREATE TABLE Staff (
  person_id  INT            NOT NULL,
  position   VARCHAR(50)    NOT NULL,
  salary     DECIMAL(10,2)  NOT NULL,
  hire_date  DATE           NOT NULL,
  CONSTRAINT PK_Staff        PRIMARY KEY (person_id),
  CONSTRAINT FK_Staff_Person FOREIGN KEY (person_id)
    REFERENCES Person(person_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT CHK_Staff_Salary CHECK (salary > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.4 ROOM CLASS
-- ------------------------------------------------------------
CREATE TABLE Room_Class (
  room_class_id  INT            NOT NULL AUTO_INCREMENT,
  class_name     VARCHAR(30)    NOT NULL,
  base_price     DECIMAL(10,2)  NOT NULL,
  capacity       INT            NOT NULL,
  CONSTRAINT PK_Room_Class      PRIMARY KEY (room_class_id),
  CONSTRAINT UQ_RC_Name         UNIQUE (class_name),
  CONSTRAINT CHK_RC_Price       CHECK (base_price > 0),
  CONSTRAINT CHK_RC_Capacity    CHECK (capacity > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.5 BED TYPE
-- ------------------------------------------------------------
CREATE TABLE Bed_Type (
  bed_type_id   INT          NOT NULL AUTO_INCREMENT,
  bed_type_name VARCHAR(30)  NOT NULL,
  CONSTRAINT PK_Bed_Type     PRIMARY KEY (bed_type_id),
  CONSTRAINT UQ_BT_Name      UNIQUE (bed_type_name)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.6 FEATURE
-- ------------------------------------------------------------
CREATE TABLE Feature (
  feature_id   INT          NOT NULL AUTO_INCREMENT,
  feature_name VARCHAR(50)  NOT NULL,
  CONSTRAINT PK_Feature      PRIMARY KEY (feature_id),
  CONSTRAINT UQ_Feature_Name UNIQUE (feature_name)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.7 ROOM CLASS BED TYPE (Junction -- M:N resolver)
-- ------------------------------------------------------------
CREATE TABLE Room_Class_Bed_Type (
  room_class_id  INT  NOT NULL,
  bed_type_id    INT  NOT NULL,
  number_of_beds INT  NOT NULL,
  CONSTRAINT PK_RCBT     PRIMARY KEY (room_class_id, bed_type_id),
  CONSTRAINT FK_RCBT_RC  FOREIGN KEY (room_class_id)
    REFERENCES Room_Class(room_class_id) ON DELETE CASCADE,
  CONSTRAINT FK_RCBT_BT  FOREIGN KEY (bed_type_id)
    REFERENCES Bed_Type(bed_type_id)   ON DELETE CASCADE,
  CONSTRAINT CHK_RCBT_Beds CHECK (number_of_beds > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.8 ROOM CLASS FEATURE (Junction -- M:N resolver)
-- ------------------------------------------------------------
CREATE TABLE Room_Class_Feature (
  room_class_id  INT  NOT NULL,
  feature_id     INT  NOT NULL,
  CONSTRAINT PK_RCF      PRIMARY KEY (room_class_id, feature_id),
  CONSTRAINT FK_RCF_RC   FOREIGN KEY (room_class_id)
    REFERENCES Room_Class(room_class_id) ON DELETE CASCADE,
  CONSTRAINT FK_RCF_F    FOREIGN KEY (feature_id)
    REFERENCES Feature(feature_id)       ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.9 ROOM (Consolidated -- 2NF Fix Applied)
--
--  NORMALISATION NOTE:
--  Standard_Room (smoking, view_type) and Accessible_Room
--  (wheelchair_access, grab_bars) were separate subtype tables
--  in the original ERD -- a 2NF violation. Both are now
--  merged into Room as boolean/varchar columns.
-- ------------------------------------------------------------
CREATE TABLE Room (
  room_id            INT          NOT NULL AUTO_INCREMENT,
  room_class_id      INT          NOT NULL,
  room_number        VARCHAR(10)  NOT NULL,
  floor_number       INT          NOT NULL,
  status             VARCHAR(25)  NOT NULL DEFAULT 'Available',
  smoking            BOOLEAN      DEFAULT FALSE,
  view_type          VARCHAR(30),
  wheelchair_access  BOOLEAN      DEFAULT FALSE,
  grab_bars          BOOLEAN      DEFAULT FALSE,
  CONSTRAINT PK_Room        PRIMARY KEY (room_id),
  CONSTRAINT UQ_Room_Number UNIQUE      (room_number),
  CONSTRAINT FK_Room_Class  FOREIGN KEY (room_class_id)
    REFERENCES Room_Class(room_class_id) ON UPDATE CASCADE,
  CONSTRAINT CHK_Room_Status CHECK (
    status IN ('Available','Occupied','Reserved','Under Maintenance')
  ),
  CONSTRAINT CHK_Room_Floor CHECK (floor_number > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.10 BOOKING
--
--  NORMALISATION NOTE:
--  Original ERD had booking.person_id -> Person (incorrect).
--  Fixed: booking.guest_id -> Guest (semantically correct,
--  as only Guests make bookings -- 3NF design fix).
-- ------------------------------------------------------------
CREATE TABLE Booking (
  booking_id    INT          NOT NULL AUTO_INCREMENT,
  guest_id      INT          NOT NULL,
  booking_date  DATE         NOT NULL,
  num_adults    INT          NOT NULL DEFAULT 1,
  num_children  INT          DEFAULT 0,
  status        VARCHAR(20)  NOT NULL DEFAULT 'Confirmed',
  CONSTRAINT PK_Booking        PRIMARY KEY (booking_id),
  CONSTRAINT FK_Booking_Guest  FOREIGN KEY (guest_id)
    REFERENCES Guest(person_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT CHK_Booking_Adults   CHECK (num_adults > 0),
  CONSTRAINT CHK_Booking_Children CHECK (num_children >= 0),
  CONSTRAINT CHK_Booking_Status   CHECK (
    status IN ('Confirmed','Checked-In','Checked-Out','Cancelled')
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.11 RESERVATION
--
--  NORMALISATION NOTE:
--  Original ERD had nightly_rate stored in Reservation --
--  a 3NF violation (transitive dependency through room_class_id
--  -> Room_Class.base_price). nightly_rate is now derived
--  from Room_Class.base_price at query time via JOIN.
--  room_class_id added for class-level reservation before
--  specific room assignment.
-- ------------------------------------------------------------
CREATE TABLE Reservation (
  reservation_id  INT          NOT NULL AUTO_INCREMENT,
  guest_id        INT          NOT NULL,
  room_class_id   INT          NOT NULL,
  booking_id      INT          NOT NULL,
  checkin_date    DATE         NOT NULL,
  checkout_date   DATE         NOT NULL,
  status          VARCHAR(20)  NOT NULL DEFAULT 'Pending',
  CONSTRAINT PK_Reservation      PRIMARY KEY (reservation_id),
  CONSTRAINT FK_Res_Guest        FOREIGN KEY (guest_id)
    REFERENCES Guest(person_id),
  CONSTRAINT FK_Res_RoomClass    FOREIGN KEY (room_class_id)
    REFERENCES Room_Class(room_class_id),
  CONSTRAINT FK_Res_Booking      FOREIGN KEY (booking_id)
    REFERENCES Booking(booking_id),
  CONSTRAINT CHK_Res_Dates  CHECK (checkout_date > checkin_date),
  CONSTRAINT CHK_Res_Status CHECK (
    status IN ('Pending','Confirmed','Checked-In','Checked-Out','Cancelled')
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.12 ADDON
-- ------------------------------------------------------------
CREATE TABLE Addon (
  addon_id    INT            NOT NULL AUTO_INCREMENT,
  addon_name  VARCHAR(100)   NOT NULL,
  price       DECIMAL(10,2)  NOT NULL,
  CONSTRAINT PK_Addon       PRIMARY KEY (addon_id),
  CONSTRAINT UQ_Addon_Name  UNIQUE (addon_name),
  CONSTRAINT CHK_Addon_Price CHECK (price >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.13 BOOKING ADDON (Junction -- M:N resolver)
-- ------------------------------------------------------------
CREATE TABLE Booking_Addon (
  booking_id  INT            NOT NULL,
  addon_id    INT            NOT NULL,
  quantity    INT            NOT NULL,
  unit_price  DECIMAL(10,2)  NOT NULL,
  -- total_price is NOT stored (3NF: compute as quantity * unit_price)
  CONSTRAINT PK_BookingAddon  PRIMARY KEY (booking_id, addon_id),
  CONSTRAINT FK_BA_Booking    FOREIGN KEY (booking_id)
    REFERENCES Booking(booking_id) ON DELETE CASCADE,
  CONSTRAINT FK_BA_Addon      FOREIGN KEY (addon_id)
    REFERENCES Addon(addon_id),
  CONSTRAINT CHK_BA_Qty       CHECK (quantity > 0),
  CONSTRAINT CHK_BA_Price     CHECK (unit_price >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.14 INVOICE
-- ------------------------------------------------------------
CREATE TABLE Invoice (
  invoice_id    INT            NOT NULL AUTO_INCREMENT,
  booking_id    INT            NOT NULL,
  issued_date   DATE           NOT NULL,
  due_date      DATE,
  total_amount  DECIMAL(10,2)  NOT NULL,
  status        VARCHAR(20)    NOT NULL DEFAULT 'Unpaid',
  CONSTRAINT PK_Invoice         PRIMARY KEY (invoice_id),
  CONSTRAINT UQ_Invoice_Booking UNIQUE      (booking_id),
  CONSTRAINT FK_Invoice_Booking FOREIGN KEY (booking_id)
    REFERENCES Booking(booking_id) ON DELETE RESTRICT,
  CONSTRAINT CHK_Invoice_Amount CHECK (total_amount >= 0),
  CONSTRAINT CHK_Invoice_Status CHECK (
    status IN ('Unpaid','Partially Paid','Paid','Overdue')
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.15 INVOICE ITEM
--
--  NORMALISATION NOTE:
--  total_price column REMOVED from this table -- a 3NF
--  violation (derived: quantity * unit_price). Storing it
--  creates update anomalies. Compute it in SELECT queries
--  as: (quantity * unit_price) AS total_price
-- ------------------------------------------------------------
CREATE TABLE Invoice_Item (
  item_id      INT            NOT NULL AUTO_INCREMENT,
  invoice_id   INT            NOT NULL,
  description  VARCHAR(200)   NOT NULL,
  quantity     INT            NOT NULL,
  unit_price   DECIMAL(10,2)  NOT NULL,
  -- total_price deliberately omitted (3NF compliance)
  CONSTRAINT PK_Invoice_Item   PRIMARY KEY (item_id),
  CONSTRAINT FK_Item_Invoice   FOREIGN KEY (invoice_id)
    REFERENCES Invoice(invoice_id) ON DELETE CASCADE,
  CONSTRAINT CHK_Item_Qty      CHECK (quantity > 0),
  CONSTRAINT CHK_Item_Price    CHECK (unit_price >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2.16 PAYMENT
--
--  NORMALISATION NOTE:
--  payment_type removed -- duplicate of payment_method
--  (design fix). Only payment_method retained.
-- ------------------------------------------------------------
CREATE TABLE Payment (
  payment_id      INT            NOT NULL AUTO_INCREMENT,
  invoice_id      INT            NOT NULL,
  payment_date    DATE           NOT NULL,
  amount          DECIMAL(10,2)  NOT NULL,
  payment_method  VARCHAR(30)    NOT NULL,
  status          VARCHAR(20)    NOT NULL DEFAULT 'Completed',
  CONSTRAINT PK_Payment          PRIMARY KEY (payment_id),
  CONSTRAINT FK_Payment_Invoice  FOREIGN KEY (invoice_id)
    REFERENCES Invoice(invoice_id) ON DELETE RESTRICT,
  CONSTRAINT CHK_Payment_Amount  CHECK (amount > 0),
  CONSTRAINT CHK_Payment_Method  CHECK (
    payment_method IN ('Cash','Credit Card','Debit Card',
                       'Bank Transfer','Online')
  ),
  CONSTRAINT CHK_Payment_Status  CHECK (
    status IN ('Completed','Pending','Refunded','Failed')
  )
) ENGINE=InnoDB;

-- ============================================================
--  SECTION 3 -- INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX IDX_Room_Status       ON Room(status);
CREATE INDEX IDX_Room_Class        ON Room(room_class_id);
CREATE INDEX IDX_Booking_Guest     ON Booking(guest_id);
CREATE INDEX IDX_Booking_Status    ON Booking(status);
CREATE INDEX IDX_Res_Booking       ON Reservation(booking_id);
CREATE INDEX IDX_Res_Dates         ON Reservation(checkin_date, checkout_date);
CREATE INDEX IDX_Invoice_Status    ON Invoice(status);
CREATE INDEX IDX_Payment_Invoice   ON Payment(invoice_id);
CREATE INDEX IDX_Payment_Date      ON Payment(payment_date);

-- ============================================================
--  SECTION 4 -- DML : SAMPLE DATA
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Persons
-- ------------------------------------------------------------
INSERT INTO Person (person_id, first_name, last_name, email,
                    date_of_birth, gender, city) VALUES
(1, 'Ali',    'Khan',   'ali.khan@email.com',    '1990-05-15', 'Male',   'Peshawar'),
(2, 'Sara',   'Ahmed',  'sara.ahmed@email.com',  '1985-11-20', 'Female', 'Islamabad'),
(3, 'Usman',  'Shah',   'usman.shah@email.com',  '1992-03-08', 'Male',   'Lahore'),
(4, 'Maria',  'Iqbal',  'maria.iqbal@email.com', '1988-07-30', 'Female', 'Karachi'),
(5, 'Hamza',  'Ali',    'hamza.ali@hotel.com',   '1995-01-12', 'Male',   'Peshawar'),
(6, 'Zainab', 'Mir',    'zainab.mir@email.com',  '1998-04-22', 'Female', 'Quetta'),
(7, 'Bilal',  'Yusuf',  'bilal.yusuf@hotel.com', '1991-09-05', 'Male',   'Peshawar');

-- ------------------------------------------------------------
-- 4.2 Guests & Staff
-- ------------------------------------------------------------
INSERT INTO Guest (person_id, loyalty_points, guest_type) VALUES
(1, 150, 'Regular'),
(2, 500, 'VIP'),
(3, 0,   'Regular'),
(4, 300, 'Regular'),
(6, 800, 'VIP');

INSERT INTO Staff (person_id, position, salary, hire_date) VALUES
(5, 'Receptionist', 45000.00, '2022-01-15'),
(7, 'Manager',      85000.00, '2020-06-01');

-- ------------------------------------------------------------
-- 4.3 Room Classes
-- ------------------------------------------------------------
INSERT INTO Room_Class (room_class_id, class_name, base_price, capacity) VALUES
(1, 'Standard',   5000.00, 2),
(2, 'Deluxe',     8000.00, 2),
(3, 'Suite',     15000.00, 4),
(4, 'Executive', 12000.00, 3);

-- ------------------------------------------------------------
-- 4.4 Bed Types & Features
-- ------------------------------------------------------------
INSERT INTO Bed_Type (bed_type_id, bed_type_name) VALUES
(1, 'Single'), (2, 'Double'), (3, 'King'), (4, 'Twin');

INSERT INTO Feature (feature_id, feature_name) VALUES
(1, 'Wi-Fi'), (2, 'Air Conditioning'), (3, 'Sea View'),
(4, 'Balcony'), (5, 'Mini Bar'), (6, 'Jacuzzi');

-- ------------------------------------------------------------
-- 4.5 Room Class Bed Types & Features (Junction Data)
-- ------------------------------------------------------------
INSERT INTO Room_Class_Bed_Type VALUES
(1,1,2), (1,2,1),
(2,2,1), (2,3,1),
(3,3,1),
(4,3,1);

INSERT INTO Room_Class_Feature VALUES
(1,1),(1,2),
(2,1),(2,2),(2,4),
(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),
(4,1),(4,2),(4,5);

-- ------------------------------------------------------------
-- 4.6 Rooms (Consolidated -- with boolean flags)
-- ------------------------------------------------------------
INSERT INTO Room (room_id, room_class_id, room_number,
                  floor_number, status, smoking,
                  view_type, wheelchair_access, grab_bars) VALUES
(1, 1, '101', 1, 'Available',         FALSE, 'Garden',   FALSE, FALSE),
(2, 1, '102', 1, 'Available',         FALSE, 'Garden',   FALSE, FALSE),
(3, 2, '201', 2, 'Available',         FALSE, 'City',     FALSE, FALSE),
(4, 2, '202', 2, 'Occupied',          FALSE, 'City',     FALSE, FALSE),
(5, 3, '301', 3, 'Available',         FALSE, 'Sea',      FALSE, FALSE),
(6, 3, '302', 3, 'Reserved',          FALSE, 'Sea',      FALSE, FALSE),
(7, 4, '401', 4, 'Available',         FALSE, 'Mountain', TRUE,  TRUE),
(8, 1, '103', 1, 'Under Maintenance', TRUE,  'Garden',   FALSE, FALSE);

-- ------------------------------------------------------------
-- 4.7 Add-ons
-- ------------------------------------------------------------
INSERT INTO Addon (addon_id, addon_name, price) VALUES
(1, 'Breakfast',          800.00),
(2, 'Spa Package',       3000.00),
(3, 'Airport Transfer',  1500.00),
(4, 'Late Checkout',     1000.00),
(5, 'Extra Bed',         1200.00);

-- ------------------------------------------------------------
-- 4.8 Bookings
-- ------------------------------------------------------------
INSERT INTO Booking (booking_id, guest_id, booking_date,
                     num_adults, num_children, status) VALUES
(1, 1, '2026-06-01', 2, 0, 'Checked-In'),
(2, 2, '2026-06-05', 1, 1, 'Confirmed'),
(3, 3, '2026-06-10', 2, 2, 'Confirmed'),
(4, 4, '2026-05-20', 2, 0, 'Checked-Out'),
(5, 6, '2026-06-08', 3, 1, 'Confirmed');

-- ------------------------------------------------------------
-- 4.9 Reservations (nightly_rate NOT stored -- 3NF)
-- ------------------------------------------------------------
INSERT INTO Reservation (reservation_id, guest_id, room_class_id,
                          booking_id, checkin_date,
                          checkout_date, status) VALUES
(1, 1, 2, 1, '2026-06-02', '2026-06-06', 'Checked-In'),
(2, 2, 3, 2, '2026-06-06', '2026-06-10', 'Confirmed'),
(3, 3, 1, 3, '2026-06-11', '2026-06-14', 'Confirmed'),
(4, 4, 2, 4, '2026-05-21', '2026-05-25', 'Checked-Out'),
(5, 6, 3, 5, '2026-06-09', '2026-06-13', 'Confirmed');

-- ------------------------------------------------------------
-- 4.10 Booking Add-ons
-- ------------------------------------------------------------
INSERT INTO Booking_Addon (booking_id, addon_id, quantity, unit_price) VALUES
(1, 1, 3, 800.00),   -- Booking 1: Breakfast x3
(1, 2, 1, 3000.00),  -- Booking 1: Spa Package
(2, 3, 1, 1500.00),  -- Booking 2: Airport Transfer
(4, 1, 5, 800.00),   -- Booking 4: Breakfast x5
(4, 4, 1, 1000.00),  -- Booking 4: Late Checkout
(5, 2, 2, 3000.00),  -- Booking 5: Spa Package x2
(5, 3, 1, 1500.00);  -- Booking 5: Airport Transfer

-- ------------------------------------------------------------
-- 4.11 Invoices
-- ------------------------------------------------------------
INSERT INTO Invoice (invoice_id, booking_id, issued_date,
                     due_date, total_amount, status) VALUES
(1, 1, '2026-06-02', '2026-06-06', 52000.00, 'Partially Paid'),
(2, 2, '2026-06-06', '2026-06-10', 63500.00, 'Unpaid'),
(3, 3, '2026-06-11', '2026-06-14', 15000.00, 'Unpaid'),
(4, 4, '2026-05-21', '2026-05-25', 40000.00, 'Paid'),
(5, 5, '2026-06-09', '2026-06-13', 73500.00, 'Unpaid');

-- ------------------------------------------------------------
-- 4.12 Invoice Items (total_price NOT stored -- 3NF)
-- ------------------------------------------------------------
INSERT INTO Invoice_Item (item_id, invoice_id, description,
                           quantity, unit_price) VALUES
(1,  1, 'Deluxe Room (4 nights)',    4,  8000.00),
(2,  1, 'Breakfast',                 3,   800.00),
(3,  1, 'Spa Package',               1,  3000.00),
(4,  2, 'Suite Room (4 nights)',     4, 15000.00),
(5,  2, 'Airport Transfer',          1,  1500.00),
(6,  3, 'Standard Room (3 nights)', 3,  5000.00),
(7,  4, 'Deluxe Room (4 nights)',    4,  8000.00),
(8,  4, 'Breakfast',                 5,   800.00),
(9,  4, 'Late Checkout',             1,  1000.00),
(10, 5, 'Suite Room (4 nights)',     4, 15000.00),
(11, 5, 'Spa Package',               2,  3000.00),
(12, 5, 'Airport Transfer',          1,  1500.00);

-- ------------------------------------------------------------
-- 4.13 Payments
-- ------------------------------------------------------------
INSERT INTO Payment (payment_id, invoice_id, payment_date,
                     amount, payment_method, status) VALUES
(1, 4, '2026-05-25', 40000.00, 'Credit Card', 'Completed'),
(2, 1, '2026-06-03', 25000.00, 'Cash',        'Completed');

-- ============================================================
--  SECTION 5 -- VIEWS (Reporting Layer)
-- ============================================================

-- ------------------------------------------------------------
-- VIEW 1: Guest Ledger
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_Guest_Ledger AS
SELECT
  p.person_id,
  CONCAT(p.first_name, ' ', p.last_name)  AS guest_name,
  p.email,
  g.guest_type,
  b.booking_id,
  b.booking_date,
  b.status                                AS booking_status,
  i.invoice_id,
  i.total_amount,
  COALESCE(SUM(pay.amount), 0)            AS amount_paid,
  (i.total_amount - COALESCE(SUM(pay.amount), 0))
                                          AS outstanding_balance,
  i.status                                AS invoice_status
FROM Booking b
JOIN Guest g        ON b.guest_id   = g.person_id
JOIN Person p       ON g.person_id  = p.person_id
LEFT JOIN Invoice i     ON b.booking_id = i.booking_id
LEFT JOIN Payment pay   ON i.invoice_id = pay.invoice_id
  AND pay.status = 'Completed'
GROUP BY b.booking_id, p.person_id, i.invoice_id;

-- ------------------------------------------------------------
-- VIEW 2: Room Availability Dashboard
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_Room_Status AS
SELECT
  r.room_id,
  r.room_number,
  r.floor_number,
  rc.class_name,
  rc.base_price           AS nightly_rate,
  r.status,
  r.smoking,
  r.view_type,
  r.wheelchair_access,
  r.grab_bars
FROM Room r
JOIN Room_Class rc ON r.room_class_id = rc.room_class_id;

-- ------------------------------------------------------------
-- VIEW 3: Invoice Items with Computed Total (3NF compliant)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_Invoice_Items_Full AS
SELECT
  ii.item_id,
  ii.invoice_id,
  ii.description,
  ii.quantity,
  ii.unit_price,
  (ii.quantity * ii.unit_price) AS total_price   -- derived, not stored
FROM Invoice_Item ii;

-- ------------------------------------------------------------
-- VIEW 4: Defaulters Report
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_Defaulters AS
SELECT
  CONCAT(p.first_name, ' ', p.last_name) AS guest_name,
  p.email,
  b.booking_id,
  i.invoice_id,
  i.total_amount,
  COALESCE(SUM(pay.amount), 0)           AS amount_paid,
  (i.total_amount - COALESCE(SUM(pay.amount), 0))
                                         AS outstanding_balance,
  i.due_date
FROM Invoice i
JOIN Booking b  ON i.booking_id = b.booking_id
JOIN Guest g    ON b.guest_id   = g.person_id
JOIN Person p   ON g.person_id  = p.person_id
LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id
  AND pay.status = 'Completed'
WHERE b.status = 'Checked-Out'
GROUP BY i.invoice_id, p.person_id, b.booking_id,
         i.total_amount, i.due_date
HAVING outstanding_balance > 0;

-- ============================================================
--  SECTION 6 -- SQL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q1: All available rooms with class name and nightly rate
--     (rate derived from Room_Class.base_price -- not stored)
-- ------------------------------------------------------------
SELECT
  r.room_number,
  r.floor_number,
  rc.class_name,
  rc.base_price          AS nightly_rate,
  r.status,
  r.view_type,
  r.wheelchair_access,
  r.smoking
FROM Room r
JOIN Room_Class rc ON r.room_class_id = rc.room_class_id
WHERE r.status = 'Available'
ORDER BY rc.base_price, r.floor_number;

-- ------------------------------------------------------------
-- Q2: Full guest booking history with reservation & invoice
-- ------------------------------------------------------------
SELECT
  CONCAT(p.first_name, ' ', p.last_name)              AS guest_name,
  g.guest_type,
  b.booking_id,
  b.booking_date,
  rc.class_name                                        AS room_class,
  res.checkin_date,
  res.checkout_date,
  DATEDIFF(res.checkout_date, res.checkin_date)        AS nights,
  rc.base_price * DATEDIFF(res.checkout_date, res.checkin_date)
                                                       AS room_cost,
  i.total_amount                                       AS invoice_total,
  i.status                                             AS payment_status
FROM Booking b
JOIN Guest g          ON b.guest_id        = g.person_id
JOIN Person p         ON g.person_id       = p.person_id
JOIN Reservation res  ON b.booking_id      = res.booking_id
JOIN Room_Class rc    ON res.room_class_id = rc.room_class_id
LEFT JOIN Invoice i   ON b.booking_id      = i.booking_id
ORDER BY b.booking_date DESC;

-- ------------------------------------------------------------
-- Q3: Invoice items with computed total_price (3NF compliant)
-- ------------------------------------------------------------
SELECT
  i.invoice_id,
  CONCAT(p.first_name, ' ', p.last_name)  AS guest_name,
  ii.description,
  ii.quantity,
  ii.unit_price,
  (ii.quantity * ii.unit_price)           AS total_price,
  i.total_amount                          AS invoice_total
FROM Invoice i
JOIN Booking b        ON i.booking_id   = b.booking_id
JOIN Guest g          ON b.guest_id     = g.person_id
JOIN Person p         ON g.person_id    = p.person_id
JOIN Invoice_Item ii  ON i.invoice_id   = ii.invoice_id
ORDER BY i.invoice_id, ii.item_id;

-- ------------------------------------------------------------
-- Q4: Revenue summary grouped by room class
-- ------------------------------------------------------------
SELECT
  rc.class_name,
  COUNT(DISTINCT b.booking_id)                             AS total_bookings,
  SUM(DATEDIFF(res.checkout_date, res.checkin_date))       AS total_nights,
  SUM(rc.base_price *
      DATEDIFF(res.checkout_date, res.checkin_date))       AS room_revenue
FROM Booking b
JOIN Reservation res  ON b.booking_id      = res.booking_id
JOIN Room_Class rc    ON res.room_class_id = rc.room_class_id
WHERE b.status IN ('Checked-In', 'Checked-Out')
GROUP BY rc.class_name
ORDER BY room_revenue DESC;

-- ------------------------------------------------------------
-- Q5: Defaulters list (outstanding balance after checkout)
-- ------------------------------------------------------------
SELECT
  CONCAT(p.first_name, ' ', p.last_name)  AS guest_name,
  p.email,
  b.booking_id,
  i.invoice_id,
  i.total_amount,
  COALESCE(SUM(pay.amount), 0)            AS amount_paid,
  (i.total_amount - COALESCE(SUM(pay.amount), 0))
                                          AS outstanding_balance,
  i.due_date
FROM Invoice i
JOIN Booking b   ON i.booking_id = b.booking_id
JOIN Guest g     ON b.guest_id   = g.person_id
JOIN Person p    ON g.person_id  = p.person_id
LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id
  AND pay.status = 'Completed'
WHERE b.status = 'Checked-Out'
GROUP BY i.invoice_id, p.person_id, b.booking_id,
         i.total_amount, i.due_date
HAVING outstanding_balance > 0
ORDER BY outstanding_balance DESC;

-- ------------------------------------------------------------
-- Q6: Room occupancy rate per floor
-- ------------------------------------------------------------
SELECT
  r.floor_number,
  COUNT(r.room_id)                                              AS total_rooms,
  SUM(CASE WHEN r.status = 'Occupied'  THEN 1 ELSE 0 END)     AS occupied,
  SUM(CASE WHEN r.status = 'Available' THEN 1 ELSE 0 END)     AS available,
  SUM(CASE WHEN r.status = 'Reserved'  THEN 1 ELSE 0 END)     AS reserved,
  ROUND(
    SUM(CASE WHEN r.status = 'Occupied' THEN 1 ELSE 0 END)
    * 100.0 / COUNT(r.room_id), 2
  )                                                            AS occupancy_pct
FROM Room r
GROUP BY r.floor_number
ORDER BY r.floor_number;

-- ------------------------------------------------------------
-- Q7: Add-on revenue summary
-- ------------------------------------------------------------
SELECT
  a.addon_name,
  SUM(ba.quantity)                   AS total_units_sold,
  SUM(ba.quantity * ba.unit_price)   AS total_revenue
FROM Booking_Addon ba
JOIN Addon a ON ba.addon_id = a.addon_id
GROUP BY a.addon_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------
-- Q8: Guests with above-average loyalty points (subquery)
-- ------------------------------------------------------------
SELECT
  CONCAT(p.first_name, ' ', p.last_name)  AS guest_name,
  p.city,
  g.guest_type,
  g.loyalty_points
FROM Guest g
JOIN Person p ON g.person_id = p.person_id
WHERE g.loyalty_points > (
  SELECT AVG(loyalty_points) FROM Guest
)
ORDER BY g.loyalty_points DESC;

-- ------------------------------------------------------------
-- Q9: Most booked room class (nested subquery)
-- ------------------------------------------------------------
SELECT class_name, booking_count
FROM (
  SELECT rc.class_name,
         COUNT(res.reservation_id) AS booking_count
  FROM Room_Class rc
  JOIN Reservation res ON rc.room_class_id = res.room_class_id
  GROUP BY rc.class_name
) AS class_stats
WHERE booking_count = (
  SELECT MAX(cnt)
  FROM (
    SELECT COUNT(reservation_id) AS cnt
    FROM Reservation
    GROUP BY room_class_id
  ) AS counts
);

-- ------------------------------------------------------------
-- Q10: Full payment summary -- total paid vs outstanding
-- ------------------------------------------------------------
SELECT
  i.invoice_id,
  CONCAT(p.first_name, ' ', p.last_name)  AS guest_name,
  i.total_amount,
  COALESCE(SUM(pay.amount), 0)            AS total_paid,
  (i.total_amount - COALESCE(SUM(pay.amount), 0))
                                          AS balance_due,
  i.status                                AS invoice_status
FROM Invoice i
JOIN Booking b   ON i.booking_id = b.booking_id
JOIN Guest g     ON b.guest_id   = g.person_id
JOIN Person p    ON g.person_id  = p.person_id
LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id
  AND pay.status = 'Completed'
GROUP BY i.invoice_id, p.person_id, i.total_amount, i.status
ORDER BY balance_due DESC;

-- ------------------------------------------------------------
-- Q11: Rooms with all features (GROUP_CONCAT)
-- ------------------------------------------------------------
SELECT
  r.room_number,
  rc.class_name,
  r.floor_number,
  rc.base_price                                                  AS nightly_rate,
  GROUP_CONCAT(f.feature_name ORDER BY f.feature_name SEPARATOR ', ')
                                                                 AS features
FROM Room r
JOIN Room_Class rc          ON r.room_class_id  = rc.room_class_id
JOIN Room_Class_Feature rcf ON rc.room_class_id = rcf.room_class_id
JOIN Feature f              ON rcf.feature_id   = f.feature_id
GROUP BY r.room_id, r.room_number, rc.class_name,
         r.floor_number, rc.base_price
ORDER BY rc.base_price DESC;

-- ------------------------------------------------------------
-- Q12: Monthly revenue trend
-- ------------------------------------------------------------
SELECT
  DATE_FORMAT(pay.payment_date, '%Y-%m')  AS month,
  COUNT(DISTINCT pay.payment_id)          AS payments_received,
  SUM(pay.amount)                         AS monthly_revenue
FROM Payment pay
WHERE pay.status = 'Completed'
GROUP BY DATE_FORMAT(pay.payment_date, '%Y-%m')
ORDER BY month;

-- ------------------------------------------------------------
-- Q13: Rooms available for a given date range (availability check)
-- ------------------------------------------------------------
SELECT
  r.room_number,
  rc.class_name,
  rc.base_price AS nightly_rate,
  r.floor_number,
  r.view_type
FROM Room r
JOIN Room_Class rc ON r.room_class_id = rc.room_class_id
WHERE r.status = 'Available'
  AND r.room_id NOT IN (
    SELECT res.booking_id        -- rooms with overlapping reservations
    FROM Reservation res
    WHERE res.status NOT IN ('Cancelled','Checked-Out')
      AND NOT (res.checkout_date <= '2026-06-10'
               OR res.checkin_date >= '2026-06-15')
  )
ORDER BY rc.base_price;

-- ------------------------------------------------------------
-- Q14: Staff roster
-- ------------------------------------------------------------
SELECT
  CONCAT(p.first_name, ' ', p.last_name)  AS staff_name,
  p.email,
  s.position,
  s.salary,
  s.hire_date
FROM Staff s
JOIN Person p ON s.person_id = p.person_id
ORDER BY s.position, p.last_name;

-- ------------------------------------------------------------
-- Q15: Bed types and features per room class (multi-join)
-- ------------------------------------------------------------
SELECT
  rc.class_name,
  rc.base_price,
  GROUP_CONCAT(DISTINCT bt.bed_type_name ORDER BY bt.bed_type_name) AS bed_types,
  GROUP_CONCAT(DISTINCT f.feature_name  ORDER BY f.feature_name)   AS features
FROM Room_Class rc
LEFT JOIN Room_Class_Bed_Type rcbt ON rc.room_class_id = rcbt.room_class_id
LEFT JOIN Bed_Type bt              ON rcbt.bed_type_id  = bt.bed_type_id
LEFT JOIN Room_Class_Feature rcf   ON rc.room_class_id  = rcf.room_class_id
LEFT JOIN Feature f                ON rcf.feature_id    = f.feature_id
GROUP BY rc.room_class_id, rc.class_name, rc.base_price
ORDER BY rc.base_price;

-- ============================================================
--  END OF SCRIPT
--  Hotel Management System | University of Malakand
--  Database Systems | June 2026
-- ============================================================
