# JaChegai — Portable Product and System Specification

**Document status:** Draft baseline for implementation planning
**Version:** 1.0.0
**Last updated:** 2026-07-31
**Technology posture:** Language-, framework-, provider-, database-, and deployment-agnostic
**Review state:** Review required

## 0. Purpose

This document specifies what JaChegai must do without prescribing how it must be implemented. It is intended to be portable input for creating an implementation plan in any suitable technology stack.

It preserves:

- product outcomes;
- actors and permissions;
- domain language and invariants;
- functional capabilities;
- workflows and state machines;
- logical service and integration boundaries;
- conceptual data requirements;
- security, privacy, reliability, and quality requirements;
- acceptance scenarios and release gates.

It intentionally does not select:

- a programming language or runtime;
- a backend or frontend framework;
- an API transport style;
- an identity product;
- a database product or data-access library;
- a queue, broker, or job runner;
- an object-storage provider;
- a payment provider;
- a mapping provider;
- a cloud, container, or orchestration platform;
- a testing library or CI provider.

The implementation planner must select those mechanisms and demonstrate how each selection satisfies this specification.

### 0.1 Normative language

- **MUST / MUST NOT:** mandatory for the stated release.
- **SHOULD / SHOULD NOT:** expected unless a documented trade-off justifies an exception.
- **MAY:** optional.

### 0.2 Requirement identifiers

Requirements use stable prefixes:

| Prefix | Area |
|---|---|
| `PRD` | product outcome and scope |
| `IAM` | identity and access management |
| `PUB` | public acquisition and discovery |
| `CUS` | customer experience |
| `SEL` | seller operations |
| `COU` | courier operations |
| `ORD` | cart, checkout, order, and delivery lifecycle |
| `PAY` | payment and financial records |
| `SUP` | support |
| `ADM` | administration and marketplace operations |
| `DAT` | conceptual data and consistency |
| `INT` | integrations and asynchronous work |
| `UX` | user experience and accessibility |
| `SEC` | security and privacy |
| `NFR` | non-functional requirements |
| `TST` | verification and release quality |

Every implementation-plan item SHOULD reference one or more requirement IDs. Every mandatory requirement MUST have test or review evidence before release.

---

## 1. Product Definition

JaChegai is a local beverage-delivery marketplace that connects buyers, stores, delivery couriers, and marketplace operators.

### 1.1 Primary product outcomes

| ID | Outcome |
|---|---|
| PRD-001 | A customer can discover a local seller, select available products, place an order, and follow fulfillment. |
| PRD-002 | A seller can onboard a store, publish products and inventory, receive an order, and prepare it for delivery. |
| PRD-003 | A courier can become available, accept an eligible delivery, collect it, and complete it. |
| PRD-004 | An administrator can moderate marketplace participants, monitor orders, handle support, and maintain essential operational settings. |
| PRD-005 | A visitor can understand the service and begin product discovery before being forced to authenticate. |

The MVP is not complete unless all four operational outcomes work together in one end-to-end scenario.

### 1.2 Product principles

- Optimize first for a complete buying-and-delivery loop.
- Do not confuse visual prototypes with completed operational flows.
- Keep customer, seller, courier, and administrator experiences distinct.
- Share common capabilities and visual language where this reduces duplication.
- Introduce operational complexity only when a measured product or reliability need requires it.
- Preserve auditability for money, inventory, moderation, and order state changes.

### 1.3 Product success indicators

The system MUST make it possible to measure:

- account registration and successful authentication by actor type;
- approved and active sellers;
- published and in-stock products;
- carts started and orders created;
- checkout success and failure reasons;
- orders by lifecycle state;
- order completion and cancellation/rejection rates;
- available couriers and completed deliveries;
- payment records by state;
- open and aging support tickets;
- operational failures and delayed asynchronous work.

Numeric targets are deployment-specific inputs and must be filled in the implementation decision worksheet.

---

## 2. Scope

### 2.1 MVP scope

The MVP includes:

1. public marketing, institutional content, seller discovery, product discovery, and guest-cart entry;
2. identity, authentication, authorization, and actor onboarding;
3. customer profile, addresses, favorites, persistent cart, checkout, order history, order detail, tracking, and support;
4. seller profile, moderation state, categories, products, inventory, and order handling;
5. courier profile, approval, availability, delivery queue, assignment, location updates, and basic statistics;
6. administrator dashboards, participant moderation, order oversight, support visibility, basic settings, fees, invoices, audit, and operational health;
7. payment abstraction with a manual or simulated option that does not block the end-to-end order flow;
8. reliable persistence, schema evolution, background work, file handling, observability, backup, and recovery appropriate to the selected deployment;
9. responsive installable web experiences or equivalent platform experiences for the public area and four operational actors.

### 2.2 Outside MVP unless explicitly promoted

- multiple sellers in one checkout;
- complex multi-tenancy;
- social login;
- mandatory external identity federation;
- partial order fulfillment;
- partial cancellation;
- refunds and chargebacks;
- automated seller settlement;
- advanced fiscal issuance;
- promotions, coupons, subscriptions, or loyalty programs;
- dynamic courier dispatch optimization;
- route optimization;
- customer-to-courier chat;
- multi-warehouse inventory;
- advanced analytics and forecasting;
- native mobile distribution;
- internationalization beyond the baseline locale;
- independently deployed product-area applications;
- active-active multi-region operation.

An implementation MAY prepare clean boundaries for these capabilities but MUST NOT add speculative operational complexity to the MVP.

---

## 3. Actors and Authorization Model

### 3.1 Actors

| Actor | Goal | Primary authority |
|---|---|---|
| Visitor | Understand the service and discover sellers/products | Public content and guest cart |
| Customer | Buy products and follow/support orders | Own profile, addresses, favorites, carts, orders, and tickets |
| Seller user | Operate a seller/store | Own seller profile, catalog, inventory, and seller orders |
| Courier | Deliver eligible orders | Own courier profile, availability, assigned deliveries, and location |
| Administrator | Operate the marketplace | Participant moderation, order oversight, support, settings, invoices, audit, and health |
| System worker | Execute reliable background effects | Only explicitly authorized jobs and integration calls |

### 3.2 Authorization requirements

| ID | Requirement |
|---|---|
| IAM-001 | Every protected operation MUST resolve an authenticated principal. |
| IAM-002 | Every protected operation MUST enforce role/capability authorization server-side. |
| IAM-003 | Customer data access MUST be restricted to the owning customer except for explicitly authorized administrator operations. |
| IAM-004 | Seller mutations MUST be restricted to users authorized for that seller. |
| IAM-005 | Courier pickup and delivery transitions MUST be restricted to the assigned courier. |
| IAM-006 | Administrative operations MUST require administrator authority. |
| IAM-007 | Public self-registration MUST NOT allow privilege escalation to administrator. |
| IAM-008 | Disabling a user MUST prevent new authentication and invalidate or reject existing access. |
| IAM-009 | The first administrator MUST be provisioned through a controlled bootstrap process. |
| IAM-010 | Authentication and authorization failures MUST not reveal sensitive account details. |

### 3.3 Identity implementation boundary

The product requires identity capabilities, not a specific identity product.

An implementation MAY use:

- application-managed credentials and sessions;
- an external identity provider using a standards-based authentication protocol;
- a hybrid model behind an identity adapter.

If external identity is selected, the implementation SHOULD use an interoperable authentication layer such as OpenID Connect over OAuth 2.x or an equivalent approved standard. Product services MUST depend on a normalized principal containing at least:

```text
principal_id
actor_roles or capabilities
active status
verified identity attributes required by policy
correlation/session context
```

The implementation plan MUST define account linking, logout, session/token lifetime, revocation, administrator bootstrap, provider outage behavior, and migration between identity mechanisms.

