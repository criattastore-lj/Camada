-- Camada Operações — libera as contas Admin e Vendas.
-- Rode DEPOIS de criar os dois usuários em Authentication → Users → Add user.
insert into public.profiles (id, nick, role, approved, owner)
select id, 'Admin', 'gestao', true, true from auth.users where email = 'admin@criatta.app'
on conflict (id) do update set nick = excluded.nick, role = excluded.role, approved = true, owner = true;

insert into public.profiles (id, nick, role, approved, owner)
select id, 'Vendas', 'vendas', true, false from auth.users where email = 'vendas@criatta.app'
on conflict (id) do update set nick = excluded.nick, role = excluded.role, approved = true, owner = false;

-- Confere: devem aparecer as duas linhas
select u.email, p.nick, p.role, p.approved, p.owner
from public.profiles p join auth.users u on u.id = p.id order by p.owner desc;
