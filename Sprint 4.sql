-- NIVEL 1
-- Descarga los archivos CSV, estudiales y diseña una base de datos con un esquema de 
-- estrella que contenga, al menos 4 tablas de las que puedas realizar las siguientes 
-- consultas:

-- Creamos la base de datos
CREATE DATABASE IF NOT EXISTS transacciones;

-- Creamos la tabla products
USE transacciones;
CREATE TABLE IF NOT EXISTS products (
	id VARCHAR(20) PRIMARY KEY,
	product_name VARCHAR(100),
	price VARCHAR(20),
	colour VARCHAR(20),
	weight VARCHAR(20),
	warehouse_id VARCHAR(20)
);


-- Creamos la tabla companies
CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(20) PRIMARY KEY,
	company_name VARCHAR(100),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(100) NULL
);

-- creamos la tabla users, las cuales unificaremos en una sola tabla
CREATE TABLE IF NOT EXISTS users (
	id VARCHAR(100) PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(30),
	email VARCHAR(100),
	birth_date VARCHAR(15),
	country VARCHAR(100),
	city VARCHAR(100),
	postal_code VARCHAR(15),
	address VARCHAR(150)
);

-- creamos la tabla credit_card
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(20) PRIMARY KEY,
	user_id VARCHAR(100),
	iban VARCHAR(50) NULL,
	pan VARCHAR(50),
	pin VARCHAR(4),
	cvv VARCHAR(4),
	track1 VARCHAR(100) NULL,
	track2 VARCHAR(100) NULL,
	expiring_date VARCHAR(14)
);


