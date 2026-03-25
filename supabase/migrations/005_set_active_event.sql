CREATE OR REPLACE FUNCTION set_active_event(p_user_id UUID, p_event_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE events SET is_active = false WHERE user_id = p_user_id AND is_active = true;
  UPDATE events SET is_active = true WHERE id = p_event_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
