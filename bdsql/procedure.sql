use bd_appbotica;

DELIMITER $$
CREATE PROCEDURE sp_authenticate_user(
  IN p_usuario VARCHAR(150),
  IN p_password VARCHAR(255)
)
BEGIN
  DECLARE v_count INT DEFAULT 0;

  -- Ajusta el nombre de la tabla/columnas según tu esquema real:
  SELECT COUNT(*) INTO v_count
  FROM usuario
  WHERE usuario = p_usuario
    AND clave = p_password;

  IF v_count = 1 THEN
    -- Credenciales correctas -> devolvemos un pequeño resultado (puede incluir otros campos si quieres)
    SELECT 'Autenticación correcta' AS message;
  ELSE
    -- Credenciales inválidas -> lanzamos un error que el cliente recibirá
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario o contraseña inválidos';
  END IF;
END $$
-- DELIMITER ;
CREATE PROCEDURE bd_appbotica.sp_listarMedicamentos()
BEGIN
    SELECT * FROM medicamento;
end $$

CREATE PROCEDURE bd_appbotica.sp_listarLaboratorio()
BEGIN
  SELECT * FROM laboratorio;
END $$

CREATE PROCEDURE bd_appbotica.sp_list_compra()
BEGIN
  SELECT * FROM compra;
END $$


-- DELIMITER $$
-- Crear registros
CREATE PROCEDURE bd_appbotica.sp_create_medicamento(
  IN p_descripcion VARCHAR(255),
  IN p_pre_cos DECIMAL(12,2),
  IN p_pre_ven DECIMAL(12,2),
  IN p_observacion TEXT,
  IN p_stock INT
)
BEGIN
  DECLARE v_exists INT DEFAULT 0;

  IF p_stock < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock no puede ser negativo';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM medicamento WHERE descripcion = p_descripcion;
  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento ya existe';
  END IF;

  INSERT INTO medicamento (descripcion, pre_cos, pre_ven, observacion, stock)
  VALUES (p_descripcion, p_pre_cos, p_pre_ven, p_observacion, p_stock);

END $$
-- DELIMITER ;

CREATE PROCEDURE bd_appbotica.sp_create_laboratorio(
  IN p_ruc_lab VARCHAR(20),
  IN p_razon_social VARCHAR(255),
  IN p_direccion TEXT,
  IN p_telefono CHAR(9),
  IN p_email VARCHAR(200)
)
BEGIN
  DECLARE v_exists INT DEFAULT 0;

  IF p_ruc_lab IS NULL OR TRIM(p_ruc_lab) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUC es requerido';
  END IF;
  
  SELECT COUNT(*) INTO v_exists FROM laboratorio WHERE ruc_lab = p_ruc_lab;
  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUC ya existe';
  END IF;
  
  INSERT INTO laboratorio (ruc_lab, razon_social, direccion, telefono, email)
  VALUES (p_ruc_lab, p_razon_social, p_direccion, p_telefono, p_email);

END $$

CREATE PROCEDURE bd_appbotica.sp_create_compra(
  IN p_id_medi INT,
  IN p_ruc_lab VARCHAR(20),
  IN p_lote VARCHAR(100),
  IN p_cantidad INT
)
BEGIN
  DECLARE v_exists INT DEFAULT 0;

  -- Validaciones simples
  IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser mayor que 0';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM medicamento WHERE id_medi = p_id_medi;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento no existe';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM laboratorio WHERE ruc_lab = p_ruc_lab;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Laboratorio no existe';
  END IF;

  -- Insertar en compra; el trigger AFTER INSERT completará nombre_medi, nombre_lab y precio
  INSERT INTO compra (id_medi, ruc_lab, lote, cantidad)
  VALUES (p_id_medi, p_ruc_lab, p_lote, p_cantidad);

END $$


CREATE PROCEDURE bd_appbotica.sp_eliminarMedicamento(IN p_id_medi INT)
BEGIN
    -- Verificar si el medicamento existe
    IF EXISTS (SELECT 1 FROM medicamento WHERE id_medi = p_id_medi) THEN
        DELETE FROM medicamento
        WHERE id_medi = p_id_medi;
    ELSE
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento no existe';
    END IF;
END $$
-- DELIMITER $$
CREATE PROCEDURE bd_appbotica.sp_eliminarLaboratorio(IN p_ruclab VARCHAR(20))
BEGIN
    IF EXISTS (SELECT 1 FROM laboratorio WHERE ruc_lab = p_ruclab) THEN
        DELETE FROM laboratorio
        WHERE ruc_lab = p_ruclab;
    ELSE
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento no existe';
    END IF;
END $$


CREATE PROCEDURE bd_appbotica.sp_eliminarCompra(IN p_id_compra INT)
BEGIN
    IF EXISTS (SELECT 1 FROM compra WHERE id_compra = p_id_compra) THEN
        DELETE FROM compra
        WHERE id_compra = p_id_compra;
    ELSE
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra no existe';
    END IF;
END $$
DELIMITER ;