---

## 4. Ubiquitous Language

| Term | Definition |
|---|---|
| User | A normalized identity recognized by the application |
| Principal | The authenticated security context for one request or operation |
| Customer | A buyer profile associated with a user |
| Seller | A store/business that owns a catalog, inventory, and incoming orders |
| Seller membership | Authorization relationship between a user and a seller |
| Courier | A delivery operator profile associated with a user |
| Address | A customer-owned delivery destination |
| Category | Seller-owned product grouping |
| Product | Seller-owned item offered for sale |
| Inventory item | Sellable quantity for one seller product |
| Guest cart | Pre-authentication product selection associated with a visitor context |
| Customer cart | Persistent, seller-scoped product selection owned by a customer |
| Checkout | Atomic conversion of an eligible cart into an order and related records |
| Order | Commercial snapshot between one customer and one seller |
| Order item | Immutable product-name, quantity, and unit-price snapshot within an order |
| Order history entry | Append-only record of an order lifecycle transition |
| Delivery | Courier-facing fulfillment of an order after seller preparation |
| Payment record | Financial state associated one-to-one with an order in the MVP |
| Favorite | Customer bookmark of a seller |
| Support ticket | Customer support case, optionally associated with an order |
| Invoice | Simple seller-facing or operator-facing charge record for a period |
| Audit record | Append-only evidence of a sensitive operation |
| Domain event | Fact that occurred in the business domain |
| Background job | Retryable asynchronous processing of a domain event or scheduled action |

### 4.1 Terminology rules

- **User** and **Customer** are not synonyms.
- **Seller** means the business/store, not the seller user's identity.
- **Order status** and **payment status** are independent state machines.
- **Courier approval** and **courier availability** are independent concepts.
- **Seller approval** and **seller open/closed operating state** are independent concepts if operating hours are introduced.
- **Guest cart** and **customer cart** are different ownership contexts and require an explicit handoff policy.

---

## 5. Capability Map

The implementation SHOULD organize responsibilities around these logical capabilities, regardless of physical module or service boundaries:

```text
Public Experience
Identity and Access
Customer Management
Seller Management
Catalog
Inventory
Cart and Checkout
Order Management
Courier and Delivery
Payments
Support
Fees and Invoices
Administration
Audit
Notifications
Background Work
File Storage
Observability
```

Logical boundaries do not imply separate processes, repositories, deployments, or databases. The implementation planner MUST choose the simplest topology that satisfies scale, team, reliability, and deployment constraints.

### 5.1 Capability dependency direction

- Public Experience reads approved seller/catalog data and manages guest-cart context.
- Checkout depends on Customer, Seller, Catalog, Inventory, Order, Payment, and Background Work capabilities.
- Seller and Courier operations use Order Management but MUST NOT bypass its lifecycle rules.
- Administration orchestrates management capabilities through authorized application interfaces.
- Notifications consume domain events and MUST NOT own core business state.
- Observability receives operational signals but MUST NOT become required for core transaction correctness.

---

## 6. Public Experience Requirements

| ID | Requirement |
|---|---|
| PUB-001 | The public home MUST communicate the value proposition and provide entry points for customer, seller, and courier journeys. |
| PUB-002 | Public content MUST include About, Become a Seller/Partners, Become a Courier, FAQ/Help, Terms, and Privacy. |
| PUB-003 | Visitors MUST be able to list sellers eligible for public discovery. |
| PUB-004 | Visitors MUST be able to view active and available products for a selected seller. |
| PUB-005 | Visitors MUST be able to begin a guest cart without early authentication. |
| PUB-006 | Product price and availability displayed or accepted by the server MUST come from trusted catalog/inventory state, never from client assertions. |
| PUB-007 | Guest-cart continuity MUST survive normal navigation for a documented duration. |
| PUB-008 | Authentication during purchase MUST have an explicit guest-cart handoff policy: merge, replace, or ask the customer. Silent data loss is prohibited. |
| PUB-009 | Public content SHOULD expose appropriate metadata for discovery, sharing, and indexing. |
| PUB-010 | A seller MUST not appear publicly unless its moderation state and publication rules permit it. |

### 6.1 Guest-cart rules

- A guest cart belongs to one visitor context.
- A guest cart MUST contain products from one seller for one checkout.
- Adding a product from another seller MUST apply a documented replace/confirm policy.
- Guest-cart identifiers MUST be opaque and protected from guessing or tampering.
- Guest-cart retention and cleanup MUST be defined.
- Client-provided quantity MUST be validated as a positive bounded integer.
- Unit price MUST be recalculated or verified from trusted product state.

---

## 7. Customer Requirements

| ID | Requirement |
|---|---|
| CUS-001 | A customer MUST be able to create, view, and update a buyer profile. |
| CUS-002 | A customer MUST be able to create, list, update, select, and delete owned delivery addresses, subject to order-history retention rules. |
| CUS-003 | A customer MUST be able to add, list, and remove favorite sellers. |
| CUS-004 | A customer MUST have one active cart per seller unless the implementation chooses a stricter single-cart policy. |
| CUS-005 | A customer MUST be able to add, update, remove, and list cart items. |
| CUS-006 | A customer MUST be shown authoritative prices, quantities, fees, and total before confirming checkout. |
| CUS-007 | Delivery checkout MUST require a valid address owned by the customer. |
| CUS-008 | Checkout MUST return explicit success or a recoverable failure with a stable reason. |
| CUS-009 | A customer MUST be able to list and inspect only their own orders. |
| CUS-010 | Order detail MUST include item snapshots, monetary totals, current state, and lifecycle history. |
| CUS-011 | When a courier is assigned and location is available, the customer MUST be able to see fulfillment progress and the latest permitted location. |
| CUS-012 | A customer MUST be able to create a support ticket with a subject and initial message. |
| CUS-013 | A customer MUST be able to list their own support tickets and see ticket state. |
| CUS-014 | The customer experience MUST provide usable empty, loading, success, retry, and authorization-error states. |

### 7.1 Address rules

- Address ownership MUST be verified at checkout.
- Address deletion MUST NOT destroy the historical delivery destination of existing orders.
- The implementation MUST either snapshot delivery address fields into the order or preserve referenced address history immutably.
- Coordinates are optional unless required by the selected delivery model.
- Address validation/geocoding MAY be delegated through an adapter.

---

## 8. Seller Requirements

| ID | Requirement |
|---|---|
| SEL-001 | A seller-authorized user MUST be able to submit seller onboarding information. |
| SEL-002 | Seller public visibility MUST be controlled by a moderation state. |
| SEL-003 | An authorized seller user MUST be able to view and update basic store profile data. |
| SEL-004 | An authorized seller user MUST be able to create, list, update, order, and remove owned categories when referential rules allow it. |
| SEL-005 | An authorized seller user MUST be able to create, list, update, activate, and deactivate owned products. |
| SEL-006 | Product pricing MUST use the system's integer minor currency unit. |
| SEL-007 | An authorized seller user MUST be able to read and update inventory for owned products. |
| SEL-008 | Inventory MUST never become negative. |
| SEL-009 | A seller MUST be able to list and inspect orders belonging to that seller. |
| SEL-010 | A seller MUST be able to accept or reject a pending order. |
| SEL-011 | A seller MUST be able to move an accepted order into preparation and then ready-for-delivery state. |
| SEL-012 | Seller actions MUST follow the canonical order state machine and append history/audit evidence. |
| SEL-013 | Product media MUST be handled through a validated storage or trusted-media policy. |

### 8.1 Seller moderation state

Canonical seller moderation states:

```text
pending_review
approved
suspended
rejected
```

Allowed transitions and authority:

