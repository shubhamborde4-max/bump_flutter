CREATE OR REPLACE FUNCTION public.activate_event(p_user_id uuid, p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Atomic: deactivate all, then activate target
  UPDATE public.events SET is_active = false WHERE user_id = p_user_id AND is_active = true;
  UPDATE public.events SET is_active = true, updated_at = now() WHERE id = p_event_id AND user_id = p_user_id;
END;
$$;
