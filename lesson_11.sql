-- Домашнее задание к уроку 10.

-- Практическое задание по теме “Оптимизация запросов”
-- 1.	Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, catalogs и products в таблицу logs помещается время и дата создания записи, название таблицы, идентификатор первичного ключа и содержимое поля name.
drop table if exists logs;
CREATE TABLE logs (
  table_name varchar(32),
  record_id INT unsigned,
  record_name VARCHAR(255),
  created_at DATETIME) ENGINE=Archive;
  
-- и создаем триггеры:
drop trigger if exists user_log_insert;
DELIMITER -
create trigger user_log_insert after insert on users
for each row BEGIN
	insert into logs values  
		('users', 
		new.id,
		new.name,
		new.created_at);
END - 
DELIMITER ;

drop trigger if exists catalog_log_insert;
DELIMITER -
create trigger catalog_log_insert after insert on catalogs
for each row BEGIN
	insert into logs values  
		('catalogs', 
		new.id,
		new.name,
		new.created_at);
END - 
DELIMITER ;

drop trigger if exists product_log_insert;
DELIMITER -
create trigger product_log_insert after insert on products
for each row BEGIN
	insert into logs values  
		('products', 
		new.id,
		new.name,
		new.created_at);
END - 
DELIMITER ;

-- 2.	(по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.
-- решение - шутка:
insert into users values (null,'миллион записей',now(),now(),now());

-- решение через процедуру:
DELIMITER -
CREATE procedure insert_into_users (in num int unsigned)
BEGIN
  DECLARE i INT unsigned DEFAULT 0;
  WHILE i < num DO 
	insert into users values (
		null,
		concat('user',' ',i),
		'1970-01-01',
		now(),
		now());
	SET i = i + 1;
  END WHILE;
END -
DELIMITER ;

call insert_into_users(1000000);



-- Практическое задание по теме “NoSQL”
-- 1.	В базе данных Redis подберите коллекцию для подсчета посещений с определенных IP-адресов.
127.0.0.1:6379> hset visits 192.168.1.1 0
(integer) 1
127.0.0.1:6379> hset visits 192.168.1.2 0
(integer) 1
127.0.0.1:6379> hset visits 192.168.1.3 0
(integer) 1
127.0.0.1:6379> hgetall visits
1) "192.168.1.1"
2) "0"
3) "192.168.1.2"
4) "0"
5) "192.168.1.3"
6) "0"
-- включим инкремент по нескольким адресам
127.0.0.1:6379> hincrby visits 192.168.1.1 1
(integer) 1
127.0.0.1:6379> hincrby visits 192.168.1.1 1
(integer) 2
127.0.0.1:6379> hincrby visits 192.168.1.3 1
(integer) 1
-- получаем результат:
127.0.0.1:6379> hgetall visits
1) "192.168.1.1"
2) "2"
3) "192.168.1.2"
4) "0"
5) "192.168.1.3"
6) "1"
127.0.0.1:6379> 

-- 2.	При помощи базы данных Redis решите задачу поиска имени пользователя по электронному адресу и наоборот, поиск электронного адреса пользователя по его имени.

-- поиск в Redis не возможен по values, 

-- Вариант 1. необходимо создавать встречные ключи, или в одну сторону строковые значения а обратно - хеш:
127.0.0.1:6379[1]> hmset users:email kylee.pouros@example.org Smith users:email aliza66@example.net Wilkinson users:email gideon37@example.org Jenkins users:email hquigley@example.org Johnson users:email fmitchell@example.com Schiller

127.0.0.1:6379[1]> keys *
1) "users:Smith"
2) "users:Jenkins"
3) "users:Wilkinson"
4) "users:Schiller"
5) "users:email"
6) "users:Johnson"
127.0.0.1:6379[1]> hmset users:email kylee.pouros@example.org Smith aliza66@example.net Wilkinson gideon37@example.org Jenkins hquigley@example.org Johnson fmitchell@example.com Schiller
-- тогда поиск по имени электронной почты:
127.0.0.1:6379[1]> get users:Jenkins
"gideon37@example.org"
-- а поиск имени по электронной почте:
127.0.0.1:6379[1]> hget users:email aliza66@example.net
"Wilkinson"

-- вариант 2. создать хеш где в качестве поля будет выступать json в котором будет и имя и email. а для поиска воспользуемся hscan
127.0.0.1:6379[2]> hmset users "{name: Isom Wintheiser, email: chanelle.stoltenberg@example.org}"  0 "{name: Cyrus Bruen, email: tillman.luettgen@example.org}"  0  "{name: Ruth Graham, email: jorge.jerde@example.org}"  0 "{name: Darrel Schiller, email: fmitchell@example.com}"  0 "{name: Kayleigh Herman, email: herminio40@example.org}"  0
OK
127.0.0.1:6379[2]> hgetall users
 1) "{name: Isom Wintheiser, email: chanelle.stoltenberg@example.org}"
 2) "0"
 3) "{name: Cyrus Bruen, email: tillman.luettgen@example.org}"
 4) "0"
 5) "{name: Ruth Graham, email: jorge.jerde@example.org}"
 6) "0"
 7) "{name: Darrel Schiller, email: fmitchell@example.com}"
 8) "0"
 9) "{name: Kayleigh Herman, email: herminio40@example.org}"
10) "0"

