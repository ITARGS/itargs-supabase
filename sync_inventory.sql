-- DYNAMIC INVENTORY MANAGEMENT SYSTEM

-- 1. Function to reduce stock when order items are added
CREATE OR REPLACE FUNCTION public.handle_inventory_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    current_stock INTEGER;
    prod_name TEXT;
BEGIN
    -- If it's a variant, update variant stock
    IF NEW.product_variant_id IS NOT NULL THEN
        SELECT stock_quantity, name INTO current_stock, prod_name 
        FROM public.product_variants WHERE id = NEW.product_variant_id;
        
        IF current_stock < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient stock for variant % (SKU: %). Available: %, Requested: %', 
                prod_name, (SELECT sku FROM public.product_variants WHERE id = NEW.product_variant_id), current_stock, NEW.quantity;
        END IF;

        UPDATE public.product_variants
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE id = NEW.product_variant_id;
    ELSE
        -- Update main product stock
        SELECT stock_quantity, name INTO current_stock, prod_name 
        FROM public.products WHERE id = NEW.product_id;

        IF current_stock < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient stock for product %. Available: %, Requested: %', 
                prod_name, current_stock, NEW.quantity;
        END IF;

        UPDATE public.products
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE id = NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to restore stock when order is cancelled
CREATE OR REPLACE FUNCTION public.handle_inventory_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
    current_stock INTEGER;
    prod_name TEXT;
BEGIN
    -- Only act if status CHANGED to 'cancelled'
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        FOR item IN (SELECT * FROM public.order_items WHERE order_id = NEW.id) LOOP
            IF item.product_variant_id IS NOT NULL THEN
                UPDATE public.product_variants
                SET stock_quantity = stock_quantity + item.quantity
                WHERE id = item.product_variant_id;
            ELSE
                UPDATE public.products
                SET stock_quantity = stock_quantity + item.quantity
                WHERE id = item.product_id;
            END IF;
        END LOOP;
    
    -- Optional: If status changed FROM 'cancelled' to something else (RE-OPENING)
    ELSIF OLD.status = 'cancelled' AND NEW.status != 'cancelled' THEN
        FOR item IN (SELECT * FROM public.order_items WHERE order_id = NEW.id) LOOP
            IF item.product_variant_id IS NOT NULL THEN
                SELECT stock_quantity, name INTO current_stock, prod_name 
                FROM public.product_variants WHERE id = item.product_variant_id;

                IF current_stock < item.quantity THEN
                    RAISE EXCEPTION 'Insufficient stock to re-open order. Product: %. Available: %, Needed: %', 
                        prod_name, current_stock, item.quantity;
                END IF;

                UPDATE public.product_variants
                SET stock_quantity = stock_quantity - item.quantity
                WHERE id = item.product_variant_id;
            ELSE
                SELECT stock_quantity, name INTO current_stock, prod_name 
                FROM public.products WHERE id = item.product_id;

                IF current_stock < item.quantity THEN
                    RAISE EXCEPTION 'Insufficient stock to re-open order. Product: %. Available: %, Needed: %', 
                        prod_name, current_stock, item.quantity;
                END IF;

                UPDATE public.products
                SET stock_quantity = stock_quantity - item.quantity
                WHERE id = item.product_id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create Triggers
DROP TRIGGER IF EXISTS tr_order_items_stock_insert ON public.order_items;
CREATE TRIGGER tr_order_items_stock_insert
AFTER INSERT ON public.order_items
FOR EACH ROW EXECUTE FUNCTION public.handle_inventory_on_insert();

DROP TRIGGER IF EXISTS tr_orders_stock_cancel ON public.orders;
CREATE TRIGGER tr_orders_stock_cancel
AFTER UPDATE OF status ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_inventory_on_status_change();
