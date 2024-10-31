USE [master]
GO

/*******************************************************************************
   Drop database if it exists
********************************************************************************/
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'ffood')
BEGIN
	ALTER DATABASE ffood SET OFFLINE WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE ffood SET ONLINE;
	DROP DATABASE ffood;
END

GO

CREATE DATABASE ffood
GO

USE ffood
GO

/*******************************************************************************
	Drop tables if exists
*******************************************************************************/
DECLARE @sql nvarchar(MAX) 
SET @sql = N'' 

SELECT @sql = @sql + N'ALTER TABLE ' + QUOTENAME(KCU1.TABLE_SCHEMA) 
    + N'.' + QUOTENAME(KCU1.TABLE_NAME) 
    + N' DROP CONSTRAINT ' -- + QUOTENAME(rc.CONSTRAINT_SCHEMA)  + N'.'  -- not in MS-SQL
    + QUOTENAME(rc.CONSTRAINT_NAME) + N'; ' + CHAR(13) + CHAR(10) 
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS RC 

INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU1 
    ON KCU1.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG  
    AND KCU1.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA 
    AND KCU1.CONSTRAINT_NAME = RC.CONSTRAINT_NAME 

EXECUTE(@sql) 

GO
DECLARE @sql2 NVARCHAR(max)=''

SELECT @sql2 += ' Drop table ' + QUOTENAME(TABLE_SCHEMA) + '.'+ QUOTENAME(TABLE_NAME) + '; '
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'

Exec Sp_executesql @sql2 
GO 

--use ffood database
use ffood;
GO

-- Create 16 tables
create table FoodType (
	food_type_id	tinyint identity(1,1) not null primary key,
	food_type		nvarchar(50) not null
);

GO

create table Food (
	food_id			smallint identity(1,1) not null primary key,
	food_name		nvarchar(500) not null,
	food_description	nvarchar(2000) null,
	food_price		money not null,
        food_limit		smallint not null,
	food_status		bit not null,
	food_rate		tinyint null,
	discount_percent	tinyint not null,
	food_img_url		varchar(400) not null,
	food_type_id		tinyint not null foreign key references FoodType(food_type_id)
);

GO

create table [Admin] (
	admin_id		tinyint identity(1,1) not null primary key,
	admin_fullname		nvarchar(200) not null,
);

GO

create table AdminFood (
	admin_id		tinyint not null foreign key references [Admin](admin_id),
	food_id			smallint not null foreign key references Food(food_id)
);

GO

create table Staff (
	staff_id		tinyint identity(1,1) not null primary key,
	staff_fullname		nvarchar(200) not null,
);

GO

create table Voucher (
	voucher_id		tinyint identity(1,1) not null primary key,
	voucher_name		nvarchar(200) not null,
	voucher_code			char(16) not null,
	voucher_discount_percent	tinyint not null,
	voucher_quantity		smallint not null,
	voucher_status			bit not null,
	voucher_date			datetime not null
);

GO

create table PromotionManager (
	pro_id			tinyint identity(1,1) not null primary key,
	pro_fullname		nvarchar(200) not null,
);

GO

create table Customer (
	customer_id		int identity(1,1) not null primary key,
	customer_firstname	nvarchar(200) not null,
	customer_lastname	nvarchar(200) not null,
	customer_gender		nvarchar(5) not null,
	customer_phone		varchar(11) not null,
	customer_address	nvarchar(1000) not null
);

GO

-- Create index for Customer table to improve search performance
create index idx_customer_firstname_lastname_gender_phone_address
on Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address);

GO

create table Account (
	account_id		int identity(1,1) not null primary key,
	customer_id		int null foreign key references Customer(customer_id),
	staff_id		tinyint null foreign key references Staff(staff_id),
	pro_id			tinyint null foreign key references PromotionManager(pro_id),
	admin_id		tinyint null foreign key references [Admin](admin_id),
	account_username	nvarchar(100) not null,
	account_email		nvarchar(500) not null,
	account_password	char(32) not null,
	account_type		varchar(20) not null,
	lastime_order 	datetime null
);

GO

