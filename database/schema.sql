-- =============================================================================
-- ARCHIVO: database/schema.sql
-- =============================================================================
--
-- ANALOGÍA: Es el plano de construcción del almacén de la tienda.
-- Define las "estanterías" (tablas) y pone productos de ejemplo para probar.
--
-- ¿Qué hace?
-- - Crea la base de datos ecommerceflutter
-- - Crea 4 tablas: users, categories, products, cart_items
-- - Inserta 4 categorías y 10 productos de prueba (con image_url Unsplash)
--
-- CÓMO EJECUTAR: Copia todo en MySQL Workbench y presiona el rayo ⚡
-- (Solo para instalaciones nuevas. Si la BD ya existe, usar
--  database/migrations/001_catalog_images.sql)
--
-- =============================================================================

CREATE DATABASE IF NOT EXISTS ecommerceflutter;
USE ecommerceflutter;

-- ─── TABLA: users ────────────────────────────────────────────────────────────
-- Guarda los usuarios registrados (nombre, email, contraseña encriptada)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,        -- ID único que se genera solo
  name VARCHAR(100) NOT NULL,               -- Nombre del usuario
  email VARCHAR(150) NOT NULL UNIQUE,       -- Email único (no se puede repetir)
  password VARCHAR(255) NOT NULL,           -- Contraseña encriptada (bcrypt)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Fecha de registro
);

-- ─── TABLA: categories ───────────────────────────────────────────────────────
-- Tipos de productos: Electrónica, Ropa, Hogar, Deportes
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  image_url VARCHAR(500) NULL               -- URL HTTPS de la imagen de categoría
);

-- ─── TABLA: products ─────────────────────────────────────────────────────────
-- Catálogo de productos de la tienda
CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,            -- Precio con 2 decimales
  image_url VARCHAR(500),                   -- URL HTTPS de la imagen del producto
  category_id INT NOT NULL,                 -- A qué categoría pertenece
  FOREIGN KEY (category_id) REFERENCES categories(id) -- Relación con categories
);

-- ─── TABLA: cart_items ───────────────────────────────────────────────────────
-- Carrito de cada usuario (persistencia en BD, no local)
CREATE TABLE IF NOT EXISTS cart_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,                     -- De qué usuario es el carrito
  product_id INT NOT NULL,                  -- Qué producto lleva
  quantity INT NOT NULL DEFAULT 1,          -- Cuántas unidades
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_product (user_id, product_id) -- Un usuario no repite el mismo producto
);

-- ─── DATOS INICIALES: 4 categorías (con imagen Unsplash) ─────────────────────
INSERT INTO categories (name, description, image_url) VALUES
('Electrónica', 'Dispositivos y gadgets tecnológicos', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&h=600&q=80'),
('Ropa', 'Prendas de vestir para toda ocasión', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=600&h=600&q=80'),
('Hogar', 'Artículos para el hogar', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=600&h=600&q=80'),
('Deportes', 'Equipamiento y accesorios deportivos', 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=600&h=600&q=80');

-- ─── DATOS INICIALES: 10 productos (imágenes representativas Unsplash) ────────
INSERT INTO products (name, description, price, image_url, category_id) VALUES
('Auriculares Bluetooth', 'Auriculares inalámbricos con cancelación de ruido', 49.99, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&h=600&q=80', 1),
('Smartwatch', 'Reloj inteligente con monitor de actividad', 89.99, 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?auto=format&fit=crop&w=600&h=600&q=80', 1),
('Camiseta Básica', 'Camiseta de algodón 100% en varios colores', 19.99, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&h=600&q=80', 2),
('Jeans Clásicos', 'Pantalón jeans corte recto', 39.99, 'https://images.unsplash.com/photo-1475178626620-a4d074967452?auto=format&fit=crop&w=600&h=600&q=80', 2),
('Lámpara LED', 'Lámpara de escritorio con luz regulable', 24.99, 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&h=600&q=80', 3),
('Set de Sábanas', 'Juego de sábanas de algodón tamaño queen', 34.99, 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=600&h=600&q=80', 3),
('Balón de Fútbol', 'Balón oficial tamaño 5', 29.99, 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&h=600&q=80', 4),
('Mancuernas 5kg', 'Par de mancuernas de 5 kg cada una', 44.99, 'https://images.unsplash.com/photo-1576678927484-cc907957088c?auto=format&fit=crop&w=600&h=600&q=80', 4),
('Tablet 10"', 'Tablet con pantalla de 10 pulgadas', 199.99, 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=600&h=600&q=80', 1),
('Chaqueta Deportiva', 'Chaqueta ligera para entrenamiento', 54.99, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=600&h=600&q=80', 2);

-- =============================================================================
-- GLOSARIO
-- - PRIMARY KEY: identificador único de cada fila
-- - AUTO_INCREMENT: el ID se genera automáticamente (1, 2, 3...)
-- - FOREIGN KEY: conecta dos tablas (ej: producto → categoría)
-- - ON DELETE CASCADE: si borras un usuario, se borra su carrito también
-- - INSERT: agregar filas de datos a una tabla
-- - image_url: URL externa HTTPS (Unsplash); MySQL no almacena el archivo binario
-- =============================================================================
