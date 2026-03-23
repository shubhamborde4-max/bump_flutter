-- Add personal fields
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS mobile_number text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_pic_url text;

-- Add work fields
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_logo text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS department text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS designation text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_address text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS note text;

-- Visible fields for card customization (comma-separated field names)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS visible_fields text DEFAULT 'firstName,lastName,email,phone,company,title';

-- Update public_profiles view to include new fields
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT id, username, first_name, last_name, company, title, avatar_url,
       designation, department, company_logo, profile_pic_url, visible_fields
FROM public.profiles;