-- поиск по имени
127.0.0.1:6379[2]> hscan users 0 match *Herman*
1) "0"
2) 1) "{name: Kayleigh Herman, email: herminio40@example.org}"
   2) "0"
-- поиск по электронной почте:
127.0.0.1:6379[2]> hscan users 0 match *fmitchell@example.com*
1) "0"
2) 1) "{name: Darrel Schiller, email: fmitchell@example.com}"
   2) "0"
127.0.0.1:6379[2]> 


-- 3.	Организуйте хранение категорий и товарных позиций учебной базы данных shop в СУБД MongoDB.

-- Вариант 1. одноранговое хранение:
> db.shop.insert({name: "Intel Core i3-8100", description: "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", price: 7890.00, catalog: "Процессоры" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "Intel Core i5-7400", description: "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", price: 12700.00, catalog: "Процессоры" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "AMD FX-8320E", description: "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", price: 4780.00, catalog: "Процессоры" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "AMD FX-8320", description: "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", price: 7120.00, catalog: "Процессоры" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "ASUS ROG MAXIMUS X HERO", description: "Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX", price: 19310.00, catalog: "Материнские платы" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "Gigabyte H310M S2H", description: "Материнская плата Gigabyte H310M S2H, H310, Socket 1151-V2, DDR4, mATX", price: 4790.00, catalog: "Материнские платы" })
WriteResult({ "nInserted" : 1 })
> db.shop.insert({name: "MSI B250M GAMING PRO", description: "Материнская плата MSI B250M GAMING PRO, B250, Socket 1151, DDR4, mATX", price: 5060.00, catalog: "Материнские платы" })
WriteResult({ "nInserted" : 1 })
> db.shop.find()
{ "_id" : ObjectId("5e3b1dc3a63184a2321c201c"), "name" : "Intel Core i3-8100", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", "price" : 7890, "catalog" : "Процессоры" }
{ "_id" : ObjectId("5e3b1df9a63184a2321c201d"), "name" : "Intel Core i5-7400", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", "price" : 12700, "catalog" : "Процессоры" }
{ "_id" : ObjectId("5e3b1e0aa63184a2321c201e"), "name" : "AMD FX-8320E", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", "price" : 4780, "catalog" : "Процессоры" }
{ "_id" : ObjectId("5e3b1e0da63184a2321c201f"), "name" : "AMD FX-8320", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", "price" : 7120, "catalog" : "Процессоры" }
{ "_id" : ObjectId("5e3b1e1ba63184a2321c2020"), "name" : "ASUS ROG MAXIMUS X HERO", "description" : "Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX", "price" : 19310, "catalog" : "Материнские платы" }
{ "_id" : ObjectId("5e3b1e22a63184a2321c2021"), "name" : "Gigabyte H310M S2H", "description" : "Материнская плата Gigabyte H310M S2H, H310, Socket 1151-V2, DDR4, mATX", "price" : 4790, "catalog" : "Материнские платы" }
{ "_id" : ObjectId("5e3b1e2aa63184a2321c2022"), "name" : "MSI B250M GAMING PRO", "description" : "Материнская плата MSI B250M GAMING PRO, B250, Socket 1151, DDR4, mATX", "price" : 5060, "catalog" : "Материнские платы" }
> 

-- Вариант 2. Хранение в дереве:
> db.shop1.insert({ catalog: "Процессоры",
... products: [
... {name: "Intel Core i3-8100", description: "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", price: 7890.00 },
... {name: "Intel Core i5-7400", description: "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", price: 12700.00 },
... {name: "AMD FX-8320E", description: "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", price: 4780.00 },
... {name: "AMD FX-8320", description: "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", price: 7120.00 },] })
WriteResult({ "nInserted" : 1 })
> db.shop1.insert({ catalog: "Материнские платы",
... products: [
... {name: "ASUS ROG MAXIMUS X HERO", description: "Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX", price: 19310.00 },
... {name: "Gigabyte H310M S2H", description: "Материнская плата Gigabyte H310M S2H, H310, Socket 1151-V2, DDR4, mATX", price: 4790.00 },
... {name: "MSI B250M GAMING PRO", description: "Материнская плата MSI B250M GAMING PRO, B250, Socket 1151, DDR4, mATX", price: 5060.00 },] })
WriteResult({ "nInserted" : 1 })
> db.shop1.find()
{ "_id" : ObjectId("5e3b2286a63184a2321c2023"), "catalog" : "Процессоры", "products" : [ { "name" : "Intel Core i3-8100", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", "price" : 7890 }, { "name" : "Intel Core i5-7400", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе Intel.", "price" : 12700 }, { "name" : "AMD FX-8320E", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", "price" : 4780 }, { "name" : "AMD FX-8320", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе AMD.", "price" : 7120 } ] }
{ "_id" : ObjectId("5e3b23f3a63184a2321c2024"), "catalog" : "Материнские платы", "products" : [ { "name" : "ASUS ROG MAXIMUS X HERO", "description" : "Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX", "price" : 19310 }, { "name" : "Gigabyte H310M S2H", "description" : "Материнская плата Gigabyte H310M S2H, H310, Socket 1151-V2, DDR4, mATX", "price" : 4790 }, { "name" : "MSI B250M GAMING PRO", "description" : "Материнская плата MSI B250M GAMING PRO, B250, Socket 1151, DDR4, mATX", "price" : 5060 } ] }
> 
