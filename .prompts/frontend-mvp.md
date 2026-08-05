
# Fase 14 — Frontend MVP (Design Brutalista)

**Fonte:** `.prompts/frontend-mvp.md`
**Dependências:** Backend API concluída (89 endpoints, JWT Bearer, envelope `{ok, data, meta}`).
**Stack:** React 19 + Vite + TypeScript + TailwindCSS 4 + React Router 7.
**Restrições:**
- ⛔ Não alterar controllers, models ou rotas Rails existentes.
- ⛔ Não usar Material UI, Bootstrap, Chakra ou qualquer kit UI pré-estilizado.
- ⛔ Não armazenar tokens em cookies — usar `localStorage` com limpeza em logout/expiração.
- ⛔ Lógica de negócio fica no backend — frontend é camada de visualização + formulários.

**Design System — Brutalismo:**
- Paleta: branco (`#FFFFFF`), vermelho claro (`#FF6B6B`), preto (`#000000`), cinza claro (`#F5F5F5`) para fundos.
- Bordas: `border-4 border-black` em cards, inputs, botões e modais.
- Cantos: `rounded-3xl` (24px) — arredondamento grande em tudo.
- Sombras: `shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]` — hard shadow preta.
- Tipografia: títulos em `font-black italic` (ex: `text-4xl font-black italic`).
- Botões: fundo preto + texto branco (primário), fundo vermelho claro + texto preto (ação), fundo branco + borda preta (secundário). Hover inverte ou desloca sombra.
- Inputs: `border-4 border-black rounded-3xl px-6 py-3 text-lg focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]`.

---

## T14.1 — Scaffold Vite + Tailwind + proxy

- [ ] `npm create vite@latest frontend -- --template react-ts` na raiz do projeto.
- [ ] `cd frontend && npm install react-router-dom axios`.
- [ ] `npm install -D tailwindcss @tailwindcss/vite` (Tailwind 4 plugin Vite).
- [ ] Configurar `vite.config.ts`:
  - Plugin `@tailwindcss/vite`.
  - `server.proxy`: `"/api/v1"` → `http://localhost:3000`, `/healthz` → idem, `/readyz` → idem.
  - `server.port`: 5173.
- [ ] Criar `frontend/src/index.css` com `@import "tailwindcss"` + `@theme` contendo:
  - `--color-brutal-red: #FF6B6B`, `--color-brutal-black: #000000`, `--color-brutal-white: #FFFFFF`, `--color-brutal-gray: #F5F5F5`.
  - `--radius-brutal: 1.5rem`, `--shadow-brutal: 8px 8px 0px 0px rgba(0,0,0,1)`.
- [ ] Limpar arquivos gerados pelo scaffold (App.css, assets/react.svg, conteúdo padrão do App.tsx).
- [ ] Verificar: `npm run dev` compila sem erros e a página raiz renderiza com fundo branco.
- [ ] Verificar: `curl http://localhost:5173/api/v1/auth/me` retorna `401` (proxy funciona para o Rails).
- [ ] Adicionar `frontend/node_modules/` e `frontend/dist/` ao `.gitignore` (já existem).

---

## T14.2 — Design system: componentes base brutalistas

Todos os componentes em `frontend/src/components/ui/`.

- [ ] `Button.tsx` — variantes: `primary` (bg-black text-white), `danger` (bg-brutal-red text-black), `outline` (bg-white border-black). Props: `variant`, `size`, `loading`, `disabled`, `children`, `onClick`, `type`. Todos com `border-4 border-black rounded-3xl shadow-brutal`. Estado hover: desloca sombra para `4px 4px`. Estado disabled: `opacity-50 cursor-not-allowed`.
- [ ] `Input.tsx` — Props: `label`, `name`, `type`, `error`, `placeholder`, `value`, `onChange`, `required`. Label em `font-bold text-sm uppercase tracking-wider`. Input com `border-4 border-black rounded-3xl`. Erro: `border-brutal-red` + mensagem vermelha abaixo.
- [ ] `Select.tsx` — Mesmo padrão visual do Input. Props: `label`, `options`, `value`, `onChange`, `error`.
- [ ] `Card.tsx` — Container com `border-4 border-black rounded-3xl shadow-brutal bg-white p-6`. Props: `children`, `className`.
- [ ] `Modal.tsx` — Overlay `bg-black/50`, conteúdo centralizado com Card brutalista. Props: `open`, `onClose`, `title`, `children`. Título em `font-black italic text-2xl`. Botão X no canto superior.
- [ ] `Badge.tsx` — Para status labels. Variantes por status: `pending` (amarelo), `approved/paid` (verde), `rejected/cancelled` (vermelho), `active` (azul). Todos com `border-2 border-black rounded-full px-3 py-1 text-xs font-bold uppercase`.
- [ ] `Table.tsx` — Tabela com `border-4 border-black rounded-3xl overflow-hidden`. Headers em `bg-black text-white font-bold uppercase`. Linhas alternadas `bg-white / bg-brutal-gray`. Props: `columns`, `data`, `onRowClick`.
- [ ] `EmptyState.tsx` — Ícone grande + título italic bold + descrição + botão de ação opcional. Para listas vazias.
- [ ] `LoadingSpinner.tsx` — Spinner brutalista (quadrado rotacionando com `border-4 border-black`).
- [ ] `ErrorState.tsx` — Card vermelho com ícone + mensagem + botão "Tentar novamente".
- [ ] `PageTitle.tsx` — `<h1 className="text-4xl font-black italic text-black">`. Subtítulo opcional em `text-lg text-gray-600`.
- [ ] `ConfirmDialog.tsx` — Modal com mensagem + botões "Confirmar" (danger) e "Cancelar" (outline). Para ações destrutivas (UX-004).

