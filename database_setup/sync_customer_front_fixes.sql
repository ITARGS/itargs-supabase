-- Consolidate addresses: Ensure addresses table has all data from customer_addresses if any
INSERT INTO addresses (user_id, full_name, phone, street_address, city, state, postal_code, country, is_default, created_at, updated_at)
SELECT user_id, full_name, phone, street_address, city, state, postal_code, country, is_default, created_at, updated_at 
FROM customer_addresses
ON CONFLICT DO NOTHING;

-- Drop redundant table (optional, but keep for safety for now or drop if we are sure)
-- DROP TABLE customer_addresses;

-- Create validate_discount RPC function
CREATE OR REPLACE FUNCTION validate_discount(p_code text, p_user uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_discount record;
    v_usage_count int;
    v_user_usage_count int;
    v_can_apply boolean := true;
    v_failure_reason text := null;
BEGIN
    -- Find the discount code
    SELECT * INTO v_discount FROM discount_codes 
    WHERE code = UPPER(p_code) AND is_active = true;

    IF v_discount.id IS NULL THEN
        RETURN jsonb_build_object(
            'can_apply', false,
            'failure_reason', 'invalid_code'
        );
    END IF;

    -- Check dates
    IF v_discount.start_date > NOW() THEN
        v_can_apply := false;
        v_failure_reason := 'not_started';
    ELSIF v_discount.end_date IS NOT NULL AND v_discount.end_date < NOW() THEN
        v_can_apply := false;
        v_failure_reason := 'expired';
    END IF;

    -- Check total usage limit
    IF v_can_apply AND v_discount.usage_limit IS NOT NULL THEN
        SELECT COUNT(*) INTO v_usage_count FROM orders WHERE discount_code = v_discount.code;
        IF v_usage_count >= v_discount.usage_limit THEN
            v_can_apply := false;
            v_failure_reason := 'usage_limit_reached';
        END IF;
    END IF;

    -- Check per-customer limit
    IF v_can_apply AND v_discount.one_per_customer = true AND p_user IS NOT NULL THEN
        SELECT COUNT(*) INTO v_user_usage_count FROM orders WHERE user_id = p_user AND discount_code = v_discount.code;
        IF v_user_usage_count > 0 THEN
            v_can_apply := false;
            v_failure_reason := 'already_used';
        END IF;
    END IF;

    -- Check first order only
    IF v_can_apply AND v_discount.first_order_only = true AND p_user IS NOT NULL THEN
        SELECT COUNT(*) INTO v_user_usage_count FROM orders WHERE user_id = p_user;
        IF v_user_usage_count > 0 THEN
            v_can_apply := false;
            v_failure_reason := 'not_first_order';
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'id', v_discount.id,
        'code', v_discount.code,
        'discount_type', v_discount.discount_type,
        'discount_value', v_discount.discount_value,
        'min_order_amount', v_discount.min_order_amount,
        'max_discount_amount', v_discount.max_discount_amount,
        'can_apply', v_can_apply,
        'failure_reason', v_failure_reason
    );
END;
$$;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
