-- Email Communication System - Database Schema
-- Creates tables for email tracking, notification preferences, and admin messages

-- =====================================================
-- 1. Email Notifications Table
-- =====================================================
-- Tracks all emails sent through the system

CREATE TABLE IF NOT EXISTS email_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Email Details
  recipient_email TEXT NOT NULL,
  recipient_name TEXT,
  sender_email TEXT DEFAULT 'orders@elnajar.com',
  sender_name TEXT DEFAULT 'Elnajar Store',
  
  -- Template & Content
  template_key TEXT NOT NULL,
  subject TEXT NOT NULL,
  body_html TEXT,
  body_text TEXT,
  
  -- Context
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Status Tracking
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'bounced')),
  sent_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  error_message TEXT,
  
  -- Metadata
  variables JSONB,
  email_provider TEXT DEFAULT 'resend',
  provider_message_id TEXT,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_notifications_order_id ON email_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_user_id ON email_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);
CREATE INDEX IF NOT EXISTS idx_email_notifications_created_at ON email_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_notifications_template_key ON email_notifications(template_key);

-- RLS Policies
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Admins can view all email notifications
CREATE POLICY "Admins can view all email notifications"
  ON email_notifications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can view their own email notifications
CREATE POLICY "Users can view own email notifications"
  ON email_notifications FOR SELECT
  USING (auth.uid() = user_id);

-- =====================================================
-- 2. Notification Preferences Table
-- =====================================================
-- Stores user email notification preferences

CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  
  -- Email Preferences
  order_confirmation BOOLEAN DEFAULT true,
  order_status_updates BOOLEAN DEFAULT true,
  order_shipped BOOLEAN DEFAULT true,
  order_delivered BOOLEAN DEFAULT true,
  order_cancelled BOOLEAN DEFAULT true,
  payment_updates BOOLEAN DEFAULT true,
  
  -- Marketing (Optional)
  promotional_emails BOOLEAN DEFAULT false,
  newsletter BOOLEAN DEFAULT false,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- RLS Policies
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users can view and update their own preferences
CREATE POLICY "Users can view own preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all preferences
CREATE POLICY "Admins can view all preferences"
  ON notification_preferences FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- 3. Admin Messages Table
-- =====================================================
-- Stores messages sent from admin to customers

CREATE TABLE IF NOT EXISTS admin_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Message Details
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Content
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  
  -- Status
  sent_via_email BOOLEAN DEFAULT true,
  email_notification_id UUID REFERENCES email_notifications(id) ON DELETE SET NULL,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_admin_messages_order_id ON admin_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_admin_messages_customer_id ON admin_messages(customer_id);
CREATE INDEX IF NOT EXISTS idx_admin_messages_created_at ON admin_messages(created_at DESC);

-- RLS Policies
ALTER TABLE admin_messages ENABLE ROW LEVEL SECURITY;

-- Admins can view and create all messages
CREATE POLICY "Admins can view all messages"
  ON admin_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can create messages"
  ON admin_messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Customers can view messages sent to them
CREATE POLICY "Customers can view own messages"
  ON admin_messages FOR SELECT
  USING (auth.uid() = customer_id);

-- =====================================================
-- 4. Automated Email Trigger Function
-- =====================================================
-- Automatically creates email notification records when orders change

CREATE OR REPLACE FUNCTION send_order_notification_emails()
RETURNS TRIGGER AS $$
DECLARE
  v_customer_email TEXT;
  v_customer_name TEXT;
  v_user_id UUID;
  v_template_key TEXT;
  v_subject TEXT;
BEGIN
  -- Get customer details
  SELECT customer_email, customer_name, user_id
  INTO v_customer_email, v_customer_name, v_user_id
  FROM orders
  WHERE id = NEW.id;
  
  -- On status change
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    -- Determine template based on new status
    v_template_key := CASE NEW.status
      WHEN 'confirmed' THEN 'order_confirmed'
      WHEN 'processing' THEN 'order_processing'
      WHEN 'shipped' THEN 'order_shipped'
      WHEN 'delivered' THEN 'order_delivered'
      WHEN 'cancelled' THEN 'order_cancelled'
      ELSE 'order_status_update'
    END;
    
    v_subject := 'Order Update - ' || NEW.order_number;
    
    -- Insert email notification request
    INSERT INTO email_notifications (
      recipient_email,
      recipient_name,
      template_key,
      subject,
      order_id,
      user_id,
      variables,
      status
    ) VALUES (
      v_customer_email,
      v_customer_name,
      v_template_key,
      v_subject,
      NEW.id,
      v_user_id,
      jsonb_build_object(
        'order_number', NEW.order_number,
        'old_status', OLD.status,
        'new_status', NEW.status,
        'customer_name', v_customer_name,
        'tracking_number', NEW.tracking_number,
        'estimated_delivery_date', NEW.estimated_delivery_date
      ),
      'pending'
    );
  END IF;
  
  -- On payment status change
  IF NEW.payment_status IS DISTINCT FROM OLD.payment_status THEN
    v_template_key := CASE NEW.payment_status
      WHEN 'paid' THEN 'payment_received'
      WHEN 'failed' THEN 'payment_failed'
      WHEN 'refunded' THEN 'refund_processed'
      ELSE 'payment_status_update'
    END;
    
    v_subject := 'Payment Update - ' || NEW.order_number;
    
    INSERT INTO email_notifications (
      recipient_email,
      recipient_name,
      template_key,
      subject,
      order_id,
      user_id,
      variables,
      status
    ) VALUES (
      v_customer_email,
      v_customer_name,
      v_template_key,
      v_subject,
      NEW.id,
      v_user_id,
      jsonb_build_object(
        'order_number', NEW.order_number,
        'payment_status', NEW.payment_status,
        'total_amount', NEW.total_amount,
        'customer_name', v_customer_name,
        'currency', NEW.currency
      ),
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS send_order_emails_trigger ON orders;
CREATE TRIGGER send_order_emails_trigger
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION send_order_notification_emails();

-- =====================================================
-- 5. Email Notification on Order Creation
-- =====================================================

CREATE OR REPLACE FUNCTION send_order_confirmation_email()
RETURNS TRIGGER AS $$
BEGIN
  -- Send order confirmation email
  INSERT INTO email_notifications (
    recipient_email,
    recipient_name,
    template_key,
    subject,
    order_id,
    user_id,
    variables,
    status
  ) VALUES (
    NEW.customer_email,
    NEW.customer_name,
    'order_confirmation',
    'Order Confirmation - ' || NEW.order_number,
    NEW.id,
    NEW.user_id,
    jsonb_build_object(
      'order_number', NEW.order_number,
      'total_amount', NEW.total_amount,
      'customer_name', NEW.customer_name,
      'currency', NEW.currency,
      'created_at', NEW.created_at
    ),
    'pending'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS send_order_confirmation_trigger ON orders;
CREATE TRIGGER send_order_confirmation_trigger
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION send_order_confirmation_email();

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON TABLE email_notifications IS 'Tracks all emails sent through the system with delivery status';
COMMENT ON TABLE notification_preferences IS 'Stores user email notification preferences';
COMMENT ON TABLE admin_messages IS 'Messages sent from admin to customers regarding orders';
COMMENT ON FUNCTION send_order_notification_emails() IS 'Automatically creates email notifications when order status or payment status changes';
COMMENT ON FUNCTION send_order_confirmation_email() IS 'Sends order confirmation email when new order is created';