---

## T14.3 — Layout, Header, Footer, navegação e rotas

- [ ] `Footer.tsx` — em `frontend/src/components/layout/`:
  - Fundo preto, texto branco.
  - 4 colunas: **JaChegai** (logo + tagline), **Para você** (links: Descubra sellers, Seja courier, Seja parceiro), **Suporte** (FAQ, Termos, Privacidade, Contato), **Siga-nos** (ícones placeholder).
  - Copyright `© 2026 JaChegai. Todos os direitos reservados.` centralizado embaixo.
  - Border-top: `border-t-4 border-brutal-red`.
  - Presente em **todas** as páginas sem exceção.
- [ ] `Header.tsx` — componente condicional por role:
  - **Visitante**: logo + links "Entrar" / "Cadastrar".
  - **Customer**: logo + "Meu carrinho" + "Meus pedidos" + "Perfil" + "Sair".
  - **Seller**: logo + "Produtos" + "Pedidos" + "Estoque" + "Perfil" + "Sair".
  - **Courier**: logo + "Entregas" + "Disponibilidade" + "Estatísticas" + "Perfil" + "Sair".
  - **Admin**: logo + "Dashboard" + "Usuários" + "Sellers" + "Couriers" + "Pedidos" + "Pagamentos" + "Tickets" + "Faturas" + "Config" + "Sair".
  - Fundo branco, `border-b-4 border-black`, logo em `font-black italic text-2xl`.
  - Mobile: menu hamburger que abre sidebar com mesmos links.
- [ ] `PublicLayout.tsx` — Header visitante + `<Outlet />` + Footer.
- [ ] `CustomerLayout.tsx` — Header customer + `<Outlet />` + Footer. Redireciona para `/login` se não autenticado.
- [ ] `SellerLayout.tsx` — Header seller + `<Outlet />` + Footer. Redireciona para `/login` se não autenticado ou sem role seller.
- [ ] `CourierLayout.tsx` — Header courier + `<Outlet />` + Footer. Idem.
- [ ] `AdminLayout.tsx` — Header admin + sidebar fixa (links de navegação) + `<Outlet />` + Footer. Sidebar com `bg-black text-white` e links com hover `bg-brutal-red`.
- [ ] `ProtectedRoute.tsx` — wrapper que checa AuthContext: se não autenticado → `/login`; se autenticado mas sem a role necessária → página 403 brutalista.
- [ ] Configurar React Router em `App.tsx` com:
  ```
  /                           → PublicLayout > HomePage
  /sellers                    → PublicLayout > SellersPage
  /sellers/:id                → PublicLayout > SellerDetailPage
  /products/:id               → PublicLayout > ProductDetailPage
  /login                      → PublicLayout > LoginPage
  /register                   → PublicLayout > RegisterPage
  /customer/*                 → CustomerLayout (protected: customer)
    /customer/cart             → CartPage
    /customer/checkout         → CheckoutPage
    /customer/orders           → OrdersPage
    /customer/orders/:id       → OrderDetailPage
    /customer/tracking/:id     → TrackingPage
    /customer/addresses        → AddressesPage
    /customer/favorites        → FavoritesPage
    /customer/tickets          → TicketsPage
    /customer/tickets/:id      → TicketDetailPage
    /customer/profile          → ProfilePage
  /seller/*                   → SellerLayout (protected: seller)
    /seller/onboarding         → OnboardingPage
    /seller/products           → ProductsPage
    /seller/products/:id       → ProductEditPage
    /seller/categories         → CategoriesPage
    /seller/inventory          → InventoryPage
    /seller/orders             → OrdersPage
    /seller/orders/:id         → OrderDetailPage
    /seller/settings           → SettingsPage
    /seller/profile            → ProfilePage
  /courier/*                  → CourierLayout (protected: courier)
    /courier/onboarding        → OnboardingPage
    /courier/deliveries        → DeliveriesPage (eligible + active)
    /courier/history           → HistoryPage
    /courier/availability      → AvailabilityPage
    /courier/stats             → StatsPage
    /courier/profile           → ProfilePage
  /admin/*                    → AdminLayout (protected: admin)
    /admin/dashboard           → DashboardPage
    /admin/users               → UsersPage
    /admin/users/:id           → UserDetailPage
    /admin/sellers             → SellersPage
    /admin/sellers/:id         → SellerDetailPage
    /admin/couriers            → CouriersPage
    /admin/couriers/:id        → CourierDetailPage
    /admin/orders              → OrdersPage
    /admin/orders/:id          → OrderDetailPage
    /admin/payments            → PaymentsPage
    /admin/payments/:id        → PaymentDetailPage
    /admin/tickets             → TicketsPage
    /admin/tickets/:id         → TicketDetailPage
    /admin/invoices            → InvoicesPage
    /admin/invoices/:id        → InvoiceDetailPage
    /admin/settings            → SettingsPage
    /admin/observability       → ObservabilityPage
  *                            → NotFoundPage (404 brutalista)
  ```

