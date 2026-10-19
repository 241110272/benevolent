import { createClient } from 'npm:@supabase/supabase-js@2';

const headers = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info', 'Content-Type': 'application/json' };
const reply = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers });
  if (req.method !== 'POST') return reply(405, { error: 'Method not allowed' });
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return reply(401, { error: 'Authentication required' });
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const { data: { user }, error } = await admin.auth.getUser(token);
  if (error || !user) return reply(401, { error: 'Invalid session' });
  // Check a real sign-in timestamp, not JWT iat (which changes on refresh).
  const signedInAt = Date.parse(user.last_sign_in_at ?? '');
  if (!Number.isFinite(signedInAt) || Date.now() - signedInAt > 10 * 60 * 1000) return reply(403, { error: 'Sign in with a fresh email code before deleting your account' });
  const result = await admin.auth.admin.deleteUser(user.id);
  if (result.error) return reply(500, { error: 'Deletion not completed. Try again.' });
  // user_state and reports are removed via ON DELETE CASCADE.
  return reply(200, { deleted: true });
});