| From | To | Authority |
|---|---|---|
| `pending_review` | `approved` | administrator |
| `pending_review` | `rejected` | administrator |
| `approved` | `suspended` | administrator |
| `suspended` | `approved` | administrator |

A rejected seller MAY be allowed to resubmit through a separately specified workflow. Every moderation transition MUST be audited with actor, timestamp, target, action, and optional reason.

---

## 9. Courier Requirements

| ID | Requirement |
|---|---|
| COU-001 | A courier-authorized user MUST be able to submit courier onboarding information. |
| COU-002 | Courier approval MUST be controlled independently from operational availability. |
| COU-003 | An approved courier MUST be able to view and update a basic profile. |
| COU-004 | An approved courier MUST be able to become available or unavailable when not constrained by an active delivery. |
| COU-005 | Only an approved and available courier MAY accept a new delivery. |
| COU-006 | A courier MUST be able to view eligible unassigned deliveries and their own active deliveries. |
| COU-007 | Delivery acceptance MUST assign at most one courier and prevent concurrent double acceptance. |
| COU-008 | The assigned courier MUST be able to mark the delivery picked up and delivered according to the state machine. |
| COU-009 | A courier MUST NOT mutate another courier's assigned delivery. |
| COU-010 | A courier MAY publish location only under the documented consent, frequency, precision, and retention policy. |
| COU-011 | Courier statistics MUST include at least completed deliveries and estimated earnings under a documented calculation. |
| COU-012 | The courier experience MUST distinguish queue, active delivery, completed work, and availability state. |

### 9.1 Courier state dimensions

Courier approval state:

```text
pending_review
approved
suspended
rejected
```

Courier operational state:

```text
offline
available
on_delivery
```

Approval state and operational state MUST NOT be represented as one ambiguous field in the conceptual model.

---

## 10. Cart, Checkout, Order, and Delivery Rules

### 10.1 Cart invariants

| ID | Requirement |
|---|---|
| ORD-001 | One cart/checkout MUST contain products from exactly one seller. |
| ORD-002 | Cart quantities MUST be positive bounded integers. |
| ORD-003 | Adding a product MUST verify that the product belongs to the cart seller and is purchasable. |
| ORD-004 | The cart MAY retain a displayed price, but checkout MUST use an authoritative price validation policy. |
| ORD-005 | Removing the last item MAY delete or retain the empty cart according to a documented retention policy. |

### 10.2 Checkout invariants

| ID | Requirement |
|---|---|
| ORD-006 | Checkout MUST authenticate and resolve the customer. |
| ORD-007 | Checkout MUST verify seller eligibility, product ownership, product activity, quantity, inventory, and address ownership. |
| ORD-008 | Checkout MUST calculate subtotal, delivery fee, discounts if supported, and total on the trusted application side. |
| ORD-009 | Checkout MUST atomically create the order, item snapshots, initial history, payment record, inventory reservation/decrement, and reliable follow-up event. |
| ORD-010 | Checkout MUST prevent inventory from becoming negative under concurrent requests. |
| ORD-011 | Checkout retries MUST not create duplicate orders or duplicate charges. |
| ORD-012 | Cart clearing MUST occur only if order creation succeeds. |
| ORD-013 | Failed checkout MUST leave the cart recoverable unless a documented business rule says otherwise. |
| ORD-014 | Order item name, quantity, and unit price MUST remain historical snapshots after catalog changes. |
| ORD-015 | The delivery destination used for an order MUST remain historically reconstructable. |

The implementation plan MUST choose and document inventory semantics:

- decrement at checkout;
- reserve at checkout and decrement later;
- another model with equivalent overselling protection.

It must also define release/restoration behavior after rejection, expiration, or cancellation.

### 10.3 Canonical order state machine

States:

```text
pending
accepted
rejected
preparing
ready
assigned
picked_up
delivered
cancelled
```

Allowed transitions:

| From | To | Authorized actor/capability |
|---|---|---|
| `pending` | `accepted` | owning seller |
| `pending` | `rejected` | owning seller |
| `pending` | `cancelled` | authorized cancellation policy |
| `accepted` | `preparing` | owning seller |
| `accepted` | `cancelled` | authorized cancellation policy |
| `preparing` | `ready` | owning seller |
| `ready` | `assigned` | eligible courier assignment |
| `assigned` | `picked_up` | assigned courier |
| `assigned` | `cancelled` | authorized cancellation policy |
| `picked_up` | `delivered` | assigned courier |

Terminal states:

```text
rejected
delivered
cancelled
```

### 10.4 Transition requirements

| ID | Requirement |
|---|---|
| ORD-016 | Invalid transitions MUST fail without changing order state. |
| ORD-017 | Every successful transition MUST append a history record containing previous state, new state, actor, timestamp, and optional reason/note. |
| ORD-018 | State update, history append, and required domain-event persistence MUST be one consistency unit. |
| ORD-019 | Concurrent courier acceptance MUST result in exactly one successful assignment. |
| ORD-020 | Seller and courier ownership/assignment MUST be checked in the same authoritative operation as the transition. |
| ORD-021 | Cancellation actors, reasons, inventory effects, payment effects, and notification effects MUST be approved before a cancellation command is exposed. |
| ORD-022 | Order and payment state MUST remain separate even when one influences the other. |

### 10.5 Tracking

- Tracking MUST show the current order state and ordered history.
- The latest courier location MAY be shown only for an owned order and only within the permitted lifecycle/retention window.
- Location freshness MUST be visible to the customer.
- The UI MUST not imply continuous real-time tracking if updates are periodic.
- Map rendering is optional if a clear location/progress alternative satisfies the approved MVP experience; the product owner must decide this before implementation planning is final.

---

## 11. Payments and Financial Records

| ID | Requirement |
|---|---|
| PAY-001 | Every successfully created order MUST have exactly one initial payment record in the MVP. |
| PAY-002 | Payment amount and currency MUST match the authoritative order total and market configuration. |
| PAY-003 | The MVP MAY use a manual or simulated payment method if the complete operational order flow remains testable. |
| PAY-004 | Payment integration MUST be accessed through a provider-neutral application interface. |
| PAY-005 | External payment callbacks MUST be authenticated/verified according to the provider protocol. |
| PAY-006 | Payment commands and callbacks MUST be idempotent. |
| PAY-007 | External references MUST be unique where required to prevent duplicate processing. |
| PAY-008 | Payment transitions MUST be auditable and reconcilable against order state. |
| PAY-009 | Sensitive payment data MUST not be stored unless explicitly required and compliant with applicable standards. |
| PAY-010 | A provider outage MUST not corrupt order, inventory, or payment state. |

Canonical MVP payment states:

```text
pending
paid
failed
refunded
```

`refunded` may remain unused until refund capability is promoted. The implementation plan MUST define whether payment occurs before, during, or after order creation and how pending/failed payment affects inventory and order expiration.

### 11.1 Fees and invoices

- Monetary amounts MUST use integer minor units and an explicit currency.
- Platform fee configuration MUST be effective-dated or historically reconstructable.
- Existing order totals MUST not change when fee settings change.
- Simple invoices MUST identify seller, period, amount, currency, state, and timestamps.
- Invoice states are `pending`, `paid`, and `cancelled` for the MVP.
- Advanced tax calculation and legal fiscal documents are outside MVP unless promoted with jurisdiction-specific requirements.

---

## 12. Support Requirements

| ID | Requirement |
|---|---|
| SUP-001 | A customer MUST be able to create a ticket with subject and initial message. |
| SUP-002 | A ticket MAY reference an order owned by that customer. |
| SUP-003 | Ticket messages MUST be append-only and identify sender and timestamp. |
| SUP-004 | Customers MUST be restricted to their own tickets. |
| SUP-005 | Administrators MUST be able to list and inspect tickets and messages. |
| SUP-006 | Ticket state changes MUST be authorized and auditable. |
| SUP-007 | The implementation MUST define whether customer/admin replies and resolution are MVP or a subsequent slice. |