-- Creamos la tabla transactions
CREATE TABLE IF NOT EXISTS transactions(
	id VARCHAR(100) PRIMARY KEY,
    card_id VARCHAR(20),
    business_id VARCHAR(20),
    timestamp VARCHAR(20),
    amount DECIMAL(10, 2),
    declined BOOLEAN,
    product_ids VARCHAR(20),
    user_id VARCHAR(100) REFERENCES user(id),
    lat VARCHAR(100),
    longitude VARCHAR(100),
    CONSTRAINT fk_credit_card FOREIGN KEY (card_id) REFERENCES credit_card(id),
    CONSTRAINT fk_company FOREIGN KEY (business_id) REFERENCES companies(company_id),
    CONSTRAINT fk_users FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 👀 He obviado las conexiones con la tabla products ya que posteriormente 
-- trabajaremos con ello y ademas me genera un error

-- Cargamos los datos
SET SQL_SAFE_UPDATES = 0;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\users_uk.csv" INTO TABLE users
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;
  
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\users_usa.csv" INTO TABLE users
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\users_ca.csv"INTO TABLE users
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\companies.csv" INTO TABLE companies
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\credit_cards.csv" INTO TABLE credit_card
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  IGNORE 1 LINES;
  
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\products.csv" INTO TABLE products
  FIELDS TERMINATED BY ','
  IGNORE 1 LINES;
  
-- quitamos el signo de $

UPDATE products SET price=REPLACE(price,'$','');
ALTER TABLE products 
MODIFY COLUMN price DECIMAL(9,2),
MODIFY COLUMN weight DECIMAL(4,2);
  
  -- A diferencia de las demás, la tabla de transactions está separada por punto y coma y no por coma
  
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\transactions.csv" INTO TABLE transactions
  FIELDS TERMINATED BY ';'
  IGNORE 1 LINES; 
  
-- Ahora cambiamos los datos del timestamp que era VARCHAR
ALTER TABLE transactions CHANGE timestamp timestamp TIMESTAMP;

-- EJERCICIO 1:
-- Realiza una subconsulta que muestre a todos los usuarios con más de 30 transacciones 
-- utilizando al menos 2 tablas:

SELECT *
FROM users
WHERE users.id IN (SELECT t.user_id
				  FROM transactions t
                  GROUP BY t.user_id
                  HAVING COUNT(t.id) > 30);
                  

-- EJERCICIO 2:
-- Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., 
-- utiliza por lo menos 2 tablas

SELECT com.company_name, cc.iban, t.card_id, ROUND(AVG(t.amount),2) AS Monto
FROM credit_card cc
JOIN transactions t
ON t.card_id = cc.id
JOIN companies com
ON t.business_id = com.company_id
WHERE com.company_name = 'Donec Ltd' and t.declined = 0
GROUP BY t.card_id;

-- NIVEL 2:
-- Ejercicio 1:
-- Crea una nueva tabla que refleje el estado de las tarjetas de crédito basado en si 
-- las últimas tres transacciones fueron declinadas y genera la siguiente consulta:

CREATE TABLE cc_status(
	card_id VARCHAR(20),
	estado VARCHAR(20)
);

INSERT INTO cc_status(card_id, estado)
SELECT card_id, 
	CASE 
		WHEN SUM(declined) >= 3 THEN 'INACTIVA'
		ELSE 'ACTIVA'
	END AS estado
FROM (SELECT cc.id AS card_id, t.declined, 
	  ROW_NUMBER() OVER (PARTITION BY cc.id, t.declined 
      ORDER BY timestamp DESC) AS NumTipo
	  FROM transactions t
      JOIN credit_card cc
	  ON t.card_id = cc.id) AS conteo
WHERE NumTipo <= 3
GROUP BY card_id;

ALTER TABLE cc_status 
ADD UNIQUE (card_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_card_id
FOREIGN KEY (card_id) REFERENCES cc_status(card_id);

SELECT *
FROM cc_status;

-- veo que todas las tarjetas me dan "ACTIVA", por lo cual paso a comprobar
-- primero mediante una consulta de la tabla transactions, contado cantidad de registros por card_id donde declined = 1 (operación declinada) sea igual o mayor a 3
SELECT card_id, COUNT(*)
FROM transactions
WHERE (declined = 1) >= 3
GROUP BY card_id;

-- verificamos que ninguna tarjeta tiene 3 o más transacciones declinadas.
-- sigo comprobando, pero ahora consultamos todas las tarjetas que tienen al menos una transacción = 1
SELECT card_id, COUNT(*)
FROM transactions
WHERE declined = 1
GROUP BY card_id;

-- Ejercicio 1:
-- ¿Cuántas tarjetas están activas?
SELECT COUNT(card_id)
FROM cc_status
WHERE estado = 'Activa';

-- NIVEL 3:
-- Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con 
-- la base de datos creada, teniendo en cuenta que desde transaction tienes product_ids. 

-- Creamos la tabla
CREATE TABLE tabla_conexion (
id VARCHAR(100),
product_ids VARCHAR(20)
);


-- Insertamos los datos a la tabla de conexion desde la tabla temporal
INSERT INTO tabla_conexion (id, product_ids) 
SELECT id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.product_ids, ',', numpartes.n), ',', -1)) 
FROM transactions t
JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) AS numpartes
ON CHAR_LENGTH(t.product_ids) - CHAR_LENGTH(REPLACE(t.product_ids, ',', '')) >= numpartes.n - 1;


-- Agregamos la pk y las fk
ALTER TABLE tabla_conexion
ADD PRIMARY KEY (id, product_ids),
ADD FOREIGN KEY (id) REFERENCES transactions(id),
ADD FOREIGN KEY (product_ids) REFERENCES products(id);
SET SQL_SAFE_UPDATES = 1;


-- Genera la siguiente consulta:
-- Ejercicio 1: 
-- Necesitamos conocer el número de veces que se ha vendido cada producto.
SELECT p.id, p.product_name, count(tc.id) AS CantidadVentas
FROM products p 
LEFT JOIN tabla_conexion tc
ON p.id = tc.product_ids
GROUP BY p.id
ORDER BY CantidadVentas DESC;