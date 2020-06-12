-----------------------------------------
-- Drop old schmema
-----------------------------------------

DROP SCHEMA IF EXISTS  public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-----------------------------------------
-- Tables
-----------------------------------------

CREATE TABLE categories (
                            id SERIAL PRIMARY KEY,
                            name TEXT NOT NULL UNIQUE
);

CREATE TABLE genres (
                        id SERIAL PRIMARY KEY,
                        name TEXT NOT NULL UNIQUE
);

CREATE TABLE platforms (
                           id SERIAL PRIMARY KEY,
                           name TEXT NOT NULL UNIQUE
);

CREATE TABLE pictures (
                          id SERIAL PRIMARY KEY,
                          url TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          name TEXT NOT NULL UNIQUE,
                          name_tsvector tsvector DEFAULT NULL,
                          weight_tsvector  tsvector DEFAULT NULL,
                          description TEXT,
                          category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE CASCADE,
                          picture_id INTEGER DEFAULT 2 NOT NULL REFERENCES pictures (id) ON DELETE SET DEFAULT ON UPDATE CASCADE,
                          deleted BOOLEAN NOT NULL DEFAULT FALSE,
                          launch_date DATE NOT NULL,
                          num_sells INTEGER NOT NULL DEFAULT 0,
                          CONSTRAINT num_sells_chk CHECK (num_sells >= 0)
);

CREATE TABLE product_has_genres (
                                    genre_id INTEGER NOT NULL REFERENCES genres(id) ON DELETE CASCADE ON UPDATE CASCADE,
                                    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
                                    PRIMARY KEY (genre_id, product_id)
);

CREATE TABLE product_has_platforms (
                                       platform_id INTEGER REFERENCES platforms(id) ON DELETE CASCADE ON UPDATE CASCADE,
                                       product_id INTEGER REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
                                       PRIMARY KEY (platform_id, product_id)
);

CREATE TABLE users (
                       id SERIAL PRIMARY KEY,
                       username TEXT NOT NULL UNIQUE,
                       email TEXT NOT NULL UNIQUE,
                       description TEXT NOT NULL DEFAULT '',
                       name_tsvector tsvector DEFAULT NULL,
                       weight_tsvector  tsvector DEFAULT NULL,
                       password TEXT NOT NULL,
                       rating INTEGER DEFAULT NULL,
                       birth_date date NOT NULL,
                       paypal TEXT,
                       picture_id INTEGER NOT NULL DEFAULT 1 REFERENCES pictures(id) ON DELETE SET DEFAULT ON UPDATE CASCADE,
                       num_sells INTEGER NOT NULL DEFAULT 0,
                       remember_token VARCHAR,
                       CONSTRAINT rating_ck CHECK (rating >= 0 AND rating <= 100),
                       CONSTRAINT birthdate_ck CHECK (date_part('year', age(birth_date)) >= 18),
                       CONSTRAINT num_sells_ck CHECK (num_sells >= 0)
);

CREATE TABLE offers (
                        id SERIAL PRIMARY KEY,
                        price REAL NOT NULL,
                        init_date date NOT NULL DEFAULT NOW(),
                        final_date date,
                        profit REAL NOT NULL DEFAULT 0,
                        platform_id INTEGER NOT NULL REFERENCES platforms(id) ON DELETE RESTRICT ON UPDATE CASCADE,
                        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
                        product_id INTEGER REFERENCES products(id) ON DELETE SET NULL ON UPDATE CASCADE,
                        stock INTEGER NOT NULL DEFAULT 0,
                        CONSTRAINT price_ck CHECK (price > 0),
                        CONSTRAINT init_date_ck CHECK (init_date <= NOW()),
                        CONSTRAINT final_date_ck CHECK (final_date IS NULL OR final_date >= init_date),
                        CONSTRAINT profit_ck CHECK (profit >= 0),
                        CONSTRAINT stock_ck CHECK (stock >= 0)
);

CREATE TABLE discounts (
                           id SERIAL PRIMARY KEY,
                           rate INTEGER NOT NULL,
                           start_date date NOT NULL,
                           end_date date NOT NULL,
                           offer_id INTEGER NOT NULL REFERENCES offers(id) ON DELETE CASCADE ON UPDATE CASCADE,

                           CONSTRAINT end_date_ck CHECK (end_date > start_date),
                           CONSTRAINT rate_ck CHECK (rate >= 0 AND rate <= 100)
);

CREATE TABLE banned_users (
                              id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
                              username TEXT
);

