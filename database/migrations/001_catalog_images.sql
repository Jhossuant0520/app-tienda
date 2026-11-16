-- =============================================================================
-- MIGRACIÓN: 001_catalog_images.sql
-- =============================================================================
--
-- Objetivo:
--   1) Agregar image_url a categories (VARCHAR(500) NULL)
--   2) Ampliar products.image_url a VARCHAR(500) NULL
--   3) Asignar imágenes representativas (Unsplash, HTTPS) a categorías y productos
--
-- Base de datos: ecommerceflutter
-- Compatible con: MySQL 8.x (INFORMATION_SCHEMA + prepared statements)
-- Idempotente: se puede ejecutar más de una vez sin duplicar columnas ni filas
--
-- IMPORTANTE:
--   - NO borra tablas ni registros
--   - NO cambia IDs ni relaciones
--   - Ejecutar manualmente en MySQL Workbench cuando se autorice
--
-- Fuente de imágenes: Unsplash (https://unsplash.com) — licencia Unsplash
-- Parámetros CDN: auto=format&fit=crop&w=600&h=600&q=80 (tarjeta cuadrada)
--
-- IDs verificados previamente vía API GET /api/categories y /api/products
-- (Prompt 0 / línea base). Los UPDATE también filtran por name por seguridad.
--
-- =============================================================================

USE ecommerceflutter;

-- ─── 1. ESTRUCTURA: categories.image_url ─────────────────────────────────────
-- Agrega la columna solo si aún no existe (evita error al re-ejecutar)

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'categories'
    AND COLUMN_NAME = 'image_url'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE categories ADD COLUMN image_url VARCHAR(500) NULL COMMENT ''URL HTTPS de la imagen de categoría''',
  'SELECT ''categories.image_url ya existe — sin cambios estructurales'' AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ─── 2. ESTRUCTURA: products.image_url → VARCHAR(500) ────────────────────────
-- MODIFY es seguro de re-ejecutar; conserva NULL y no altera otras columnas

ALTER TABLE products
  MODIFY COLUMN image_url VARCHAR(500) NULL COMMENT 'URL HTTPS de la imagen del producto';

-- ─── 3. DATOS: categorías (ids 1–4 según seed / API) ─────────────────────────
-- Electrónica (id=1)
UPDATE categories
SET image_url = 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 1 AND name = 'Electrónica';
-- Fuente: Unsplash photo-1498049794561-7780e7231661 (gadgets: laptop, auriculares, teléfono)

-- Ropa (id=2)
UPDATE categories
SET image_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 2 AND name = 'Ropa';
-- Fuente: Unsplash photo-1441986300917-64674bd600d8 (boutique / prendas)

-- Hogar (id=3)
UPDATE categories
SET image_url = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 3 AND name = 'Hogar';
-- Fuente: Unsplash photo-1586023492125-27b2c045efd7 (interior / living)

-- Deportes (id=4)
UPDATE categories
SET image_url = 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 4 AND name = 'Deportes';
-- Fuente: Unsplash photo-1552674605-db6ffd4facb5 (atletas en carrera)

-- ─── 4. DATOS: productos (ids 1–10 según seed / API) ─────────────────────────

-- 1 Auriculares Bluetooth (Electrónica)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 1 AND name = 'Auriculares Bluetooth';
-- Fuente: Unsplash photo-1505740420928-5e560c06d30e (auriculares over-ear)

-- 2 Smartwatch (Electrónica)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 2 AND name = 'Smartwatch';
-- Fuente: Unsplash photo-1434493789847-2f02dc6ca35d (smartwatch en muñeca)

-- 3 Camiseta Básica (Ropa)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 3 AND name = 'Camiseta Básica';
-- Fuente: Unsplash photo-1521572163474-6864f9cf17ab (camiseta blanca básica)

-- 4 Jeans Clásicos (Ropa)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1475178626620-a4d074967452?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 4 AND name = 'Jeans Clásicos';
-- Fuente: Unsplash photo-1475178626620-a4d074967452 (jeans denim)

-- 5 Lámpara LED (Hogar)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 5 AND name = 'Lámpara LED';
-- Fuente: Unsplash photo-1507473885765-e6ed057f782c (lámpara moderna)

-- 6 Set de Sábanas (Hogar)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 6 AND name = 'Set de Sábanas';
-- Fuente: Unsplash photo-1631049307264-da0ec9d70304 (cama con sábanas blancas)

-- 7 Balón de Fútbol (Deportes)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 7 AND name = 'Balón de Fútbol';
-- Fuente: Unsplash photo-1574629810360-7efbbe195018 (balón de fútbol en césped)

-- 8 Mancuernas 5kg (Deportes)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1576678927484-cc907957088c?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 8 AND name = 'Mancuernas 5kg';
-- Fuente: Unsplash photo-1576678927484-cc907957088c (mancuernas en rack)

-- 9 Tablet 10" (Electrónica)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 9 AND name = 'Tablet 10"';
-- Fuente: Unsplash photo-1544244015-0df4b3ffc6b0 (tablet)

-- 10 Chaqueta Deportiva (Ropa)
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=600&h=600&q=80'
WHERE id = 10 AND name = 'Chaqueta Deportiva';
-- Fuente: Unsplash photo-1591047139829-d91aecb6caea (chaqueta tipo bomber / deportiva)

-- =============================================================================
-- CONSULTAS DE VERIFICACIÓN (ejecutar después de la migración)
-- =============================================================================
--
-- SELECT id, name, image_url FROM categories ORDER BY id;
-- SELECT id, name, image_url, category_id FROM products ORDER BY id;
--
-- SELECT COUNT(*) AS categorias_sin_imagen
-- FROM categories WHERE image_url IS NULL OR image_url = '';
--
-- SELECT COUNT(*) AS productos_con_picsum
-- FROM products WHERE image_url LIKE '%picsum.photos%';
--
-- SHOW COLUMNS FROM categories LIKE 'image_url';
-- SHOW COLUMNS FROM products LIKE 'image_url';
-- =============================================================================
