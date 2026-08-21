/* 
======== CREATE PRODUCT DIMENSIONS=============*/

CREATE TABLE dim_products
(
    ProductID VARCHAR(20) NOT NULL,
    ProductName VARCHAR(150) NOT NULL,
    Category VARCHAR(100),
    SubCategory VARCHAR(100),
    UnitCost DECIMAL(18,2),
    UnitPrice DECIMAL(18,2),
    SupplierID VARCHAR(20),
    Perishable CHAR(1),
    AvgDailyDemand_Est DECIMAL(18,4),
    DemandVariability_CV DECIMAL(18,4)
    CONSTRAINT PK_dim_products
    PRIMARY KEY (ProductID)
);
GO

/* == CHECK TABLE CREATION===*/
SELECT * FROM dim_products

/* == LOAD PRODUCTS TABLE ==*/
BULK INSERT dim_products
FROM 'C:\Users\Expert\OneDrive\Documents\Products.csv'
WITH(
     FORMAT = 'CSV',
     FIRSTROW = 2,
     FIELDQUOTE = '"',
     TABLOCK
);

/*==== CREATE SUPPLIER DIMENSIONS */
CREATE TABLE dim_suppliers
(
    SupplierID VARCHAR(20) NOT NULL,
    SupplierName VARCHAR(150) NOT NULL,
    Region VARCHAR(100),
    ReliabilityTier VARCHAR(50),
    BaseLeadTimeDays INT,
    OnTimeDeliveryRate DECIMAL(8,4),
    DefectRatePct DECIMAL(8,4),
    PaymentTerms VARCHAR(50),

    CONSTRAINT PK_dim_suppliers
        PRIMARY KEY (SupplierID)
);
GO
/* == CHECK TABLE CREATION===*/
SELECT * FROM dim_suppliers

/* LOAD SUPPLIER TABLE*/
BULK INSERT dim_suppliers
FROM 'C:\Users\Expert\OneDrive\Documents\Suppliers.csv'
WITH(
     FIRSTROW = 2,
     FIELDTERMINATOR = ',',
     ROWTERMINATOR = '0x0a',
     TABLOCK
);

/*==== CREATE WAREHOUSE DIMENSIONS */
CREATE TABLE dim_warehouses
(
    WarehouseID VARCHAR(20) NOT NULL,
    WarehouseName VARCHAR(150) NOT NULL,
    Location VARCHAR(150),
    RegionServed VARCHAR(100),
    Capacity INT,

    CONSTRAINT PK_dim_warehouses
        PRIMARY KEY (WarehouseID)
);
GO
/* == CHECK TABLE CREATION===*/
SELECT * FROM dim_warehouses
/* LOAD WAREHOUSE TABLE*/
BULK INSERT dim_warehouses
FROM 'C:\Users\Expert\OneDrive\Documents\Warehouses.csv'
WITH(
     FORMAT = 'CSV',
     FIRSTROW = 2,
     FIELDQUOTE = '"',
     TABLOCK
);

/*==== CREATE DAILY INVENTORY FACT TABLE */
CREATE TABLE fact_inventory_daily
(
    Date DATE NOT NULL,
    ProductID VARCHAR(20) NOT NULL,
    WarehouseID VARCHAR(20) NOT NULL,
    OpeningStock INT,
    UnitsReceived INT,
    UnitsSold INT,
    LostSales INT,
    ClosingStock INT,
    StockoutFlag INT,
    Promotion INT,

    CONSTRAINT PK_fact_inventory_daily
        PRIMARY KEY
        (
            Date,
            ProductID,
            WarehouseID
        )
);
GO
/* == CHECK TABLE CREATION===*/
SELECT * FROM fact_inventory_daily
/* LOAD INVENTORY TABLE*/
BULK INSERT fact_inventory_daily
FROM 'C:\Users\Expert\OneDrive\Documents\Inventory_Daily.csv'
WITH(
     FORMAT = 'CSV',
     FIRSTROW = 2,
     FIELDQUOTE = '"',
     TABLOCK
);
/*==== CREATE PURCHASE ORDER FACT TABLE */
CREATE TABLE fact_purchase_orders
(
    PO_ID VARCHAR(30) NOT NULL,

    ProductID VARCHAR(20) NOT NULL,
    SupplierID VARCHAR(20) NOT NULL,
    WarehouseID VARCHAR(20) NOT NULL,

    OrderDate DATE,
    ExpectedDeliveryDate DATE,
    ActualDeliveryDate DATE,

    QuantityOrdered INT,
    QuantityReceived INT,

    UnitCost DECIMAL(18,2),
    TotalCost DECIMAL(18,2),

    Status VARCHAR(50),
    DelayDays INT,

    CONSTRAINT PK_fact_purchase_orders
        PRIMARY KEY (PO_ID)
);
GO
SELECT * from fact_purchase_orders
/* LOAD DATA */
BULK INSERT fact_purchase_orders
FROM 'C:\Users\Expert\OneDrive\Documents\Purchase_Orders.csv'
WITH(
     FORMAT = 'CSV',
     FIRSTROW = 2,
     FIELDQUOTE = '"',
     TABLOCK
);

