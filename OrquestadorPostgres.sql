

CREATE TABLE cliente (
    cliId SERIAL PRIMARY KEY,
    cliNombre VARCHAR(255) NOT NULL,
    cliEmail VARCHAR(255)
);

INSERT INTO cliente (cliNombre, cliEmail) VALUES
('John Doe', 'john.doe@example.com'),
('Jane Smith', 'jane.smith@example.com'),
('Bob Johnson', 'bob.johnson@example.com'),
('Alice Williams', 'alice.williams@example.com'),
('Michael Brown', 'michael.brown@example.com'),
('Emily Davis', 'emily.davis@example.com'),
('David Wilson', 'david.wilson@example.com'),
('Sophia Martinez', 'sophia.martinez@example.com'),
('James Anderson', 'james.anderson@example.com'),
('Isabella Thomas', 'isabella.thomas@example.com');


CREATE TABLE producto (
    proId SERIAL PRIMARY KEY,
    proNombre VARCHAR(255) NOT NULL,
    proPrecio DECIMAL(18, 2) NOT NULL,  
    proStock INT NOT NULL  
);

INSERT INTO producto (proNombre, proPrecio, proStock) VALUES
('Producto A', 10.50, 100),
('Producto B', 20.75, 200),
('Producto C', 15.00, 150),
('Producto D', 30.25, 120),
('Producto E', 25.10, 130),
('Producto F', 40.50, 110),
('Producto G', 35.75, 140),
('Producto H', 50.00, 90),
('Producto I', 45.25, 80),
('Producto J', 60.10, 70);

CREATE TABLE factura (
    facId SERIAL PRIMARY KEY,
    facClienteId INT NOT NULL,
    facFecha TIMESTAMP NOT NULL,
    facEstado VARCHAR(30) NOT NULL,
    FOREIGN KEY (facClienteId) REFERENCES cliente(cliId),
    CHECK (facEstado IN (
        'EMITIDA',
        'ENVIADA',
        'RECIBIDA',
        'PENDIENTE_DE_PAGO',
        'PAGADA_PARCIALMENTE',
        'PAGADA',
        'VENCIDA',
        'CANCELADA',
        'EN_DISPUTA',
        'DEVUELTA',
        'ARCHIVADA'
    ))
);

CREATE TABLE detalleFactura (
    dtfId SERIAL PRIMARY KEY,
    dtfFacturaId INT NOT NULL,
    dtfProductoId INT NOT NULL,
    dtfCantidad INT NOT NULL,
    dtfTotal DECIMAL(18, 2) NOT NULL,  
    FOREIGN KEY (dtfFacturaId) REFERENCES factura(facId),
    FOREIGN KEY (dtfProductoId) REFERENCES producto(proId)
);
