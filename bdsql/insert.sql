use bd_appbotica;

INSERT INTO medicamento (descripcion, pre_cos, pre_ven, observacion, stock) VALUES
('Paracetamol 500 mg - tabletas',    0.50,  1.00, 'Analgésico / antipirético',              150),
('Ibuprofeno 400 mg - tabletas',     0.60,  1.20, 'Antiinflamatorio no esteroideo',         120),
('Amoxicilina 500 mg - cápsulas',    1.50,  3.00, 'Antibiótico betalactámico',               80),
('Omeprazol 20 mg - cápsulas',       0.80,  1.80, 'Inhibidor bomba de protones',             60),
('Metronidazol 500 mg - tabletas',   1.00,  2.50, 'Antiprotozoario/antibacteriano anaerobio',70),
('Loratadina 10 mg - tabletas',      0.40,  1.00, 'Antihistamínico (alergias)',             200),
('Cetirizina 10 mg - tabletas',      0.35,  0.90, 'Antihistamínico (alergias)',             180),
('Salbutamol inhalador 100 mcg',     3.00,  6.50, 'Broncodilatador (respiratorio)',          40),
('Insulina humana 10 mL (U-100)',   10.00, 20.00, 'Inyectable, uso subcutáneo',              25),
('Vitamina C 500 mg - tabletas',     0.20,  0.60, 'Suplemento vitamínico',                  300),
('Enalapril 10 mg - tabletas',       0.30,  0.80, 'Antihipertensivo (IECA)',                 90),
('Diazepam 5 mg - tabletas',         0.25,  0.70, 'Ansiolítico - requiere receta',           50);

INSERT INTO laboratorio (ruc_lab, razon_social, direccion, telefono, email) VALUES
('20123456789', 'Laboratorios San Jose', 'Av. Los Olivos 123, Lima', '987654321', 'contacto@labsanjose.com'),
('20456789123', 'Farmaceutica Andina', 'Jr. Progreso 456, Cusco', '912345678', 'info@farmandina.com'),
('20678912345', 'Botica Central', 'Av. Grau 789, Arequipa', '934567890', 'ventas@boticacentral.com'),
('20891234567', 'Medic Pharma', 'Calle Union 321, Trujillo', '956789012', 'soporte@medicpharma.com'),
('20987654321', 'Farmacorp', 'Av. La Marina 654, Piura', '978901234', 'farmacorp@correo.com');