Canonical ticket states:

```text
open
in_progress
resolved
closed
```

Allowed transitions SHOULD be:

```text
open -> in_progress
open -> resolved
in_progress -> resolved
resolved -> open       # reopen by policy
resolved -> closed
```

The final implementation plan MUST approve exact reopen/close policy.

---

## 13. Administration Requirements

| ID | Requirement |
|---|---|
| ADM-001 | Administrators MUST have an operational dashboard with user, seller, courier, order, payment, and support indicators appropriate to the MVP. |
| ADM-002 | Administrators MUST be able to list users and inspect user status and actor relationships. |
| ADM-003 | Administrators MUST be able to list, inspect, approve, reject, suspend, and reinstate sellers according to policy. |
| ADM-004 | Administrators MUST be able to list, inspect, approve, reject, suspend, and reinstate couriers according to policy. |
| ADM-005 | Administrators MUST be able to list and inspect orders and their history. |
| ADM-006 | Administrators MUST be able to inspect support tickets and messages. |
| ADM-007 | Administrators MUST be able to read and update essential marketplace and fee settings. |
| ADM-008 | Administrators MUST be able to list and inspect simple invoices. |
| ADM-009 | Sensitive administrative commands MUST require explicit authorization and create immutable audit evidence. |
| ADM-010 | The administrator experience MUST show operational failures without exposing secrets or raw internal errors. |
| ADM-011 | Destructive actions SHOULD require confirmation and SHOULD prefer reversible suspension over deletion. |

### 13.1 Audit record minimum

An audit record for a sensitive operation MUST include:

```text
audit_id
actor_principal_id
action
resource_type
resource_id
occurred_at
correlation_id
result
reason or metadata when applicable
```

Audit records MUST be tamper-resistant within the selected platform's reasonable threat model and retention policy.

---

## 14. Conceptual Data Model

This section defines information and relationships, not physical tables, collections, documents, or storage technology.

### 14.1 Core entities

| Entity | Required information |
|---|---|
| User | ID, external/internal identity reference, active state, created/updated timestamps |
| Role/capability assignment | user/principal, role or capability, scope, timestamps |
| Customer | ID, user relationship, name, phone/contact data, timestamps |
| Address | ID, customer, label, structured address, optional coordinates, default flag, timestamps |
| Seller | ID, public slug/reference, name, description, contact/address/media, moderation state, timestamps |
| Seller membership | seller, user, seller-level role, timestamps |
| Courier | ID, user, profile/contact, vehicle data, approval state, operational state, timestamps |
| Courier location | ID, courier, coordinates, accuracy if available, recorded timestamp |
| Category | ID, seller, name, order, timestamps |
| Product | ID, seller, optional category, name, description, price/currency, media, activity state, timestamps |
| Inventory item | ID, seller, product, available/reserved quantity according to chosen model, timestamps/version |
| Guest cart | ID, visitor context, seller, expiry, timestamps |
| Customer cart | ID, customer, seller, timestamps |
| Cart item | ID, cart, product, quantity, displayed/last-known price, timestamps |
| Order | ID, customer, seller, optional courier, delivery-address snapshot/reference, state, monetary totals, notes, timestamps/version |
| Order item | ID, order, product reference, name snapshot, quantity, unit-price snapshot, timestamps |
| Order history entry | ID, order, from/to state, actor, note/reason, timestamp |
| Payment record | ID, order, method, state, amount/currency, external reference, timestamps |
| Favorite | ID, customer, seller, timestamp |
| Support ticket | ID, customer, optional order, subject, state, timestamps |
| Support message | ID, ticket, sender, content, timestamp |
| Setting | ID/key, value, description, effective/updated metadata |
| Invoice | ID, seller, amount/currency, state, period, timestamps |
| Upload/media object | ID, owner/uploader, logical storage key, content metadata, access classification, timestamp |
| Domain event/job | ID, event type, payload/reference, state, attempts, last error, timestamps |
| Audit record | ID, actor, action, resource, result, correlation, metadata, timestamp |

### 14.2 Data invariants

| ID | Requirement |
|---|---|
| DAT-001 | Entity identifiers MUST be globally unique within their domain and generated by a trusted application boundary. |
| DAT-002 | Client applications MUST NOT authoritatively choose entity identifiers for protected business objects. |
| DAT-003 | Timestamps MUST use a documented canonical time zone and serialization format. |
| DAT-004 | Monetary values MUST use integer minor units with explicit currency. |
| DAT-005 | Main mutable entities MUST record creation and last-update time. |
| DAT-006 | Order history, support messages, audit records, and consumed domain facts SHOULD be append-only. |
| DAT-007 | Referential integrity MUST prevent orphaned operational records. |
| DAT-008 | Historical order and payment data MUST survive later profile, catalog, address, or fee changes. |
| DAT-009 | Inventory consistency MUST be protected against concurrent overselling. |
| DAT-010 | Collection queries MUST have deterministic ordering and bounded pagination. |
| DAT-011 | Schema/data evolution MUST be versioned, repeatable, and tested against representative existing data. |
| DAT-012 | Personal data retention and deletion MUST respect legal obligations and historical transaction integrity. |

### 14.3 Consistency boundaries

The implementation MUST provide an atomic consistency boundary for:

1. checkout creation and inventory effect;
2. order transition, history, and required event;
3. courier assignment and order-state transition;
4. payment state transition and idempotency record;
5. sensitive moderation change and audit record;
6. ticket creation and initial message.

If the selected architecture cannot provide one local transaction, the implementation plan MUST specify an equivalent consistency protocol, failure recovery, idempotency, and tests. Distributed consistency mechanisms are an implementation choice, not a product requirement.

---

## 15. Logical Application Interfaces

These are capability contracts, not language interfaces or network APIs.

### 15.1 Identity gateway

```text
register_actor(identity_data, requested_actor_type) -> principal
authenticate(credentials_or_assertion) -> authenticated_context
resolve_principal(access_context) -> principal
revoke_access(access_context) -> result
set_user_active(user_id, active, actor) -> result
```

### 15.2 Catalog and inventory

```text
list_public_sellers(page) -> sellers
list_public_products(seller_reference, page) -> products
create_or_update_product(seller_scope, product_input) -> product
set_inventory(seller_scope, product_id, quantity) -> inventory
check_and_reserve_or_decrement_inventory(items, consistency_context) -> result
restore_or_release_inventory(order_id, reason) -> result
```

### 15.3 Cart and checkout

```text
get_cart(owner_context, seller_id) -> cart
add_or_update_cart_item(owner_context, seller_id, product_id, quantity) -> cart
remove_cart_item(owner_context, seller_id, product_id) -> cart
handoff_guest_cart(guest_context, customer_id, policy) -> customer_cart
checkout(customer_id, seller_id, address_id, idempotency_key) -> order_result
```

### 15.4 Orders and deliveries

```text
list_customer_orders(customer_id, page) -> orders
get_customer_order(customer_id, order_id) -> order_detail
list_seller_orders(seller_scope, filters, page) -> orders
transition_seller_order(seller_scope, order_id, action, reason) -> order
list_courier_work(courier_id, filters, page) -> deliveries
accept_delivery(courier_id, order_id, idempotency_key) -> delivery
transition_delivery(courier_id, order_id, action) -> delivery
get_tracking(customer_id, order_id) -> tracking_view
record_courier_location(courier_id, location) -> result
```

### 15.5 Payments

```text
create_payment(order, idempotency_key) -> payment
process_payment_callback(verified_callback, idempotency_key) -> payment
get_payment(order_id) -> payment
reconcile_payment(external_reference) -> reconciliation_result
```