---

## T14.4 — Serviço de API e AuthContext

- [ ] `frontend/src/services/api.ts`:
  - Instância Axios com `baseURL: ""` (proxy resolve).
  - Request interceptor: se `localStorage.getItem("token")` existe, adiciona `Authorization: Bearer <token>`.
  - Response interceptor: se status `401`, limpa `localStorage` (`token`, `user`), redireciona para `/login` com query `?expired=true`.
  - Helper `unwrap(response)`: extrai `response.data.data` do envelope `{ok, data, meta}`.
  - Helper `unwrapError(error)`: extrai `error.response.data` para código/mensagem de erro.
- [ ] `frontend/src/services/auth.ts` — funções tipadas:
  - `register(name, email, password)` → `POST /api/v1/auth/register` → retorna `{token, user}`.
  - `login(email, password)` → `POST /api/v1/auth/login` → retorna `{token, user}`.
  - `logout()` → `POST /api/v1/auth/logout` → limpa localStorage.
  - `getMe()` → `GET /api/v1/auth/me` → retorna user com roles.
- [ ] `frontend/src/contexts/AuthContext.tsx`:
  - State: `user` (com `id`, `email`, `name`, `roles[]`), `token`, `loading`, `isAuthenticated`.
  - `login(email, password)`: chama auth.login, salva token + user no localStorage, seta state.
  - `register(name, email, password)`: chama auth.register, salva, seta state.
  - `logout()`: chama auth.logout, limpa localStorage, seta state null.
  - `hasRole(role: string): boolean` — verifica se o user tem a role (customer, seller, courier, admin).
  - No mount: se token existe no localStorage, chama `getMe()` para validar; se 401, limpa.
- [ ] Tipos TypeScript em `frontend/src/types/`:
  - `api.ts`: `ApiResponse<T>`, `ApiError`, `PaginationMeta`.
  - `auth.ts`: `User`, `LoginRequest`, `RegisterRequest`, `AuthState`.
  - `models.ts`: `Seller`, `Product`, `Category`, `Cart`, `CartItem`, `Order`, `OrderItem`, `Address`, `Favorite`, `Ticket`, `TicketMessage`, `Courier`, `Invoice`, `Payment`, `MarketplaceSetting`.

---

## T14.5 — Autenticação: Login, Registro, Logout

- [ ] `LoginPage.tsx`:
  - Centralizada vertical/horizontal.
  - Card brutalista com título `"Entrar"` em `font-black italic text-3xl`.
  - Campos: email (type email), senha (type password). Ambos com Input brutalista.
  - Botão "Entrar" (primary). Botão "Criar conta" (outline, navega para `/register`).
  - Se `?expired=true` na URL: toast/banner vermelho "Sua sessão expirou. Faça login novamente."
  - Erro 401: mensagem "Email ou senha incorretos" sob o formulário (UX-003: preserva email digitado).
  - Após login: redireciona para dashboard do primeiro role do user (`customer` → `/customer/orders`, `seller` → `/seller/orders`, `courier` → `/courier/deliveries`, `admin` → `/admin/dashboard`).
- [ ] `RegisterPage.tsx`:
  - Card brutalista com título `"Criar conta"`.
  - Campos: nome completo, email, senha, confirmar senha.
  - Validação client-side: email format, senha mínimo 6 chars, senhas iguais.
  - Erro 422: destaca campos com `border-brutal-red` e mostra mensagem do backend por campo.
  - Após registro: login automático e redirecionamento para `/customer/orders`.
  - Link "Já tem conta? Entrar" → `/login`.
- [ ] Botão de logout no Header: chama `AuthContext.logout()` → redireciona para `/`.

---

## T14.6 — Área pública: Home, Sellers, Produtos e Guest Cart

**Endpoints consumidos:** `GET /api/v1/public/sellers`, `GET /api/v1/public/sellers/{id}`, `GET /api/v1/public/sellers/{seller_id}/products`, `GET /api/v1/public/products/{id}`, `POST|PATCH|DELETE /api/v1/public/cart/items`, `GET|DELETE /api/v1/public/cart`.

