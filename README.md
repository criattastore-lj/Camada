# Camada Operações: app da equipe

App de vendas, encomendas, produção 3D, filamentos, mensagens e indicadores. Cada pessoa entra com e-mail e senha, e tudo o que alguém lança aparece na hora nos celulares e computadores dos outros.

- **Banco de dados, login e fotos:** Supabase (plano gratuito)
- **Hospedagem do site:** Netlify ou Vercel (plano gratuito, com HTTPS)
- **Instalação nos celulares:** como app (PWA), direto pelo link, sem loja

Enquanto o `js/config.js` estiver com os valores de exemplo, o app abre em **modo demonstração**. Nesse modo não há login e os dados ficam só no aparelho.

---

## 1. Criar o banco no Supabase (cerca de 10 min)

1. Entre em <https://supabase.com> e clique em **New project**.
   - **Region:** South America (São Paulo).
   - Guarde a senha do banco num lugar seguro.
2. Abra **SQL Editor → New query**, cole todo o conteúdo de `supabase/schema.sql` e clique em **Run**.
   - Esse comando cria as tabelas, as regras de acesso, o tempo real e o local das fotos.
   - Pode rodar de novo sem perder dados.
3. Abra **Project Settings → API** e copie dois valores para o `js/config.js`:
   - a **Project URL**;
   - a chave **Publishable** (começa com sb_publishable_) ou a anon da aba Legacy.
   ```js
   window.APP_CONFIG = {
     SUPABASE_URL: 'https://abcd1234.supabase.co',
     SUPABASE_ANON_KEY: 'eyJhbGciOi...'
   };
   ```
   - A chave *anon* pode ficar no app: as regras do banco só deixam entrar quem foi aprovado.
   - **Nunca** use a chave *service_role*.

## 2. Publicar o app (cerca de 5 min)

**Jeito mais fácil (Netlify Drop):**

1. Entre em <https://app.netlify.com/drop>.
2. Arraste a pasta `camada-app` inteira para a página.
3. Em segundos sai um endereço, por exemplo `https://camada-xyz.netlify.app`.
4. Crie uma conta grátis para o site não expirar. Em *Site configuration → Change site name*, deixe o nome que quiser, por exemplo `camada-operacoes.netlify.app`.
5. Para atualizar no futuro, arraste a pasta de novo em *Deploys*.

**Com GitHub + Vercel (atualiza sozinho a cada `git push`):**

1. Suba a pasta para um repositório no GitHub.
2. Em <https://vercel.com>, clique em **Add New → Project**, escolha o repositório e clique em **Deploy**.

## 3. Ligar o login ao endereço do app

No Supabase, abra **Authentication → URL Configuration**:

- **Site URL:** o endereço do app, por exemplo `https://camada-operacoes.netlify.app`.
- **Redirect URLs:** adicione o mesmo endereço.

Sem isso, os links de confirmação de e-mail e de "Esqueci minha senha" não voltam para o app.

**Confirmação de e-mail (opcional):** em *Authentication → Sign In / Providers → Email*, você escolhe se a pessoa precisa confirmar o e-mail antes de entrar.

- **Ligado:** mais seguro.
- **Desligado:** a pessoa entra assim que cria a conta. Mesmo assim, ela só vê os dados depois que você aprova.

O envio de e-mails do plano gratuito tem limite baixo por hora. Para uma equipe pequena é suficiente.

## 4. Primeiro acesso

1. Abra o endereço do app e toque em **Criar conta**.
2. **A primeira conta criada vira o dono, com função Gestão e já aprovado.** Crie a sua antes de mandar o link para a equipe.
3. Em **Ajustes → Importar backup**, traga os dados que você já lançou. Veja a seção 6.

## 5. Colocar a equipe

1. Mande o link para a pessoa.
2. Ela toca em **Criar conta**, escolhe a função (Vendas ou Produção), o apelido, o e-mail e a senha.
3. Ela vê a tela "Aguardando aprovação".
4. Você abre **Equipe**, toca em **Aprovar** e, se for vendedor, liga ao cadastro de comissão.
5. O celular dela libera sozinho, sem precisar recarregar.

O que cada função vê:

- **Vendas:** Avisos, Mensagens, Encomendas, Produtos e Vendas.
- **Produção:** Avisos, Mensagens, Encomendas, Produção, Filamentos, Máquinas e Produtos.
- **Gestão:** tudo.

