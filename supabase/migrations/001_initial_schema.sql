-- ============================================================================
-- Bump App — Initial Database Schema
-- ============================================================================
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. PROFILES
-- ============================================================================
CREATE TABLE public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    text UNIQUE NOT NULL
              CHECK (username ~ '^[a-z0-9][a-z0-9_-]{2,29}$'),
  first_name  text NOT NULL DEFAULT '',
  last_name   text NOT NULL DEFAULT '',
  email       text NOT NULL DEFAULT '',
  phone       text DEFAULT '',
  company     text DEFAULT '',
  title       text DEFAULT '',
  avatar_url  text,
  linkedin    text,
  website     text,
  bio         text,
  card_style  text DEFAULT 'modern'
              CHECK (card_style IN ('modern', 'classic', 'minimal')),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- Public view for exchange lookups (limited columns)
CREATE VIEW public.public_profiles AS
SELECT id, username, first_name, last_name, company, title, avatar_url
FROM public.profiles;

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view any profile"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 2. EVENTS
-- ============================================================================
CREATE TABLE public.events (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  date        timestamptz NOT NULL,
  end_date    timestamptz,
  location    text DEFAULT '',
  description text DEFAULT '',
  is_active   boolean DEFAULT false,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_events_user_id ON public.events(user_id);

-- RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own events"
  ON public.events FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 3. PROSPECTS
-- ============================================================================
CREATE TABLE public.prospects (
  id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id        uuid REFERENCES public.events(id) ON DELETE SET NULL,
  exchanged_with  uuid REFERENCES auth.users(id),
  first_name      text NOT NULL DEFAULT '',
  last_name       text NOT NULL DEFAULT '',
  email           text DEFAULT '',
  phone           text DEFAULT '',
  company         text DEFAULT '',
  title           text DEFAULT '',
  avatar_url      text,
  linkedin        text,
  notes           text DEFAULT '',
  status          text DEFAULT 'new'
                  CHECK (status IN ('new', 'contacted', 'interested', 'converted', 'archived')),
  exchange_method text NOT NULL DEFAULT 'qr'
                  CHECK (exchange_method IN ('qr', 'nfc', 'link', 'bump', 'manual')),
  exchange_time   timestamptz DEFAULT now(),
  tags            text[] DEFAULT '{}',
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_prospects_user_id ON public.prospects(user_id);
CREATE INDEX idx_prospects_user_event ON public.prospects(user_id, event_id);
CREATE INDEX idx_prospects_user_status ON public.prospects(user_id, status);

-- RLS
ALTER TABLE public.prospects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own prospects"
  ON public.prospects FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 4. EXCHANGES
-- ============================================================================
CREATE TABLE public.exchanges (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  initiator_id  uuid NOT NULL REFERENCES auth.users(id),
  receiver_id   uuid NOT NULL REFERENCES auth.users(id),
  method        text NOT NULL CHECK (method IN ('qr', 'nfc', 'link')),
  event_id      uuid REFERENCES public.events(id),
  metadata      jsonb DEFAULT '{}',
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_exchanges_initiator ON public.exchanges(initiator_id, created_at DESC);
CREATE INDEX idx_exchanges_receiver ON public.exchanges(receiver_id, created_at DESC);

-- RLS
ALTER TABLE public.exchanges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own exchanges"
  ON public.exchanges FOR SELECT
  USING (auth.uid() = initiator_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can create exchanges as initiator"
  ON public.exchanges FOR INSERT
  WITH CHECK (auth.uid() = initiator_id);

-- ============================================================================
-- 5. NUDGES
-- ============================================================================
CREATE TABLE public.nudges (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prospect_id  uuid NOT NULL REFERENCES public.prospects(id) ON DELETE CASCADE,
  type         text NOT NULL CHECK (type IN ('whatsapp', 'email', 'sms')),
  message      text NOT NULL,
  status       text DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'replied')),
  sent_at      timestamptz DEFAULT now(),
  delivered_at timestamptz,
  read_at      timestamptz,
  metadata     jsonb DEFAULT '{}'
);

CREATE INDEX idx_nudges_user ON public.nudges(user_id);
CREATE INDEX idx_nudges_prospect ON public.nudges(user_id, prospect_id);

-- RLS
ALTER TABLE public.nudges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own nudges"
  ON public.nudges FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 6. TEMPLATES
-- ============================================================================
CREATE TABLE public.templates (
  id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name            text NOT NULL,
  message         text NOT NULL,
  category        text NOT NULL
                  CHECK (category IN ('follow_up', 'intro', 'meeting', 'custom')),
  is_ai_generated boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read system + own templates"
  ON public.templates FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "Users can insert own templates"
  ON public.templates FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates"
  ON public.templates FOR UPDATE
  USING (auth.uid() = user_id AND user_id IS NOT NULL)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates"
  ON public.templates FOR DELETE
  USING (auth.uid() = user_id AND user_id IS NOT NULL);

-- ============================================================================
-- 7. DEVICES (FCM tokens)
-- ============================================================================
CREATE TABLE public.devices (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token   text NOT NULL,
  platform    text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name text,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

CREATE INDEX idx_devices_user ON public.devices(user_id, is_active);

-- RLS
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own devices"
  ON public.devices FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 8. FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email, first_name, last_name)
  VALUES (
    NEW.id,
    -- Generate a default username from email prefix + random suffix
    LOWER(SPLIT_PART(NEW.email, '@', 1)) || '-' || SUBSTR(MD5(RANDOM()::text), 1, 4),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', '')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Handle exchange: creates prospect records for both parties
CREATE OR REPLACE FUNCTION public.handle_exchange(
  p_initiator_id  uuid,
  p_receiver_id   uuid,
  p_method        text,
  p_event_id      uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exchange_id uuid;
  v_initiator   public.profiles;
  v_receiver    public.profiles;
  v_result      jsonb;
BEGIN
  -- Prevent self-exchange
  IF p_initiator_id = p_receiver_id THEN
    RAISE EXCEPTION 'Cannot exchange with yourself';
  END IF;

  -- Get both profiles
  SELECT * INTO v_initiator FROM public.profiles WHERE id = p_initiator_id;
  SELECT * INTO v_receiver  FROM public.profiles WHERE id = p_receiver_id;

  IF v_receiver IS NULL THEN
    RAISE EXCEPTION 'Receiver profile not found';
  END IF;

  -- Create exchange record
  INSERT INTO public.exchanges (initiator_id, receiver_id, method, event_id)
  VALUES (p_initiator_id, p_receiver_id, p_method, p_event_id)
  RETURNING id INTO v_exchange_id;

  -- Create prospect for initiator (they now have receiver's info)
  INSERT INTO public.prospects (
    user_id, event_id, exchanged_with,
    first_name, last_name, email, phone, company, title,
    avatar_url, linkedin, status, exchange_method, exchange_time
  ) VALUES (
    p_initiator_id, p_event_id, p_receiver_id,
    v_receiver.first_name, v_receiver.last_name, v_receiver.email,
    v_receiver.phone, v_receiver.company, v_receiver.title,
    v_receiver.avatar_url, v_receiver.linkedin,
    'new', p_method, now()
  );

  -- Create prospect for receiver (they now have initiator's info)
  INSERT INTO public.prospects (
    user_id, event_id, exchanged_with,
    first_name, last_name, email, phone, company, title,
    avatar_url, linkedin, status, exchange_method, exchange_time
  ) VALUES (
    p_receiver_id, p_event_id, p_initiator_id,
    v_initiator.first_name, v_initiator.last_name, v_initiator.email,
    v_initiator.phone, v_initiator.company, v_initiator.title,
    v_initiator.avatar_url, v_initiator.linkedin,
    'new', p_method, now()
  );

  -- Return the exchange info
  v_result := jsonb_build_object(
    'exchange_id', v_exchange_id,
    'receiver', jsonb_build_object(
      'id', v_receiver.id,
      'first_name', v_receiver.first_name,
      'last_name', v_receiver.last_name,
      'company', v_receiver.company,
      'title', v_receiver.title,
      'avatar_url', v_receiver.avatar_url
    )
  );

  RETURN v_result;
END;
$$;

-- Get profile by username (public lookup for exchange)
CREATE OR REPLACE FUNCTION public.get_profile_by_username(p_username text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile public.profiles;
BEGIN
  SELECT * INTO v_profile FROM public.profiles WHERE username = p_username;

  IF v_profile IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'id', v_profile.id,
    'username', v_profile.username,
    'first_name', v_profile.first_name,
    'last_name', v_profile.last_name,
    'company', v_profile.company,
    'title', v_profile.title,
    'avatar_url', v_profile.avatar_url
  );
END;
$$;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_prospects_updated_at
  BEFORE UPDATE ON public.prospects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON public.devices
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- 9. SEED SYSTEM TEMPLATES
-- ============================================================================
INSERT INTO public.templates (user_id, name, message, category) VALUES
  (NULL, 'Quick Follow-up',
   'Hey {{firstName}}! Great connecting at {{eventName}}. Would love to continue our conversation about {{company}}. Let me know when works for a quick call!',
   'follow_up'),
  (NULL, 'Meeting Request',
   'Hi {{firstName}}, it was a pleasure meeting you at {{eventName}}. I''d love to schedule a meeting to discuss potential collaboration between {{company}} and {{userCompany}}. Would you be available this week?',
   'meeting'),
  (NULL, 'Introduction',
   'Hi {{firstName}}, this is {{userName}} from {{userCompany}}. We met at {{eventName}} and I was really impressed by your work at {{company}}. Looking forward to staying in touch!',
   'intro');

-- ============================================================================
-- 10. STORAGE BUCKET
-- ============================================================================
-- Run this separately in Supabase Dashboard → Storage → New Bucket
-- Name: avatars
-- Public: true
-- Or use the SQL below:
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: authenticated users can upload to their own folder
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');