### 15.6 Support and administration

```text
create_ticket(customer_id, optional_order_id, subject, initial_message) -> ticket
list_customer_tickets(customer_id, page) -> tickets
get_admin_ticket(admin_context, ticket_id) -> ticket_detail
transition_ticket(admin_context, ticket_id, action, message) -> ticket
moderate_participant(admin_context, participant_type, participant_id, action, reason) -> result
get_operational_dashboard(admin_context) -> dashboard
update_setting(admin_context, key, value, reason) -> setting
```

### 15.7 Interface rules

- Interfaces MUST accept actor/ownership context where authorization matters.
- Mutation interfaces SHOULD accept idempotency context when network retries or external effects can duplicate work.
- Domain errors MUST be stable and independent of database or provider error messages.
- Provider-specific objects MUST be translated at adapter boundaries.
- Internal error details MUST not cross untrusted client boundaries.

---

## 16. External Integration Boundaries

| Boundary | Required abstraction |
|---|---|
| Identity | normalized principal, login/logout, revocation, account status |
| Payment | create/confirm/query/reconcile payment, verify callbacks, idempotency |
| Geocoding/maps | normalize address, geocode, render or describe location |
| File/media storage | put/get/delete metadata, access policy, content validation |
| Notifications | send domain notification using channel-neutral message intent |
| Background execution | enqueue/persist, lease, retry, complete/fail, dead-letter/alert |
| Observability | structured events, metrics, traces/correlation, health signals |
| Backup | create/replicate, verify, restore, retention |

### 16.1 Integration requirements

| ID | Requirement |
|---|---|
| INT-001 | Core business services MUST depend on provider-neutral contracts. |
| INT-002 | Provider credentials and secrets MUST be supplied through secure configuration. |
| INT-003 | External requests MUST use timeouts and bounded retries appropriate to idempotency. |
| INT-004 | External callbacks MUST be authenticated and replay-protected. |
| INT-005 | External provider failure MUST not leave local business state ambiguous without a recoverable status. |
| INT-006 | Background handlers MUST be idempotent. |
| INT-007 | Background work MUST record attempts, last error, and next/retry state. |
| INT-008 | Work abandoned during process/node failure MUST be recoverable. |
| INT-009 | Unknown event/job types MUST be observable and MUST NOT be silently treated as success. |
| INT-010 | Poison work MUST eventually stop retrying and become visible for operator action. |

An implementation MAY execute background work in-process, through a durable job store, through a broker, or through a managed task system. The implementation plan must justify the choice using expected scale and reliability, not product fashion.

---

## 17. Client and User Experience Requirements

### 17.1 Product surfaces

The product has five logical surfaces:

| Surface | Purpose |
|---|---|
| Public | acquisition, institutional trust, seller/product discovery, guest cart |
| Customer | account, addresses, favorites, checkout, orders, tracking, support |
| Seller | onboarding, profile/settings, catalog, inventory, incoming orders |
| Courier | onboarding, availability, delivery queue, active delivery, statistics |
| Administrator | dashboard, moderation, orders, support, settings, invoices, health |

These surfaces MAY be delivered as one application, multiple applications, server-rendered pages, client-rendered applications, native clients, or a combination. The planner MUST define navigation, authentication continuity, shared design language, and deployment boundaries.

### 17.2 UX requirements

| ID | Requirement |
|---|---|
| UX-001 | Primary journeys MUST be mobile-first and usable at common phone, tablet, and desktop sizes. |
| UX-002 | Each asynchronous view MUST provide loading, empty, success, recoverable error, and unauthorized states where applicable. |
| UX-003 | Forms MUST preserve user input after recoverable failures where safe. |
| UX-004 | Destructive or high-impact actions MUST request confirmation when accidental activation is plausible. |
| UX-005 | Status labels MUST use consistent product vocabulary across all surfaces. |
| UX-006 | Monetary totals and final action consequences MUST be visible before confirmation. |
| UX-007 | Order and delivery state MUST not rely on color alone. |
| UX-008 | User-facing strings MUST be externalizable for localization; baseline locale is Brazilian Portuguese. |
| UX-009 | Navigation and session state MUST remain coherent across product surfaces. |
| UX-010 | Reusable visual patterns SHOULD be governed by a shared design system independent of client framework. |
| UX-011 | Installability and offline behavior, if offered, MUST be honest about which data/actions remain available offline. |
| UX-012 | Authentication secrets or bearer credentials MUST not be stored in insecure client storage. |

### 17.3 Accessibility baseline

- All primary journeys MUST be keyboard operable on keyboard-capable clients.
- Focus order and visible focus MUST be preserved.
- Inputs MUST have programmatic labels and error association.
- Essential content MUST meet approved contrast targets, normally WCAG AA.
- Status changes SHOULD be announced to assistive technologies.
- Images MUST have meaningful alternatives or be marked decorative.
- Dialogs MUST manage focus and provide an accessible dismissal path.
- Motion MUST respect reduced-motion preferences where applicable.
- Touch targets SHOULD meet accepted mobile accessibility guidance.

### 17.4 Visual language

The product owner may provide a brand inventory or design reference. The implementation plan must translate it into technology-neutral tokens and patterns:

```text
color roles
font roles
spacing scale
border/radius/elevation rules
interaction states
surface patterns
actor-specific accents
responsive behavior
```

Visual fidelity MUST not weaken accessibility or operational clarity.

---

## 18. Security and Privacy

### 18.1 Security requirements

| ID | Requirement |
|---|---|
| SEC-001 | Authentication credentials and secrets MUST be protected in transit and at rest according to their sensitivity. |
| SEC-002 | Passwords, when used, MUST be processed with a current adaptive password-hashing algorithm and never stored reversibly. |
| SEC-003 | Authentication attempts MUST be rate-limited and monitored. |
| SEC-004 | Sessions/tokens MUST have bounded lifetime, revocation, rotation/renewal policy, and secure client storage. |
| SEC-005 | Browser-based credential transport MUST include appropriate cookie/token, cross-site request, origin, and script-injection protections. |
| SEC-006 | Public registration MUST not create privileged administrator identities. |
| SEC-007 | Every protected resource operation MUST enforce object-level authorization. |
| SEC-008 | Request payloads MUST have schema validation, size limits, and safe unknown-field policy. |
| SEC-009 | Uploaded files MUST be size-limited, type/content-validated, renamed by the trusted boundary, and protected from path traversal and executable delivery. |
| SEC-010 | Internal errors, stack traces, credentials, access tokens, session identifiers, and sensitive personal/payment data MUST not be exposed to clients or routine logs. |
| SEC-011 | State-changing external callbacks MUST be authenticated, replay-protected, and idempotent. |
| SEC-012 | Sensitive administrative and financial actions MUST be audited. |
| SEC-013 | Dependency, artifact, and infrastructure security checks SHOULD run in delivery pipelines. |
| SEC-014 | Security headers and transport encryption MUST be configured for production clients. |
| SEC-015 | Abuse controls MUST exist for login, registration, cart mutation, checkout, support creation, and location updates. |

### 18.2 Privacy requirements

The implementation plan MUST define:

- purpose and legal basis for identity, contact, address, order, support, and location data;
- data classification;
- retention periods;
- deletion/anonymization rules;
- customer export/deletion request handling;
- courier location consent, precision, access, and retention;
- administrator access policy;
- log and analytics redaction;
- backup retention and deletion implications;
- incident response and notification responsibilities.

The privacy notice MUST describe implemented behavior rather than aspirational controls.

### 18.3 Threat scenarios to test

