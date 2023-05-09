-- Solución de Homework.
/*Homework
1.Crear un procedimiento que recibe como parametro una fecha y muestre el listado de productos que se vendieron en esa fecha.
2.Crear una función que calcule el valor nominal de un margen bruto determinado por el usuario a partir del precio de lista de los productos.
3.Obtner un listado de productos de IMPRESION y utilizarlo para cálcular el valor nominal de un margen bruto del 20% de cada uno de los productos.
4.Crear un procedimiento que permita listar los productos vendidos desde fact_venta a partir de un "Tipo" que determine el usuario.
5.Crear un procedimiento que permita realizar la insercción de datos en la tabla fact_venta.
6.Crear un procedimiento almacenado que reciba un grupo etario y devuelta el total de ventas para ese grupo.
7.Crear una variable que se pase como valor para realizar una filtro sobre Rango_etario en una consulta génerica a dim_cliente.
8.Utilizar la funcion provista 'UC_Words' para modificar a letra capital los campos que contengan descripciones para todas las tablas.
9.Utilizar el procedimiento provisto 'Llenar_Calendario' para poblar la tabla de calendario.

**/

use henry_m3;
-- 1) 1.Crear un procedimiento que recibe como parametro una fecha 
-- y muestre el listado de productos que se vendieron en esa fecha.

DROP PROCEDURE listaProductos;
DELIMITER $$ -- abro el delimiter
CREATE PROCEDURE listaProductos(IN fechaVenta DATE) -- creo el procedimiento dentro del delimiter, defino como parametro (o argumento) una fecha, y aclaro el dato DATE. pd:" no se si es necesasrio el IN- ver ej gonza code"
begin -- defino comienzo del procedimiento -- tablas que utilizo, venta y producto, ya que venta solo tiene id, debo hacer un join con producto para la descripcion del producto.
	Select distinct tp.TipoProducto, p.Producto 
	From fact_venta v join dim_producto p On (v.IdProducto = p.IdProducto And v.Fecha = fechaVenta) -- defino join y and condicion.
		join tipo_producto tp
			On (p.idTipoProducto = tp.IdTipoProducto)
	Order by tp.TipoProducto, p.Producto;
END $$
DELIMITER ;-- cierro el delimiter

CALL listaProductos('2020-01-01');  -- llamo al procedimientto en la fecha:.....


SET GLOBAL log_bin_trust_function_creators = 1;




-- 2)2.Crear una función que calcule el valor nominal de un margen bruto 
-- determinado por el usuario a partir del precio de lista de los productos.


DROP FUNCTION margenBruto;

DELIMITER $$
CREATE FUNCTION margenBruto(precio DECIMAL(15,3), margen DECIMAL (9,2)) RETURNS DECIMAL (15,3) -- creo funcion con parametros precio, margen,y defino el return en que formato lo quiero.
begin -- arranque:
	DECLARE margenBruto DECIMAL (15,3); -- declaro la variable
    SET margenBruto = precio * margen; -- seteale al valor de esa variable,
    RETURN margenBruto; -- retorname la variable calculada.
END$$ -- fin

DELIMITER ; -- fin delimiter

Select margenBruto(100.50, 1.2); -- salecciono la funcion, con los parametros.



-- no se bien este query pero esta inside punto 2
Select 	c.Fecha,
		pr.Nombre					as Proveedor,
		p.Producto,
		c.Precio 					as PrecioCompra,
        margenBruto(c.Precio, 1.3)	as PrecioMargen
From 	compra c Join producto p
			On (c.IdProducto = p.IdProducto)
		Join proveedor pr
			On (c.IdProveedor = pr.IdProveedor);

SELECT 	Producto, 
		margenBruto(Precio, 1.30) AS Margen
FROM producto;





-- 3) 3.Obtener un listado de productos de IMPRESION y utilizarlo para cálcular 
-- el valor nominal de un margen bruto del 20% de cada uno de los productos.

-- debo aplicar la funcion desarrollada en el punto dos al listado de productos impresion.

SELECT 	p.IdProducto, 
		p.Producto,
        p.Precio,
        margenBruto(p.Precio, 1.2) AS PrecioMargen -- aplico la funcion!
FROM producto p join tipo_producto tp -- hago join para clacificar por tipo de prod.
	On (p.IdTipoProducto = tp.IdTipoProducto
		And TipoProducto = 'Impresión');
  
	
	
SELECT 	IdProducto, 
		precio as PrecioVenta, 
        ROUND(precio * ( (100 + 10) /100 ), 2) AS PrecioFinal
FROM compra;

