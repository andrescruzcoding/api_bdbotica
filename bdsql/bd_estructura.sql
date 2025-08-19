use bd_appbotica;

CREATE TABLE usuario (
  id int NOT NULL auto_increment,
  usuario VARCHAR(150) NOT NULL,
  clave VARCHAR(150) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla laboratorio (RUC como PK)
CREATE TABLE laboratorio (
  ruc_lab VARCHAR(20) NOT NULL,
  razon_social VARCHAR(255) NOT NULL,
  direccion TEXT NOT NULL,
  telefono CHAR(9) NOT NULL,
  email VARCHAR(200) NOT NULL,
  PRIMARY KEY (ruc_lab)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla medicamento
CREATE TABLE medicamento (
  id_medi INT NOT NULL auto_increment,
  descripcion VARCHAR(255) NOT NULL,
  pre_cos DECIMAL(12,2) DEFAULT NULL,
  pre_ven DECIMAL(12,2) DEFAULT NULL,
  observacion TEXT,
  stock INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id_medi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla compra
-- 'monto' definido como columna generada: cantidad * precio (STORED para poder indexar si es necesario)
CREATE TABLE compra (
  id_compra INT NOT NULL auto_increment,
  id_medi INT NOT NULL,
  ruc_lab VARCHAR(20) NOT NULL,
  nombre_medi VARCHAR(255),
  nombre_lab VARCHAR(255),
  lote INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio DECIMAL(12,2),
  fecha_compra DATE NOT NULL DEFAULT (CURDATE()),
  monto DECIMAL(14,2) AS (ROUND(cantidad * precio,2)) STORED,
  PRIMARY KEY (id_compra),
  CONSTRAINT fk_compra_medicamento FOREIGN KEY (id_medi) REFERENCES medicamento(id_medi) 
  	on delete cascade on update cascade,
  CONSTRAINT fk_compra_laboratorio FOREIGN KEY (ruc_lab) REFERENCES laboratorio(ruc_lab)
  	on delete cascade on update cascade
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trigger AFTER INSERT en compra: actualiza el stock del medicamento sumando la cantidad
DELIMITER $$

CREATE TRIGGER trg_compra_after_delete AFTER DELETE ON compra
FOR EACH ROW
BEGIN
  -- resta la cantidad del stock cuando se elimina una compra
  UPDATE medicamento
  SET stock = GREATEST(0, stock - OLD.cantidad)
  WHERE id_medi = OLD.id_medi;
END $$


CREATE TRIGGER trg_compra_before_insert
BEFORE INSERT ON compra
FOR EACH ROW
BEGIN
  DECLARE v_desc VARCHAR(255) DEFAULT NULL;
  DECLARE v_razon VARCHAR(255) DEFAULT NULL;
  DECLARE v_preven DECIMAL(12,2) DEFAULT NULL;

  -- Obtener descripcion y precio desde medicamento (si existe)
  SELECT descripcion, pre_ven
    INTO v_desc, v_preven
  FROM medicamento
  WHERE id_medi = NEW.id_medi
  LIMIT 1;

  -- Obtener razon_social desde laboratorio (si existe)
  SELECT razon_social
    INTO v_razon
  FROM laboratorio
  WHERE ruc_lab = NEW.ruc_lab
  LIMIT 1;

  -- Asignar los valores a la fila que se va a insertar
  SET NEW.nombre_medi = v_desc;
  SET NEW.nombre_lab  = v_razon;
  SET NEW.precio      = v_preven;

  -- Actualizar stock del medicamento (tabla distinta, permitido)
  UPDATE medicamento
    SET stock = stock + NEW.cantidad
  WHERE id_medi = NEW.id_medi;

END $$

DELIMITER ;