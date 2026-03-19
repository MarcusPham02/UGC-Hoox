-- Enable Row-Level Security on the hooks table.
-- Hooks are shared reference data — all authenticated users can read them,
-- but only service-role (admin) can insert/update/delete.

ALTER TABLE hooks ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated user to read hooks
CREATE POLICY "Authenticated users can read hooks"
  ON hooks
  FOR SELECT
  TO authenticated
  USING (true);

-- Block anonymous access entirely (anon key cannot read hooks)
-- No policy is created for the anon role, so RLS denies by default.