DELIMITER $$
CREATE PROCEDURE MargenbrutoJ(IN porcent int)
BEGIN
    /*SELECT IdProducto, precio as PrecioVenta, ROUND(precio /((100 - porcent)/100),2) AS PrecioFinal
    FROM compra;
    */
    SELECT IdProducto, precio as PrecioVenta, ROUND(precio * ( (100 + porcent) /100 ), 2) AS PrecioFinal
    FROM compra;
END $$
DELIMITER ;

CALL MargenbrutoJ(30);




-- 4)4.Crear un procedimiento que permita
-- listar los productos vendidos desde fact_venta 
-- a partir de un "Tipo" que determine el usuario.
DROP PROCEDURE listaCategoria;

DELIMITER $$
CREATE PROCEDURE listaCategoria(IN categoria VARCHAR (25)) -- tambien el colate se puede definir aqui ariba, en la entrada de la variable, seguido de un CHARSET ... colate....)
BEGIN
	SELECT 	v.Fecha,
			v.Fecha_Entrega,
			v.IdCliente,
			v.IdCanal,
			v.IdSucursal,
			tp.TipoProducto,
			p.Producto,
			v.Precio,
			v.Cantidad
	FROM venta v join producto p -- atenti, pedia tabla fact_venta no tabla venta, gonza code esta corregido.
			On (v.IdProducto = p.idProducto
				And v.Outlier = 1)
		Join tipo_producto tp
			On (p.IdTipoProducto = tp.IdTipoProducto
				And TipoProducto collate utf8mb4_spanish_ci LIKE Concat('%', categoria, '%')); -- el colate es la colacion, es el tipo de codificación a utilizar cuando le pase el VARCHAR CATEGORIA. ..el error - mix of colation...
                -- And TipoProducto = categoria);este era el AND anterior al colocar el colate
END $$			-- el like no fue necesario en el cod_GONZA.
DELIMITER ;

CALL listaCategoria('i');



-- 5)5.Crear un procedimiento que permita realizar
--  la insercción de datos en la tabla fact_venta.

DROP PROCEDURE cargarFact_venta;

DELIMITER $$
CREATE PROCEDURE cargarFact_venta()
BEGIN
	TRUNCATE table fact_venta;

    INSERT INTO fact_venta (IdVenta, Fecha, Fecha_Entrega, IdCanal, IdCliente, IdEmpleado, IdProducto, Precio, Cantidad)
    SELECT	IdVenta, Fecha, Fecha_Entrega, IdCanal, IdCliente, IdEmpleado, IdProducto, Precio, Cantidad
    FROM 	venta
    WHERE  	Outlier = 1;
END $$
DELIMITER ;

CALL cargarFact_venta();

SHOW TRIGGERS;



-- DROP TRIGGER henry_m3.fact_venta_registros;
-- 6)6.Crear un procedimiento almacenado que reciba
-- un grupo etario y devuelta el total de ventas 
-- para ese grupo.
-- ver solucion GONZAmuy buena.

SELECT 	c.Rango_Etario, 
		sum(v.Precio*v.Cantidad) 	AS Total_Ventas
FROM fact_venta v
	INNER JOIN dim_cliente c
		ON (v.IdCliente = c.IdCliente
			and c.Rango_Etario collate utf8mb4_spanish_ci = '2_De 31 a 40 años')
GROUP BY c.Rango_Etario;
    
DROP PROCEDURE ventasGrupoEtario; 

DELIMITER $$
CREATE PROCEDURE ventasGrupoEtario(IN grupo VARCHAR(25))
BEGIN
	SELECT 	c.Rango_Etario, 
			sum(v.Precio*v.Cantidad) 	AS Total_Ventas
	FROM fact_venta v
		INNER JOIN dim_cliente c
			ON (v.IdCliente = c.IdCliente
				and c.Rango_Etario collate utf8mb4_spanish_ci like Concat('%', grupo, '%'))
	GROUP BY c.Rango_Etario;
END $$
DELIMITER ;

SELECT DISTINCT Rango_Etario FROM dim_cliente;

CALL ventasGrupoEtario('31%40');

-- 7) 7.Crear una variable que se pase como valor
-- para realizar una filtro sobre Rango_etario
--  en una consulta génerica a dim_cliente.


SET @grupo = '2_De 31 a 40 años' collate utf8mb4_spanish_ci; -- setea una variable, aqui debe ser exactamente =.

SELECT *
FROM dim_cliente
WHERE Rango_Etario 
LIMIT 10;