- customer reads or mutates another customer's address/order/ticket;
- seller mutates another seller's product/inventory/order;
- courier claims or transitions another courier's delivery;
- ordinary user registers or promotes themselves as administrator;
- replayed checkout creates duplicate order/payment;
- two couriers concurrently accept the same delivery;
- manipulated client price reduces order total;
- crafted upload escapes storage boundary or executes content;
- forged payment callback marks an order paid;
- stale/revoked session continues to authorize requests;
- cross-site request triggers a protected mutation;
- logs capture credentials or personal location.

---

## 19. Non-Functional Requirements

### 19.1 Availability and recovery

| ID | Requirement |
|---|---|
| NFR-001 | The deployed system MUST expose liveness and dependency-aware readiness signals. |
| NFR-002 | Startup MUST fail clearly when mandatory configuration, schema migration, or critical dependencies are unavailable. |
| NFR-003 | Shutdown MUST stop new work, drain in-flight requests within a bound, stop workers, and release resources safely. |
| NFR-004 | Business data MUST have automated backup/replication appropriate to the approved recovery objectives. |
| NFR-005 | Restore MUST be tested on a schedule and after material storage/schema changes. |
| NFR-006 | Background work interrupted by process/node failure MUST resume or become operator-visible. |

### 19.2 Performance and scale

The implementation plan MUST fill and test these targets:

| Measure | Target to select |
|---|---|
| Public read latency | p50 / p95 / p99 |
| Authenticated read latency | p50 / p95 / p99 |
| Mutation latency excluding external payment | p50 / p95 / p99 |
| Checkout latency | p50 / p95 / p99 |
| Concurrent active users | expected / peak |
| Orders per day | expected / peak |
| Checkout requests per second | expected / peak |
| Courier location updates per second | expected / peak |
| Background-event processing delay | normal / maximum |
| Availability objective | percentage and measurement window |
| Recovery point objective | maximum acceptable data loss |
| Recovery time objective | maximum acceptable restoration time |

| ID | Requirement |
|---|---|
| NFR-007 | Collection operations MUST use bounded pagination and indexed/query-efficient access patterns. |
| NFR-008 | Network calls MUST use explicit timeouts. |
| NFR-009 | Retries MUST use bounded backoff and must respect operation idempotency. |
| NFR-010 | Load tests MUST cover checkout inventory contention and concurrent courier acceptance. |

### 19.3 Compatibility

- The implementation plan MUST define supported browsers, devices, operating systems, and accessibility tools.
- Public integration contracts MUST have an explicit compatibility/versioning policy.
- Breaking contract changes MUST include a migration or coordinated release plan.
- Stored data migrations MUST be backward-aware or use an approved maintenance strategy.

### 19.4 Maintainability

| ID | Requirement |
|---|---|
| NFR-011 | Business rules MUST be separable from delivery framework and provider adapters. |
| NFR-012 | Provider-specific data structures MUST not leak through core domain contracts. |
| NFR-013 | Configuration MUST be centralized, validated, and environment-aware. |
| NFR-014 | Schema evolution and generated artifacts, if any, MUST be reproducible. |
| NFR-015 | The implementation MUST avoid unnecessary deployable units and dependencies. |
| NFR-016 | Product terminology in code and contracts SHOULD match this specification. |

---

## 20. Observability and Operations

### 20.1 Required signals

- structured application logs;
- unpredictable correlation/request ID propagated across synchronous and asynchronous boundaries;
- request rate, latency, status/error rate;
- dependency health and latency;
- database/data-store saturation or contention indicators where applicable;
- orders created and transitions by state;
- checkout failures by stable reason;
- payment failures and reconciliation gaps;
- background queue depth/age, retries, poison work;
- courier location ingest errors/staleness;
- support-ticket counts and age;
- audit events for sensitive commands.

### 20.2 Operational requirements

| ID | Requirement |
|---|---|
| NFR-017 | Liveness MUST indicate that the process/runtime can answer; it MUST not fail solely because an optional dependency is unavailable. |
| NFR-018 | Readiness MUST fail when the instance cannot safely serve required traffic. |
| NFR-019 | Logs MUST correlate client-visible errors with server-side diagnostics without exposing internal details. |
| NFR-020 | Alerts SHOULD focus on user-impacting symptoms and exhausted recovery, not every transient retry. |
| NFR-021 | Operators MUST have documented procedures for deployment, rollback/forward-fix, backup, restore, secret rotation, and incident response. |
| NFR-022 | Production configuration changes MUST be auditable and reversible when practical. |

---

## 21. Transport-Neutral Application Contract

The implementation MAY expose REST, GraphQL, RPC, server actions, message-based commands, or another suitable transport. The external contract MUST preserve the following semantics.

### 21.1 Command/query behavior

- Queries MUST not create hidden business mutations, except explicitly documented lazy initialization that is safe and idempotent.
- Commands MUST return or expose a stable result and stable domain error category.
- Mutations vulnerable to retry duplication MUST accept or derive an idempotency key.
- Collections MUST provide bounded pagination and deterministic ordering.
- Filters and sort options MUST be explicitly allow-listed.
- Validation errors MUST identify invalid fields without leaking internal implementation.
- Authorization failures MUST distinguish unauthenticated from authenticated-but-forbidden at the transport's semantic level.

### 21.2 Stable error taxonomy

```text
invalid_input
unauthenticated
forbidden
not_found
conflict
state_transition_not_allowed
insufficient_inventory
idempotency_conflict
rate_limited
external_dependency_unavailable
internal_failure
```

Each selected transport MUST map these categories consistently to its own status/error conventions.

### 21.3 Minimum operation catalog

Identity:

```text
register customer/seller/courier identity
login or start authentication
complete external authentication callback when applicable
logout/revoke current access
resolve current principal
```

Public:

```text
read public content
list discoverable sellers
read seller catalog
read/update guest cart
```

Customer:

```text
read/update profile
create/list/update/delete addresses
add/list/remove favorites
read/update seller-scoped cart
handoff guest cart
checkout idempotently
list/get orders
read tracking
create/list/get support tickets
```

Seller:

```text
onboard/read/update seller
manage categories
manage products and product activity
read/update inventory
list/get seller orders
execute valid seller order actions
```

Courier:

```text
onboard/read/update courier
set availability
list eligible and assigned deliveries
accept delivery idempotently
mark pickup/delivery
publish location
read statistics
```

Administrator:

```text
read dashboard
list/get users
list/get/moderate sellers
list/get/moderate couriers
list/get orders
list/get/transition support tickets
read/update settings and fees
list/get invoices
read operational health
read audit records
```

---

## 22. Verification Strategy

### 22.1 Test layers

| ID | Layer | Required evidence |
|---|---|---|
| TST-001 | Domain unit | state machines, money, inventory, permissions, validation, fee calculations |
| TST-002 | Persistence integration | constraints, migrations, transactions/consistency, pagination, concurrency |
| TST-003 | Identity integration | login, expiry, revocation, disabled user, role/capability mapping, provider failure |
| TST-004 | Application contract | every operation's success, validation, authorization, conflict, and internal-failure semantics |
| TST-005 | Provider contract | payment, storage, identity, notification, location adapters with failure and retry behavior |
| TST-006 | Client unit/component | forms, loading/errors, design-system contracts, accessibility interactions |
| TST-007 | End-to-end | one complete public/customer/seller/courier/admin order loop |
| TST-008 | Security | object-level authorization, abuse controls, session/token, CSRF/origin, callback, upload scenarios |
| TST-009 | Concurrency | inventory oversell prevention and single courier assignment |
| TST-010 | Recovery | restart during checkout/event work, retry recovery, backup restoration |
| TST-011 | Performance | approved latency, throughput, concurrency, and backlog objectives |
| TST-012 | Compatibility/accessibility | approved client matrix and accessibility baseline |

Every corrected defect MUST add a regression test at the lowest useful layer and, when user-visible, at an integration or end-to-end layer.