- [ ] `HomePage.tsx`:
  - Hero section: título grande em `font-black italic` ("Seu delivery. Já chegou."), subtítulo, botão CTA "Explorar sellers" → `/sellers`.
  - Seção "Como funciona" — 3 cards brutalistas: Escolha → Peça → Receba.
  - Seção "Sellers em destaque" — grid de cards de sellers (consumir `GET /api/v1/public/sellers?limit=6`).
  - Seção "Seja parceiro" / "Seja entregador" — CTAs para páginas estáticas futuras.
- [ ] `SellersPage.tsx`:
  - Título `"Sellers"` em PageTitle brutalista.
  - Grid de SellerCards (nome, descrição, badge de status). Cada card clicável → `/sellers/:id`.
  - Paginação se houver `meta.page`/`meta.total_pages`. EmptyState se nenhum seller.
- [ ] `SellerDetailPage.tsx`:
  - Header do seller: nome em `font-black italic`, descrição, badge moderation_state.
  - Lista de produtos desse seller (`GET /api/v1/public/sellers/{seller_id}/products`).
  - Cada produto: Card com nome, preço (formatado BRL: `R$ XX,XX`), badge disponibilidade.
  - Botão "Adicionar ao carrinho" em cada produto → chama `POST /api/v1/public/cart/items` com `{product_id, quantity: 1}`.
  - Se resposta 201: toast de sucesso. Se seller diferente do cart atual: exibir ConfirmDialog "Seu carrinho será substituído. Continuar?" (guest-cart replace policy).
- [ ] `ProductDetailPage.tsx`:
  - Detalhes do produto: nome, descrição, preço formatado, estoque (quantidade disponível ou "Esgotado").
  - Botão "Adicionar ao carrinho" se em estoque.
  - Seletor de quantidade (`1..10` ou max estoque) com Input numérico.
- [ ] `GuestCartWidget.tsx` (componente no Header público):
  - Ícone de carrinho com badge de quantidade de itens.
  - Click abre painel lateral (slide-over) com lista de itens do guest cart (`GET /api/v1/public/cart`).
  - Cada item: nome, qty, preço unitário, botão remover (`DELETE /api/v1/public/cart/items/{id}`).
  - Botão "Editar quantidade" → `PATCH /api/v1/public/cart/items/{id}` com `{quantity}`.
  - Botão "Fazer login para finalizar" → `/login` (após login, handoff do guest cart acontece via `POST /api/v1/customer/cart/handoff`).
  - EmptyState se carrinho vazio.
- [ ] Formatação monetária: criar helper `formatMoney(cents: number, currency: string): string` → `R$ 12,50` para BRL.

---

## T14.7 — Customer: Perfil, Endereços e Favoritos

**Endpoints:** `GET|PATCH /api/v1/customer/profile`, `GET|POST /api/v1/customer/addresses`, `GET|PATCH|DELETE /api/v1/customer/addresses/{id}`, `POST /api/v1/customer/addresses/{id}/default`, `GET|POST /api/v1/customer/favorites`, `DELETE /api/v1/customer/favorites/{id}`.

- [ ] `customer/ProfilePage.tsx`:
  - Card com dados do perfil: nome completo, email (readonly), data de criação.
  - Formulário de edição inline (nome completo). Botão "Salvar" (`PATCH /api/v1/customer/profile`).
- [ ] `customer/AddressesPage.tsx`:
  - Lista de endereços em cards brutalistas. Badge "Padrão" no endereço default.
  - Cada card: rua, número, complemento, bairro, cidade, estado, CEP. Botões: "Editar" (abre Modal), "Excluir" (ConfirmDialog), "Tornar padrão" (`POST .../default`).
  - Botão "Novo endereço" → abre Modal com formulário (campos: street, number, complement, neighborhood, city, state, zip_code). `POST /api/v1/customer/addresses`.
  - Validação 422: destaca campos errados.
- [ ] `customer/FavoritesPage.tsx`:
  - Grid de sellers favoritados (`GET /api/v1/customer/favorites`).
  - Cada card: nome do seller, botão "Remover" (`DELETE /api/v1/customer/favorites/{id}`).
  - Botão "Explorar sellers" → `/sellers` se lista vazia (EmptyState).

---

## T14.8 — Customer: Carrinho, Checkout e Handoff

**Endpoints:** `GET|DELETE /api/v1/customer/cart`, `POST /api/v1/customer/cart/items`, `PATCH|DELETE /api/v1/customer/cart/items/{id}`, `POST /api/v1/customer/cart/handoff`, `POST /api/v1/customer/checkout`.

- [ ] `customer/CartPage.tsx`:
  - Handoff automático: ao montar, se guest cart existia (cookie/localStorage), chamar `POST /api/v1/customer/cart/handoff` silenciosamente. Exibir toast se houver merge.
  - Lista de itens do carrinho (`GET /api/v1/customer/cart`).
  - Cada item: nome produto, quantidade (editável via input numérico → `PATCH .../items/{id}`), preço unitário, subtotal. Botão "Remover" → `DELETE`.
  - Resumo: subtotal, taxa de entrega, total. Todos em `formatMoney()`.
  - Botão "Limpar carrinho" (ConfirmDialog → `DELETE /api/v1/customer/cart`).
  - Botão "Finalizar compra" → navega para `/customer/checkout`.
  - EmptyState se carrinho vazio: "Seu carrinho está vazio" + botão "Explorar sellers".