/*Función y Procedimiento provistos*/
SET GLOBAL log_bin_trust_function_creators = 1;
DROP FUNCTION IF EXISTS `UC_Words`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `UC_Words`( str VARCHAR(255) ) RETURNS varchar(255) CHARSET utf8
BEGIN  
  DECLARE c CHAR(1);  
  DECLARE s VARCHAR(255);  
  DECLARE i INT DEFAULT 1;  
  DECLARE bool INT DEFAULT 1;  
  DECLARE punct CHAR(17) DEFAULT ' ()[]{},.-_!@;:?/';  
  SET s = LCASE( str );  
  WHILE i < LENGTH( str ) DO  
     BEGIN  
       SET c = SUBSTRING( s, i, 1 );  
       IF LOCATE( c, punct ) > 0 THEN  
        SET bool = 1;  
      ELSEIF bool=1 THEN  
        BEGIN  
          IF c >= 'a' AND c <= 'z' THEN  
             BEGIN  
               SET s = CONCAT(LEFT(s,i-1),UCASE(c),SUBSTRING(s,i+1));  
               SET bool = 0;  
             END;  
           ELSEIF c >= '0' AND c <= '9' THEN  
            SET bool = 0;  
          END IF;  
        END;  
      END IF;  
      SET i = i+1;  
    END;  
  END WHILE;  
  RETURN s;  
END$$
DELIMITER ;
DROP PROCEDURE IF EXISTS `Llenar_dimension_calendario`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Llenar_dimension_calendario`(IN `startdate` DATE, IN `stopdate` DATE)
BEGIN
    DECLARE currentdate DATE;
    SET currentdate = startdate;
    WHILE currentdate < stopdate DO
        INSERT INTO calendario VALUES (
                        YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),
                        currentdate,
                        YEAR(currentdate),
                        MONTH(currentdate),
                        DAY(currentdate),
                        QUARTER(currentdate),
                        WEEKOFYEAR(currentdate),
                        DATE_FORMAT(currentdate,'%W'),
                        DATE_FORMAT(currentdate,'%M'));
        SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

/*Se genera la dimension calendario*/
DROP TABLE IF EXISTS `calendario`;
CREATE TABLE calendario (
        id                      INTEGER PRIMARY KEY,  -- year*10000+month*100+day
        fecha                 	DATE NOT NULL,
        anio                    INTEGER NOT NULL,
        mes                   	INTEGER NOT NULL, -- 1 to 12
        dia                     INTEGER NOT NULL, -- 1 to 31
        trimestre               INTEGER NOT NULL, -- 1 to 4
        semana                  INTEGER NOT NULL, -- 1 to 52/53
        dia_nombre              VARCHAR(9) NOT NULL, -- 'Monday', 'Tuesday'...
        mes_nombre              VARCHAR(9) NOT NULL -- 'January', 'February'...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

ALTER TABLE `calendario` CHANGE `id` `IdFecha` INT(11) NOT NULL;
ALTER TABLE `calendario` ADD UNIQUE(`fecha`);

/*LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Calendario.csv' 
INTO TABLE calendario
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;*/

-- 8)
/*Normalizacion a Letra Capital*/
UPDATE cliente SET  Domicilio = UC_Words(TRIM(Domicilio)),
                    Nombre_y_Apellido = UC_Words(TRIM(Nombre_y_Apellido));
					
UPDATE sucursal SET Domicilio = UC_Words(TRIM(Domicilio)),
                    Sucursal = UC_Words(TRIM(Sucursal));
					
UPDATE proveedor SET Nombre = UC_Words(TRIM(Nombre)),
                    Domicilio = UC_Words(TRIM(Domicilio));

UPDATE producto SET Producto = UC_Words(TRIM(Producto));

UPDATE tipo_producto SET TipoProducto = UC_Words(TRIM(TipoProducto));
					
UPDATE empleado SET Nombre = UC_Words(TRIM(Nombre)),
                    Apellido = UC_Words(TRIM(Apellido));

UPDATE sector SET Sector = UC_Words(TRIM(Sector));

UPDATE cargo SET Cargo = UC_Words(TRIM(Cargo));
                    
UPDATE localidad SET Localidad = UC_Words(TRIM(Localidad));

UPDATE provincia SET Provincia = UC_Words(TRIM(Provincia));

UPDATE dim_cliente SET 	Domicilio = UC_Words(TRIM(Domicilio)),
                    Nombre_y_Apellido = UC_Words(TRIM(Nombre_y_Apellido));

UPDATE dim_producto SET Producto = UC_Words(TRIM(Producto));

-- 9)
/*TRUNCATE TABLE calendario;*/
CALL Llenar_dimension_calendario('2015-01-01','2021-01-01');
SELECT * FROM calendario;

ALTER TABLE venta ADD CONSTRAINT `venta_fk_fecha` FOREIGN KEY (fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compra ADD CONSTRAINT `compra_fk_fecha` FOREIGN KEY (Fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE gasto ADD CONSTRAINT `gasto_fk_fecha` FOREIGN KEY (Fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
