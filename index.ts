import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Content-Type': 'application/json' };
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: cors });
  try {
    const body = await req.json(); const tracking = typeof body?.tracking_number === 'string' ? body.tracking_number.trim() : '';
    if (tracking.length < 6 || tracking.length > 80) return new Response(JSON.stringify({ shipment: null, events: [] }), { headers: cors });
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data, error } = await supabase.rpc('track_shipment', { p_tracking_number: tracking });
    if (error) throw error;
    return new Response(JSON.stringify(data), { headers: cors });
  } catch (e) { console.error(e); return new Response(JSON.stringify({ error: 'Tracking temporarily unavailable' }), { status: 500, headers: cors }); }
});