CREATE TABLE admins (
                        id SERIAL PRIMARY KEY,
                        username TEXT NOT NULL UNIQUE,
                        email TEXT NOT NULL UNIQUE,
                        description TEXT NOT NULL DEFAULT '',
                        password TEXT NOT NULL,
                        picture_id INTEGER NOT NULL DEFAULT 1 REFERENCES pictures(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
);

CREATE TABLE ban_appeals (
                             id INTEGER PRIMARY KEY REFERENCES banned_users(id) ON DELETE CASCADE ON UPDATE CASCADE,
                             admin_id INTEGER REFERENCES admins(id) ON DELETE SET NULL ON UPDATE CASCADE,
                             ban_appeal TEXT NOT NULL,
                             date date NOT NULL DEFAULT NOW(),

                             CONSTRAINT date_ck CHECK(date <= NOW())
);

CREATE TABLE orders (
                        number SERIAL PRIMARY KEY,
                        date DATE NOT NULL DEFAULT NOW(),
                        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
                        order_info_name TEXT NOT NULL,
                        order_info_email TEXT NOT NULL,
                        order_info_address TEXT NOT NULL,
                        order_info_zipcode TEXT NOT NULL,

                        CONSTRAINT date_ck CHECK(date <= NOW())
);

CREATE TABLE keys (
                      id SERIAL PRIMARY KEY,
                      key TEXT NOT NULL UNIQUE,
                      price_sold REAL DEFAULT NULL,
                      offer_id integer NOT NULL REFERENCES offers(id) ON DELETE RESTRICT ON UPDATE CASCADE,
                      order_id integer DEFAULT NULL REFERENCES orders(number) ON DELETE RESTRICT ON UPDATE CASCADE,

                      CONSTRAINT price_ck CHECK(price_sold IS NULL OR price_sold > 0),
                      CONSTRAINT sold_key_ck CHECK((price_sold IS NULL AND order_id IS NULL) or (price_sold IS NOT NULL AND order_id IS NOT NULL))

);

CREATE TABLE feedback (
                          id SERIAL PRIMARY KEY,
                          evaluation BOOLEAN NOT NULL,
                          comment TEXT,
                          evaluation_date DATE NOT NULL DEFAULT NOW() CONSTRAINT fb_date_ck CHECK(evaluation_date <= NOW()),
                          user_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
                          key_id INTEGER UNIQUE NOT NULL REFERENCES keys(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE reports (
                         id SERIAL PRIMARY KEY,
                         date date NOT NULL DEFAULT NOW(),
                         description TEXT NOT NULL ,
                         title TEXT NOT NULL,
                         status BOOLEAN NOT NULL DEFAULT false,
                         key_id INTEGER NOT NULL UNIQUE REFERENCES keys(id) ON DELETE RESTRICT ON UPDATE CASCADE,
                         reporter_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
                         reported_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,

                         CONSTRAINT user_ck CHECK(reporter_id <> reported_id),
                         CONSTRAINT date_ck CHECK(date <= NOW())
);

CREATE TABLE messages (
                          id SERIAL PRIMARY KEY,
                          date date NOT NULL DEFAULT NOW(),
                          description TEXT NOT NULL,
                          user_id INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
                          admin_id INTEGER REFERENCES admins(id) ON DELETE SET NULL ON UPDATE CASCADE,
                          report_id INTEGER NOT NULL REFERENCES reports(id) ON DELETE CASCADE ON UPDATE CASCADE,

                          CONSTRAINT date_ck CHECK(date <= NOW()),
                          CONSTRAINT user_type_ck CHECK((user_id IS NULL AND admin_id IS NOT NULL ) OR (user_id IS NOT NULL AND admin_id IS NULL))
);

CREATE TABLE carts (
                       id SERIAL PRIMARY KEY,
                       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
                       offer_id INTEGER NOT NULL REFERENCES offers(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE about_us (
                          id SERIAL PRIMARY KEY,
                          description TEXT NOT NULL
);

CREATE TABLE faq (
                     id SERIAL PRIMARY KEY,
                     question TEXT NOT NULL,
                     answer TEXT NOT NULL
);
CREATE TABLE password_resets (
                                 email TEXT,
                                 token TEXT,
                                 created_at TIMESTAMP
);

-----------------------------------------
-- MATERIALIZED VIEWS
-----------------------------------------
CREATE MATERIALIZED VIEW active_products AS
SELECT products.id AS product_id
FROM products
WHERE products.deleted = FALSE;

CREATE MATERIALIZED VIEW active_offers AS
SELECT offers.id AS offer_id
FROM offers
WHERE final_date IS NULL;

-----------------------------------------
-- INDEXES
-----------------------------------------
CREATE INDEX offer_product_idx ON offers (product_id);
CREATE INDEX offer_seller_idx ON offers (user_id);
CREATE INDEX discount_offer_idx ON discounts (offer_id);
CREATE INDEX key_offer_idx ON keys (offer_id);
CREATE INDEX discount_date_idx ON discounts (start_date, end_date);
CREATE INDEX cart_buyer_idx ON carts (user_id);

CREATE INDEX product_name_idx
    ON products
        USING GIST(name_tsvector);

CREATE INDEX user_username_idx
    ON users
        USING GIST (name_tsvector);

-----------------------------------------
-- UDFs and TRIGGERS
-----------------------------------------
DROP FUNCTION IF EXISTS get_seller_through_key(integer) CASCADE;
CREATE OR REPLACE FUNCTION get_seller_through_key(key_id integer)
    RETURNS INTEGER AS $seller_id$
DECLARE
    seller_id integer;
BEGIN
    SELECT u.id INTO seller_id
    FROM keys k JOIN offers o ON k.offer_id = o.id
                JOIN users u ON o.user_id = u.id
    WHERE k.id = key_id;

    RETURN seller_id;
END;
$seller_id$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION insert_product_tsvector()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.name_tsvector := to_tsvector(NEW.name || coalesce(NEW.description, ''));
    NEW.weight_tsvector := setweight(to_tsvector(NEW.name), 'A') ||
                           setweight(to_tsvector(coalesce(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_product_tsvector_tg ON products;
CREATE TRIGGER insert_product_tsvector_tg
    BEFORE INSERT ON products
    FOR EACH ROW
EXECUTE PROCEDURE insert_product_tsvector();

CREATE OR REPLACE FUNCTION update_product_tsvector()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.name_tsvector := to_tsvector(NEW.name || coalesce(NEW.description, ''));
    NEW.weight_tsvector := setweight(to_tsvector(NEW.name), 'A') ||
                           setweight(to_tsvector(coalesce(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_product_tsvector_tg ON products;
CREATE TRIGGER update_product_tsvector_tg
    BEFORE UPDATE ON products
    FOR EACH ROW
    WHEN (NEW.name <> OLD.name or NEW.description <> OLD.description)
EXECUTE PROCEDURE update_product_tsvector();

CREATE OR REPLACE FUNCTION insert_user_tsvector()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.name_tsvector := (to_tsvector('english',NEW.username) || to_tsvector('english',NEW.description));
    NEW.weight_tsvector := setweight(to_tsvector('english',NEW.username), 'A') ||
                           setweight(to_tsvector('english',NEW.description), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS insert_user_tsvector_tg ON users;
CREATE TRIGGER insert_user_tsvector_tg
    BEFORE INSERT ON users
    FOR EACH ROW
EXECUTE PROCEDURE insert_user_tsvector();

CREATE OR REPLACE FUNCTION update_user_tsvector()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.name_tsvector := (to_tsvector('english',NEW.username) || to_tsvector('english',NEW.description));
    NEW.weight_tsvector := setweight(to_tsvector('english',NEW.username), 'A') ||
                           setweight(to_tsvector('english',NEW.description), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_tsvector_tg ON users;
CREATE TRIGGER update_user_tsvector_tg
    BEFORE UPDATE ON users
    FOR EACH ROW
    WHEN (NEW.username <> OLD.username or NEW.description <> OLD.description)
EXECUTE PROCEDURE update_user_tsvector();

CREATE OR REPLACE FUNCTION product_num_sells()
    RETURNS TRIGGER AS $$
DECLARE
    sells INTEGER;
    product_id INTEGER;
BEGIN
    SELECT products.id INTO product_id
    FROM products, offers
    WHERE products.id = offers.product_id AND offers.id = NEW.offer_id
    LIMIT 1;

    SELECT COUNT(products.id) INTO sells
    FROM (offers JOIN products ON products.id = offers.product_id)
             JOIN keys ON keys.offer_id = offers.id
    WHERE keys.order_id IS NOT NULL;

    UPDATE products
    SET num_sells = sells
    WHERE id = product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS product_num_sales_tg ON keys CASCADE;
CREATE TRIGGER product_num_sales_tg
    AFTER UPDATE OF order_id ON keys
    FOR EACH ROW
EXECUTE PROCEDURE product_num_sells();


CREATE OR REPLACE FUNCTION user_num_sells()
    RETURNS TRIGGER AS $$
DECLARE
    sells INTEGER;
    seller_id INTEGER;
BEGIN
    seller_id := get_seller_through_key(NEW.id);

    SELECT COUNT(keys.id) INTO sells
    FROM keys JOIN offers ON keys.offer_id = offers.id
              JOIN users AS seller ON seller.id = offers.user_id
    WHERE seller.id = seller_id AND keys.order_id IS NOT NULL;

    IF sells IS NULL THEN
        sells := 0;
    END IF;

    UPDATE users
    SET num_sells = sells
    WHERE id = seller_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS user_num_sells_tg ON keys CASCADE;
CREATE TRIGGER user_num_sells_tg
    AFTER INSERT OR UPDATE OF order_id ON keys
    FOR EACH ROW
EXECUTE PROCEDURE user_num_sells();

CREATE OR REPLACE FUNCTION user_num_sells_delete()
    RETURNS TRIGGER AS $$
DECLARE
    sells INTEGER;
    seller_id INTEGER;
BEGIN
    seller_id := get_seller_through_key(OLD.id);

    SELECT COUNT(keys.id) INTO sells
    FROM keys JOIN offers ON keys.offer_id = offers.id
              JOIN users AS seller ON seller.id = offers.user_id
    WHERE seller.id = seller_id AND keys.order_id IS NOT NULL;

    IF sells IS NULL THEN
        sells := 0;
    END IF;

    UPDATE users
    SET num_sells = sells
    WHERE id = seller_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS user_num_sells_delete_tg ON keys CASCADE;
CREATE TRIGGER user_num_sells_delete_tg
    AFTER DELETE ON keys
    FOR EACH ROW
EXECUTE PROCEDURE user_num_sells_delete();


CREATE OR REPLACE FUNCTION update_seller_feedback()
    RETURNS TRIGGER AS $$
DECLARE
    seller_id integer;
    positive_reviews integer;
    num_reviews integer;
    total_feedback float;
BEGIN
    seller_id := get_seller_through_key(NEW.key_id);

    -- Number of positive reviews of seller with id seller_id
    SELECT COUNT(keys.id) INTO positive_reviews
    FROM feedback JOIN keys ON feedback.key_id = keys.id
                  JOIN offers ON keys.offer_id = offers.id
    WHERE feedback.evaluation = true AND offers.user_id = seller_id;

    IF positive_reviews IS NULL THEN
        positive_reviews := 0;
    END IF;

    -- Number of reviews of seller with id seller_id
    SELECT COUNT(keys.id) INTO num_reviews
    FROM feedback JOIN keys ON feedback.key_id = keys.id
                  JOIN offers ON keys.offer_id = offers.id
    WHERE offers.user_id = seller_id;

    IF num_reviews IS NULL OR num_reviews = 0 THEN
        UPDATE users
        SET rating = NULL
        WHERE users.id = seller_id;
        RETURN NEW;
    END IF;

    total_feedback := (100 * positive_reviews) / num_reviews;

    UPDATE users
    SET rating = total_feedback
    WHERE users.id = seller_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_seller_feedback_tg ON feedback CASCADE;
CREATE TRIGGER update_seller_feedback_tg
    AFTER INSERT OR UPDATE ON feedback
    FOR EACH ROW
EXECUTE PROCEDURE update_seller_feedback();


CREATE OR REPLACE FUNCTION update_seller_feedback_delete()
    RETURNS TRIGGER AS $$
DECLARE
    seller_id integer;
    positive_reviews integer;
    num_reviews integer;
    total_feedback float;
BEGIN
    seller_id := get_seller_through_key(OLD.key_id);

    -- Number of positive reviews of seller with id seller_id
    SELECT COUNT(keys.id) INTO positive_reviews
    FROM feedback JOIN keys ON feedback.key_id = keys.id
                  JOIN offers ON keys.offer_id = offers.id
    WHERE feedback.evaluation = true AND offers.user_id = seller_id;

    IF positive_reviews IS NULL THEN
        positive_reviews := 0;
    END IF;

    -- Number of reviews of seller with id seller_id
    SELECT COUNT(keys.id) INTO num_reviews
    FROM feedback JOIN keys ON feedback.key_id = keys.id
                  JOIN offers ON keys.offer_id = offers.id
    WHERE offers.user_id = seller_id;

    IF num_reviews IS NULL OR num_reviews = 0 THEN
        UPDATE users
        SET rating = NULL
        WHERE users.id = seller_id;
        RETURN OLD;
    END IF;

    total_feedback := (100 * positive_reviews) / num_reviews;

    UPDATE users
    SET rating = total_feedback
    WHERE users.id = seller_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_seller_feedback_delete_tg ON feedback CASCADE;
CREATE TRIGGER update_seller_feedback_delete_tg
    AFTER DELETE ON feedback
    FOR EACH ROW
EXECUTE PROCEDURE update_seller_feedback_delete();


CREATE OR REPLACE FUNCTION check_user_bought_product()
    RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
            SELECT *
            FROM orders AS o JOIN keys AS k ON o.number = k.order_id
            WHERE NEW.key_id = k.id AND o.user_id = NEW.user_id
        ) THEN
        RAISE EXCEPTION 'Cannot review a product that you did not buy';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_user_bought_product_tg ON feedback CASCADE;
CREATE TRIGGER check_user_bought_product_tg
    BEFORE INSERT
    ON feedback
    FOR EACH ROW
EXECUTE PROCEDURE check_user_bought_product();


CREATE OR REPLACE FUNCTION update_product_stock()
    RETURNS TRIGGER AS $$
DECLARE
    stock_quantity INTEGER;
BEGIN
    SELECT COUNT(id) INTO stock_quantity
    FROM keys
    WHERE keys.offer_id = NEW.offer_id AND keys.order_id IS NULL;

    IF(stock_quantity IS NULL) THEN
        stock_quantity:=0;
    END IF;

    UPDATE offers
    SET stock = stock_quantity
    WHERE id = NEW.offer_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_product_stock_tg ON keys CASCADE;
CREATE TRIGGER update_product_stock_tg
    AFTER INSERT OR UPDATE OF order_id ON keys
    FOR EACH ROW
EXECUTE PROCEDURE update_product_stock();


CREATE OR REPLACE FUNCTION update_product_stock_cancel()
    RETURNS TRIGGER AS $$
DECLARE
    stock_quantity INTEGER;
BEGIN

    SELECT COUNT(id) INTO stock_quantity
    FROM keys
    WHERE keys.offer_id = OLD.offer_id AND keys.order_id IS NULL;

    IF(stock_quantity IS NULL) THEN
        stock_quantity:=0;
    END IF;

    UPDATE offers
    SET stock = stock_quantity
    WHERE id = OLD.offer_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_product_stock_delete_tg ON keys CASCADE;
CREATE TRIGGER update_product_stock_delete_tg
    AFTER DELETE ON keys
    FOR EACH ROW
EXECUTE PROCEDURE update_product_stock_cancel();



CREATE OR REPLACE FUNCTION delete_from_cart()
    RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM carts
    WHERE offer_id IN (
        SELECT offers.id
        FROM offers
        WHERE offers.product_id = NEW.id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_from_cart_tg ON products CASCADE;
CREATE TRIGGER delete_from_cart_tg
    AFTER INSERT OR UPDATE OF deleted ON products
    FOR EACH ROW
    WHEN (NEW.deleted = true)
EXECUTE PROCEDURE delete_from_cart();



CREATE OR REPLACE FUNCTION delete_from_cart_offer()
    RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM carts
    WHERE offer_id=NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS delete_from_cart_update_tg ON products CASCADE;
CREATE TRIGGER delete_from_cart_update_tg
    AFTER UPDATE OF final_date ON offers
    FOR EACH ROW
    WHEN (NEW.final_date IS NOT NULL)
EXECUTE PROCEDURE delete_from_cart_offer();


DROP FUNCTION IF EXISTS check_not_self_buying() CASCADE;
CREATE OR REPLACE FUNCTION check_not_self_buying()
    RETURNS TRIGGER AS $$
DECLARE
    seller_id INTEGER;
BEGIN
    seller_id := (
        SELECT offers.user_id
        FROM offers
        WHERE offers.id = NEW.offer_id
    );

    IF seller_id = NEW.user_id THEN
        RAISE EXCEPTION 'You cannot buy product that you are already selling!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_not_self_buying_tg ON carts CASCADE;
CREATE TRIGGER check_not_self_buying_tg
    AFTER INSERT ON carts
    FOR EACH ROW
EXECUTE PROCEDURE check_not_self_buying();


CREATE OR REPLACE FUNCTION delete_keys_from_canceled_offers()
    RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM keys
    WHERE keys.offer_id = NEW.id AND keys.order_id IS NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS delete_keys_from_canceled_offers_tg ON offers CASCADE;
CREATE TRIGGER delete_keys_from_canceled_offers_tg
    AFTER UPDATE OF final_date ON offers
    FOR EACH ROW
    WHEN(NEW.final_date IS NOT NULL)
EXECUTE PROCEDURE delete_keys_from_canceled_offers();


CREATE OR REPLACE FUNCTION rollback_offer_of_deleted_products()
    RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
            SELECT *
            FROM products
            WHERE NEW.product_id = products.id AND products.deleted = TRUE
        ) THEN
        RAISE EXCEPTION 'You cannot insert an offer of a product that was deleted by the admin';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS rollback_offer_of_deleted_products_tg ON offers CASCADE;
CREATE TRIGGER rollback_offer_of_deleted_products_tg
    BEFORE INSERT ON offers
    FOR EACH ROW
EXECUTE PROCEDURE rollback_offer_of_deleted_products();


CREATE OR REPLACE FUNCTION update_offer_final_date()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.final_date = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_offer_final_date_tg ON offers CASCADE;
CREATE TRIGGER update_offer_final_date_tg
    BEFORE INSERT OR UPDATE OF stock ON offers
    FOR EACH ROW
    WHEN(NEW.final_date IS NULL AND NEW.stock=0)
EXECUTE PROCEDURE update_offer_final_date();


CREATE OR REPLACE FUNCTION check_discount_date_overlap()
    RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
            SELECT *
            FROM discounts
            WHERE start_date IS NOT NULL
              AND start_date <= NEW.end_date
              AND end_date >= NEW.start_date
              AND NEW.offer_id = discounts.offer_id
        ) THEN
        RAISE EXCEPTION 'There is already a discount for that offer during the same time period';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS overlap_discount_dates_tg ON discounts CASCADE;
CREATE TRIGGER overlap_discount_dates_tg
    BEFORE INSERT OR UPDATE ON discounts
    FOR EACH ROW
EXECUTE PROCEDURE check_discount_date_overlap();


CREATE OR REPLACE FUNCTION refresh_active_products_view()
    RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW active_products;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS refresh_active_products_view_tg ON products CASCADE;
CREATE TRIGGER refresh_active_products_view_tg
    AFTER INSERT OR UPDATE ON products
    FOR EACH ROW
EXECUTE PROCEDURE refresh_active_products_view();


CREATE OR REPLACE FUNCTION refresh_active_products_view_delete()
    RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW active_products;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS refresh_active_products_view_delete_tg ON products CASCADE;
CREATE TRIGGER refresh_active_products_view_delete_tg
    AFTER DELETE ON products
    FOR EACH ROW
EXECUTE PROCEDURE refresh_active_products_view_delete();


CREATE OR REPLACE FUNCTION refresh_active_offers_view()
    RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW active_offers;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS refresh_active_offers_view_tg ON offers CASCADE;
CREATE TRIGGER refresh_active_offers_view_tg
    AFTER INSERT OR UPDATE ON offers
    FOR EACH ROW
EXECUTE PROCEDURE refresh_active_offers_view();


CREATE OR REPLACE FUNCTION refresh_active_offers_view_delete()
    RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW active_offers;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS refresh_active_offers_view_delete_tg ON offers CASCADE;
CREATE TRIGGER refresh_active_offers_view_delete_tg
    AFTER DELETE ON offers
    FOR EACH ROW
EXECUTE PROCEDURE refresh_active_offers_view();


CREATE OR REPLACE FUNCTION verify_banned_user_orders()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IN (SELECT id FROM banned_users) THEN
        RAISE EXCEPTION 'User with ID % is banned and cannot make purchases', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS verify_banned_user_orders_tg ON orders CASCADE;
CREATE TRIGGER verify_banned_user_orders_tg
    BEFORE INSERT ON orders
    FOR EACH ROW
EXECUTE PROCEDURE verify_banned_user_orders();


---
CREATE OR REPLACE FUNCTION update_offer_profit()
    RETURNS TRIGGER AS $$
DECLARE
    offer_profit REAL;

BEGIN

    SELECT SUM(keys.price_sold) into offer_profit
    FROM keys
    WHERE keys.offer_id = NEW.offer_id
      AND keys.price_sold IS NOT NULL
    GROUP BY keys.offer_id;

    IF (offer_profit IS NULL) THEN
        offer_profit:=0;
    END IF;

    UPDATE offers
    SET profit = offer_profit
    WHERE id = NEW.offer_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_offer_profit_tg ON keys CASCADE;
CREATE TRIGGER update_offer_profit_tg
    AFTER INSERT OR UPDATE OF price_sold ON keys
    FOR EACH ROW
EXECUTE PROCEDURE update_offer_profit();
---

CREATE OR REPLACE FUNCTION update_offer_profit_delete()
    RETURNS TRIGGER AS $$
DECLARE
    offer_profit REAL;

BEGIN

    SELECT SUM(keys.price_sold) into offer_profit
    FROM keys
    WHERE keys.offer_id = OLD.offer_id
      AND keys.price_sold IS NOT NULL
    GROUP BY keys.offer_id;

    IF (offer_profit IS NULL) THEN
        offer_profit:=0;
    END IF;

    UPDATE offers
    SET profit = offer_profit
    WHERE id = OLD.offer_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_offer_profit_delete_tg ON keys CASCADE;
CREATE TRIGGER update_offer_profit_delete_tg
    AFTER DELETE ON keys
    FOR EACH ROW
EXECUTE PROCEDURE update_offer_profit_delete();


CREATE OR REPLACE FUNCTION verify_banned_user_offer()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IN (SELECT id FROM banned_users) THEN
        RAISE EXCEPTION 'User with ID % is banned and cannot make offers', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS verify_banned_user_offer_tg ON offers CASCADE;
CREATE TRIGGER verify_banned_user_offer_tg
    BEFORE INSERT ON offers
    FOR EACH ROW
EXECUTE PROCEDURE verify_banned_user_offer();


CREATE OR REPLACE FUNCTION update_banned_user_offers()
    RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM keys
    WHERE keys.offer_id IN (SELECT offers.id FROM offers WHERE offers.user_id = NEW.id)
      AND keys.order_id IS NULL;

    UPDATE offers
    SET final_date = now()
    WHERE user_id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_banned_user_offers_tg ON banned_users CASCADE;
CREATE TRIGGER update_banned_user_offers_tg
    AFTER INSERT ON banned_users
    FOR EACH ROW
EXECUTE PROCEDURE update_banned_user_offers();


CREATE OR REPLACE FUNCTION update_offers_stock()
    RETURNS TRIGGER AS $$
DECLARE
    offer_stock INTEGER;
BEGIN
    SELECT COUNT(keys.id) INTO offer_stock
    FROM keys
    WHERE keys.offer_id = NEW.id
      AND keys.order_id IS NULL;

    IF (offer_stock IS NULL) THEN
        offer_stock := 0;
    END IF;

    IF (offer_stock <> 0) THEN
        NEW.final_date = NULL;
    END IF;

    NEW.stock = offer_stock;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_offers_stock_tg ON offers CASCADE;
CREATE TRIGGER update_offers_stock_tg
    BEFORE INSERT OR UPDATE OF stock ON offers
    FOR EACH ROW
EXECUTE PROCEDURE update_offers_stock();


CREATE OR REPLACE FUNCTION banned_user_username()
    RETURNS TRIGGER AS $$
BEGIN

    SELECT users.username INTO NEW.username
    FROM users
    WHERE users.id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS banned_user_username_tg ON banned_users CASCADE;
CREATE TRIGGER banned_user_username_tg
    BEFORE INSERT ON banned_users
    FOR EACH ROW
EXECUTE PROCEDURE banned_user_username();
-----------------------------------------
-- Drop all old table data  (TRUNCATE quickly removes all rows from a set of tables. It has the same effect as an unqualified DELETE on each table, but since it does not actually scan the tables it is faster)
-----------------------------------------

TRUNCATE admins RESTART IDENTITY CASCADE;
TRUNCATE ban_appeals RESTART IDENTITY CASCADE;
TRUNCATE banned_users RESTART IDENTITY CASCADE;
TRUNCATE carts RESTART IDENTITY CASCADE;
TRUNCATE categories RESTART IDENTITY CASCADE;
TRUNCATE discounts RESTART IDENTITY CASCADE;
TRUNCATE faq RESTART IDENTITY CASCADE;
TRUNCATE feedback RESTART IDENTITY CASCADE;
TRUNCATE genres RESTART IDENTITY CASCADE;
TRUNCATE pictures RESTART IDENTITY CASCADE;
TRUNCATE keys RESTART IDENTITY CASCADE;
TRUNCATE messages RESTART IDENTITY CASCADE;
TRUNCATE offers RESTART IDENTITY CASCADE;
TRUNCATE orders RESTART IDENTITY CASCADE;
TRUNCATE platforms RESTART IDENTITY CASCADE;
TRUNCATE products RESTART IDENTITY CASCADE;
TRUNCATE product_has_genres RESTART IDENTITY CASCADE;
TRUNCATE product_has_platforms RESTART IDENTITY CASCADE;
TRUNCATE users RESTART IDENTITY CASCADE;
TRUNCATE reports RESTART IDENTITY CASCADE;

-----------------------------------------
-- Populate the database
-----------------------------------------

-- static pages
INSERT INTO faq(question, answer) VALUES(UPPER('WHAT IS KEYSHARE?'),'KeyShare is a global marketplace which specializes in the sale of gaming related digital products using redemption keys');
INSERT INTO faq(question, answer) VALUES(UPPER('WHAT PAYMENT METHODS CAN I USE TO MAKE PURCHASE ON THE KEYSHARE WEBSITE?'),'The only available payment method Paypal');
INSERT INTO faq(question, answer) VALUES(UPPER('WHY DO I NEED TO CREATE AN ACCOUNT ON THE KEYSHARE WEBSITE?'),'Even though you can buy products without an account, if you register you can see your purchase history, have a savable cart, give feedback, etc');
INSERT INTO faq(question, answer) VALUES(UPPER('DO I NEED TO PAY ANY EXTRA TAX AFTER MAKEING A PURCHASE ON THE keyHARE WEBSITE?'),'The full price is as listed, so no!');
INSERT INTO faq(question, answer) VALUES(UPPER('DO I HAVE THE RIGHT TO A REFUND IN CASE A PRODUCT IS NOT WORKING?'),'In case a product does not work, you should report the seller and the admin will analyze yoyr situation');
INSERT INTO faq(question, answer) VALUES(UPPER('DO I HAVE ACCESS TO THE GAMES I BUY ON THE KEYSHARE WEBISTE FOREVER?'),'Yes, after buying any product, the key will work forever. If it does not, then you should report the seller');

-- categories
INSERT INTO categories(name) VALUES('GAME');
INSERT INTO categories(name) VALUES('DLC');
INSERT INTO categories(name) VALUES('EXPANSION');

-- genres
INSERT INTO genres(name) VALUES('ACTION');
INSERT INTO genres(name) VALUES('SPORT');
INSERT INTO genres(name) VALUES('ADVENTURE');
INSERT INTO genres(name) VALUES('PUZZLE');
INSERT INTO genres(name) VALUES('FPS');
INSERT INTO genres(name) VALUES('SIMULATION');
INSERT INTO genres(name) VALUES('SHOOTER');
INSERT INTO genres(name) VALUES('RACING');
INSERT INTO genres(name) VALUES('FOOTBALL');
INSERT INTO genres(name) VALUES('CO-OP');
INSERT INTO genres(name) VALUES('MULTIPLAYER');
INSERT INTO genres(name) VALUES('OPEN-WORLD');

-- platforms
INSERT INTO platforms(name) VALUES('PC');
INSERT INTO platforms(name) VALUES('PS5');
INSERT INTO platforms(name) VALUES('PS4');
INSERT INTO platforms(name) VALUES('PS3');
INSERT INTO platforms(name) VALUES('PS2');
INSERT INTO platforms(name) VALUES('XBOX SERIES X');
INSERT INTO platforms(name) VALUES('XBOX ONE');
INSERT INTO platforms(name) VALUES('XBOX 360');
INSERT INTO platforms(name) VALUES('SWITCH');

-- product pictures
INSERT INTO pictures (url)VALUES('user.png');
INSERT INTO pictures (url) VALUES ('product.png');
INSERT INTO pictures (url) VALUES ('dcdb4945904bf4da6b15ce79ad9e0492.png');
INSERT INTO pictures (url) VALUES ('6aeb7836dcb2ba2b4269accb3c2e64c7.png');
INSERT INTO pictures (url) VALUES ('5353286093c4de6d762effd4d84f3259.png');
INSERT INTO pictures (url) VALUES ('5427b3c4946d24d90cd0a91ad4934a53.png');
INSERT INTO pictures (url) VALUES ('10ad90a11279f840d1f308d29b532ad4.png');
INSERT INTO pictures (url) VALUES ('5fd9a24f8770576b18c7266167179e93.png');
INSERT INTO pictures (url) VALUES ('1a5ae8867077dd2ae4b913a76b271f4a.png');
INSERT INTO pictures (url) VALUES ('ff4a0493cae3168be2ef6117e62e7067.png');
INSERT INTO pictures (url) VALUES ('261f44e3020433d5f0b8693688ae44b5.png');
INSERT INTO pictures (url) VALUES ('942f3505aadd31c7953628370d00bf22.png');
INSERT INTO pictures (url) VALUES ('4be39b743bb0015f7dab201fa5eb7a79.png');
INSERT INTO pictures (url) VALUES ('cfd24ee575794d52a83151b0162b19d5.png');
INSERT INTO pictures (url) VALUES ('8f6e9443a4df277f7bb8bebebca94d82.png');
INSERT INTO pictures (url) VALUES ('8aeccc1d837017adc065bcbc0163aaa0.png');
INSERT INTO pictures (url) VALUES ('fda1a4aab3b10a57b2cf50ce83464840.png');
INSERT INTO pictures (url) VALUES ('7f1144248c995587e4dd4368b3bd73ce.png');
INSERT INTO pictures (url) VALUES ('b5e294ae186ce239a940349e91c825ec.png');
INSERT INTO pictures (url) VALUES ('7c7a700123deef94dcee679725acd992.png');
INSERT INTO pictures (url) VALUES ('3744b3689b77e0b216c3f76ba7eb0ecf.png');
INSERT INTO pictures (url) VALUES ('69b4252d8b1b8ed83fed1c4333a5f39e.png');
INSERT INTO pictures (url) VALUES ('b644be6b0f7e7be8977c5a43f37fd26f.png');
INSERT INTO pictures (url) VALUES ('34bf0e63edc4b2e4949b49b63d1da5c0.png');
INSERT INTO pictures (url) VALUES ('0afbae6ad65703271103dc8f392a7304.png');
INSERT INTO pictures (url) VALUES ('7684fb3f03509f9bc99149488016db68.png');
INSERT INTO pictures (url) VALUES ('ec886fbf9042af6ded4f786ce5e24e5a.png');
INSERT INTO pictures (url) VALUES ('7969c0e76cfa69a61fdba2a4896b4238.png');
INSERT INTO pictures (url) VALUES ('c4ec383184df526c005f4a26a1404349.png');
INSERT INTO pictures (url) VALUES ('d3d2bc681cef6a0631f32299b25da87d.png');
INSERT INTO pictures (url) VALUES ('14e93deeb687d1302180f7129d8a75a3.png');


INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('GTA V'), 'Grand Theft Auto V for PC will take full advantage of the power of PC to deliver across-the-board enhancements including increased resolution and graphical detail, denser traffic, greater draw distances, upgraded AI, new wildlife, and advanced weather and damage effects for the ultimate open world experience. Grand Theft Auto V for PC features the all-new First Person Mode, giving players the chance to explore the incredibly detailed world of Los Santos and Blaine County in an entirely new way across both Story Mode and Grand Theft Auto Online.Los Santos: a sprawling sun-soaked metropolis full of self-help gurus, starlets and fading celebrities, once the envy of the Western world, now struggling to stay afloat in an era of economic uncertainty and cheap reality TV. Amidst the turmoil, three very different criminals risk everything in a series of daring and dangerous heists that could set them up for life.The biggest, most dynamic and most diverse open world ever created and now packed with layers of new detail, Grand Theft Auto V blends storytelling and gameplay in new ways as players repeatedly jump in and out of the lives of the game’s three lead characters, playing all sides of the game’s interwoven story.Grand Theft Auto V for PC also includes Grand Theft Auto Online, the ever-evolving Grand Theft Auto universe. Explore the vast world or rise through the criminal ranks by banding together to complete Jobs for cash, purchase properties, vehicles and character upgrades, compete in traditional competitive', 11, 1, '2013-09-17');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,1);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(7,1);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,1);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,1);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,1);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,1);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,1);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Red Dead Redemption 2'), 'America, 1899. The end of the wild west era has begun as lawmen hunt down the last remaining outlaw gangs. Those who will not surrender or succumb are killed. After a robbery goes badly wrong in the western town of Blackwater, Arthur Morgan and the Van der Linde gang are forced to flee. With federal agents and the best bounty hunters in the nation massing on their heels, the gang must rob, steal and fight their way across the rugged heartland of America in order to survive. As deepening internal divisions threaten to tear the gang apart, Arthur must make a choice between his own ideals and loyalty to the gang who raised him.From the creators of Grand Theft Auto V and Red Dead Redemption, Red Dead Redemption 2 is an epic tale of life in America at the dawn of the modern age.', 17, 1, '2018-10-26');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,2);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(7,2);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,2);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,2);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(6,2);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('PAYDAY 2'), 'PAYDAY 2 is an 0-packed, four-player 9 6 that once again lets gamers don the masks of the original PAYDAY crew - Dallas, Hoxton, Wolf and Chains - as they descend on Washington DC for an epic crime spree. The new CRIMENET network offers a huge range of dynamic contracts, and players are free to choose anything from small-time convenience store hits or kidnappings, to big league cyber-crime or emptying out major bank vaults for that epic PAYDAY. While in DC, why not participate in the local community, and run a few political errands?Up to four friends 9erate on the hits, and as the crew progresses the jobs become bigger, better and more rewarding. Along with earning more money and becoming a legendary criminal comes a new character customization and crafting system that lets crews build and customize their own guns and gear.', 24, 1, '2013-08-13');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,3);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(7,3);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,3);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,3);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,3);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,3);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,3);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,3);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('PAYDAY 2 - San Martin Bank Heist'), 'The Payday Gang is down in Mexico, preparing to hit a small town bank that has ties to a powerful drug cartel.' ||
                                                                                                                              '
A Bank Down South
This is a one-day heist taking place in the small and sleepy Mexican town of San Martín, which is about to receive a rude awakening as the Payday Gang arrives to hit the local bank.

This DLC sees the Mexican police force make its debut appearance in PAYDAY 2, and players will find that the Mexican SWAT officers are every bit as tough as their US counterparts.

The heist is available in both stealth and loud, and has a variety of preplanning options to allow players to customize their approach.', 24, 2, '2020-02-27');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,4);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(7,4);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,4);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,4);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,4);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,4);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,4);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,4);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Rocket League'), 'What do soccer and cars have in common? Neither of them are as cool as Rocket League. This one-of-a-kind competition lets you drive a custom vehicle in a revamped soccer arena. Roll up the walls, do sick tricks, and try to smash the ball into your opponents goal. Rocket League is a hugely popular game from a tiny studio. They started out on PS3 with Supersonic Acrobatic Rocket-Powered Battle Cars in 2008 and have leveled up their game in the years since then. The latest game from the designers at Psyonix was nominated for hundreds of awards in 2015 when it released including Game of the Year! Critics love it, fans cant stop playing it. So the only question is: why dont you have it already? Buy Rocket League today and boost into 0!', 28, 1, '2015-07-07');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,5);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,5);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(10,5);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,5);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,5);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,5);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,5);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Battlefield V'), 'With Battlefield V, the series goes back to its roots in a never-before-seen portrayal of World War 2. Take on physical, all-out multiplayer with your squad in modes like the vast Grand Operations and the cooperative Combined Arms, or witness human drama set against global combat in the single player War Stories. As you fight in epic, unexpected locations across the globe, enjoy the richest and most immersive Battlefield yet.World War 2 as youve never seen it before Get ready to immerse yourself in iconic World War 2 0 - from paratrooper assaults to tank warfare. Charge into pivotal battles in the early days of the war for an experience unlike any other. This isnt the World War 2 youve come to expect - this is Battlefield V. Customize your soldiersYour journey through the world of Battlefield V starts with your Company - where every soldier is unique. Create and customize soldiers,weapons and vehicles, from the way they look to how they play.', 10, 1, '2018-09-04');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,6);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,6);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11, 6);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,6);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,6);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,6);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Battlefield 4'), 'Take 0 and rise above the chaos in Battlefield 4. This FPS from Electronic Arts is part of a genre-defining series that fans love and critics praise. In BF4 you can experience a new level of reality. Good soldiers are needed on the frontlines to lead the way. Immerse yourself in an epic single player story that puts you in the heat of the battle. The intense graphics and completely destructible environment make this Battlefield feel incredible. Master your weapons and take the fight online with great multiplayer capability. Buy it and see for yourself.FeaturesControl the battle - You decide how things happen in Battlefield 4. This game is designed to be totally interactive, allowing you more choices than in any previous Battlefield game. Explosives, bullets, and collisions have a serious impact on the environment. You can take down a building, or unleash a flood on your enemies. Even the car alarms work! When you play Battlefield 4 you re not just seeing destruction, you re experiencing it first-hand. Get creative with your strategy and experience a new way of gaming. Youve played 6s before, but this game is about strategy and tactics more than just holding down the trigger. Are you smart enough to survive the war of tomorrow?Fight for the future - Battlefield 4 offers an exciting single player campaign which takes place in the not-so-distant future. The world powers are at eachothers throats and your elite squad, the Tombstone, must work to restore balance. Make use of high-tech explosives, guns, and surveillance gear to stay one step ahead of your enemies. There are four main classes with multiple specializations to choose from. Are you a support focused player? A friendly medic? Or a deadly sniper? If you like to blow things up, try the Engineers toolkit. The future of war is waiting for you. Find your place in Battlefield.Battle anywhere - Take the fight to the skies or to the seas. Battlefield 4 offers you the opportunity to engage in naval combat, pilot planes, and drive tanks. Vehicles are an awesome feature of both the campaign and online gameplay. Get behind the wheel of every combat vehicle you can imagine. Different scenarios come with unique challenges, and special ways to blow stuff up! Play through the campaign on your own and then take your skills online. Multiplayer in BF4 is strategic and intense. There are tons of other players online that you can learn from and get to know. Don t worry about getting bored because there are tons of expansion packs to pick up. Once you get into Battlefield 4, you ll keep coming back for more. Buy it today and add a game to your library that you wont ever forget.', 19, 1, '2013-10-29');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,7);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,7);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,7);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,7);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,7);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,7);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,7);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,7);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('FIFA 20'), 'Play the beautiful game the way you want with various forms of 3v3, 4v4, and 5v5 both with and without walls, as well as Professional Futsal. Or, take your unique player through the VOLTA Story Mode culminating in the VOLTA World Championship in Buenos Aires. Find out more about VOLTA Football in FIFA 20 here. Experience the new Football Intelligence system which unlocks an unprecedented platform of football realism, putting you at the centre of every match in FIFA 20.Authentic Game Flow gives players more awareness of time, space, and positioning, putting greater emphasis on your play. You ll also have more control over the Decisive Moments that decide the outcome of games in both attack and defence with a Set Piece Refresh, Controlled Tackling, and Composed Finishing. Finally, the Ball Physics System offers new shot trajectories, more realistic tackle inter0s, and physics-driven behaviour, elevating gameplay to a new level of realism.', 6, 1, '2019-09-10');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,8);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(9,8);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,8);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,8);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,8);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,8);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,8);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('F1 2019'), 'The official videogame of the 2019 FIA FORMULA ONE WORLD CHAMPIONSHIP™, F1® 2019 challenges you to Defeat your Rivals in the most ambitious F1® game in Codemasters’ history.F1® 2019 features all the official teams, drivers and all 21 circuits from the 2019 season. This year sees the inclusion of F2™ with players being able to complete the 2018 season with the likes of George Russell, Lando Norris and Alexander Albon.With greater emphasis on graphical fidelity, the environments have been significantly enhanced, and the tracks come to life like never before. Night races have been completely overhauled creating vastly improved levels of realism and the upgraded F1® broadcast sound and visuals add further realism to all aspects of the race weekend.', 13, 1, '2019-06-25');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,9);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,9);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,9);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,9);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,9);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,9);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('DIRT RALLY'), 'GDiRT Rally is the most authentic and thrilling rally game ever made, road-tested over 80 million miles by the DiRT community. It perfectly captures that white knuckle feeling of racing on the edge as you hurtle along dangerous roads at breakneck speed, knowing that one crash could irreparably harm your stage time. DiRT Rally also includes officially licensed World Rallycross content, allowing you to experience the breathless, high-speed thrills of some of the world’s fastest off-road cars as you trade paint with other drivers at some of the series’ best-loved circuits, in both singleplayer and high-intensity multiplayer races.', 7, 1, '2015-12-07');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,10);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,10);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,10);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,10);