### 22.2 Quality gate

A release MUST NOT proceed when:

- a mandatory requirement lacks evidence;
- static analysis/type checking for the selected stack fails;
- required automated tests fail or do not exist;
- security-critical authorization paths are untested;
- schema/data migration has not been tested;
- backup restore has not been demonstrated for production data handling;
- the complete order loop has not passed against a production-like environment;
- known critical or high-severity security findings remain unaccepted;
- implementation documentation and observed behavior conflict.

Coverage percentages MAY be used as supporting indicators but MUST NOT replace scenario and risk coverage.

---

## 23. End-to-End Acceptance Scenarios

### Scenario A — Seller becomes discoverable

**Given** a seller-authorized identity has submitted onboarding data  
**And** the seller is pending review  
**When** an administrator approves the seller  
**And** the seller creates an active product with positive inventory  
**Then** the seller appears in public discovery  
**And** the product appears with authoritative price and availability  
**And** moderation is audited.

### Scenario B — Customer completes checkout

**Given** an approved seller has an active product with sufficient inventory  
**And** a customer owns a valid delivery address  
**And** the customer cart contains that seller's product  
**When** the customer confirms checkout with an idempotency key  
**Then** exactly one order is created  
**And** order item and delivery-address history are reconstructable  
**And** inventory is reserved or decremented exactly once  
**And** exactly one initial payment record exists  
**And** an initial order history entry exists  
**And** reliable follow-up work is recorded  
**And** the cart is cleared only after success.

### Scenario C — Concurrent checkout cannot oversell

**Given** one unit remains in inventory  
**When** two customers concurrently attempt to buy that unit  
**Then** at most one checkout succeeds  
**And** inventory never becomes negative  
**And** the failed customer receives a stable insufficient-inventory result  
**And** no partial order/payment remains for the failed checkout.

### Scenario D — Seller prepares an order

**Given** a pending order belongs to a seller  
**When** that seller accepts, starts preparation, and marks it ready  
**Then** each transition follows the state machine  
**And** each transition records actor and timestamp  
**And** another seller cannot inspect or transition the order.

### Scenario E — Exactly one courier accepts

**Given** a ready unassigned order  
**And** two approved available couriers can see it  
**When** both attempt to accept concurrently  
**Then** exactly one courier is assigned  
**And** the winner sees an active delivery  
**And** the other receives a stable conflict/unavailable result  
**And** history/event evidence is written once.

### Scenario F — Courier completes delivery and customer tracks it

**Given** a courier is assigned to an order  
**When** the courier marks pickup and publishes permitted location updates  
**Then** the customer sees current state, history, and latest permitted location/freshness  
**When** the courier marks delivered  
**Then** the order becomes terminally delivered  
**And** another courier cannot mutate it.

### Scenario G — Customer creates support ticket

**Given** an authenticated customer  
**When** the customer submits a subject and initial message  
**Then** the ticket and initial message are persisted atomically  
**And** the customer can list it  
**And** an administrator can inspect it  
**And** another customer cannot access it.

### Scenario H — Identity and role isolation

**Given** valid customer, seller, courier, and administrator identities  
**When** each actor attempts operations outside their authority  
**Then** every unauthorized operation is denied without data disclosure  
**And** public registration cannot create an administrator  
**And** disabling a user prevents continued access.

### Scenario I — External payment callback replay

**Given** a valid external payment callback  
**When** the same verified callback is delivered multiple times  
**Then** payment state changes at most once  
**And** no duplicate charge/order/event is created  
**And** replay processing remains auditable.

### Scenario J — Recovery

**Given** committed business state with pending background work  
**When** an application instance terminates unexpectedly  
**Then** a replacement instance recovers or retries the work safely  
**And** no committed order is lost  
**And** poison work becomes operator-visible after bounded retries.

### Scenario K — Production restoration

**Given** a production-equivalent backup  
**When** the documented restore procedure is executed  
**Then** the system restores within the approved recovery-time objective  
**And** committed data loss does not exceed the approved recovery-point objective  
**And** integrity checks and a representative order flow pass.

---

## 24. MVP Release Checklist

### Product

- [ ] Public acquisition/discovery and guest-cart entry work.
- [ ] Customer can register/authenticate, manage address, checkout, and inspect tracking/support.
- [ ] Seller can onboard, become approved, manage catalog/inventory, and prepare orders.
- [ ] Courier can become approved/available, discover, accept, collect, and deliver.
- [ ] Administrator can moderate participants and inspect operational data/support/settings.
- [ ] One complete order loop passes on a fresh environment.

### Domain integrity

- [ ] Order state machine is enforced centrally.
- [ ] Inventory cannot oversell under concurrency.
- [ ] Courier assignment is single-winner under concurrency.
- [ ] Checkout and ticket creation consistency boundaries are atomic or equivalently recoverable.
- [ ] Historical order values/address are reconstructable.
- [ ] Sensitive actions create audit evidence.

### Security/privacy

- [ ] Public privilege escalation is impossible.
- [ ] Object-level authorization tests pass for every actor.
- [ ] Session/token, request-forgery/origin, abuse, callback, and upload controls pass.
- [ ] Personal/location/payment data policy is approved and reflected in product copy.
- [ ] Production secrets and bootstrap process are safe.

### Reliability/operations

- [ ] Liveness/readiness and graceful shutdown work.
- [ ] Structured logs, correlation, metrics, and actionable alerts exist.
- [ ] Background work recovers and poison work is visible.
- [ ] Backup and restore meet approved objectives.
- [ ] Deployment and rollback/forward-fix procedures are tested.

### Quality

- [ ] Static analysis/type checks pass.
- [ ] Required unit, integration, contract, client, E2E, security, concurrency, and recovery tests pass.
- [ ] Accessibility and compatibility checks pass.
- [ ] Performance targets pass.
- [ ] Requirement-to-evidence matrix has no mandatory gaps.

---

## 25. Implementation Decision Worksheet

The implementation plan MUST complete this worksheet before estimating work. Product requirements must not be changed merely to fit a preferred tool.

| Decision area | Questions the plan must answer | Selected option / rationale |
|---|---|---|
| Programming language/runtime | What team skill, deployment, performance, safety, and maintenance needs drive the choice? | TBD |
| Application topology | Modular monolith, services, serverless functions, or other? What measured need justifies deployable-unit count? | TBD |
| Client architecture | One or multiple web/native clients? How are five product surfaces organized and shared? | TBD |
| API/transport | REST, GraphQL, RPC, server actions, or mixed? How are compatibility and errors handled? | TBD |
| Identity | Local credentials, external provider, or hybrid? Which standard protocol? How do roles, revocation, bootstrap, and outage behavior work? | TBD |
| Authorization | Role-based, capability-based, policy-based, or mixed? Where is object ownership enforced? | TBD |
| Primary data store | Which consistency, transaction, concurrency, migration, backup, and operational requirements drive the choice? | TBD |
| Data access | Direct queries, query generator, repository library, or another mechanism? How are provider details kept outside domain rules? | TBD |
| Identifier strategy | Which server-authoritative globally unique format and ordering/privacy properties are required? | TBD |
| Schema migration | How are versions applied, verified, rolled forward/back, and tested against existing data? | TBD |
| Inventory concurrency | Which locking, compare-and-swap, serializable transaction, reservation, or equivalent strategy prevents oversell? | TBD |
| Courier assignment concurrency | Which atomic conditional assignment guarantees one winner? | TBD |
| Background work | In-process, durable database jobs, broker, managed task service, or other? How are leasing, retry, idempotency, and poison jobs handled? | TBD |
| Payment | Manual MVP or external provider? How are idempotency, callbacks, verification, and reconciliation handled? | TBD |
| File/media storage | Local, network, object, or managed storage? How are validation, access, URLs, retention, and backup handled? | TBD |
| Maps/geocoding | Is map rendering in MVP? Which adapter behavior, cost, privacy, and fallback apply? | TBD |
| Notifications | Which channels are in scope? What provider-neutral intent and retry behavior apply? | TBD |
| Caching | What is cached, for how long, and how are authenticated data leakage/staleness prevented? | TBD |
| Observability | Which structured logging, metrics, tracing, correlation, dashboards, and alerting mechanisms satisfy §20? | TBD |
| Configuration/secrets | How are values validated, injected, rotated, and separated by environment? | TBD |
| Deployment | Process/container/function/managed platform? How many units and why? How is TLS handled? | TBD |
| Scaling | What are initial and trigger-based scaling strategies? Which bottlenecks are expected? | TBD |
| Backup/recovery | Mechanism, schedule, encryption, retention, RPO, RTO, and restore-test cadence? | TBD |
| CI/CD | Which build, static analysis, test, security, migration, artifact, and deployment gates run? | TBD |
| Test tooling | Which tools implement each required layer in §22? | TBD |
| Accessibility/compatibility | Which standards, target clients, automation, and manual checks apply? | TBD |
| Localization | How are Brazilian Portuguese strings, formats, and future locales managed? | TBD |
| Compliance/privacy | Which jurisdictional requirements and data-retention workflows apply? | TBD |

