-- Copper Nugget Logistics: secure baseline schema for Supabase.
-- Run in SQL Editor only after reviewing. Do not enable unrestricted public table access.
create extension if not exists pgcrypto;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','staff')),
  created_at timestamptz not null default now()
);

create table if not exists public.shipments (
  id uuid primary key default gen_random_uuid(),
  tracking_number text not null unique,
  recipient_name text not null,
  origin text not null default 'Mason, Michigan',
  destination text not null,
  status text not null default 'Label created' check (status in ('Label created','In transit','Out for delivery','Delivered','Exception')),
  estimated_delivery date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.shipment_events (
  id uuid primary key default gen_random_uuid(),
  shipment_id uuid not null references public.shipments(id) on delete cascade,
  status text not null check (status in ('Label created','In transit','Out for delivery','Delivered','Exception')),
  location text not null default '',
  description text not null,
  event_time timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.user_roles enable row level security;
alter table public.shipments enable row level security;
alter table public.shipment_events enable row level security;

-- Role lookup is server-controlled; clients cannot read or change the roles table directly.
revoke all on public.user_roles from anon, authenticated;
revoke all on public.shipments from anon, authenticated;
revoke all on public.shipment_events from anon, authenticated;
grant select, insert, update, delete on public.shipments to authenticated;
grant select, insert, update, delete on public.shipment_events to authenticated;

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = '' as $$
  select role from public.user_roles where user_id = auth.uid()
$$;
revoke all on function public.current_user_role() from public;
grant execute on function public.current_user_role() to authenticated;

create policy "staff and admins read shipments" on public.shipments for select to authenticated
  using (public.current_user_role() in ('admin','staff'));
create policy "admins and staff create shipments" on public.shipments for insert to authenticated
  with check (public.current_user_role() in ('admin','staff'));
create policy "admins and staff update shipments" on public.shipments for update to authenticated
  using (public.current_user_role() in ('admin','staff')) with check (public.current_user_role() in ('admin','staff'));
create policy "admins delete shipments" on public.shipments for delete to authenticated
  using (public.current_user_role() = 'admin');
create policy "staff and admins read events" on public.shipment_events for select to authenticated
  using (public.current_user_role() in ('admin','staff'));
create policy "staff and admins create events" on public.shipment_events for insert to authenticated
  with check (public.current_user_role() in ('admin','staff'));
create policy "admins update events" on public.shipment_events for update to authenticated
  using (public.current_user_role() = 'admin') with check (public.current_user_role() = 'admin');
create policy "admins delete events" on public.shipment_events for delete to authenticated
  using (public.current_user_role() = 'admin');

-- Public customer lookup returns only tracking-safe fields, never recipient name or shipment contents.
create or replace function public.public_track(p_tracking_number text)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare s public.shipments%rowtype; ev jsonb;
begin
  if p_tracking_number is null or length(trim(p_tracking_number)) < 6 or length(trim(p_tracking_number)) > 80 then
    return jsonb_build_object('shipment', null, 'events', '[]'::jsonb);
  end if;
  select * into s from public.shipments where upper(tracking_number) = upper(trim(p_tracking_number));
  if not found then return jsonb_build_object('shipment', null, 'events', '[]'::jsonb); end if;
  select coalesce(jsonb_agg(jsonb_build_object('status',e.status,'location',e.location,'description',e.description,'event_time',e.event_time) order by e.event_time desc), '[]'::jsonb)
    into ev from (select * from public.shipment_events where shipment_id=s.id order by event_time desc limit 30) e;
  return jsonb_build_object('shipment', jsonb_build_object('tracking_number',s.tracking_number,'origin',s.origin,'destination',s.destination,'status',s.status,'estimated_delivery',s.estimated_delivery,'updated_at',s.updated_at), 'events',ev);
end; $$;
revoke all on function public.public_track(text) from public;
grant execute on function public.public_track(text) to anon, authenticated;

-- IMPORTANT: after creating your admin user in Authentication > Users, replace the email below
-- with that exact email and run this statement once. It grants only that account the admin role.
-- insert into public.user_roles(user_id, role)
-- select id, 'admin' from auth.users where lower(email)=lower('YOUR_ADMIN_EMAIL_HERE')
-- on conflict (user_id) do update set role='admin';