INSERT INTO products(name,description, picture_id,category_id,launch_date)VALUES (UPPER('Project CARS 2'), 'THE ULTIMATE DRIVER JOURNEY! Project CARS 2 delivers the soul of motor racing in the world’s most beautiful, authentic, and technically-advanced racing game.', 14, 1, '2017-09-21');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,11);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,11);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,11);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,11);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,11);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,11);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Pro Cycling Manager 2019'), 'Manage your own team of professional cyclists in the new 2019 season. Take the lead in over 200 races and 600 stages around the world and try to win legendary races like La Vuelta and the Tour de France. Manage, negotiate contracts and land new sponsors, plan your training and strategy, and execute your tactics during races to pedal your way to victory!Pull on the jersey of a professional cyclist and pursue your career to become a champion in Pro Cyclist mode. Compete against or team up with your friends in Online mode with up to 16 players. Solo or online, be the best to take your team to the top.', 22, 1, '2019-06-27');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,12);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,12);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(11,12);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,12);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Mount & Blade 2'), 'The horns sound, the ravens gather. An empire is torn by civil war. Beyond its border, new kingdoms rise. Gird on your sword, don your armour, summon your followers and ride forth to win glory on the battlefields of Calradia. Establish your hegemony and create a new world out of the ashes of the old. Mount & Blade II: Bannerlord is the eagerly awaited sequel to the acclaimed medieval combat simulator and role-playing game Mount & Blade: Warband. Set 200 years before, it expands both the detailed fighting system and the world of Calradia. Bombard mountain fastnesses with siege engines, establish secret criminal empires in the back alleys of cities, or charge into the thick of chaotic battles in your quest for power.', 30, 1, '2020-03-30');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,13);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,13);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,13);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,13);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,13);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,13);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,13);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Age of Empires 2: Definitive Edition'), 'Age of Empires II: Definitive Edition celebrates the 20th anniversary of one of the most popular strategy games ever with stunning 4K Ultra HD graphics, a new and fully remastered soundtrack, and brand-new content, “The Last Khans” with 3 new campaigns and 4 new civilizations.Explore all the original campaigns like never before as well as the best-selling expansions, spanning over 200 hours of gameplay and 1,000 years of human history. Head online to challenge other players with 35 different civilizations in your quest for world domination throughout the ages. Choose your path to greatness with this definitive remaster to one of the most beloved strategy games of all time.', 12, 1, '2019-11-14');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,14);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,14);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,14);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,14);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Cities: Skylines'), 'Cities: Skylines is a modern take on the classic city 5. The game introduces new game play elements to realize the thrill and hardships of creating and maintaining a real city whilst expanding on some well-established tropes of the city building experience. From the makers of the Cities in Motion franchise, the game boasts a fully realized transport system. It also includes the ability to mod the game to suit your play style as a fine counter balance to the layered and challenging 5. You’re only limited by your imagination, so take control and reach for the sky!', 18, 1, '2015-03-10');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,15);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,15);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,15);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,15);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,15);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,15);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,15);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Europa Universalis IV'), 'Fulfill your quest for global domination! Paradox Development Studio is back with the fourth installment of the award-winning Europa Universalis series. The empire building game Europa Universalis IV gives you control of a nation to guide through the years in order to create a dominant global empire. Rule your nation through the centuries, with unparalleled freedom, depth and historical accuracy. True exploration, trade, warfare and diplomacy will be brought to life in this epic title rife with rich strategic and tactical depth.', 23, 1, '2013-08-13');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,16);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,16);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,16);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,16);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Civilization V'), 'Become Ruler of the World by establishing and leading a civilization from the dawn of man into the space age: Wage war, conduct diplomacy, discover new technologies, go head-to-head with some of history’s greatest leaders and build the most powerful empire the world has ever known.', 27, 1, '2010-09-21');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,17);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,17);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,17);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,17);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Watch Dogs 2'), 'The sequel to Watch Dogs has been announced, and is now right around the corner. Buy the game today to immerse yourself in the world of hackers mixed with a little violence to help you achieve your sought after goal. From the makers of the Best 0/2 Game of 2013 from the E3 Game Critics Awards, Watch Dogs, we are presented with Watch Dogs 1, a sequel which will see gameplay take place in a different city, San Francisco.', 31, 1, '2016-11-15');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,18);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,18);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,18);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,18);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,18);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,18);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Assassin''s Creed Brotherhood'), 'Live and breathe as Ezio, a legendary Master Assassin, in his enduring struggle against the powerful Templar Order. He must journey into Italy’s greatest city, Rome, center of power, greed and corruption to strike at the heart of the enemy. Defeating the corrupt tyrants entrenched there will require not only strength, but leadership, as Ezio commands an entire Brotherhood who will rally to his side. Only by working together can the Assassins defeat their mortal enemies.And for the first time, introducing an award-winning multiplayer layer that allows you to choose from a wide range of unique characters, each with their own signature weapons and assassination techniques, and match your skills against other players from around the world.It’s time to join the Brotherhood.', 29, 1, '2010-11-16');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,19);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,19);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,19);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,19);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,19);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,19);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,19);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,19);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Minecraft'), 'Explore randomly generated worlds and build amazing things from the simplest of homes to the grandest of castles. Play in creative mode with unlimited resources or mine deep into the world in survival mode, crafting weapons and armor to fend off the dangerous mobs. Craft, create, and explore alone, or with friends on mobile devices or Windows 10. Millions of crafters around the world have smashed billions of blocks - now you can join in the fun on Windows 10! ', 8, 1, '2009-05-17');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,20);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,20);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,20);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,20);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('The Crew 2'), 'The newest iteration in the revolutionary franchise, The Crew® 2 captures the thrill of the American motorsports spirit in one of the most exhilarating open worlds ever created. Welcome to Motornation, a huge, varied, 0-packed, and beautiful playground built for motorsports throughout the entire US of A. Enjoy unrestrained exploration on ground, sea, and sky. From coast to coast, street and pro racers, off-road explorers, and freestylers gather and compete in all kinds of disciplines. Join them in high-octane contests and share every glorious moment with the world.', 20, 1, '2018-06-29');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,21);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,21);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,21);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,21);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,21);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,21);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Assassin''s Creed Unity'), 'Paris, 1789. The French Revolution turns a once-magnificent city into a place of terror and chaos. Its cobblestone streets run red with the blood of commoners who dared to rise up against the oppressive aristocracy. As the nation tears itself apart, a young man named Arno will embark on an extraordinary journey to expose the true powers behind the Revolution. His pursuit will throw him into the middle of a ruthless struggle for the fate of a nation, and transform him into a true Master Assassin. Introducing Assassin s Creed Unity, the next-gen evolution of the blockbuster franchise powered by an all-new game engine. From the storming of the Bastille to the execution of King Louis XVI, experience the French Revolution as never before, and help the people of France carve an entirely new destiny.', 16, 1, '2014-11-11');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,22);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,22);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,22);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,22);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,22);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,22);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Grand Theft Auto III'), 'The sprawling crime epic that changed open-world games forever.Welcome to Liberty City. Where it all began. The critically acclaimed blockbuster Grand Theft Auto III brings to life the dark and seedy underworld of Liberty City. With a massive and diverse open world, a wild cast of characters from every walk of life and the freedom to explore at will, Grand Theft Auto III puts the dark, intriguing and ruthless world of crime at your fingertips.With stellar voice acting, a darkly comic storyline, a stunning soundtrack and revolutionary open-world gameplay, Grand Theft Auto III is the game that defined the open world genre for a generation.', 9, 1, '2001-10-22');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(2,23);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(7,23);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(8,23);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,23);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,23);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,23);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(5,23);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,23);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('The Elder Scrolls V - Skyrim'), ' true, full-length open-world game for VR has arrived from award-winning developers, Bethesda Game Studios. Skyrim VR reimagines the complete epic fantasy masterpiece with an unparalleled sense of scale, depth, and immersion. From battling ancient dragons to exploring rugged mountains and more, Skyrim VR brings to life a complete open world for you to experience any way you choose. Skyrim VR includes the critically-acclaimed core game and official add-ons – Dawnguard, Hearthfire, and Dragonborn. Dragons, long lost to the passages of the Elder Scrolls, have returned to Tamriel and the future of the Empire hangs in the balance. As Dragonborn, the prophesied hero born with the power of The Voice, you are the only one who can stand amongst them.', 21, 1, '2011-11-11');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,24);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,24);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(3,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(4,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(8,24);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,24);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Witcher 3'), 'The Witcher 3: Wild Hunt Game of the Year edition brings together the base game and all the additional content released to date. Includes the Hearts of Stone and Blood & Wine expansions, which offer a massive 50 hours of additional storytelling as well as new features and new areas that expand the explorable world by over a third! Affords access to all additional content released so far, including weapons, armor, side quests, game modes and new GWENT cards! Features all technical and visual updates as well as a new user interface completely redesigned on the basis of feedback from members of the Witcher Community. Become a professional monster slayer and embark on an 2 of epic proportions! Upon its release, The Witcher 3: Wild Hunt became an instant classic, claiming over 250 Game of the Year awards. Now you can enjoy this huge, over 100-hour long, open-world 2 along with both its story-driven expansions worth an extra 50 hours of gameplay. This edition includes all additional content - new weapons, armor, companion outfits, new game mode and side quests.', 5, 1, '2015-05-19');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,25);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,25);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(3,25);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,25);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,25);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,25);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,25);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('The Sims 4 - Cats & Dogs 1'), 'Create a variety of cats and dogs, add them to your Sims’ homes to forever change their lives and care for neighbourhood pets as a veterinarian with The Sims™ 4 Cats & Dogs. The powerful new Create A Pet tool lets you personalise cats and dogs, each with their own unique appearances, distinct behaviours and for the first time, expressive outfits! These wonderful, lifelong companions will change your Sims’ lives in new and special ways. Treat animal ailments as a veterinarian and run your own clinic in a beautiful coastal world where there’s so much for your Sims and their pets to discover.', 15, 1, '2017-11-10');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,26);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(3,26);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,26);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,26);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,26);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Euro Truck Simulator 2 - Vive la France') , 'Vive la France ! is a large map expansion add-on for Euro Truck Simulator 2. Make your way through broad boulevards of industrial cities and narrow streets of rural hamlets. Enjoy French outdoors with its diverse looks and disparate vegetation from north to south. Discover famous landmarks, deliver to expansive industrial areas, navigate complex intersections and interchanges, enjoy visually unique roundabouts inspired by real locations. Transport a variety of new cargo to service new local French companies as well as connecting the region to the rest of Europe.', 26, 1, '2012-10-19');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,27);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,27);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,27);