- [ ] `customer/CheckoutPage.tsx`:
  - Resumo do carrinho (readonly): itens, quantidades, preços, total.
  - Seletor de endereço de entrega: dropdown com endereços do customer (`GET /api/v1/customer/addresses`). Endereço padrão pré-selecionado. Link "Adicionar endereço" → abre Modal.
  - Botão "Confirmar pedido" → `POST /api/v1/customer/checkout` com `{address_id}`.
  - Resposta 201: exibir Card de sucesso com order ID, navegar para `/customer/orders/{id}`.
  - Resposta 422 `insufficient_inventory`: mensagem "Estoque insuficiente para um ou mais itens". Manter carrinho recuperável.
  - Resposta 422 `idempotency_conflict`: mensagem "Este pedido já foi processado".
  - Resposta 422/500 `external_dependency_unavailable`: mensagem "Erro no processamento do pagamento. Tente novamente."

---

## T14.9 — Customer: Pedidos, Tracking e Tickets

**Endpoints:** `GET /api/v1/customer/orders/{id}/cancel` (POST), `GET /api/v1/customer/orders/{id}/tracking`, `GET|POST /api/v1/customer/tickets`, `GET /api/v1/customer/tickets/{id}`, `POST /api/v1/customer/tickets/{id}/messages`.

- [ ] `customer/OrdersPage.tsx`:
  - Lista paginada de pedidos do customer. Buscar de onde? A API não tem `GET /api/v1/customer/orders` explícito — verificar se existe. Se não: página estática "Ver tracking de pedido por ID".
  - Cada card: order ID (truncado), status (Badge), data, total, seller. Click → `/customer/orders/:id`.
- [ ] `customer/OrderDetailPage.tsx`:
  - Card com: status atual (Badge grande), data de criação, seller.
  - Lista de itens: nome, quantidade, preço unitário, subtotal.
  - Totais: subtotal, delivery_fee, discount, courier_fee, total.
  - Histórico de status: timeline vertical com estado + data + ator. Estado em `font-bold`, data em `text-sm text-gray-500`.
  - Se status é `pending`: botão "Cancelar pedido" (ConfirmDialog → `POST .../cancel`).
- [ ] `customer/TrackingPage.tsx`:
  - Consome `GET /api/v1/customer/orders/{id}/tracking`.
  - Card com: estado atual do pedido, histórico de transições.
  - Se courier atribuído e localização disponível: exibir coordenadas (lat, lng) e timestamp de última atualização. Sem mapa (deferred) — exibir dados textuais: "Courier próximo — última posição: X, Y às HH:MM".
  - Mensagem de freshness: "Atualizado há X minutos" (UX: não implicar real-time se periódico).
- [ ] `customer/TicketsPage.tsx`:
  - Lista de tickets do customer (`GET /api/v1/customer/tickets`).
  - Cada card: subject, status (Badge), data de criação. Click → `/customer/tickets/:id`.
  - Botão "Novo ticket" → abre Modal com campos: subject, message, order_id (opcional, dropdown com pedidos do customer). `POST /api/v1/customer/tickets`.
- [ ] `customer/TicketDetailPage.tsx`:
  - Título do ticket, status (Badge), data.
  - Lista de mensagens em timeline (chat-like): mensagem do customer (alinhada à direita, bg-white), mensagem do admin (alinhada à esquerda, bg-brutal-gray). Cada uma com sender, timestamp, body.
  - Campo de nova mensagem + botão "Enviar" (`POST .../messages`). Interativo: limpa campo após envio, adiciona mensagem à lista.

---

## T14.10 — Seller: Onboarding e Perfil

**Endpoints:** `POST /api/v1/seller/onboarding`, `GET|PATCH /api/v1/seller/profile`, `GET|PATCH /api/v1/seller/settings`.

- [ ] `seller/OnboardingPage.tsx`:
  - Formulário de onboarding: business_name, document (CNPJ/CPF), description, phone.
  - Botão "Enviar para aprovação" → `POST /api/v1/seller/onboarding`.
  - Sucesso 201: Card de confirmação "Sua loja foi enviada para análise" + Badge `pending_review`.
  - Erro 422: destaca campos. Se already onboarded: mensagem "Você já tem um cadastro de seller".
  - Se já tem seller: redirecionar para `/seller/products`.
- [ ] `seller/ProfilePage.tsx`:
  - Card com dados do seller: business_name, document, description, phone, moderation_state (Badge).
  - Formulário de edição: business_name, description, phone (document readonly).
  - Botão "Salvar" → `PATCH /api/v1/seller/profile`.
  - Se `moderation_state != approved`: banner "Sua loja está em análise / suspensa / rejeitada" com Badge.
