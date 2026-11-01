-- Cronômetro de Estudos: tabelas de sincronização
-- Cole tudo no Supabase (SQL Editor → New query) e clique em Run.

create table if not exists public.estudo_sessoes (
  id       text primary key,
  user_id  uuid not null default auth.uid() references auth.users(id) on delete cascade,
  c_id     text,
  m_id     text,
  c_nome   text,
  m_nome   text,
  ini      bigint not null,
  fim      bigint,
  dur      bigint not null,
  manual   boolean not null default false,
  apagada  boolean not null default false,
  upd      bigint not null,
  srv      timestamptz not null default now()
);
create index if not exists estudo_sessoes_user_srv on public.estudo_sessoes (user_id, srv);

create table if not exists public.estudo_config (
  user_id   uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  concursos jsonb not null default '[]'::jsonb,
  ativo     jsonb,
  upd       bigint not null
);

-- marca a hora do servidor em cada gravação (usada para buscar só o que mudou)
create or replace function public.estudo_touch_srv() returns trigger
language plpgsql as $$ begin new.srv := now(); return new; end $$;
drop trigger if exists estudo_sessoes_srv on public.estudo_sessoes;
create trigger estudo_sessoes_srv before insert or update on public.estudo_sessoes
for each row execute function public.estudo_touch_srv();

-- cada conta só enxerga os próprios dados
alter table public.estudo_sessoes enable row level security;
alter table public.estudo_config  enable row level security;
drop policy if exists "dono sessoes" on public.estudo_sessoes;
create policy "dono sessoes" on public.estudo_sessoes for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "dono config" on public.estudo_config;
create policy "dono config" on public.estudo_config for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