/*==== CREATE DATE TABLE */

CREATE TABLE dim_date
(
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Week INT NOT NULL,
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL,

    CONSTRAINT PK_dim_date
        PRIMARY KEY (Date)
);
GO

DECLARE @StartDate DATE = '2025-01-01';
DECLARE @EndDate   DATE = '2027-12-31';

;WITH DateSeries AS
(
    SELECT @StartDate AS Date

    UNION ALL

    SELECT DATEADD(DAY, 1, Date)
    FROM DateSeries
    WHERE Date < @EndDate
)
/** LOAD DATA*/
INSERT INTO dim_date
(
    Date,
    Year,
    Quarter,
    Month,
    MonthNumber,
    MonthName,
    Week,
    Day,
    DayOfWeek,
    DayName,
    IsWeekend
)
SELECT
    Date,

    YEAR(Date) AS Year,

    DATEPART(QUARTER, Date) AS Quarter,

    MONTH(Date) AS Month,

    MONTH(Date) AS MonthNumber,

    DATENAME(MONTH, Date) AS MonthName,

    DATEPART(WEEK, Date) AS Week,

    DAY(Date) AS Day,

    DATEPART(WEEKDAY, Date) AS DayOfWeek,

    DATENAME(WEEKDAY, Date) AS DayName,

    CASE
        WHEN DATEPART(WEEKDAY, Date) IN (1, 7)
        THEN 1
        ELSE 0
    END AS IsWeekend

FROM DateSeries

OPTION (MAXRECURSION 0);
GO

/* addition of foreign keys */
/*Inventory -> Product*/
ALTER TABLE fact_inventory_daily
ADD CONSTRAINT FK_inventory_product
FOREIGN KEY (ProductID)
REFERENCES dim_products(ProductID);
GO
    
Inventory -> Warehouse
ALTER TABLE fact_inventory_daily
ADD CONSTRAINT FK_inventory_warehouse
FOREIGN KEY (WarehouseID)
REFERENCES dim_warehouses(WarehouseID);
GO
    
Inventory → Date
ALTER TABLE fact_inventory_daily
ADD CONSTRAINT FK_inventory_date
FOREIGN KEY (Date)
REFERENCES dim_date(Date);
GO
/* PURCHASE ORDERS ->WAREHOUSE*/
ALTER TABLE fact_purchase_orders
ADD CONSTRAINT FK_purchase_warehouse
FOREIGN KEY (WarehouseID)
REFERENCES dim_warehouses(WarehouseID);
GO
/* PURCHASE ORDERS -> PRODUCT*/    
ALTER TABLE fact_purchase_orders
ADD CONSTRAINT FK_purchase_order_date
FOREIGN KEY (OrderDate)
REFERENCES dim_date(Date);
GO
/* DATE KEYS TO PURCHASE ORDERS*/
ALTER TABLE fact_purchase_orders
ADD CONSTRAINT FK_purchase_supplier
FOREIGN KEY (SupplierID)
REFERENCES dim_suppliers(SupplierID);
GO

/* PURCHASE ORDERS -> PRODUCT*/
ALTER TABLE fact_purchase_orders
ADD CONSTRAINT FK_purchase_product
FOREIGN KEY (ProductID)
REFERENCES dim_products(ProductID);
GO