- [ ] `seller/SettingsPage.tsx`:
  - Card com settings do seller (`GET /api/v1/seller/settings`).
  - Formulário de edição dos settings editáveis. `PATCH /api/v1/seller/settings`.

---

## T14.11 — Seller: Categorias e Produtos

**Endpoints:** `GET|POST /api/v1/seller/categories`, `GET|PATCH|DELETE /api/v1/seller/categories/{id}`, `PUT /api/v1/seller/categories/order`, `GET|POST /api/v1/seller/products`, `GET|PATCH|DELETE /api/v1/seller/products/{id}`, `POST .../activate`, `POST .../deactivate`.

- [ ] `seller/CategoriesPage.tsx`:
  - Lista de categorias com drag-and-drop para reordenar (ou botões ↑↓). Ao reordenar: `PUT /api/v1/seller/categories/order` com `{ids: [...]}`.
  - Cada card: nome, posição, botões "Editar" (Modal) e "Excluir" (ConfirmDialog → DELETE).
  - Botão "Nova categoria" → Modal com campo nome. `POST /api/v1/seller/categories`.
  - Erro ao excluir (422 referential): mensagem "Categoria possui produtos vinculados".
- [ ] `seller/ProductsPage.tsx`:
  - Tabela brutalista de produtos: nome, preço (formatMoney), categoria, status (Badge: active/inactive), ações.
  - Ações: "Editar" → `/seller/products/:id`, "Ativar/Desativar" → `POST .../activate` ou `.../deactivate` (toggle), "Excluir" (ConfirmDialog → DELETE).
  - Botão "Novo produto" → `/seller/products/new` ou Modal com formulário.
  - Formulário de produto (Modal ou página):
    - Campos: name, description, price_cents (input monetário: digita `12,50` → envia `1250`), category_id (dropdown), image_url (texto).
    - `POST /api/v1/seller/products` (novo) ou `PATCH` (editar).
  - EmptyState se nenhum produto.
- [ ] `seller/InventoryPage.tsx`:
  - Tabela: produto, estoque atual, input para ajustar quantidade.
  - Botão "Atualizar" por linha → `PATCH /api/v1/seller/inventory/{product_id}` com `{quantity}`.
  - Validação: quantidade >= 0, inteiro.

---

## T14.12 — Seller: Pedidos recebidos e transições

**Endpoints:** `GET /api/v1/seller/orders`, `GET /api/v1/seller/orders/{id}`, `POST .../accept`, `.../reject`, `.../preparing`, `.../ready`.

- [ ] `seller/OrdersPage.tsx`:
  - Filtros por status: tabs "Pendentes", "Aceitos", "Em preparação", "Prontos", "Todos".
  - Tabela: ID (truncado), customer info, itens (resumo), total, status (Badge), data. Click → detalhe.
  - Badge vermelha pulsante em "Pendentes" se houver pedidos pendentes.
- [ ] `seller/OrderDetailPage.tsx`:
  - Card com detalhes: status (Badge grande), data, customer.
  - Lista de itens com quantidades e preços.
  - Totais discriminados.
  - Botões de transição conforme estado atual (state machine):
    - `pending` → "Aceitar" (primary) + "Rejeitar" (danger com ConfirmDialog e campo razão).
    - `accepted` → "Iniciar preparo" (primary).
    - `preparing` → "Pronto para entrega" (primary).
    - `ready` → sem ação (aguardando courier).
  - Cada ação: `POST /api/v1/seller/orders/{id}/{action}`. Feedback: reload do pedido com novo status.
  - Histórico de transições: timeline como no customer.

---

## T14.13 — Courier: Onboarding, Perfil e Disponibilidade

**Endpoints:** `POST /api/v1/courier/onboarding`, `GET|PATCH /api/v1/courier/profile`, `PATCH /api/v1/courier/availability`.

- [ ] `courier/OnboardingPage.tsx`:
  - Formulário: full_name, document (CPF), vehicle_type (select: moto, bicicleta, carro), phone.
  - Botão "Cadastrar como entregador" → `POST /api/v1/courier/onboarding`.
  - Sucesso: "Cadastro enviado para análise" + Badge `pending_review`.
- [ ] `courier/ProfilePage.tsx`:
  - Card: nome, documento, veículo, phone, approval_state (Badge), operational_state (Badge).
  - Formulário de edição: nome, phone, vehicle_type. `PATCH /api/v1/courier/profile`.
- [ ] `courier/AvailabilityPage.tsx`:
  - Card grande com estado operacional atual: `offline` (cinza), `available` (verde), `on_delivery` (azul).
  - Toggle brutalista (botão grande): "Ficar disponível" / "Ficar offline" → `PATCH /api/v1/courier/availability` com `{available: true/false}`.
  - Se on_delivery: toggle desabilitado com mensagem "Finalize sua entrega atual antes de alterar disponibilidade".
  - Se não aprovado: toggle desabilitado com mensagem "Aguardando aprovação do admin".

---

## T14.14 — Courier: Entregas (eligible, accept, pickup, deliver) e Stats

