-- customers definition

CREATE TABLE customers (
	"index" BIGINT, 
	customer_id TEXT, 
	customer_unique_id TEXT, 
	customer_zip_code_prefix BIGINT, 
	customer_city TEXT, 
	customer_state TEXT
);

CREATE INDEX ix_customers_index ON customers ("index");


-- geoloc definition

CREATE TABLE geoloc (
	"index" BIGINT, 
	geolocation_zip_code_prefix BIGINT, 
	geolocation_lat FLOAT, 
	geolocation_lng FLOAT, 
	geolocation_city TEXT, 
	geolocation_state TEXT
);

CREATE INDEX ix_geoloc_index ON geoloc ("index");


-- order_items definition

CREATE TABLE order_items (
	"index" BIGINT, 
	order_id TEXT, 
	order_item_id BIGINT, 
	product_id TEXT, 
	seller_id TEXT, 
	shipping_limit_date TEXT, 
	price FLOAT, 
	freight_value FLOAT
);

CREATE INDEX ix_order_items_index ON order_items ("index");


-- order_pymts definition

CREATE TABLE order_pymts (
	"index" BIGINT, 
	order_id TEXT, 
	payment_sequential BIGINT, 
	payment_type TEXT, 
	payment_installments BIGINT, 
	payment_value FLOAT
);

CREATE INDEX ix_order_pymts_index ON order_pymts ("index");


-- order_reviews definition

CREATE TABLE order_reviews (
	"index" BIGINT, 
	review_id TEXT, 
	order_id TEXT, 
	review_score BIGINT, 
	review_comment_title TEXT, 
	review_comment_message TEXT, 
	review_creation_date TEXT, 
	review_answer_timestamp TEXT
);

CREATE INDEX ix_order_reviews_index ON order_reviews ("index");


-- orders definition

CREATE TABLE orders (
	"index" BIGINT, 
	order_id TEXT, 
	customer_id TEXT, 
	order_status TEXT, 
	order_purchase_timestamp TEXT, 
	order_approved_at TEXT, 
	order_delivered_carrier_date TEXT, 
	order_delivered_customer_date TEXT, 
	order_estimated_delivery_date TEXT
);

CREATE INDEX ix_orders_index ON orders ("index");


-- products definition

CREATE TABLE products (
	"index" BIGINT, 
	product_id TEXT, 
	product_category_name TEXT, 
	product_name_lenght FLOAT, 
	product_description_lenght FLOAT, 
	product_photos_qty FLOAT, 
	product_weight_g FLOAT, 
	product_length_cm FLOAT, 
	product_height_cm FLOAT, 
	product_width_cm FLOAT
);

CREATE INDEX ix_products_index ON products ("index");


-- sellers definition

CREATE TABLE sellers (
	"index" BIGINT, 
	seller_id TEXT, 
	seller_zip_code_prefix BIGINT, 
	seller_city TEXT, 
	seller_state TEXT
);

CREATE INDEX ix_sellers_index ON sellers ("index");


-- "translation" definition

CREATE TABLE translation (
	"index" BIGINT, 
	product_category_name TEXT, 
	product_category_name_english TEXT
);

CREATE INDEX ix_translation_index ON translation ("index");