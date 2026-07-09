-- =========================================================
-- PAN LATE PYAR Stationery Shop - Database Schema
-- Import this via phpMyAdmin (XAMPP) or:
--   mysql -u root -p < stationery_shop.sql
-- =========================================================

CREATE DATABASE IF NOT EXISTS stationery_shop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE stationery_shop;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS wishlist;
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS product_variations;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(120)        NOT NULL,
    email          VARCHAR(150) UNIQUE NOT NULL,
    password_hash  VARCHAR(255)        NOT NULL,
    phone          VARCHAR(30),
    role           ENUM('customer','admin') DEFAULT 'customer',
    profile_image  VARCHAR(255),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    address_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    label          VARCHAR(50) DEFAULT 'Home',
    recipient_name VARCHAR(120),
    phone          VARCHAR(30),
    address_line   VARCHAR(255) NOT NULL,
    city           VARCHAR(100),
    state          VARCHAR(100),
    postcode       VARCHAR(20),
    is_default     BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE categories (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    slug           VARCHAR(100) UNIQUE NOT NULL,
    icon           VARCHAR(50)
);

CREATE TABLE products (
    product_id     INT AUTO_INCREMENT PRIMARY KEY,
    category_id    INT,
    name           VARCHAR(150) NOT NULL,
    description    TEXT,
    price          DECIMAL(10,2) NOT NULL,
    stock_qty      INT DEFAULT 0,
    image_url      VARCHAR(255),
    is_active      BOOLEAN DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE product_variations (
    variation_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    variation_name  VARCHAR(100) NOT NULL,
    variation_value VARCHAR(100) NOT NULL,
    price_delta     DECIMAL(10,2) DEFAULT 0,
    stock_qty       INT DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
    cart_item_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    product_id     INT NOT NULL,
    variation_id   INT,
    quantity       INT DEFAULT 1,
    added_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (variation_id) REFERENCES product_variations(variation_id)
);

CREATE TABLE wishlist (
    wishlist_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    product_id     INT NOT NULL,
    added_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    order_code      VARCHAR(24) UNIQUE NOT NULL,
    user_id         INT NOT NULL,
    delivery_method ENUM('pickup','delivery') NOT NULL,
    address_id      INT NULL,
    payment_method  ENUM('cod','card') NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    delivery_fee    DECIMAL(10,2) DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    status          ENUM('pending','processing','out_for_delivery','ready_for_pickup','completed','cancelled') DEFAULT 'pending',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
);

CREATE TABLE order_items (
    order_item_id   INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    variation_label VARCHAR(150),
    product_name    VARCHAR(150) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    quantity        INT NOT NULL,
    line_total      DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE activity_logs (
    log_id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    action         VARCHAR(255) NOT NULL,
    ip_address     VARCHAR(50),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO categories (name, slug, icon) VALUES
('Notebooks & Journals', 'notebooks', 'NB'),
('Pens & Pencils', 'pens-pencils', 'PN'),
('Art Supplies', 'art-supplies', 'AR'),
('Paper & Cards', 'paper-cards', 'PC'),
('Desk Accessories', 'desk-accessories', 'DA'),
('Washi Tape & Stickers', 'washi-stickers', 'WS');

INSERT INTO products (category_id, name, description, price, stock_qty, image_url) VALUES
(1, 'Kraft Cover Dot Journal', 'Dot-grid pages under a soft kraft cover. 160 pages of 100gsm paper.', 28900.00, 34, 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=700&q=75'),
(1, 'Marbled Paper Notebook', 'Hand-marbled covers, lined pages, and a thread-bound spine.', 22500.00, 12, 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=700&q=75'),
(1, 'Linen Bound Planner 2026', 'Weekly spreads, monthly overviews, and a ribbon marker.', 48000.00, 22, 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=700&q=75'),
(2, 'Brass Fountain Pen', 'A weighty brass fountain pen with a starter ink cartridge.', 45000.00, 8, 'https://images.unsplash.com/photo-1583485088034-697b5bc36b3b?auto=format&fit=crop&w=700&q=75'),
(2, 'Calligraphy Dip Pen Set', 'One holder, three nibs, and a starter ink bottle.', 34000.00, 14, 'https://images.unsplash.com/photo-1517842645767-c639042777db?auto=format&fit=crop&w=700&q=75'),
(3, 'Watercolour Pencil Set (24pc)', 'Twenty-four shades for dry sketching and wet blending.', 39900.00, 20, 'https://images.unsplash.com/photo-1607166452427-7e4477079cb9?auto=format&fit=crop&w=700&q=75'),
(3, 'Gouache Paint Set (12 colours)', 'Opaque matte colours for starter illustration work.', 55000.00, 10, 'https://images.unsplash.com/photo-1568205612837-017257d2310a?auto=format&fit=crop&w=700&q=75'),
(3, 'Recycled Cotton Sketchbook', 'Toothy recycled cotton paper for graphite, charcoal, and ink.', 26000.00, 18, 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=700&q=75'),
(4, 'Pressed Flower Card Set', 'Six blank cards with pressed-flower styling and envelopes.', 15000.00, 40, 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=700&q=75'),
(5, 'Woven Desk Organiser', 'Four compartments for pens, clips, and desk tools.', 32000.00, 15, 'https://images.unsplash.com/photo-1517842645767-c639042777db?auto=format&fit=crop&w=700&q=75'),
(5, 'Wooden Ruler & Stamp Set', 'A beech ruler with three small rubber stamps.', 18500.00, 0, 'https://images.unsplash.com/photo-1568205612837-017257d2310a?auto=format&fit=crop&w=700&q=75'),
(6, 'Botanical Washi Tape Bundle', 'Five rolls of pressed-botanical patterns for wrapping and journaling.', 12900.00, 60, 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=700&q=75');

INSERT INTO product_variations (product_id, variation_name, variation_value, price_delta, stock_qty) VALUES
(1, 'Size', 'A5', 0, 20),
(1, 'Size', 'B6', 0, 14),
(3, 'Colour', 'Forest', 0, 8),
(3, 'Colour', 'Plum', 0, 7),
(3, 'Colour', 'Charcoal', 0, 7),
(4, 'Nib', 'Fine', 0, 4),
(4, 'Nib', 'Medium', 0, 4),
(12, 'Set', 'Botanical', 0, 20),
(12, 'Set', 'Pastel Dot', 0, 20),
(12, 'Set', 'Kraft Line', 0, 20);

-- Sample admin login:
-- email: admin@panlatepyar.com
-- password: password
INSERT INTO users (full_name, email, password_hash, role) VALUES
('Shop Admin', 'admin@panlatepyar.com', '$2y$10$1fa7GCYlx8Lqh93Z.iWsE.sCCKbPwr/XRJSuooDw0TMO1YXSIQRZ2', 'admin');