**Endpoints:** `GET /api/v1/courier/orders/eligible`, `GET /api/v1/courier/orders/active`, `GET /api/v1/courier/orders/history`, `POST .../accept`, `.../pickup`, `.../deliver`, `GET /api/v1/courier/stats`.

- [ ] `courier/DeliveriesPage.tsx`:
  - Duas seções:
    1. **Entrega ativa** (se houver): Card grande com detalhes do pedido ativo (`GET .../active`). Botões de transição:
       - `assigned` → "Confirmar coleta" (pickup).
       - `picked_up` → "Confirmar entrega" (deliver).
       - Cada ação requer `Idempotency-Key` header (gerar UUID v4 no frontend).
    2. **Entregas disponíveis**: lista de pedidos elegíveis (`GET .../eligible`). Cada card: seller, endereço de entrega (parcial), número de itens. Botão "Aceitar entrega" → `POST .../accept` com `Idempotency-Key`.
       - Sucesso: recarrega página, entrega aparece em "Entrega ativa".
       - Erro 409/422 (já aceita por outro): mensagem "Esta entrega já foi aceita por outro entregador".
  - EmptyState se sem entregas disponíveis: "Nenhuma entrega disponível no momento".
- [ ] `courier/HistoryPage.tsx`:
  - Lista paginada de entregas concluídas (`GET .../history`). Cada card: data, seller, status terminal, valor courier_fee.
- [ ] `courier/StatsPage.tsx`:
  - Card de estatísticas (`GET /api/v1/courier/stats`): total de entregas, ganhos totais (formatMoney por currency), média por entrega.
  - Exibir breakdown por currency se múltiplas moedas existirem.

---

## T14.15 — Admin: Dashboard e Gestão de Usuários

**Endpoints:** `GET /api/v1/admin/dashboard`, `GET /api/v1/admin/users`, `GET /api/v1/admin/users/{id}`, `POST .../disable`, `.../enable`.

- [ ] `admin/DashboardPage.tsx`:
  - Grid de cards de métricas (consumir `GET /api/v1/admin/dashboard`):
    - Total de usuários, sellers ativos, couriers ativos, pedidos hoje, tickets abertos, pagamentos pendentes.
  - Cada métrica: número grande em `font-black text-5xl`, label em `text-sm uppercase`, ícone.
  - Cards com `border-4 border-black rounded-3xl shadow-brutal`.
- [ ] `admin/UsersPage.tsx`:
  - Tabela brutalista: nome, email, roles (Badges), status (ativo/disabled), data de criação.
  - Click na row → `/admin/users/:id`.
  - Paginação.
- [ ] `admin/UserDetailPage.tsx`:
  - Card com detalhes do user: nome, email, roles, status, criação.
  - Botão "Desabilitar" (ConfirmDialog → `POST .../disable`) ou "Habilitar" (`POST .../enable`) conforme status.

---

## T14.16 — Admin: Moderação de Sellers e Couriers

**Endpoints:** `GET /api/v1/admin/sellers`, `GET /api/v1/admin/sellers/{id}`, `POST .../approve|reject|suspend|reinstate`. Idem para couriers.

- [ ] `admin/SellersPage.tsx`:
  - Tabela: business_name, document, moderation_state (Badge), data. Click → detalhe.
  - Filtros por status: tabs "Pendentes", "Aprovados", "Suspensos", "Rejeitados", "Todos".
- [ ] `admin/SellerDetailPage.tsx`:
  - Card com todos os dados do seller.
  - Botões de moderação conforme estado (state machine):
    - `pending_review` → "Aprovar" (primary) + "Rejeitar" (danger, com ConfirmDialog + campo `reason`).
    - `approved` → "Suspender" (danger, ConfirmDialog + reason).
    - `suspended` → "Reativar" (primary).
  - Cada ação: `POST /api/v1/admin/sellers/{id}/{action}` com `{reason}` quando aplicável.
  - Feedback: reload com novo status.
- [ ] `admin/CouriersPage.tsx` — mesma estrutura que SellersPage, com endpoints de courier.
- [ ] `admin/CourierDetailPage.tsx` — mesma estrutura que SellerDetailPage:
  - Exibe: nome, documento, veículo, approval_state, operational_state.
  - Botões: approve/reject/suspend/reinstate conforme state machine.

---

## T14.17 — Admin: Pedidos, Pagamentos e Tickets

**Endpoints:** `GET /api/v1/admin/orders`, `GET /api/v1/admin/orders/{id}`, `POST .../cancel`, `GET /api/v1/admin/payments`, `GET /api/v1/admin/payments/{id}`, `POST .../confirm`, `GET /api/v1/admin/tickets`, `GET /api/v1/admin/tickets/{id}`, `POST .../messages`, `.../start_progress`, `.../resolve`, `.../reopen`, `.../close`.

- [ ] `admin/OrdersPage.tsx`:
  - Tabela: ID, customer, seller, status (Badge), total (formatMoney), data. Click → detalhe.
  - Filtros por status.
