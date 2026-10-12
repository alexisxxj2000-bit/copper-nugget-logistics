(() => {
  const $ = (s) => document.querySelector(s);
  $('#year').textContent = new Date().getFullYear();
  const cfg = window.CNL_CONFIG || {};
  const ready = cfg.supabaseUrl && cfg.supabasePublishableKey && cfg.supabaseUrl.startsWith('https://') && !cfg.supabaseUrl.includes('PASTE_') && !cfg.supabasePublishableKey.includes('PASTE_');
  $('#track-form').addEventListener('submit', async (e) => {
    e.preventDefault(); const number = $('#tracking-number').value.trim(); const out = $('#result');
    if (!ready) { out.innerHTML = '<div class="result-empty">Setup needed: add your Supabase Project URL and publishable key to <code>config.js</code>, then deploy the <code>public-track</code> Edge Function.</div>'; return; }
    const button = e.submitter; button.disabled = true; button.textContent = 'Searching…'; out.innerHTML = '<div class="result-empty">Looking up your shipment…</div>';
    try {
      const client = window.supabase.createClient(cfg.supabaseUrl, cfg.supabasePublishableKey);
      const {data, error} = await client.functions.invoke('public-track', {body: {tracking_number: number}});
      if (error) throw error; if (!data || data.found !== true || !data.shipment) { out.innerHTML = '<div class="result-empty">We couldn’t find that tracking number. Check it and try again.</div>'; return; }
      const s = data.shipment; const events = s.events || [];
      const safe = (v) => String(v ?? '—').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
      out.innerHTML = `<article class="result-card"><span class="status">${safe(s.status)}</span><h2>Shipment ${safe(s.tracking_number)}</h2><div class="details"><div class="detail"><small>Origin</small>${safe(s.origin)}</div><div class="detail"><small>Destination</small>${safe(s.destination)}</div><div class="detail"><small>Estimated delivery</small>${safe(s.estimated_delivery || 'Not available')}</div><div class="detail"><small>Last updated</small>${safe(events.length && events[0].event_time ? new Date(events[0].event_time).toLocaleString() : '—')}</div></div><h3>Shipment history</h3><div class="timeline">${events.length ? events.map(ev => `<div class="event"><strong>${safe(ev.status)}</strong><div>${safe(ev.description)}</div><small>${safe(ev.location)} · ${safe(ev.event_time ? new Date(ev.event_time).toLocaleString() : '')}</small></div>`).join('') : '<p>No tracking events have been added yet.</p>'}</div></article>`;
    } catch (err) { out.innerHTML = '<div class="result-empty">Tracking is temporarily unavailable. Please try again later or contact the sender.</div>'; console.error(err); }
    finally { button.disabled = false; button.textContent = 'Track shipment'; }
  });
})();