create table Point (
	point_id			int identity(1,1) not null primary key,
	customer_id		int not null foreign key references Customer(customer_id),
	[point]		tinyint not null
);

GO

create table Cart (
	cart_id			int identity(1,1) not null primary key,
	customer_id		int not null foreign key references Customer(customer_id)
);

GO

create table CartItem (
	cart_item_id		int identity(1,1) not null primary key,
	cart_id			int not null foreign key references Cart(cart_id),
	food_id			smallint not null foreign key references Food(food_id),
	food_price		money not null,
	food_quantity		tinyint not null
);

GO

create table OrderStatus (
	order_status_id		tinyint identity(1,1) not null primary key,
	order_status		nvarchar(50) not null
);

GO

create table PaymentMethod (
	payment_method_id	tinyint identity(1,1) not null primary key,
	payment_method		nvarchar(50) not null
);

GO

create table [Order] (
	order_id		int identity(1,1) not null primary key,
	cart_id			int not null foreign key references Cart(cart_id),
	customer_id		int not null foreign key references Customer(customer_id),
	order_status_id		tinyint not null foreign key references OrderStatus(order_status_id),
	payment_method_id	tinyint not null foreign key references PaymentMethod(payment_method_id),
	voucher_id		tinyint null foreign key references Voucher(voucher_id),
	contact_phone		varchar(11) not null,
	delivery_address	nvarchar(500) not null,
	order_time		datetime not null,
	order_total		money not null,
	order_note		nvarchar(1023) null,
	delivery_time		datetime null,
	order_cancel_time	datetime null
);

GO

create table Payment (
    order_id                int not null foreign key references [Order](order_id),
    payment_method_id       tinyint not null foreign key references PaymentMethod(payment_method_id),
    payment_total           money not null,
    payment_content         nvarchar(1023) null,
    payment_bank            nvarchar(50) null,
    payment_code            varchar(20) null,
    payment_status          tinyint not null,
    payment_time            datetime not null
);

GO

create table OrderLog (
    log_id				int identity(1,1) not null primary key,
    order_id            int not null foreign key references [Order](order_id),
    staff_id			tinyint null foreign key references Staff(staff_id),
    admin_id			tinyint null foreign key references [Admin](admin_id),
    log_activity        nvarchar(100) not null,
    log_time            datetime not null
);

GO

--Use ffood database
USE ffood
GO

--Set status of food = 0 if limit = 0
CREATE TRIGGER tr_UpdateFoodStatus
ON Food
AFTER UPDATE
AS
BEGIN
    IF UPDATE(food_limit)
    BEGIN
        UPDATE Food
        SET food_status = 0
        WHERE food_limit = 0;
    END
END;

GO

-- Inactivate food when delete
CREATE TRIGGER tr_InactivateFood
ON Food
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Food
    SET food_status = 0
    WHERE food_id IN (SELECT food_id FROM deleted);
END;

GO

-- Remove cart after customer deleted
CREATE TRIGGER tr_delete_cart_links
ON Account
AFTER DELETE
AS
BEGIN
    DELETE FROM Cart WHERE customer_id IN (SELECT deleted.customer_id FROM deleted);
END

GO

-- Don't delete when still have order
CREATE TRIGGER tr_prevent_delete_customer
ON Customer
INSTEAD OF DELETE
AS
BEGIN
    IF (EXISTS (SELECT 1 FROM Cart WHERE customer_id = (SELECT customer_id FROM deleted)) OR
        EXISTS (SELECT 1 FROM [Order] WHERE customer_id = (SELECT customer_id FROM deleted)))
    BEGIN
        RAISERROR('Cannot delete customer with active cart or orders.', 16, 1)
    END
    ELSE
    BEGIN
        DELETE FROM Customer WHERE customer_id = (SELECT customer_id FROM deleted)
    END
END

GO

--Use ffood database
use ffood;

-- Insert Admin records
insert into [Admin] (admin_fullname) values (N'Nguyễn Quốc Anh');


-- Insert Account records for Admins
-- Admin passwords are 'admin#' where # ranges from 1 to 6
-- Hash the passwords using MD5 algorithm
-- Admin passwords = 123456
-- Admin account ID starts from 1-20