- [ ] `admin/OrderDetailPage.tsx`:
  - Mesmo layout que customer order detail, mas com botão "Cancelar pedido" → `POST .../cancel` (ConfirmDialog).
  - Visualização: itens, totais, status, histórico, courier (se atribuído).
- [ ] `admin/PaymentsPage.tsx`:
  - Tabela: ID, order_id, amount (formatMoney), status (Badge), data.
- [ ] `admin/PaymentDetailPage.tsx`:
  - Detalhes do pagamento. Se status `pending`: botão "Confirmar pagamento" → `POST .../confirm`.
- [ ] `admin/TicketsPage.tsx`:
  - Tabela: subject, customer, status (Badge), data. Click → detalhe.
  - Filtros por status.
- [ ] `admin/TicketDetailPage.tsx`:
  - Histórico de mensagens (chat-like, como customer).
  - Botões de transição conforme estado:
    - `open` → "Iniciar atendimento" (start_progress) + "Resolver" (resolve).
    - `in_progress` → "Resolver" (resolve).
    - `resolved` → "Reabrir" (reopen) + "Fechar" (close).
  - Campo de nova mensagem + botão "Enviar" (`POST .../messages`).

---

## T14.18 — Admin: Faturas, Configurações e Observabilidade

**Endpoints:** `GET /api/v1/admin/invoices`, `POST /api/v1/admin/invoices/generate`, `GET /api/v1/admin/invoices/{id}`, `GET|POST /api/v1/admin/settings`, `GET /api/v1/admin/observability/summary|requests|orders|jobs`.

- [ ] `admin/InvoicesPage.tsx`:
  - Tabela de faturas: seller, período, total, data de geração. Click → detalhe.
  - Botão "Gerar fatura" → Modal com campos: seller_id (dropdown), period_start, period_end (date inputs). `POST /api/v1/admin/invoices/generate`.
- [ ] `admin/InvoiceDetailPage.tsx`:
  - Card com detalhes: seller, período, breakdown (subtotal, fees), total.
- [ ] `admin/SettingsPage.tsx`:
  - Lista de settings atuais (`GET /api/v1/admin/settings`). Cada setting: key, value, effective_from.
  - Formulário para adicionar novo setting: key (select entre opções conhecidas), value, effective_from (date). `POST /api/v1/admin/settings`.
- [ ] `admin/ObservabilityPage.tsx`:
  - Cards com métricas do sistema (`GET .../summary`): total de requests recentes, orders pendentes, jobs no outbox.
  - Tabela de requests recentes (`.../requests`): path, method, status, duration.
  - Tabela de orders recentes (`.../orders`): ID, status, data.
  - Tabela de jobs (`.../jobs`): tipo, status, tentativas, próxima execução.

---

## T14.19 — Estados visuais, i18n e polish final

- [ ] **Empty states** em todas as listagens: EmptyState brutalista com ícone + mensagem + ação.
- [ ] **Loading states**: LoadingSpinner em todas as páginas que fazem fetch.
- [ ] **Error states**: ErrorState com botão "Tentar novamente" em todos os fetches que falharem.
- [ ] **Toast notifications**: componente `Toast.tsx` para feedback de ações (sucesso verde, erro vermelho). Posição: bottom-right, auto-dismiss 4s.
- [ ] **Responsividade**: todas as páginas funcionais em mobile (≥375px). Grid → coluna única. Tabela → cards stacked. Sidebar admin → menu hamburger.
- [ ] **i18n base**: criar `frontend/src/i18n/pt-BR.ts` com todas as strings da UI. Componentes usam constantes do i18n, nunca strings hardcoded (UX-008). Idioma base: português brasileiro.
- [ ] **Formatação monetária**: `formatMoney(1250, "BRL")` → `R$ 12,50`. Nunca exibir centavos brutos.
- [ ] **Status labels**: vocabulário consistente (UX-005). Mapear todos os status do backend para labels PT-BR:
  - `pending` → "Pendente", `accepted` → "Aceito", `rejected` → "Rejeitado", `preparing` → "Em preparo", `ready` → "Pronto", `assigned` → "Em entrega", `picked_up` → "Coletado", `delivered` → "Entregue", `cancelled` → "Cancelado".
  - `pending_review` → "Aguardando análise", `approved` → "Aprovado", `suspended` → "Suspenso".
  - `open` → "Aberto", `in_progress` → "Em atendimento", `resolved` → "Resolvido", `closed` → "Fechado".
  - `paid` → "Pago", `failed` → "Falhou", `refunded` → "Estornado".
- [ ] **Confirmação em ações destrutivas** (UX-004): ConfirmDialog em todas as ações de cancelar, excluir, rejeitar, suspender.
- [ ] **Preservar input após falha** (UX-003): formulários não limpam campos após erro 422.
- [ ] **Verificar**: `npm run build` passa sem erros (TypeScript strict).
- [ ] **Verificar**: navegação entre todos os fluxos funcional com backend rodando.
