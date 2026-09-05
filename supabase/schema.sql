-- Falta Uno UY - esquema inicial Supabase
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  zone text not null default '',
  position text not null default '',
  level text not null default 'Intermedio',
  rating numeric(2,1) not null default 5.0,
  attendance_percent integer not null default 100,
  created_at timestamptz not null default now()
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles(id) on delete cascade,
  venue text not null,
  zone text not null,
  starts_at timestamptz not null,
  price_per_player integer not null default 0 check (price_per_player >= 0),
  level text not null default 'Cualquiera',
  max_players integer not null default 10 check (max_players between 2 and 30),
  status text not null default 'open' check (status in ('open','full','playing','finished','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.match_players (
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'confirmed' check (status in ('confirmed','waitlist','left','no_show')),
  role text not null default 'starter' check (role in ('starter','reserve')),
  joined_at timestamptz not null default now(),
  primary key(match_id, user_id)
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  zone text not null default '',
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.team_members (
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'player' check (role in ('captain','admin','player')),
  joined_at date not null default current_date,
  left_at date,
  primary key(team_id, user_id, joined_at)
);

create or replace view public.matches_with_counts as
select m.*,
       count(mp.user_id) filter (where mp.status = 'confirmed')::int as player_count
from public.matches m
left join public.match_players mp on mp.match_id = m.id
group by m.id;

alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.match_players enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;

create policy "profiles readable" on public.profiles for select to authenticated using (true);
create policy "own profile insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "own profile update" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "matches readable" on public.matches for select to authenticated using (true);
create policy "organizer creates match" on public.matches for insert to authenticated with check (auth.uid() = organizer_id);
create policy "organizer updates match" on public.matches for update to authenticated using (auth.uid() = organizer_id);
create policy "organizer deletes match" on public.matches for delete to authenticated using (auth.uid() = organizer_id);

create policy "match players readable" on public.match_players for select to authenticated using (true);
create policy "join self" on public.match_players for insert to authenticated with check (auth.uid() = user_id);
create policy "leave self" on public.match_players for delete to authenticated using (auth.uid() = user_id);
create policy "update self membership" on public.match_players for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "teams readable" on public.teams for select to authenticated using (true);
create policy "create teams" on public.teams for insert to authenticated with check (auth.uid() = created_by);
create policy "team members readable" on public.team_members for select to authenticated using (true);
create policy "join team self" on public.team_members for insert to authenticated with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'Jugador'));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

grant select on public.matches_with_counts to authenticated;

-- V3: max_players representa titulares. La app permite 1 suplente adicional.
-- En una migración posterior se agregará role ('starter'/'reserve') a match_players
-- para hacer atómica la promoción automática del suplente cuando se libera un titular.
\n\n-- V5: al bajarse un titular, el suplente se promueve automáticamente.\ncreate or replace function public.leave_match_and_promote_reserve(p_match_id uuid)\nreturns void\nlanguage plpgsql\nsecurity definer\nset search_path = public\nas $$\ndeclare\n  leaving_role text;\n  reserve_user uuid;\nbegin\n  select role into leaving_role\n  from public.match_players\n  where match_id = p_match_id and user_id = auth.uid() and status = 'confirmed';\n\n  delete from public.match_players\n  where match_id = p_match_id and user_id = auth.uid();\n\n  if leaving_role = 'starter' then\n    select user_id into reserve_user\n    from public.match_players\n    where match_id = p_match_id and status = 'confirmed' and role = 'reserve'\n    order by joined_at\n    limit 1;\n\n    if reserve_user is not null then\n      update public.match_players\n      set role = 'starter'\n      where match_id = p_match_id and user_id = reserve_user;\n    end if;\n  end if;\nend;\n$$;\n\ngrant execute on function public.leave_match_and_promote_reserve(uuid) to authenticated;\n