### 25.1 Architecture fitness rules

A proposed stack is acceptable only if the plan demonstrates:

1. how checkout and assignment concurrency invariants are enforced;
2. how domain rules remain testable independently of providers;
3. how identity and object-level authorization are enforced;
4. how schema/data evolution and recovery work;
5. how background work is durable and idempotent where required;
6. how all five product surfaces are delivered and secured;
7. how the quality gate can run automatically;
8. why the deployable-unit count is the smallest reasonable choice;
9. how operational cost and team capability fit the MVP;
10. how the implementation can be replaced or evolved without changing product semantics.

---

## 26. From Specification to Implementation Plan

A generated implementation plan MUST include the following sections.

### 26.1 Selected architecture

- completed decision worksheet;
- context and component diagram;
- deployable-unit diagram;
- data ownership and transaction boundaries;
- identity and authorization flow;
- synchronous and asynchronous interaction paths;
- failure and recovery model;
- rejected alternatives and rationale.

### 26.2 Vertical slices

Recommended dependency order:

1. project foundation, delivery pipeline, liveness/readiness, and observable app shell;
2. identity, principal normalization, authorization, and administrator bootstrap;
3. seller onboarding/moderation plus catalog/inventory;
4. public discovery and guest cart;
5. customer profile/addresses and persistent cart;
6. atomic checkout, order history, payment record, and inventory concurrency;
7. seller order handling;
8. courier approval/availability, eligible queue, atomic assignment, and delivery transitions;
9. customer tracking;
10. support ticket flow;
11. administrator operations, settings, invoices, audit, and operational dashboard;
12. file/media handling;
13. background integration hardening, backup/restore, security, performance, accessibility, and release validation.

Each slice MUST include:

```text
requirement IDs
user-visible outcome
scope and non-scope
domain rules
contract changes
data/schema changes
security considerations
observability signals
tests by layer
migration/rollback considerations
acceptance evidence
```

### 26.3 Traceability matrix template

| Requirement ID | Plan item | Design/component | Test/evidence | Status | Deviation |
|---|---|---|---|---|---|
| `PRD-001` | TBD | TBD | TBD | planned | none |
| `ORD-009` | TBD | TBD | TBD | planned | none |
| `ORD-019` | TBD | TBD | TBD | planned | none |
| `SEC-007` | TBD | TBD | TBD | planned | none |
| `TST-007` | TBD | TBD | TBD | planned | none |

No mandatory requirement may be omitted. Deviations require explicit product/technical approval and an update to this specification.

### 26.4 Estimation rules

Estimates MUST include:

- domain implementation;
- contracts and migrations;
- provider adapters;
- automated tests at all required layers;
- security hardening;
- observability;
- accessibility/responsive behavior;
- data migration/seed needs;
- deployment and rollback;
- documentation and review;
- contingency for unresolved product decisions.

A task is not complete when only the happy-path code exists.

### 26.5 Reusable planning prompt

The following prompt may be used with a planning agent after the decision worksheet inputs are available:

```text
Create an implementation plan for JaChegai using docs/PORTABLE_PRODUCT_SPEC.md as the normative product source.

Selected constraints and preferences:
- programming language/runtime: <fill>
- backend/client framework preferences: <fill or "open">
- identity approach/provider constraints: <fill>
- primary data-store constraints: <fill>
- background-work constraints: <fill>
- payment scope/provider constraints: <fill>
- storage and mapping constraints: <fill>
- deployment target and budget: <fill>
- expected scale and performance targets: <fill>
- availability, RPO, and RTO: <fill>
- team size and experience: <fill>
- delivery deadline: <fill>
- compliance jurisdiction: <fill>

Instructions:
1. Do not change or silently omit mandatory product requirements.
2. First list unresolved product decisions, assumptions, and conflicts between the selected stack and the specification.
3. Complete the implementation decision worksheet with rationale and rejected alternatives.
4. Prefer the smallest reliable deploy topology that satisfies the stated constraints.
5. Organize the plan as testable vertical slices that progressively complete customer-buy, seller-sell, courier-deliver, and administrator-operate flows.
6. For every plan item, include requirement IDs, dependencies, data/contract changes, security, observability, tests, migration/rollback, acceptance evidence, and estimate.
7. Include explicit designs for checkout idempotency, inventory concurrency, single-winner courier assignment, identity/authorization, background-work recovery, payment callbacks, backup/restore, and schema evolution.
8. Produce a requirement-to-plan-to-test traceability matrix and identify all mandatory requirements not yet scheduled.
9. Separate MVP, production-readiness blockers, and post-MVP work.
10. Do not claim completion based only on code generation or a successful build; define functional verification evidence.
```

---

## 27. Product Decisions Required Before Final Planning

The following are intentionally unresolved and must be decided or explicitly deferred:

1. Password policy, email verification, account recovery, and whether external identity is required.
2. Guest-cart retention and merge/replace/prompt behavior after authentication.
3. Whether a customer may maintain carts for multiple sellers simultaneously.
4. Delivery fee calculation and historical fee policy.
5. Inventory decrement versus reservation model and restoration rules.
6. Payment timing relative to order creation and expiration of unpaid orders.
7. Customer/seller cancellation actors, windows, reasons, inventory effects, and payment effects.
8. Whether seller rejection requires a reason.
9. Courier assignment model: open queue, administrator dispatch, automated dispatch, or hybrid.
10. Courier availability constraints while an active delivery exists.
11. Location update frequency, freshness threshold, precision, consent, map experience, and retention.
12. Product media upload versus trusted external-media policy.
13. Support replies, ticket ownership assignment, resolution, reopening, and SLA.
14. Administrator authority over user activation and customer data.
15. Fee and invoice business meaning, generation cadence, and payment workflow.
16. Notification channels required for the MVP.
17. Required availability, performance, RPO, and RTO targets.
18. Supported client/device matrix and installability expectations.
19. Applicable privacy jurisdiction and retention schedule.
20. Whether five surfaces share one client deployment or require distinct install identities.

The implementation planner MUST not silently invent these answers. Unresolved decisions must appear as blocking questions or explicit assumptions.

---

## 28. Final Product Rule

For every proposed feature, provider, deployable unit, abstraction, or operational dependency, ask:

> Does it directly help a customer buy, a seller sell, a courier deliver, or an administrator operate—and is it the smallest reliable way to do so under the selected constraints?

If not, keep it outside the MVP implementation plan.
