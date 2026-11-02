-- Camada Operações — banco de dados (Supabase)
-- Cole tudo no SQL Editor do Supabase e clique em Run. Pode rodar de novo sem perder dados.

-- 1) Pessoas da equipe (uma linha por conta criada no app)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nick text not null default '',
  role text not null default 'vendas' check (role in ('gestao', 'vendas', 'producao')),
  approved boolean not null default false,
  owner boolean not null default false,
  seller_id text not null default '',
  created_at timestamptz not null default now()
);

-- 2) Todos os registros do app (produtos, filamentos, vendas, encomendas, mensagens...)
create table if not exists public.docs (
  id text primary key,
  coll text not null,
  data jsonb not null default '{}'::jsonb,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now()
);
create index if not exists docs_coll_idx on public.docs (coll);
alter table public.docs replica identity full;

-- 3) Funções de permissão
create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and approved);
$$;
create or replace function public.is_manager() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and approved and role = 'gestao');
$$;

-- 4) Quem cria a conta primeiro vira o dono (gestão, já aprovado). Os demais entram aguardando aprovação.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  is_first boolean;
  wanted text := coalesce(new.raw_user_meta_data->>'role', 'vendas');
begin
  perform pg_advisory_xact_lock(424242);
  select not exists (select 1 from public.profiles) into is_first;
  if wanted not in ('vendas', 'producao') then wanted := 'vendas'; end if;
  insert into public.profiles (id, nick, role, approved, owner)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'nick'), ''), split_part(new.email, '@', 1)),
    case when is_first then 'gestao' else wanted end,
    is_first,
    is_first
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5) Proteções: só a gestão muda função/aprovação; o dono não pode ser rebaixado
create or replace function public.protect_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return new; end if;        -- painel do Supabase / serviço
  new.owner := old.owner;
  if old.owner then new.role := 'gestao'; new.approved := true; end if;
  if not public.is_manager() then
    if new.id <> auth.uid() then raise exception 'sem permissão'; end if;
    new.role := old.role; new.approved := old.approved; new.seller_id := old.seller_id;
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_protect on public.profiles;
create trigger profiles_protect before update on public.profiles
  for each row execute function public.protect_profile();

-- 6) Regras de acesso (RLS)
alter table public.profiles enable row level security;
alter table public.docs enable row level security;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (public.is_member() or id = auth.uid());
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = auth.uid() and approved = false and owner = false and role in ('vendas', 'producao'));
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated
  using (public.is_manager() or id = auth.uid());
drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles for delete to authenticated
  using (public.is_manager() and not owner);

drop policy if exists docs_all on public.docs;
create policy docs_all on public.docs for all to authenticated
  using (public.is_member()) with check (public.is_member());

-- 7) Tempo real: avisa todos os aparelhos a cada mudança
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null; end $$;

-- 8) Fotos dos produtos
insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true)
  on conflict (id) do nothing;
drop policy if exists fotos_insert on storage.objects;
create policy fotos_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and public.is_member());
drop policy if exists fotos_update on storage.objects;
create policy fotos_update on storage.objects for update to authenticated
  using (bucket_id = 'fotos' and public.is_member());
drop policy if exists fotos_delete on storage.objects;
create policy fotos_delete on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and public.is_member());