INSERT INTO products(name,description, picture_id,category_id, launch_date)VALUES (UPPER('Europa Universalis IV - Wealth of Nations Expansion'), 'Wealth of Nations is the second expansion for the critically praised strategy game Europa Universalis IV, focusing on trade and how to make the wealth of the world flow into your coffers. The expansion allows you to create trade conflicts in secret, steal from your competitors with the use of privateers, use peace treaties to gain trade power and create a new trade capital to strengthen your grasp over trade. The age of exploration is brought to life in this epic game of trade, diplomacy, warfare and exploration by Paradox Development Studio, the Masters of Strategy. Europa Universalis IV gives you control of a nation to rule an empire that lasts through the ages.', 25, 3, '2014-05-29');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,28);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(6,28);
INSERT INTO product_has_genres(genre_id, product_id)VALUES(12,28);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,28);

INSERT INTO products(name,description, picture_id,category_id,deleted, launch_date)VALUES (UPPER('DRAGON BALL FighterZ'), 'DRAGON BALL FighterZ is born from what makes the DRAGON BALL series so loved and famous: endless spectacular fights with its all-powerful fighters.', 3, 1, TRUE, '2018-01-26');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,29);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,29);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,29);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,29);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(9,29);

INSERT INTO products(name,description, picture_id,category_id,deleted, launch_date)VALUES (UPPER('Shenmue I & II'), 'Originally released for the Dreamcast in 2000 and 2001, Shenmue I & II is an open world action 2 combining jujitsu combat, investigative sleuthing, RPG elements, and memorable mini-games. It pioneered many aspects of modern gaming, including open world city exploration, and was the game that coined the Quick Time Event (QTE). It was one of the first games with a persistent open world, where day cycles to night, weather changes, shops open and close and NPCs go about their business all on their own schedules. Its engrossing epic story and living world created a generation of passionate fans, and the game consistently makes the list of “greatest games of all time”.', 4, 1, TRUE, '2018-08-21');
INSERT INTO product_has_genres(genre_id, product_id)VALUES(1,30);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(1,30);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(3,30);
INSERT INTO product_has_platforms(platform_id, product_id)VALUES(7,30);

