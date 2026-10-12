# Copper Nugget Logistics — website starter v3

This is a starter, not a live or production-ready website. It contains a customer tracking page and an authenticated staff portal.

## Files
- `index.html`, `app.js`, `styles.css`: public tracking page.
- `staff.html`, `staff.js`: staff login, shipment creation/updates, admin-only staff creation UI.
- `config.js`: set your Supabase Project URL and publishable key. Never use a service-role/secret key here.
- `supabase/functions/public-track`: public tracking endpoint; it calls the existing `track_shipment` function and returns only its safe tracking payload.
- `supabase/functions/create-staff`: admin-checked staff account creation endpoint.
- `supabase/schema.sql`: reference schema for a fresh project only.

## IMPORTANT for your existing project
You already created `shipments`, `shipment_events`, `user_roles`, RLS policies, `current_user_role`, `is_admin`, and `track_shipment` in Supabase. **Do not run `supabase/schema.sql` in full**; it is intended for a fresh project and may conflict with your existing tables and policy names.

## Next setup steps
1. In `config.js`, set `supabaseUrl` to your Supabase Project URL and `supabasePublishableKey` to your publishable key. These are designed for browser use; do not put any secret/service-role key in this file.
2. Deploy both Edge Functions (`public-track` and `create-staff`) to your existing Supabase project. They require the server-side Supabase secrets available to Edge Functions. Never put the service-role key in frontend files or a public GitHub repository.
3. Host the static site on a service such as Vercel or Netlify.
4. Test with fake/non-sensitive shipment data and separate admin/staff accounts before real use.

## Production checklist
The starter has not been independently security-tested and is not production-ready. Before handling real customer data, test all RLS rules, enable suitable rate limiting/bot protection for public tracking, configure CORS for your deployed domain, add password-reset/invitation flows, and test the admin/staff account lifecycle. Tracking numbers should be long and unpredictable.
