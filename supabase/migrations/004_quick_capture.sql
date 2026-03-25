-- Add Quick Capture fields to prospects table
ALTER TABLE prospects
  ADD COLUMN IF NOT EXISTS exchange_type TEXT DEFAULT 'mutual_bump',
  ADD COLUMN IF NOT EXISTS enrichment_status TEXT DEFAULT 'complete',
  ADD COLUMN IF NOT EXISTS missing_fields TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS exchange_direction TEXT DEFAULT 'mutual';

-- Index for finding partial contacts
CREATE INDEX IF NOT EXISTS idx_prospects_enrichment ON prospects(user_id, enrichment_status) WHERE enrichment_status != 'complete';