insert into Account (admin_id, account_username, account_email, account_password, account_type) values (1, N'quocanh1130', N'anhnqce170483@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', 'Abcd1234@'), 2), 'admin');

-- Staffs must be added before an associated Account (if exists) can be created
insert into Staff (staff_fullname) values (N'Staff Một');
insert into Staff (staff_fullname) values (N'Staff Hai');
insert into Staff (staff_fullname) values (N'Staff Ba');
-- Reset the identity seed for the Account table to 20
-- Staffs' account ID starts from 21-40
dbcc checkident (Account, RESEED, 50);
-- Insert Staff Account
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (1, N'testStaff1', N'teststaff1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '12345678'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (2, N'testStaff2', N'teststaff2@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '12345678'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (3, N'testStaff3', N'teststaff3@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '12345678'), 2), 'staff');

-- Insert test promotion manager account
insert into PromotionManager (pro_fullname) values (N'Promotion Manager Một');

-- Promotion managers' account ID starts from 41-50
dbcc checkident (Account, RESEED, 100);
-- Insert Promotion Manager Account
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (1, N'testPromotion1', N'testPromotion1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');

-- Promotion managers' account ID starts from 41-50
-- Customer must be added before an associated Account (if exists) can be created
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) 
values (N'Quốc Anh', N'Nguyễn', N'Nam', '0914875606', N'Đường sô 3, Khu Vực Bình thường B, Bình Thủy, Cần Thơ');

dbcc checkident (Account, RESEED, 120);
-- Insert Customer Account
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (1, N'quocanh123', N'anhnq1130@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');

-- Insert Powder seed milk Types
insert into FoodType (food_type) values (N'Tăng cân');
insert into FoodType (food_type) values (N'Giảm cân');
insert into FoodType (food_type) values (N'Hương vị');
insert into FoodType (food_type) values (N'Combo');

-- Ensure food_id starts from 1
dbcc checkident (Food, RESEED, 0);

-- Traditional Seed Powder Milk
insert into Food (food_type_id, food_name, food_description, food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (1, N'Bột sữa hạt mix 6 loại hạt hỗ trợ Tăng cân', 
N'Bột sữa hạt truyền thống là sự kết hợp cân bằng của các loại hạt như đậu xanh, đậu đỏ và gạo. Sản phẩm cung cấp nguồn dinh dưỡng dồi dào, giúp bổ sung năng lượng và hỗ trợ tăng cân tự nhiên. Phù hợp cho bữa sáng lành mạnh và dễ tiêu hóa.', 
300000, 30, 1, 5, 0, 'https://i.postimg.cc/MKkNqKLW/bo-t-be-o.png');

-- Maca Seed Powder Milk
insert into Food (food_type_id, food_name, food_description, food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (2, N'Bột sữa hạt mix 6 loại hạt hỗ trợ Giảm cân', 
N'Bột sữa hạt Maca là sự pha trộn giữa bột hạt Maca từ Peru và các loại hạt giàu dinh dưỡng khác. Sản phẩm giúp giảm cân an toàn và hiệu quả, đồng thời cung cấp năng lượng cho cơ thể, giúp tăng cường sức khỏe và khả năng tập trung.', 
320000, 40, 1, 5, 0, 'https://i.postimg.cc/WpqCBJXW/bth.png');

-- Walnut Seed Powder Milk
insert into Food (food_type_id, food_name, food_description, food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
values (3, N'Bột sữa hạt mix 6 loại hạt hương vị Cacao', 
N'Bột sữa hạt óc chó hương vị cacao giàu omega-3, giúp tăng cường sức khỏe tim mạch và mang lại hương vị thơm ngon, đậm đà. Đây là lựa chọn lý tưởng cho những ai đang theo đuổi chế độ ăn uống lành mạnh và cân bằng.', 
370000, 50, 1, 5, 0, 'https://i.postimg.cc/J4bgnCwj/cacao.png');

-- Combo 1
insert into Food (food_type_id, food_name, food_description, food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
values (4, N'Combo 1 (loại 1+loại 3)', 
N'Combo 1 là sự kết hợp hoàn hảo giữa sữa hạt mix 6 loại hạt hỗ trợ Tăng cân và sữa hạt óc chó hương vị Cacao. Sự hòa quyện giữa các loại hạt giàu dinh dưỡng và cacao mang đến hương vị tuyệt vời và nguồn năng lượng dồi dào cho cơ thể.', 
650000, 30, 1, 5, 0, 'https://i.postimg.cc/zG8QH256/box.png');

-- Combo 2
insert into Food (food_type_id, food_name, food_description, food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
values (4, N'Combo 2 (loại 2+loại 3)', 
N'Combo 2 kết hợp sữa hạt mix 6 loại hạt hỗ trợ Giảm cân và sữa hạt óc chó hương vị Cacao. Sự kết hợp này không chỉ giúp hỗ trợ giảm cân mà còn cung cấp dinh dưỡng tối ưu từ các loại hạt và cacao thơm ngon.', 
670000, 40, 1, 5, 0, 'https://i.postimg.cc/7hzR0p58/boxslogan.png');


-- Payment methods
-- insert into PaymentMethod (payment_method) values (N'Thẻ tín dụng');
-- insert into PaymentMethod (payment_method) values (N'Thẻ ghi nợ');
insert into PaymentMethod (payment_method) values (N'COD');

-- Order statuses
insert into OrderStatus (order_status) values (N'Chờ xác nhận');
insert into OrderStatus (order_status) values (N'Đang giao');
insert into OrderStatus (order_status) values (N'Đã giao');
insert into OrderStatus (order_status) values (N'Đã hủy');

-- Voucher
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng Đồng', 'ADJAUEJFHD234N8J', 5, 200, 1,'20240201 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng Bạc', 'JKDS8A9FNJ8L1O9K', 10, 200, 1,'20240301 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng Vàng', 'HKADU2BS812FD4SG', 15, 200, 1,'20240401 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng Bạch Kim', '9SJDNRH789HK9HN6', 20, 200, 1,'20240501 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Quốc tế phụ nữ', 'ADASD2FD23123DBE', 30, 15, 1,'20241021 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng may mắn', 'BD2128BDYOQM87V7', 20, 10, 1,'20240809 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Halloween cùng Healthy Plus', 'XDEF39O9YOQM8PPV', 15, 20, 1,'20241101 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Người đặc biệt', 'DJWOA975N4B92BH6', 50, 3, 1,'20241112 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Ngày Nhà giáo Việt Nam', '9JADYEDYOQM8E7OA', 15, 10, 0,'20241121 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values (N'Quà tặng Noel', 'DUEMAHWOPUNH62GH', 20, 10, 1,'20241223 00:01:00 AM' );

insert into Payment (
    order_id, payment_method_id, payment_total, payment_content, payment_bank, payment_code, payment_status, payment_time
) values (
    1,1,190000,N'Thanh toán đơn hàng ffood',N'NCB','14111641',1,'20240708 11:20:00 AM'
);

update Account set lastime_order = '20240708 10:34:00 AM' where account_id = 201

-- Cart, CartItem, Order test data
insert into Cart (customer_id) values (1);

insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 1, 600000, 2);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 2, 1100000, 3);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 3, 650000, 1);

insert into [Order] (
cart_id, customer_id ,order_status_id, payment_method_id,
contact_phone, delivery_address, order_time, order_total, 
order_note, delivery_time, order_cancel_time
) values (
1, 1, 3, 1, 
'0931278397', N'39 Mậu Thân, Ninh Kiều, Cần Thơ', '20240708 15:43:00 PM', 2350000, 
NULL, '20240708 15:43:00 PM', NULL);

update Account set lastime_order = '20240708 15:43:00 PM' where account_id = 205

insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 1, N'Cập nhật trạng thái đơn hàng','20240708 15:50:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 2, N'Cập nhật trạng thái đơn hàng','20240708 16:05:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 3, N'Cập nhật trạng thái đơn hàng','20240708 16:20:00 PM');

-- Point test data
insert into Point (customer_id, [point]) values (1, 55);