-- users images
INSERT INTO pictures (url)VALUES('7b28b3589283f938bd68c2941d0d69d5.png');
INSERT INTO pictures (url)VALUES('8d3e8eb63f8681d36f182a9d80e73c5a.png');
INSERT INTO pictures (url)VALUES('2bd8cc3a6021fe4ea0f6bf3ce8575efc.png');
INSERT INTO pictures (url)VALUES('c03a67ae76e1937cc8f5b741f264e71a.png');
INSERT INTO pictures (url)VALUES('557a2acefd26cbecbd832951aaa66c16.png');
-- users
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('motapinto', 'martimpintodasilva@gmail.com', 'Hey there! I am a software engineer and i am looking forward to trade with you', '''engin'':8 ''forward'':13 ''hey'':2 ''look'':12 ''motapinto'':1 ''softwar'':7 ''trade'':15', '''engin'':8B ''forward'':13B ''hey'':2B ''look'':12B ''motapinto'':1A ''softwar'':7B ''trade'':15B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', null, '1998-12-05', null, 1, 0, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('trustlessuser123', 'trustlessuser123@gmail.com', 'You should not, at all, trust me. Even then, there are some fools who will :)', '''even'':9 ''fool'':14 ''trust'':7 ''trustlessuser123'':1', '''even'':9B ''fool'':14B ''trust'':7B ''trustlessuser123'':1A', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 100, '0200-02-11', null, 32, 4, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('lpvramos', 'up201706253@g.uporto.com', 'Doom and CS addict sometimes. When I am not that i am a game connoisseur  looking for some good deals', '''addict'':5 ''connoisseur'':16 ''cs'':4 ''deal'':21 ''doom'':2 ''game'':15 ''good'':20 ''look'':17 ''lpvramo'':1 ''sometim'':6', '''addict'':5B ''connoisseur'':16B ''cs'':4B ''deal'':21B ''doom'':2B ''game'':15B ''good'':20B ''look'':17B ''lpvramo'':1A ''sometim'':6B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 100, '1949-06-21', null, 34, 1, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('lockdown', 'kkeelinge1p@g.co', 'Bootstrap master by day, Trader by night', '''bootstrap'':2 ''day'':5 ''lockdown'':1 ''master'':3 ''night'':8 ''trader'':6', '''bootstrap'':2B ''day'':5B ''lockdown'':1A ''master'':3B ''night'':8B ''trader'':6B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 75, '1968-06-10', null, 33, 11, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('arubenruben', 'lhumberstone1q@topsy.com', 'Hey! I am the one you gave up on google login. Ban me if you think that was the wrong move', '''arubenruben'':1 ''ban'':13 ''gave'':8 ''googl'':11 ''hey'':2 ''login'':12 ''move'':22 ''one'':6 ''think'':17 ''wrong'':21', '''arubenruben'':1A ''ban'':13B ''gave'':8B ''googl'':11B ''hey'':2B ''login'':12B ''move'':22B ''one'':6B ''think'':17B ''wrong'':21B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', null, '1972-03-11', null, 35, 0, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('odin123', 'odinMaster@valhalla.god', 'If you want to join me in Valhalla buy from me.', '''buy'':10 ''join'':6 ''odin123'':1 ''valhalla'':9 ''want'':4', '''buy'':10B ''join'':6B ''odin123'':1A ''valhalla'':9B ''want'':4B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 33, '1989-08-20', null, 1, 5, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('ragnarok', 'ragnarok@gmail.com', 'No introductions needed', '''introduct'':3 ''need'':4 ''ragnarok'':1', '''introduct'':3B ''need'':4B ''ragnarok'':1A', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 100, '1991-07-25', null, 1, 2, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('yodajedi', 'yodajedi@gmail.com', 'I am really good person. May the force be with you', '''forc'':9 ''good'':5 ''may'':7 ''person'':6 ''realli'':4 ''yodajedi'':1', '''forc'':9B ''good'':5B ''may'':7B ''person'':6B ''realli'':4B ''yodajedi'':1A', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 60, '1960-10-10', null, 1, 5, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('sithloard', 'sithloard@gmail.com', 'You either buy from me or dont buy at all', '''buy'':4,9 ''dont'':8 ''either'':3 ''sithloard'':1', '''buy'':4B,9B ''dont'':8B ''either'':3B ''sithloard'':1A', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', null, '1990-02-11', null, 1, 0, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('enzioauditore', 'enzioauditore@gmail.com', 'I am part of an Assassin''s creed and fight for justice and good commercial relationships', '''assassin'':7 ''commerci'':16 ''creed'':9 ''enzioauditor'':1 ''fight'':11 ''good'':15 ''justic'':13 ''part'':4 ''relationship'':17', '''assassin'':7B ''commerci'':16B ''creed'':9B ''enzioauditor'':1A ''fight'':11B ''good'':15B ''justic'':13B ''part'':4B ''relationship'':17B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 100, '1991-04-26', null, 1, 5, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('bjornironside', 'bjornironside@gmail.com', 'I am the true successor of Ragnar LothBrok', '''bjornironsid'':1 ''lothbrok'':9 ''ragnar'':8 ''successor'':6 ''true'':5', '''bjornironsid'':1A ''lothbrok'':9B ''ragnar'':8B ''successor'':6B ''true'':5B', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 42, '1948-08-12', null, 1, 10, null);
INSERT INTO users (username, email, description, name_tsvector, weight_tsvector, password, rating, birth_date, paypal, picture_id, num_sells, remember_token) VALUES ('ssn', 'up310021@g.uporto.pt', 'LBAW professor', '''lbaw'':2 ''professor'':3 ''ssn'':1', '''lbaw'':2B ''professor'':3B ''ssn'':1A', '$2y$10$PA30ELTzJN7HOUSZ./TyQOBAT6fUntWicXLQiXxWPFu/LKU456yn6', 66, '1958-09-14', null, 36, 4, null);

-- banned users
INSERT INTO banned_users(id)VALUES(1);
INSERT INTO banned_users(id)VALUES(5);
INSERT INTO banned_users(id)VALUES(9);

-- admins
INSERT INTO admins (username, email, description, password, picture_id)VALUES('admin', 'admin@keyhare.com', 'Hello. Welcome to my Profile.', '$2y$10$.8Ql.bH9QsbCQMKNf5XR6Oz.4yt8/i0mKEy4EcX7prMZtG3jsuJ22', 1);
INSERT INTO admins (username, email, description, password, picture_id)VALUES('ssn', 'up310021@g.uporto.pt', 'LBAW teacher and comercial master moderator', '$2y$10$PA30ELTzJN7HOUSZ./TyQOBAT6fUntWicXLQiXxWPFu/LKU456yn6', 36);

-- ban appeals
INSERT INTO ban_appeals(id, ban_appeal, date)VALUES(5, 'I swear i will never sell to third parties. Please forgive me! This is my job!!', '2020-02-25');
INSERT INTO ban_appeals(id, ban_appeal, date)VALUES(9, 'Just because i am a sith that does not mean i not a good community member. I think there was a mistake', '2020-05-12');

-- offers
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (15.99, '2020-06-04', null, 99.98, 7, 6, 15, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (49.99, '2020-06-04', null, 0, 3, 12, 8, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (19.99, '2020-06-04', '2020-06-07', 0, 7, 12, 5, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (12.99, '2020-06-04', '2020-06-07', 0, 7, 8, 6, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (9.99, '2020-06-04', '2020-06-07', 9.99, 1, 6, 25, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (3.99, '2020-06-04', '2020-06-07', 3.99, 9, 8, 24, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (59.99, '2020-06-04', '2020-06-07', 209.96, 3, 12, 22, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (4.99, '2020-06-04', '2020-06-07', 0, 4, 7, 4, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (49.99, '2020-06-04', '2020-06-07', 0, 9, 12, 13, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (20.99, '2020-06-04', '2020-06-07', 0, 1, 7, 14, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (79.99, '2020-06-04', null, 0, 3, 3, 18, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (12.99, '2020-06-04', null, 39.98, 1, 7, 20, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (17.99, '2020-06-04', '2020-06-07', 71.96, 1, 11, 28, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (12.99, '2020-06-04', '2020-06-07', 0, 1, 10, 17, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (49.99, '2020-06-04', null, 0, 3, 4, 11, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (7.99, '2020-06-04', null, 0, 1, 11, 10, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (22.99, '2020-06-04', null, 0, 1, 10, 9, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (39.99, '2020-06-04', '2020-06-05', 9.99, 1, 4, 16, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (8.99, '2020-06-04', null, 0, 1, 7, 14, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (44.99, '2020-06-04', null, 0, 7, 11, 18, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (5.99, '2020-06-04', null, 0, 7, 4, 7, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (2.99, '2020-06-04', '2020-06-07', 2.99, 1, 10, 27, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (25.99, '2020-06-04', null, 0, 3, 6, 9, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (25.99, '2020-06-04', null, 0, 7, 3, 15, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (12.99, '2020-06-04', null, 0, 1, 6, 12, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (1, '2020-06-04', null, 0, 1, 6, 20, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (19.99, '2020-06-04', '2020-06-07', 19.99, 3, 3, 26, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (1.99, '2020-06-04', null, 0, 1, 12, 12, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (15.99, '2020-06-04', null, 0, 3, 10, 25, 7);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (27.88, '2020-06-04', null, 25.98, 3, 6, 9, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (15.99, '2020-06-04', null, 3.99, 1, 10, 13, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (8.99, '2020-06-04', null, 0, 1, 12, 19, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (29.99, '2020-06-04', null, 0, 1, 3, 20, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (17.99, '2020-06-04', null, 0, 1, 12, 6, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (1.99, '2020-06-04', '2020-06-07', 5.9700003, 1, 11, 23, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (9.99, '2020-06-04', '2020-06-07', 0, 7, 4, 21, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (13.99, '2020-06-04', null, 0, 7, 11, 11, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (6.99, '2020-06-04', '2020-06-07', 0, 1, 11, 25, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (1, '2020-06-05', '2020-06-07', 0, 4, 4, 3, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (20, '2020-06-05', null, 40, 4, 4, 1, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (69.99, '2020-06-05', '2020-06-05', 139.98, 6, 4, 2, 0);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (34.99, '2020-06-05', null, 69.98, 3, 4, 9, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (10.99, '2020-06-05', null, 43.96, 1, 4, 5, 1);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (20.99, '2020-06-05', null, 0, 3, 7, 9, 5);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (19.99, '2020-06-05', null, 0, 3, 6, 9, 5);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (12.88, '2020-06-05', null, 0, 1, 4, 9, 8);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (5.99, '2020-06-05', null, 17.97, 3, 10, 9, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (15.99, '2020-06-05', null, 47.97, 3, 11, 9, 2);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (30, '2020-06-05', null, 0, 3, 11, 9, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (23.99, '2020-06-05', null, 95.96, 3, 8, 9, 6);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (9.89, '2020-06-05', null, 0, 3, 7, 9, 4);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (19.98, '2020-06-05', null, 0, 3, 7, 9, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (14.3, '2020-06-05', null, 57.2, 3, 2, 9, 3);
INSERT INTO offers (price, init_date, final_date, profit, platform_id, user_id, product_id, stock) VALUES (50.99, '2020-06-05', null, 0, 3, 2, 9, 8);

-- orders
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 7, 'dsffdfwea', 'adfseaf@dsg.com', 'adsfergreg', '4100-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 7, 'wefrfsegreggse', 'afd@sdfasdasd.com', 'sdfsdfsdfds', '3000-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 7, 'asdfdsfsfgsf', 'asdas2afdds@asddsf.com', 'asdasdkaslfasdasd', '4100-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 8, 'pkfsdofjnndf', 'asdknwasf@asfasf.com', 'oknfepfjnreponf', '1111-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 10, 'TRGTG', 'asaf@afd.com', 'DSFSDFSD', '1341-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 10, 'jblkpbjpijbipbpb', 'bihbii@adafd.com', 'dasdsadsad', '3100-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 11, 'hjjhkhvkhkvhbhbhasdf', 'adlfndlsd@adfa.com', 'asdasibwfpabb', '1111-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 12, 'oaj dfvasfsdf', 'marrgrt@dsf.com', 'dsgsgrgyn', '1111-000');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 3, 'fdsfsfdf', 'fsdfsdfsdfsdf@email.com', 'fsdfsdfffs', 'fsdfsdfsf');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 7, 'ddasdad', 'email@email.coms', 'dasddasdasd', '23413');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 6, 'gffgfdgfdqg', 'email@emial.com', 'dfsdfsdff', '34343');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 10, 'fdfdsfsdfd', 'email@email.com', 'rua das ruas', '21323');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 10, 'enzio', 'italy@myfamily.com', 'address', '3333');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 4, 'Jose Guerra', 'dsadasdsa@email.com', 'sdadasd', '3434');
INSERT INTO orders (date, user_id, order_info_name, order_info_email, order_info_address, order_info_zipcode) VALUES ('2020-04-03', 4, 'Jose guerra', 'comander23@live.com.pt', 'asdasdadsda', 'd2222');

--discounts
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (20, '2020-06-04', '2020-06-13', 15);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (10, '2020-06-15', '2020-06-16', 15);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (40, '2020-06-18', '2020-06-19', 15);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (10, '2020-06-06', '2020-06-16', 42);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (5, '2020-06-09', '2020-06-13', 21);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (25, '2020-06-04', '2020-06-12', 46);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (10, '2020-06-04', '2020-06-13', 16);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (20, '2020-06-04', '2020-06-13', 48);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (10, '2020-06-04', '2020-06-15', 37);
INSERT INTO discounts (rate, start_date, end_date, offer_id) VALUES (15, '2020-06-04', '2020-06-13', 49);

-- keys
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdgnopre982341ndsl', 49.99, 1, 1);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ASDSF435658679I6UH', 9.99, 18, 2);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sgtrhtyj6757658', 19.99, 12, 3);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdferg35354435', 19.99, 12, 3);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdflk2424tergdqpkog', 49.99, 1, 4);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('jniibpbrbfvbfd', 12.99, 30, 5);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('wopnverojveqrve', 12.99, 30, 5);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('caojerjovnerabneearbn', 3.99, 31, 6);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('adfergSFGDG123213', 29.99, 7, 7);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('34365uyjasFDHKL235', null, 1, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfgrjt45765667SFG', null, 2, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdfgdfh456457SBH', null, 2, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('1234TGFBDSsdgfho54', 9.99, 5, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('12335ygyt7j76FDF', 3.99, 6, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('SCGW214346YH4T5H', 59.99, 7, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('SDFSDF234256UTYJGH', 59.99, 7, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('124345YYGFDGSDGFF32', 59.99, 7, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdgggghg66s2331r47', null, 11, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asfefg65787980ghfsd', null, 11, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asd-masdmlsm09091', null, 11, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asftrju6789dssvb-fh-n', null, 11, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('svffgbjyk456456', null, 12, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fdbhym7457567', null, 12, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('xvfgrhymjy57568', null, 12, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('o-knfgvgroptg23', 17.99, 13, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('wferth56u467567', 17.99, 13, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sadsadqweq123123', 17.99, 13, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdsfdsfsdfsdfq21212', 17.99, 13, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('DFD34536HGHDFGG', null, 16, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('SDERT3534543543TF', null, 16, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('AFDGRTH67658FDBD', null, 17, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('FDGFHTY456456DFGS', null, 17, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('DFSDGHTU646535REF', null, 17, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('frthyuy867854', null, 19, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asdsftuj786543', null, 19, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asdsfgy6u54rr', null, 20, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asdweryth6jyad', null, 20, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('adrth67u4rtyu76y', null, 20, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('moksfpeiruogh3940', null, 21, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdfo3i43o8u123123', 2.99, 22, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('qwadert3464543542', null, 23, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('12323rty5u67i6u7y6trf', null, 23, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('knjejhiweqohfqwgup', null, 23, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gepobpiwbgio0rub3r', null, 23, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dsfojpeorghwerphgpg', null, 24, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfohwerpoghpferbguwpre', null, 24, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('23oihpotwptop3btb4p', null, 25, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('23oihpotwptop3btb41', null, 25, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ob8wrgfbweaweg', null, 26, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('afopn3pugp93q4bpgqr', 19.99, 27, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('noppqbuhgrep9238042', null, 28, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('onpjqrnopebvepa', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdewio439785', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fwerijng', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('werwer', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('werwerwevdf', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('werfdfbsdc', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('qrdsdv', null, 29, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fvpoanvneav', null, 30, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('wefwiherpgiwhwppowg', null, 31, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('onkrqefe', null, 31, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('kjbkhbbhkhblkhbhl', null, 32, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('afsfdsfgsdgegera', null, 32, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ihbihoohvvhoo', null, 33, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('hhohvhvohvvh', null, 33, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ih778g86gyygog', null, 33, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ojajsfgbbrsgbazabr', null, 34, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ewrooraeeeeeba', null, 34, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgaarhjrzhgjjhgz', null, 34, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('jtujgkguikgjbuik', null, 34, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('aorghjjoahtfxoajoahthtx', 1.99, 35, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ilgghghllflfhllflfylyflfllffflyfy', 1.99, 35, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('jhgkghkghhgkhggkjggjh', 1.99, 35, 15);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ouuhuhhuhuhipilb', null, 37, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('jnbhiibhbhhbobihobih', null, 37, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('hblihbihbillibhibhlbkh', null, 37, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('igiglgigiibbobo', null, 37, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fsdfdgfigjngnewgregfg', 20, 40, 10);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fggfegfgwgfgefg', 20, 40, 11);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgaqgergqergreg', null, 40, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dsadgfgghghjngjnghjghghefhgfhehe', 69.99, 41, 9);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gdgfgfhjthyhghrtgh', 69.99, 41, 10);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fsdfhgtrhehgefdsghhg', 34.99, 42, 9);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('vgfbdfggergrhjjht', 34.99, 42, 11);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('egertgergergqgqwergerf', null, 42, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('rgregergergrqgergerg', null, 42, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('edfewfefwe', null, 42, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgrhghhgrhrghrhthrth', 10.99, 43, 9);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gfefwfwefwfwfwf', 10.99, 43, 10);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fwefwghgnhjhtjhjtrhkygeg', 10.99, 43, 11);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gegwfwerfefwffggf', 10.99, 43, 11);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gfhfgghfhghgh', null, 43, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fewfwfwfgefgghgrhrghjgjhjjghgfdcsvsdfdsvdvdvxc', null, 44, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('cxczxvzxcvcbcsvbscxczxczxcxcvscczxc', null, 44, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('cxzcxzcccdvfbghtjhykjollohfvdcdscsdc', null, 44, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dsfcsdfvdsfdfgdsadasdsdfcsvdfbgdfvbfbdgfdv', null, 44, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfvdfvdfvdfvfdsvdfvscvsdvcsdcvsddsvdsfv', null, 44, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('asdasddgfefgedfgfefg', null, 45, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('wdeffgdgw3fdfqwfwdfgvgh', null, 45, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dwfwedfwdfgeqfgeqfgefg', null, 45, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ffwf', null, 45, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fwfwfwfwdfsdfsdf', null, 45, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdasdasdasdsad', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sadasdsdsds', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sadfdfdfdfdsfs', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfdsfsdf', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fsdfdsfsdfdfdfgdfwgfd', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfgdwfdwfdwfdwf', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('efefdfdfdwfdwsfdswf', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfdfsdfdsfdsfsdf', null, 46, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('sdsadasdsadfgdsfsdfdf', 5.99, 47, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfwrgwrgfgrgrgrg', 5.99, 47, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fffgegegeeg', 5.99, 47, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgfefgegegwgwggg', null, 47, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ggrhrhwrggwegwgdgscsdgdsg', null, 47, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fdghvghbgjhkdghefgghgh', 15.99, 48, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gefghfhhjshfhfghefg', 15.99, 48, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgghjgfhhjgbhwghrfggdrfgwgfrg', 15.99, 48, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gfrghfdrhtrhthfhs', null, 48, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dgewrgbrhrghaetqete', null, 48, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fdfgfghfhfgfh', null, 49, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gewfgrhghjhjkhkhjkjhjh', null, 49, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('grgfegtrhrrhth', null, 49, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('bngjnhtkhjtkhgffgfdwfg', 23.99, 50, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gfhfeghegwfehgwgfwdgwdgdfweg', 23.99, 50, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('efre2frgrefhgghfgwfgwfwdf', 23.99, 50, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('344t34trgtfefegfeg', 23.99, 50, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('rffghfghrfter4trrt34t43tt', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gefgefg35rt3g34t34t', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('43t4ttrtfgfgfg', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('t43t43tet34t34t4t', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('gterwg354t3gefrgeg', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('34t4t34tggergt34t43rt3t5ygfhghgfrhu756768', null, 50, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('de5rt34rtyhjuuijuiefer342r34e2fre2edfef', null, 51, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('e2f2efef2ef2efrefrfgr3gr', null, 51, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fg3fef2r3fgdregfgwgfegffdgrg', null, 51, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('r32r32r3rtgrt5y5y53g3rg2ef2', null, 51, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('grf4ghy6th4rt4t24t2tg4t2y6h', null, 52, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('43r34tr244425r4h54rgh5rtrghfr', null, 52, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('2453yt5h356hj356nhjq5hq', null, 52, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ththj4tq4ytu4tyuyty', 14.3, 53, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('y5yty56tyututyjhutyh', 14.3, 53, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('yty4y564y54y45y4t5y564y', 14.3, 53, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('y45y45yy54y5y54y564yt4', 14.3, 53, 14);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('y5y5yt45yrt3erfgfvbghrg4hghgrh', null, 53, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('4rt34t43trtgrewgterwg', null, 53, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('34rtgreyh34rty3556245r23tds', null, 53, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('dfdgt4qtyhjw4trhjrgwhg', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('54fg4rtgy4ttghrtg3rg4gg', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('trg4tg4rt435r43tr4grgreg', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('4tg4t43rghfhrgjyhtjkyhtjjyhjtj', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('tr4t5341er3wfdsfsdgftfsdgrt', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fvgfge34rgefgbgfdbgwfergrgfrg', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('e2fswaf3qedfdgbferweerfg', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('rt342r2rtefwdrtfwer23rf2we2fw', null, 54, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fwedfwefwfwef', null, 15, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fwefgrghrgrg', null, 15, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('fgrghregrgrg', null, 15, null);
INSERT INTO keys (key, price_sold, offer_id, order_id) VALUES ('ffrgregggw', null, 15, null);


-- feedback
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Great product. Thank you!', '2020-06-07', 4, 111);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'the game is very slow and the seller didn''t fix it', '2020-06-07', 4, 112);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Liked this game!!!!!!!', '2020-06-07', 4, 113);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Hated the seller, never buy again', '2020-06-07', 4, 116);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (false, 'Great product. Thank you!', '2020-06-07', 4, 118);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Great product. Thank you!', '2020-06-07', 4, 125);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (false, 'Hate you', '2020-06-07', 4, 124);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (false, 'Hate you', '2020-06-07', 4, 126);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Yoda rules', '2020-06-07', 4, 127);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Adored the seller, should change name to trustworthy', '2020-06-07', 4, 141);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Adored the seller, should change name to trustworthy', '2020-06-07', 4, 142);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Odin Rules!!!!!!! ;) ;)', '2020-06-07', 7, 1);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'lockdown best in the world', '2020-06-07', 7, 2);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'ragnarok rocked my world', '2020-06-07', 7, 3);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Seller the best keep going', '2020-06-07', 7, 4);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (false, 'Odin rules', '2020-06-07', 8, 5);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Loved the game, seller was alright, would buy again', '2020-06-07', 3, 81);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (false, 'Boring game', '2020-06-07', 3, 83);
INSERT INTO feedback (evaluation, comment, evaluation_date, user_id, key_id) VALUES (true, 'Rocket league is very good', '2020-06-07', 3, 88);