O dono não pode ser removido nem rebaixado.

## 6. Trazer os dados que você já tem

1. Na versão que você usa hoje, abra **Ajustes → Exportar backup**. O app baixa um arquivo `.json`.
2. No app novo, já logado como dono, abra **Ajustes → Importar backup** e escolha esse arquivo.

Produtos, filamentos, compras, produções, vendas, encomendas, despesas, mensagens e ajustes vão para a nuvem da equipe.

As **fotos** não vêm junto quando o backup sai da versão no Claude, porque lá elas ficam guardadas em outro lugar. Depois de importar, abra cada produto e envie a foto de novo: ela vai para a nuvem e aparece para todos.

## 7. Instalar nos celulares

- **Android (Chrome):**
  1. Abra o link.
  2. Toque em **Instalar app** no menu do Camada, ou em ⋮ → *Instalar app*.
  3. O ícone aparece na tela inicial e o app abre em tela cheia.
- **iPhone (Safari):**
  1. Abra o link.
  2. Toque em **Compartilhar** e depois em **Adicionar à Tela de Início**.
- **Computador (Chrome/Edge):** clique no ícone de instalar na barra de endereço.

As atualizações chegam sozinhas: quando você publica uma versão nova, ela vale na próxima vez que o app abrir.

**Quer um arquivo APK ou publicar na Play Store?**

1. Entre em <https://www.pwabuilder.com>.
2. Cole o endereço do app e clique em **Package for stores → Android**.
3. Ele gera o APK para instalar direto e o pacote para a Play Store.
   - A conta de desenvolvedor do Google custa US$ 25, uma vez só.
   - O conteúdo continua sendo o mesmo site: atualizou o site, atualizou o app.

## Como funciona o tempo real

- Cada registro salvo vai para a tabela `docs` do Supabase.
- O Supabase Realtime avisa todos os aparelhos conectados, e a tela de cada um se atualiza na hora: avisos, mensagens, estoque e encomendas.
- No rodapé do menu, **● Sincronizado em tempo real** mostra que está conectado.
- Quando o celular volta do segundo plano ou recupera a internet, o app busca tudo de novo para não perder nada.
- **Sem internet:** o app abre, mas não salva. Ele avisa "Sem internet: não foi salvo".

## Custos e limites do plano gratuito

- **Supabase grátis:** 500 MB de banco, 1 GB de fotos e 200 conexões em tempo real ao mesmo tempo. Sobra muito para uma equipe pequena.
- **Pausa por falta de uso:** o projeto gratuito **pausa depois de 7 dias sem nenhum acesso**. Os dados não se perdem: é só entrar no painel do Supabase e clicar em *Restore*. Com uso diário, isso não acontece. O plano Pro (US$ 25/mês) não pausa e tem backup diário automático.
- **Netlify e Vercel grátis:** suficiente.
- **Backup:** use **Ajustes → Exportar backup** de vez em quando, por exemplo toda semana.

## Segurança

- As senhas ficam no Supabase Auth. O app nunca vê nem guarda a senha.
- Só contas **aprovadas** leem ou gravam dados. Quem cria conta sem aprovação não vê nada.
- Só a **Gestão** aprova, muda função ou remove pessoas. Essas regras estão no próprio banco (RLS), não só na tela.
- As funções Vendas e Produção organizam as telas. No banco, qualquer pessoa aprovada pode gravar registros. Aprove só quem é da equipe.
- **"Manter conectado neste aparelho":**
  - **Marcado:** a pessoa continua logada mesmo fechando o app.
  - **Desmarcado:** o login vale só até fechar o navegador. Use em aparelho que não é seu.
- **Para tirar alguém:** em **Equipe → Remover**. Para apagar a conta de vez, use também *Authentication → Users* no Supabase.

## Estrutura

```
index.html             o app inteiro (mesmo código da versão no Claude)
manifest.webmanifest   nome, ícone e cores do app instalado
sw.js                  abre o app sem internet e mantém a versão nova
js/config.js           ← endereço e chave do Supabase
js/supabase.js         biblioteca do Supabase (2.118.0, incluída para funcionar offline)
icons/                 ícones do app
supabase/schema.sql    banco, regras de acesso, tempo real e fotos
build.py               gera o index.html a partir do código-fonte (só para quem for programar)
```
