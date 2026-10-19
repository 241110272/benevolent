// Server-only importer. Requires a Jooble API key AND permission for your use.
// Do not run against production until attribution/redistribution rights are approved.
import { createClient } from 'npm:@supabase/supabase-js@2';

const json = (status: number, body: unknown) => new Response(JSON.stringify(body), {status, headers: {'Content-Type': 'application/json'}});
Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, {error: 'Method not allowed'});
  const configured = Deno.env.get('JOB_IMPORT_TOKEN');
  const token = req.headers.get('x-import-token') ?? '';
  if (!configured || configured.length < 32 || token !== configured) return json(401, {error: 'Unauthorized'});
  if (Deno.env.get('JOOBLE_LICENSE_CONFIRMED') !== 'true') return json(503, {error: 'Confirm provider rights before enabling import'});
  const key = Deno.env.get('JOOBLE_API_KEY');
  if (!key) return json(503, {error: 'Provider not configured'});
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {auth: {persistSession: false}});
  let count = 0;
  for (let page = 1; page <= 3; page++) {
    const response = await fetch(`https://jooble.org/api/${encodeURIComponent(key)}`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({keywords: '', location: 'Indonesia', page: String(page)}), signal: AbortSignal.timeout(20000),
    });
    if (!response.ok) return json(502, {error: 'Provider request failed', imported: count});
    const body = await response.json();
    if (!Array.isArray(body.jobs)) return json(502, {error: 'Unexpected provider response'});
    const records = body.jobs.flatMap((j: Record<string, unknown>) => {
      if (!j.id || !j.title || !j.company || !j.link || !j.location) return [];
      let url: URL;
      try { url = new URL(String(j.link)); } catch { return []; }
      if (url.protocol !== 'https:' || url.username || url.password) return [];
      const time = Date.parse(String(j.updated ?? ''));
      const publishedAt = Number.isFinite(time) ? new Date(time) : new Date();
      const expires = new Date(publishedAt.getTime() + 14 * 86400000);
      if (expires.getTime() <= Date.now()) return [];
      const id = `jooble-${String(j.id)}`;
      return [{id, country: 'ID', published: true, published_at: publishedAt.toISOString(), expires_at: expires.toISOString(), imported_at: new Date().toISOString(), payload: {
        slug: id, title: String(j.title).slice(0, 300), company_name: String(j.company).slice(0, 200),
        location: String(j.location).slice(0, 200), description: String(j.snippet ?? '').slice(0, 30000),
        url: url.href, remote: /^(remote|work from home|wfh)$/i.test(String(j.location)), tags: [],
        job_types: j.type ? [String(j.type).slice(0, 100)] : [], source: 'Jooble', demo: false,
        salary: j.salary ? String(j.salary).slice(0, 300) : null,
        created_at: Number.isFinite(time) ? Math.floor(time / 1000) : null,
      }}];
    });
    if (records.length) {
      const {error} = await db.from('jobs').upsert(records, {onConflict: 'id'});
      if (error) return json(500, {error: 'Import storage failed', imported: count});
      count += records.length;
    }
    if (body.jobs.length === 0) break;
  }
  return json(200, {imported: count, country: 'ID'});
});
