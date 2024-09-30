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
	food_type		nvarchar(20) not null
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
	voucher_quantity		tinyint not null,
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
insert into [Admin] (admin_fullname) values (N'Nguyễn Vũ Như Huỳnh');
insert into [Admin] (admin_fullname) values (N'Nguyễn Hoàng Khang');
insert into [Admin] (admin_fullname) values (N'Huỳnh Khắc Huy');
insert into [Admin] (admin_fullname) values (N'Hứa Tiến Thành');
insert into [Admin] (admin_fullname) values (N'Nguyễn Quốc Anh');
insert into [Admin] (admin_fullname) values (N'Huỳnh Duy Khang');

-- Insert Account records for Admins
-- Admin passwords are 'admin#' where # ranges from 1 to 6
-- Hash the passwords using MD5 algorithm
-- Admin passwords = 123456
-- Admin account ID starts from 1-20

INSERT INTO Account (admin_id, account_username, account_email, account_password, account_type) VALUES (1, N'vuhuynh123', N'huynhnvnce170550@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (2, N'hoangkhang123', N'khangnhce171197@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (3, N'khachuy123', N'huyhkce171229@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (4, N'tienthanh123', N'thanhhtce171454@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (5, N'quocanh1130', N'anhnqce170483@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');
insert into Account (admin_id, account_username, account_email, account_password, account_type) values (6, N'duykhang123', N'khanghdse172647@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'admin');

-- Staffs must be added before an associated Account (if exists) can be created
insert into Staff (staff_fullname) values (N'Test Staff Một');
insert into Staff (staff_fullname) values (N'Test Staff Hai');
insert into Staff (staff_fullname) values (N'Test Staff Ba');
insert into Staff (staff_fullname) values (N'Test Staff Bốn');
insert into Staff (staff_fullname) values (N'Test Staff Năm');
insert into Staff (staff_fullname) values (N'Test Staff Sáu');
-- Reset the identity seed for the Account table to 20
-- Staffs' account ID starts from 21-40
dbcc checkident (Account, RESEED, 50);
-- Insert Staff Account
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (1, N'testStaff1', N'teststaff1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (2, N'testStaff2', N'teststaff2@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (3, N'testStaff3', N'teststaff3@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (4, N'testStaff4', N'teststaff4@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (5, N'testStaff5', N'teststaff5@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');
insert into Account(staff_id, account_username, account_email, account_password, account_type) values (6, N'testStaff6', N'teststaff6@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'staff');

-- Insert test promotion manager account
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Một');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Hai');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Ba');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Bốn');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Năm');
insert into PromotionManager (pro_fullname) values (N'Test Promotion Manager Sáu');
-- Promotion managers' account ID starts from 41-50
dbcc checkident (Account, RESEED, 100);
-- Insert Promotion Manager Account
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (1, N'testPromotion1', N'testPromotion1@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (2, N'testPromotion2', N'testPromotion2@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (3, N'testPromotion3', N'testPromotion3@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (4, N'testPromotion4', N'testPromotion4@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (5, N'testPromotion5', N'testPromotion5@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');
insert into Account(pro_id, account_username, account_email, account_password, account_type) values (6, N'testPromotion6', N'testPromotion6@fpt.edu.vn', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'promotionManager');


-- Customer must be added before an associated Account (if exists) can be created
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Quốc Anh', N'Nguyễn', N'Nam', '0914875606', N'Đường sô 3, Khu Vực Bình thường B, Bình Thủy, Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Khắc Huy', N'Huỳnh', N'Nam', '0375270803', N'132/24D, đường 3-2, Ninh Kiều Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Vũ Như Huỳnh', N'Nguyễn', N'Nữ', '0896621155', N'34, B25, Kdc 91B, An Khánh, Ninh Kiều');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Tiến Thành', N'Hứa', N'Nam', '0912371282', N'39 Mậu Thân, Xuân Khánh, Ninh Kiều, Cần Thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Hoàng Khang', N'Nguyễn', N'Nam', '0387133745', N'110/22/21 Trần Hưng Đạo, Bình Thỷ, Cần thơ');
insert into Customer (customer_firstname, customer_lastname, customer_gender, customer_phone, customer_address) values (N'Duy Khang', N'Huỳnh', N'Nam', '0913992409', N'138/29/21 Trần Hưng Đạo, Ninh Kiều, Cần thơ');
dbcc checkident (Account, RESEED, 200);
-- Insert Customer Account
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (1, N'quocanh123', N'anhnq1130@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (2, N'hkhachuy', N'hkhachuy.dev@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (3, N'rainyvuwritter', N'rainyvuwritter@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (4, N'huatienthanh2003', N'huatienthanh2003@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (5, N'khangnguyen', N'khgammingcraft@gmail.com', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');
insert into Account (customer_id, account_username, account_email, account_password, account_type) values (6, N'hdkhang2112', N'hdkhang2112@gmail.com ', CONVERT(NVARCHAR(32), HashBytes('MD5', '123456'), 2), 'user');

-- Insert Powder seed milk Types
insert into FoodType (food_type) values (N'Truyền thống');
insert into FoodType (food_type) values (N'Hạt Maca');
insert into FoodType (food_type) values (N'Hạt óc chó');
insert into FoodType (food_type) values (N'Hạt hạnh nhân');
insert into FoodType (food_type) values (N'Hạt lúa mì');
insert into FoodType (food_type) values (N'Hạt đậu phộng');
insert into FoodType (food_type) values (N'Hạt đậu đen');
insert into FoodType (food_type) values (N'Combo ăn kiêng');
insert into FoodType (food_type) values (N'Combo thể thao');

-- Ensure food_id starts from 1
dbcc checkident (Food, RESEED, 0);

-- Traditional Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (1, N'Bột sữa hạt truyền thống', N'Bột sữa hạt truyền thống là sự kết hợp của các loại đậu và ngũ cốc thông thường như đậu xanh, đậu đỏ và hạt gạo. Đây là loại sữa bột giàu dinh dưỡng, dễ tiêu hóa và phù hợp cho bữa sáng dinh dưỡng.', 40000, 30, 1, 5, 0, 'https://i.postimg.cc/xjxXtRm6/category-1-1.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (1, N'Bột sữa ngũ cốc truyền thống', N'Sữa bột ngũ cốc là sự hòa quyện giữa các loại ngũ cốc lành mạnh như gạo, đậu và mè, mang đến nguồn dinh dưỡng đầy đủ.', 42000, 35, 1, 5, 0, 'https://i.postimg.cc/zvBVqLsw/category-1-2.jpg');

-- Maca Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (2, N'Bột sữa hạt Maca', N'Bột sữa hạt Maca là sự pha trộn giữa bột hạt Maca và các loại hạt khác, mang lại nguồn dinh dưỡng quý giá từ Peru, giúp tăng cường sức khỏe và nâng cao khả năng tập trung.', 50000, 40, 1, 5, 5, 'https://i.postimg.cc/zvBVqLsw/category-1-2.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url) 
values (2, N'Bột sữa hạt Maca mật ong', N'Sữa bột hạt Maca kết hợp với mật ong tự nhiên, mang lại vị ngọt thanh và giàu dinh dưỡng, giúp phục hồi năng lượng.', 53000, 30, 1, 5, 10, 'https://i.postimg.cc/j5qjhwSV/category-2-1.png');

-- Walnut Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (3, N'Bột sữa hạt óc chó', N'Bột sữa hạt óc chó giàu axit béo omega-3, giúp tăng cường sức khỏe tim mạch và là lựa chọn tuyệt vời cho người đang theo chế độ ăn uống cân bằng.', 60000, 50, 1, 5, 10, 'https://i.postimg.cc/j5qjhwSV/category-2-1.png');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (3, N'Bột sữa hạt óc chó cacao', N'Bột sữa hạt óc chó cacao có vị béo của óc chó và hương vị thơm ngọt của cacao tự nhiên, bổ sung năng lượng nhanh chóng.', 62000, 40, 1, 5, 5, 'https://i.postimg.cc/658ySvLt/category-2-2.jpg');

-- Almond Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (4, N'Bột sữa hạnh nhân', N'Bột sữa hạt hạnh nhân giàu vitamin E, chất xơ và chất chống oxy hóa, giúp nuôi dưỡng làn da và tăng cường hệ miễn dịch.', 55000, 40, 1, 5, 0, 'https://i.postimg.cc/658ySvLt/category-2-2.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (4, N'Bột sữa hạnh nhân vanilla', N'Sữa bột hạnh nhân vanilla mang hương vị ngọt ngào, tinh tế của vanilla cùng lợi ích dinh dưỡng từ hạnh nhân.', 57000, 35, 1, 5, 5, 'https://i.postimg.cc/25DyVXpS/category-3-1.jpg');

-- Wheat Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (5, N'Bột sữa hạt lúa mì', N'Bột sữa hạt lúa mì là nguồn dinh dưỡng dồi dào cung cấp năng lượng cho cơ thể, thích hợp cho bữa ăn sáng đầy đủ chất xơ và khoáng chất.', 45000, 20, 1, 5, 0, 'https://i.postimg.cc/25DyVXpS/category-3-1.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (5, N'Bột sữa lúa mì mật ong', N'Bột sữa lúa mì kết hợp cùng mật ong tạo nên vị ngọt dịu, cung cấp năng lượng cho cả ngày dài hoạt động.', 47000, 25, 1, 5, 0, 'https://i.postimg.cc/FKVRcgmg/category-3-2.jpg');

-- Peanut Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (6, N'Bột sữa hạt đậu phộng', N'Bột sữa hạt đậu phộng là loại sữa bột giàu protein và vitamin B6, giúp hỗ trợ quá trình phát triển cơ bắp và sức khỏe tổng quát.', 50000, 35, 1, 5, 0, 'https://i.postimg.cc/FKVRcgmg/category-3-2.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (6, N'Bột sữa hạt đậu phộng socola', N'Sữa bột hạt đậu phộng kết hợp với vị socola thơm ngon, mang lại trải nghiệm mới lạ và đầy bổ dưỡng.', 52000, 30, 1, 5, 10, 'https://i.postimg.cc/dtgLKV4d/category-4-1.jpg');

-- Black Bean Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (7, N'Bột sữa hạt đậu đen', N'Bột sữa hạt đậu đen giàu chất chống oxy hóa và là nguồn cung cấp chất xơ tốt cho hệ tiêu hóa, giúp thanh lọc cơ thể.', 48000, 25, 1, 5, 0, 'https://i.postimg.cc/dtgLKV4d/category-4-1.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (7, N'Bột sữa hạt đậu đen mè đen', N'Kết hợp độc đáo giữa hạt đậu đen và mè đen, giúp cải thiện sức khỏe tổng thể và tốt cho tóc, da.', 50000, 30, 1, 5, 5, 'https://i.postimg.cc/RVJZGz40/category-4-2.jpg');

-- Diet Combo Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (8, N'Combo bột sữa hạt ăn kiêng', N'Combo bột sữa hạt ăn kiêng bao gồm sự kết hợp của nhiều loại hạt giảm cân như hạnh nhân, óc chó và hạt chia, giúp hỗ trợ giảm cân an toàn và hiệu quả.', 75000, 30, 1, 5, 15, 'https://i.postimg.cc/mZ5rQrxq/catgory-5-2.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (8, N'Combo bột sữa hạt giảm béo', N'Combo giảm béo đặc biệt được thiết kế cho người ăn kiêng với các loại hạt giàu chất xơ và ít calo.', 78000, 25, 1, 5, 10, 'https://i.postimg.cc/XqjZtTqH/category-5-3.jpg');

-- Sports Combo Seed Powder Milk
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (9, N'Combo bột sữa hạt thể thao', N'Combo bột sữa hạt thể thao được thiết kế đặc biệt để cung cấp năng lượng và protein cho các vận động viên, bao gồm các loại hạt giàu dinh dưỡng như đậu phộng, maca và hạt bí.', 80000, 20, 1, 5, 0, 'https://i.postimg.cc/mZ5rQrxq/catgory-5-2.jpg');
insert into Food (food_type_id, food_name, food_description,food_price, food_limit, food_status, food_rate, discount_percent, food_img_url)  
VALUES (9, N'Combo thể thao giàu năng lượng', N'Bổ sung nhiều protein và chất xơ từ đậu phộng, hạt chia, và các loại ngũ cốc, giúp phục hồi năng lượng nhanh chóng.', 83000, 20, 1, 5, 10, 'https://i.postimg.cc/rFZt2QgS/category-5-4.jpg');

-- Payment methods
insert into PaymentMethod (payment_method) values (N'Thẻ tín dụng');
insert into PaymentMethod (payment_method) values (N'Thẻ ghi nợ');
insert into PaymentMethod (payment_method) values (N'COD');

-- Order statuses
insert into OrderStatus (order_status) values (N'Chờ xác nhận');
insert into OrderStatus (order_status) values (N'Đang giao');
insert into OrderStatus (order_status) values (N'Đã giao');
insert into OrderStatus (order_status) values (N'Đã hủy');

-- Voucher
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Quốc tế phụ nữ', 'ADASD2FD23123DBE', 30, 15, 0,'20231021 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Khách hàng may mắn', 'BD2128BDYOQM87V7', 20, 10, 0,'20230809 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Halloween cùng Healthy Plus', 'XDEF39O9YOQM8PPV', 15, 20, 0,'20231101 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Người đặc biệt', 'DJWOA975N4B92BH6', 50, 3, 1,'20231112 00:01:00 AM' );
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values ( N'Ngày Nhà giáo Việt Nam', '9JADYEDYOQM8E7OA', 15, 10, 0,'20231121 00:01:00 AM');
insert into Voucher (voucher_name, voucher_code, voucher_discount_percent, voucher_quantity, voucher_status, voucher_date) values (N'Quà tặng Noel', 'DUEMAHWOPUNH62GH', 20, 10, 1,'20231223 00:01:00 AM' );

-- Cart, CartItem, Order test data
insert into Cart (customer_id) values (1);

insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 2, 50000, 2);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 2, 30000, 1);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (1, 2, 20000, 3);

-- Insert an Order for the Cart
insert into [Order] (
cart_id, customer_id ,order_status_id, payment_method_id,
contact_phone, delivery_address, order_time, order_total, 
order_note, delivery_time, order_cancel_time
) values (
1, 1, 4, 1, 
'0931278397', N'39 Mậu Thân, Ninh Kiều, Cần Thơ', '20240708 10:49:00 AM', 190000, 
NULL, '20240708 10:49:00 AM', NULL);

insert into Payment (
    order_id, payment_method_id, payment_total, payment_content, payment_bank, payment_code, payment_status, payment_time
) values (
    1,1,190000,N'Thanh toán đơn hàng ffood',N'NCB','14111641',1,'20240708 11:20:00 AM'
);

update Account set lastime_order = '20240708 10:34:00 AM' where account_id = 201

insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 1, N'Cập nhật thông tin đơn hàngg','20240708 10:51:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 1, N'Cập nhật trạng thái đơn hàng','20240708 11:03:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 2, N'Cập nhật trạng thái đơn hàng','20240708 11:18:00 AM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (1, 3, N'Cập nhật trạng thái đơn hàng','20240708 11:20:00 AM');

-- Cart, CartItem, Order test data
insert into Cart (customer_id) values (2);

insert into CartItem (cart_id, food_id, food_price, food_quantity) values (2, 1, 40000, 2);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (2, 2, 25000, 3);
insert into CartItem (cart_id, food_id, food_price, food_quantity) values (2, 1, 20000, 3);

-- Insert an Order for the Cart
insert into [Order] (
cart_id, customer_id ,order_status_id, payment_method_id,
contact_phone, delivery_address, order_time, order_total, 
order_note, delivery_time, order_cancel_time
) values (
2, 5, 4, 3, 
'0931278397', N'39 Mậu Thân, Ninh Kiều, Cần Thơ', '20240708 15:43:00 PM', 215000, 
NULL, '20240708 15:43:00 PM', NULL);

update Account set lastime_order = '20240708 15:43:00 PM' where account_id = 205

insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 1, N'Cập nhật trạng thái đơn hàng','20240708 15:50:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 2, N'Cập nhật trạng thái đơn hàng','20240708 16:05:00 PM');
insert into OrderLog (order_id, staff_id, log_activity, log_time) values (2, 3, N'Cập nhật trạng thái đơn hàng','20240708 16:20:00 PM');

