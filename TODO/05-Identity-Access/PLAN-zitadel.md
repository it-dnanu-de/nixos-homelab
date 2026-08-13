# PLAN — ZITADEL IdP milestone (architect, rev. 2026-08-13)

> **SWITCHED FROM AUTHENTIK → ZITADEL** (human ruling 2026-08-13): `services.zitadel` is native in pinned `nixos-26.05` (package **2.71.7**). No flake input.
>
> **Rev. 2 (2026-08-13)** folds in the human rulings: oauth2-proxy forward-auth, dual-domain strategy, PostgreSQL required. Two rulings could not be implemented as literally stated — see **§1 D1/D2**. Read §0 and §1 before writing any code.
>
> Implements OpenCode.md §9 (IdP row), §10 (profile/WG-QR page), TODO 05.
> Every option below was read out of the pinned checkout at
> `github.com/NixOS/nixpkgs@nixos-26.05` (`git log -1` = `9f78f44a879`, branch `nixos-26.05`).
> Public-safe: no secrets, no tokens.

---

## 0. Findings that change the brief

| # | Finding | Consequence |
|---|---|---|
| **F1** | `services.zitadel` exists in 26.05 — module at `nixos/modules/services/web-apps/zitadel.nix`, package `2.71.7`. Options: `enable`, `package`, `user`, `group`, `openFirewall`, `masterKeyFile`, `tlsMode`, `settings` (freeform YAML, only `Port` + `TLS.*` are typed), `extraSettingsPaths`, `steps` (freeform YAML), `extraStepsPaths`. **That is the complete surface — there is nothing else.** | No flake input. Anything not in that list is written as freeform YAML under `settings` / `steps`. |
| **F2** | **ZITADEL 2.71.7 requires PostgreSQL.** `Database.postgres.*` — there is no embedded/badger store. (`Database.cockroach` also exists; postgres is the supported path.) The old plan's `Database.Badger.Directory` key **does not exist** — it would have been silently written into the YAML and ZITADEL would have started against `localhost:5432` anyway. Human ruling #3 is correct. | Use the **already-enabled host PostgreSQL** (`configuration.nix` line `services.postgresql.enable = true;`). No new DB container. |
| **F3** | With `enableTCPIP = false` (the current/default state) NixOS sets `listen_addresses = "localhost"` → PostgreSQL **already listens on `127.0.0.1:5432`**, and the default `pg_hba` already contains `host all all 127.0.0.1/32 md5`. | **Zero changes to the postgres module are required.** Do **not** set `enableTCPIP = true` — that sets `listen_addresses = "*"` (all interfaces, no `mkDefault`) and would violate the zero-exposure rule. |
| **F4** | The zitadel systemd unit has **no `LoadCredential`, no `StateDirectory`, no `DynamicUser`** — it runs plainly as `User = zitadel`. `masterKeyFile` and every `extraSettingsPaths` entry are opened **by the zitadel process itself**. | Those sops secrets **must** carry `owner = "zitadel"`. A root-only `0400` secret (the sops default) makes the unit crash-loop. |
| **F5** | The module builds args as `config = extraSettingsPaths ++ [ configFile ]` — the Nix-store `configFile` is passed **last**. The option doc claims `extraSettingsPaths` "override" `settings`, but the CLI order says otherwise and ZITADEL merges via viper. **Precedence is ambiguous.** | **Never write the same key in both places.** Secret-bearing keys (`Database.postgres.*.Password`, SMTP) live **only** in the sops YAML; everything else **only** in `settings`. This sidesteps the ambiguity entirely. Still recorded as ⚠️ **V2**. |
| **F6** | `masterKeyFile` must be **exactly 32 bytes**. `openssl rand -base64 32` produces 44 chars — wrong. A trailing newline also breaks it. | Generate with `openssl rand -hex 16` (32 chars). Store as a **plain single-line YAML scalar** (not a `\|` block). Verify `wc -c` = 32 on the deployed path (⚠️ **V3**). |
| **F7** | **`ExternalDomain` is singular.** ZITADEL docs: *"For most cases ZITADEL should run on exactly one domain."* There is **no `ExternalDomains` array**. Extra domains exist only via the imperative System API `AddDomain`, and changing `ExternalDomain` requires re-running the setup phase. | Ruling #2 cannot be implemented as written. See **§1 D1**. |
| **F8** | `services.oauth2-proxy` exists in 26.05, plus the companion `oauth2-proxy-nginx.nix` which auto-generates the whole nginx `auth_request` scaffolding (`/oauth2/`, `= /oauth2/auth`, `@redirectToAuth2ProxyLogin`, the `auth_request_set` block). **`provider` enum has no `zitadel` entry** — the correct value is **`"oidc"`** + `oidcIssuerUrl`. | Use the native module. Do **not** hand-roll auth_request. Ruling #1 is correct and gets even simpler than expected. |
| **F9** | The oauth2-proxy nginx helper wires `proxy_set_header X-User $user;` for a **proxied upstream**. Our profile page is **static files** (`root` / `alias`) — `proxy_set_header` is a no-op there. | The profile vhost must consume the identity via `auth_request_set` + an nginx variable, not via a forwarded header. See §3.5. |
| **F10** | `oauth2-proxy` secrets go through systemd `LoadCredential` (`clientSecretFile`, `cookie.secretFile`) or `EnvironmentFile` (`keyFile`) — all read **by systemd as root** before the drop to `User = oauth2-proxy`. | Those sops secrets stay root-only `0400`. **Opposite of F4.** |
| **F11** | `services.oauth2-proxy.reverseProxy = true` with an empty `trustedProxyIP` emits a **build warning**. Repo standard is "zero warnings". | Always set `trustedProxyIP = [ "127.0.0.1/32" "::1/128" ]`. |
| **F12** | AdGuard already rewrites `*.${settings.domains.internal}` → `settings.network.address` (`modules/networking/adguard.nix` line 68), and the comment states it matches apex + all subdomains. | `auth.nanulab.de` / `profile.nanulab.de` need **no new rewrite**. Only `auth.dnanu.de` does (`*.dnanu.de` is *not* rewritten — only `mail.dnanu.de` is). Task item 3.7 shrinks accordingly. |
| **F13** | `acme.nix` names the `*.dnanu.de` cert **`mail.dnanu.de`** (`certs."mail.dnanu.de"` with `domain = "dnanu.de"`). The disabled `ios-profile.nix` uses `useACMEHost = settings.domains.public` → would fail at eval/runtime. | Every `*.dnanu.de` vhost must use `useACMEHost = settings.domains.mail`. `*.nanulab.de` vhosts use `settings.domains.internal`. |
| **F14** | `DefaultInstance.DomainPolicy.UserLoginMustBeDomain` defaults to **`false`** → usernames are **not** suffixed with the org domain. So the ZITADEL username and the `preferred_username` claim are both plain `first.last`. | The WG render dir can be keyed on `preferred_username` directly. |
| **F15** | `users.nix` has **no** `first` / `last` / `email` fields — only `tier` + `devices`. `blocks` and the IP helpers are unrelated. | `users.nix` must be extended (step 1). Surnames now supplied — see §1. |
| **F16** | ZITADEL is placed in the `.10` system **container** zone by OpenCode.md §3.1, but **no container infrastructure exists in this repo yet** (nginx/mail/adguard/postgres all run host-side). | Build host-side, bound to `127.0.0.1`, shaped so the module drops into `containers.zitadel` unchanged later. **Do not invent container infra in this milestone.** |
| **F17** | Downstream OIDC consumers (Nextcloud, HA, Jellyfin, Glance, arrs) do not exist yet. | Ship the IdP + exactly **one** OIDC client (oauth2-proxy). Instantiate **zero** other providers. Dead OIDC config rots. |

---

## 1. Blockers — human input required before build

### Surnames — ✅ RESOLVED (2026-08-13)

| users.nix key | first | last | ZITADEL username | display name |
|---|---|---|---|---|
| `admin` | Admin | *(null)* | `admin` | Admin |
| `dumitru` | Dumitru | Nanu | `dumitru.nanu` | Dumitru Nanu |
| `adela` | Adela | Nanu | `adela.nanu` | Adela Nanu |
| `tiberiu` | Tiberiu | Nanu | `tiberiu.nanu` | Tiberiu Nanu |
| `david` | David | Nanu | `david.nanu` | David Nanu |
| `ramona` | Ramona | Nanu | `ramona.nanu` | Ramona Nanu |
| `tibisor` | Tibisor | Nanu | `tibisor.nanu` | Tibisor Nanu |
| `iza` | Izabela | Dwilewicz | `izabela.dwilewicz` | Izabela Dwilewicz |
| `kerem` | Kerem | Demir | `kerem.demir` | Kerem Demir |
| `hannah` | Hannah | Chertes | `hannah.chertes` | Hannah Chertes |

> Note `iza` → `izabela.dwilewicz`: the users.nix **key stays `iza`** (it drives `blocks`, IPs, `mail_iza`, WG peer names — all frozen). Only the derived ZITADEL username changes. Same for the WG render dir.

### D1 — ⛔ `ExternalDomains` array does not exist (F7). Decision required.

Ruling #2 asks for `ExternalDomains = [ "auth.nanulab.de" "auth.dnanu.de" ]`. ZITADEL has a single `ExternalDomain`, and it is baked into the OIDC **issuer** at setup time. Two hosts cannot both be the issuer. Additional instance domains are only addable imperatively via the System API, and the docs warn about lost org context.

Compounding it: `oauth2-proxy.oidcIssuerUrl` must match the `iss` claim **byte-for-byte**, or every login fails.

**Recommended resolution (build this):**

- `ExternalDomain = "auth.dnanu.de"` — **one** issuer, `https://auth.dnanu.de`.
  - Public via the cloudflared tunnel → the invite/first-login flow works off-VPN. This is mandatory: a new user has no WireGuard config yet, so an internal-only IdP is a chicken-and-egg deadlock.
  - **Also** rewritten by AdGuard to `10.0.0.2`, so LAN/VPN clients reach nginx directly instead of hairpinning through Cloudflare. Same host header, same cert (`*.dnanu.de`), so ZITADEL is happy either way.
- `auth.nanulab.de` — an nginx vhost that does nothing but `return 301 https://auth.dnanu.de$request_uri;`. Keeps the name alive as a bookmark, costs nothing, cannot break the issuer.
- **No IP allowlist on `auth.dnanu.de`.** ZITADEL *is* the authentication boundary; the console is gated by the `IAM_OWNER` role. Bolting `userAllowlist` on top would break the public invite flow, and an ACL on `/ui/console` alone is cosmetic (the console is a SPA hitting the same API paths the login page uses).

**If the human rejects this** and wants the admin console genuinely VPN-only, the only sound alternative is: `ExternalDomain = "auth.nanulab.de"` (VPN-only, allowlisted) and **drop public self-service entirely** — users get WG configs handed over out-of-band. That is a real product decision, not a config toggle. Do not attempt to run both.

### D2 — ⚠️ Profile page domain. Decision required.

The task specifies `profile.nanulab.de` with redirect `https://profile.nanulab.de/callback`. Three problems:

1. `*.nanulab.de` has **no public DNS records** and is VPN-only by design (OpenCode.md §3.4). A user who cannot yet get on the VPN cannot fetch the WireGuard QR that gets them on the VPN. Deadlock.
2. `profile.dnanu.de` already has a cloudflared ingress (`cloudflare.nix`) **and** a CF DNS upsert (`cloudflare-dns.nix` lines 89–92). That machinery works today.
3. oauth2-proxy's callback path is `${proxyPrefix}/callback` = **`/oauth2/callback`**, not `/callback`.

**Recommended resolution (build this):** keep **`profile.dnanu.de`**, public via the tunnel, gated by oauth2-proxy. Redirect URL = `https://profile.dnanu.de/oauth2/callback`.

### D3 — Secret values (human, via `sops secrets/secrets.yaml`)

Nothing in the repo. See §3.2 for the exact shape. Note `zitadel_oidc_client_id` / `_secret` are **chicken-and-egg**: they only exist after ZITADEL is running and the OIDC app has been created in the console. Build in two passes — see §2.

---

## 2. Build order

```
1  users.nix              (identity fields + helpers)            ── eval-only
2  secrets + sops.nix     (master key, pg password, zitadel_env) ── human fills
3  zitadel.nix            (service + postgres role + vhosts)     ── builds
   ── DEPLOY PASS 1: ZITADEL up, create OIDC app in console ──
   ── human adds zitadel_oidc_client_secret to sops ──
4  oauth2-proxy.nix       (profile-page gateway)                 ── builds
5  profile-page.nix       (WG-QR content vhost)                  ── builds
6  wireguard.nix          (rename render dirs, logout link)      ── small edit
7  adguard.nix            (auth.dnanu.de rewrite)                ── one line
8  cloudflare.nix + cloudflare-dns.nix (auth.dnanu.de ingress+DNS) ── small edit
9  configuration.nix      (imports + postgres backup)            ── small edit
10 docs                   (OpenCode.md, TODO 05, Changes.md)     ── same PR
```

**Two-pass deploy is unavoidable.** Steps 4–5 need a client ID/secret that only exists once ZITADEL is running. Commit steps 1–3, deploy, create the OIDC app (1% manual), fill the secret, then commit 4–10. One feature branch `feat/zitadel-idp`, one PR containing both passes.

Commit after each numbered step (repo rule 7).

---

## 3. File-by-file

### 3.1 `users.nix` — MODIFY (additive only)

Add to **each** user attrset. Do **not** touch `devices`, `blocks`, or any IP helper.

```nix
first = "Dumitru";
last  = "Nanu";
email = "dumitru@dnanu.de";   # CURRENT mailbox — the first.last MAIL rename is a SEPARATE milestone
```
`admin` gets `first = "Admin"; last = null; email = "admin@dnanu.de";`.

Add helpers at the bottom. **Pure `builtins` only** — `lib` is not in scope in this file (same constraint the existing helpers already live under):

```nix
# lowercase via builtins only (no lib.toLower available here)
toLower = s: ... ;                       # builtins.replaceStrings upper→lower

# idpUsername "dumitru" → "dumitru.nanu";  "admin" → "admin"
idpUsername = userName:
  let u = users.${userName}; in
  if u.last == null then userName
  else "${toLower u.first}.${toLower u.last}";

# idpDisplayName "iza" → "Izabela Dwilewicz"
idpDisplayName = userName:
  let u = users.${userName}; in
  if u.last == null then u.first else "${u.first} ${u.last}";

# idpUsers :: [ { key; username; displayName; first; last; email; tier; isAdmin; } ] — 10 entries
idpUsers = ... ;
```

**Rules:** derived only, zero duplication. `email` stays the short-name mailbox so `mail.nix` is untouched — when the `first.last` mail rename lands, only that one line changes per user.

⚠️ Name the helper `idpUsername`, **not** `zitadelUsername` — it is consumed by `wireguard.nix` and will outlive the choice of IdP.

### 3.2 `secrets/secrets.yaml` + `modules/system/sops.nix` — MODIFY

**`sops.nix`** — register five secrets. Note the split ownership (F4 vs F10):

```nix
# read by the zitadel process itself (no LoadCredential in the unit) → must be zitadel-owned
zitadel_master_key       = { owner = "zitadel"; group = "zitadel"; mode = "0400"; };
zitadel_env              = { owner = "zitadel"; group = "zitadel"; mode = "0400"; };

# read by systemd as root (LoadCredential / EnvironmentFile) → stay root-only
zitadel_postgres_password  = {};   # consumed by the zitadel-db-password oneshot (runs as root)
zitadel_oidc_client_secret = {};   # oauth2-proxy clientSecretFile  → LoadCredential
oauth2_proxy_cookie_secret = {};   # oauth2-proxy cookie.secretFile → LoadCredential
```

Delete the stale comment naming `authentik_secret_key` / `authentik_postgres_password`.

**`secrets/secrets.yaml`** — human fills. Shapes:

| key | shape | how to generate |
|---|---|---|
| `zitadel_master_key` | **exactly 32 bytes**, plain single-line scalar, **no** trailing newline, **not** a `\|` block | `openssl rand -hex 16` |
| `zitadel_postgres_password` | single-line | `openssl rand -base64 24` |
| `zitadel_oidc_client_secret` | single-line — **pass 2**, copied out of the ZITADEL console | ZITADEL console |
| `oauth2_proxy_cookie_secret` | **exactly 32 bytes** (AES-256) | `openssl rand -base64 32 \| head -c 32` |
| `zitadel_env` | **multi-line YAML** (`\|` block) — this is a ZITADEL config file, *not* an env file | hand-written, see below |

`zitadel_env` content — **only secret-bearing keys** (F5: never duplicate a key that also appears in `settings`):

```yaml
Database:
  postgres:
    User:
      Password: <zitadel_postgres_password>
    Admin:
      Password: <zitadel_postgres_password>
```

> The old plan's `ZITADEL_MASTER_KEY=…` env-file shape is **wrong** — `extraSettingsPaths` takes **YAML config files**, and `masterKeyFile` is a separate raw-key file. They are two different secrets. (Corrections table, row 3.)

### 3.3 `modules/services/zitadel.nix` — CREATE

```nix
{ config, lib, pkgs, settings, users, ... }:
let
  helpers  = import ../networking/nginx-helpers.nix { inherit lib settings users; };
  authHost = "auth.${settings.domains.public}";     # auth.dnanu.de  — the ONE ExternalDomain (D1)
  altHost  = "auth.${settings.domains.internal}";   # auth.nanulab.de — 301 redirect only
in { ... }
```

**a) PostgreSQL role + database** (host postgres is already enabled — F2/F3):

```nix
services.postgresql = {
  ensureDatabases = [ "zitadel" ];
  ensureUsers = [{
    name = "zitadel";
    ensureDBOwnership = true;
    ensureClauses = { login = true; createdb = true; createrole = true; };
  }];
};
```
`ensureDBOwnership = true` requires `"zitadel"` to also be in `ensureDatabases` (module assertion) — it is. `createdb`/`createrole` are needed because ZITADEL's own init phase creates its role/schema.

`ensureUsers` cannot set a password. Add a tiny root oneshot that applies it from sops, idempotently:

```nix
systemd.services.zitadel-db-password = {
  after = [ "postgresql.service" ]; requires = [ "postgresql.service" ];
  wantedBy = [ "zitadel.service" ]; before = [ "zitadel.service" ];
  serviceConfig = { Type = "oneshot"; User = "postgres"; };
  script = ''
    pw=$(cat ${config.sops.secrets.zitadel_postgres_password.path})
    ${config.services.postgresql.package}/bin/psql -tAc \
      "ALTER ROLE zitadel WITH PASSWORD '$pw';"
  '';
};
```
⚠️ Escape/quoting is the builder's problem — use `psql -v` binding or a here-doc; do not interpolate a raw password into SQL naively.

**b) ZITADEL service**

```nix
services.zitadel = {
  enable        = true;
  tlsMode       = "external";     # nginx terminates TLS (this is also the module default)
  openFirewall  = false;          # zero-port rule
  masterKeyFile = config.sops.secrets.zitadel_master_key.path;
  extraSettingsPaths = [ config.sops.secrets.zitadel_env.path ];

  settings = {
    Port           = 8080;
    ExternalDomain = authHost;    # auth.dnanu.de — SINGULAR (F7 / D1)
    ExternalPort   = 443;
    ExternalSecure = true;

    Database.postgres = {
      Host     = "127.0.0.1";     # already listening there — F3
      Port     = 5432;
      Database = "zitadel";
      User  = { Username = "zitadel"; SSL.Mode = "disable"; };   # Password → sops (F5)
      Admin = { Username = "zitadel"; ExistingDatabase = "postgres"; SSL.Mode = "disable"; };
    };

    DefaultInstance = {
      InstanceName = "nanulab";
      DefaultLanguage = "en";
      Org.Name = "nanulab";

      # Invite-only, NOT open signup. auth.dnanu.de is internet-reachable (D1);
      # AllowRegister=true would let anyone create an account. Admin creates the
      # user → ZITADEL mails an init code → user sets their own password.
      LoginPolicy = {
        AllowRegister      = false;   # ← corrections table row 4
        AllowExternalIDP   = false;
        AllowUsernamePassword = true;
        HidePasswordReset  = false;
      };

      DomainPolicy.UserLoginMustBeDomain = false;   # explicit; = the default (F14)

      # Transactional mail only (OpenCode.md email rule). Local postfix → Resend.
      SMTPConfiguration = {
        SMTP.Host = "127.0.0.1:25";   # NOTE: host:port in ONE string
        TLS       = false;
        From      = "app@${settings.domains.public}";
        FromName  = "nanulab";
        ReplyToAddress = settings.email.admin;
      };
    };
  };

  steps.FirstInstance = {
    InstanceName = "nanulab";
    Org = {
      Name = "nanulab";
      Human = {
        UserName  = "admin";
        FirstName = "Admin";
        LastName  = "Nanu";
        Email = { Address = settings.email.admin; Verified = true; };
        PasswordChangeRequired = true;
      };
    };
  };
};
```

> `steps.FirstInstance.Org.Human.Password` is deliberately **omitted** — ZITADEL falls back to its default and forces a change at first login. If the human wants a specific bootstrap password, it goes in a **separate** sops YAML wired through `extraStepsPaths` (never in `steps`, which lands world-readable in the Nix store).

**c) nginx vhosts**

```nix
services.nginx.virtualHosts = {
  # The IdP itself. NO IP allowlist — ZITADEL is the auth boundary (D1).
  ${authHost} = {
    forceSSL    = true;
    useACMEHost = settings.domains.mail;      # the *.dnanu.de cert is NAMED mail.dnanu.de (F13)
    locations."/" = {
      proxyPass       = "http://127.0.0.1:8080";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host              $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        grpc_read_timeout 300s;
        client_max_body_size 20m;
      '';
    };
  };

  # Bookmark alias only — never an issuer (D1).
  ${altHost} = {
    forceSSL    = true;
    useACMEHost = settings.domains.internal;   # the nanulab.de cert
    locations."/".return = "301 https://${authHost}$request_uri";
  };
};
```
ZITADEL is strict about the `Host` header (docs: *"the original Host header value must be unchanged"*). `recommendedProxySettings` is already on globally; the explicit `Host` line is belt-and-braces. ⚠️ **V1**.

> **ZITADEL serves gRPC-Web over HTTP/2.** The console may need `http2 on;`. nginx in 26.05 enables HTTP/2 on TLS vhosts by default — confirm the console loads, ⚠️ **V1**.

### 3.4 `modules/services/oauth2-proxy.nix` — CREATE

Native module + its nginx companion (F8). This replaces the entire hand-rolled `auth_request` design.

```nix
{ config, settings, ... }:
let
  authHost    = "auth.${settings.domains.public}";      # auth.dnanu.de
  profileHost = "profile.${settings.domains.public}";   # profile.dnanu.de (D2)
in {
  services.oauth2-proxy = {
    enable   = true;
    provider = "oidc";                                   # NO "zitadel" provider exists (F8)
    oidcIssuerUrl = "https://${authHost}";               # must equal the `iss` claim byte-for-byte

    clientID       = "<from ZITADEL console — public, safe in git>";
    clientSecretFile = config.sops.secrets.zitadel_oidc_client_secret.path;
    cookie.secretFile = config.sops.secrets.oauth2_proxy_cookie_secret.path;

    redirectURL = "https://${profileHost}/oauth2/callback";   # = ${proxyPrefix}/callback (D2)
    httpAddress = "http://127.0.0.1:4180";                    # module default; explicit
    scope       = "openid profile email";

    upstream = "static://202";        # pure auth_request mode — nothing is proxied through
    setXauthrequest = true;           # emits X-Auth-Request-User / -Email / -Preferred-Username
    passBasicAuth   = false;
    reverseProxy    = true;
    trustedProxyIP  = [ "127.0.0.1/32" "::1/128" ];   # else a build WARNING (F11)

    email.domains = [ settings.domains.public ];       # only @dnanu.de identities

    cookie = { secure = true; httpOnly = true; expire = "168h"; refresh = "1h"; };

    nginx = {
      domain = profileHost;                            # where /oauth2/* is mounted
      virtualHosts.${profileHost} = { allowed_email_domains = [ settings.domains.public ]; };
    };
  };
}
```

`services.oauth2-proxy.nginx.virtualHosts` auto-generates, on that vhost: `location /oauth2/` (proxy), `location = /oauth2/auth` (the subrequest), `location @redirectToAuth2ProxyLogin` (the 307 to `/oauth2/start`), the `auth_request_set` block in `location /`, and `auth_request /oauth2/auth; error_page 401 = @redirectToAuth2ProxyLogin;` at server level. **Do not write any of that by hand.**

**1% manual, pass 1 → pass 2:** in the ZITADEL console create Project `nanulab` → Application `profile-page`, type **Web**, auth method **Basic** (client secret), grant **Authorization Code + PKCE**, redirect URI `https://profile.dnanu.de/oauth2/callback`, post-logout redirect URI `https://profile.dnanu.de/`. Copy the client ID into `oauth2-proxy.nix`, the secret into sops.

### 3.5 `modules/services/profile-page.nix` — CREATE, and **delete `modules/services/ios-profile.nix`**

Serves `/var/lib/mobileprofile/wg/<idpUsername>/` — static files, so identity must come from an nginx variable, not a proxied header (F9).

```nix
services.nginx.virtualHosts."profile.${settings.domains.public}" = {
  forceSSL    = true;
  useACMEHost = settings.domains.mail;    # F13
  # NO IP allowlist — intentionally reachable off-VPN via the tunnel (D2).
  # oauth2-proxy is the gate; the auth_request wiring is injected by 3.4.

  locations = {
    # bare / → bounce the user to their own directory
    "= /".extraConfig = ''
      auth_request_set $authuser $upstream_http_x_auth_request_preferred_username;
      return 302 /$authuser/;
    '';

    # named captures = the traversal guard. $reqdir cannot contain "/" and is
    # compared for EQUALITY against the authenticated username, so ".." can
    # never match a real user → 403.
    "~ ^/(?<reqdir>[a-z0-9][a-z0-9._-]*)/(?<reqfile>[a-zA-Z0-9._-]*)$".extraConfig = ''
      auth_request_set $authuser $upstream_http_x_auth_request_preferred_username;
      set $denied 1;
      if ($reqdir = $authuser)  { set $denied 0; }
      if ($authuser = "admin")  { set $denied 0; }   # admin may read every user's QRs
      if ($denied)              { return 403; }

      root /var/lib/mobileprofile/wg;
      index index.html;
      autoindex off;
      add_header Cache-Control "no-store";
    '';

    # RP-initiated logout: drop the oauth2-proxy session, then ZITADEL's.
    "= /logout".return =
      "302 /oauth2/sign_out?rd=https%3A%2F%2Fauth.${settings.domains.public}%2Foidc%2Fv1%2Fend_session";
  };
};
```

- **Sign-out** (corrections table row 2): `/oauth2/sign_out?rd=<url-encoded ZITADEL end_session>`. `https://auth.dnanu.de/oidc/v1/end_session` must be registered as a post-logout redirect target in the ZITADEL app. ⚠️ **V9**.
- `$reqfile` is captured but unused — the regex exists purely to force `$reqdir` into its own capture. `root` (not `alias`) is used deliberately: `alias` with variables plus `try_files` is a known nginx footgun.
- Only `set` and `return` are used inside `if` — the two directives that are actually safe there.
- ⚠️ **V4**: confirm oauth2-proxy actually emits `X-Auth-Request-Preferred-Username` for the `oidc` provider. **Fallback if it does not:** set `extraConfig = { "oidc-email-claim" = "preferred_username"; }` + `email.domains = [ "*" ]` and read `$upstream_http_x_auth_request_email` instead. Decide this on the running instance before merging, not by guessing.

### 3.6 `modules/networking/cloudflare.nix` — MODIFY

Add one ingress line, mirroring the existing entries:

```nix
"auth.${settings.domains.public}" = "https://127.0.0.1:443";
```
Route it at **nginx** (`https://127.0.0.1:443`), **not** directly at `http://127.0.0.1:8080`. Going straight to ZITADEL would bypass TLS termination and hand ZITADEL a `Host` of `127.0.0.1:8080`, breaking instance resolution (F7 "Instance not found"). `originRequest.noTLSVerify = true` is already set on the tunnel. This is a deliberate deviation from ruling #2's "Route to `http://127.0.0.1:8080`".

**Also `modules/services/cloudflare-dns.nix`** — add the public CNAME, mirroring the `profile.dnanu.de` block at lines 89–92:

```sh
deleteRecord "$Z_DNANU" A "auth.${settings.domains.public}"
upsert "$Z_DNANU" CNAME "auth.${settings.domains.public}" \
  "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
```

### 3.7 `modules/networking/adguard.nix` — MODIFY (one line)

`*.nanulab.de` is **already** rewritten (F12) — `auth.nanulab.de` and `profile.nanulab.de` need nothing. Only `auth.dnanu.de` does, so LAN/VPN clients hit nginx directly instead of hairpinning through Cloudflare:

```nix
{ domain = "auth.${settings.domains.public}"; answer = settings.network.address; enabled = true; }
```

Leave `profile.dnanu.de` **unrewritten** — it stays on the public tunnel path, which is what §13 already verifies.

### 3.8 `modules/networking/wireguard.nix` — MODIFY (surgical)

`users` is already passed into this module.

- Render dir: `user_out="$BASE/${users.idpUsername userName}"` (was `$BASE/${userName}`). This is what makes `dumitru` → `dumitru.nanu` and `iza` → `izabela.dwilewicz`.
- Add stale-dir cleanup: `rm -rf "$BASE"` at the top of the render script, before the loop. The tree is fully regenerated every boot, and the old short-name dirs must not linger (they would be served to `admin`, whose branch reads any dir).
- Replace the Authelia logout `<form>`+JS in the generated `index.html` with a plain `<a href="/logout">Sign out</a>` (3.5 handles the rest).
- Append the iOS/Android/PC setup guide as a static `<details>` block in the generated `index.html`. No new service.
- Update the stale header comment on line 10 (`Served behind Authelia at profile.dnanu.de/<user>/`) → oauth2-proxy + ZITADEL.
- The existing `chown -R root:nginx` + `750`/`640` at the end stays as-is.
- **Do not touch** peer derivation, IPs, keys, or the interface. WG v5 renumber is a different milestone.

### 3.9 `hosts/homelab/configuration.nix` — MODIFY

- Add imports: `../../modules/services/zitadel.nix`, `../../modules/services/oauth2-proxy.nix`, `../../modules/services/profile-page.nix`.
- **Remove** the stale `# ios-profile.nix disabled (build target) — … Authentik …` comment line.
- `services.postgresqlBackup.databases = [ "zitadel" ];` (currently `[ ]`).
- **Do not** touch `services.postgresql.enable` / `enableTCPIP` (F3).

### 3.10 Docs — MODIFY (same PR; repo rule "docs ship with the code")

- **`OpenCode.md` §7** — replace `authentik_secret_key` / `authentik_postgres_password` with the five secrets from §3.2.
- **`OpenCode.md` §9** — Authentik row → **ZITADEL** (`services.zitadel`, native 26.05, host-side for now, `.10` zone when containerization lands). URL column: `auth.dnanu.de` (public, tunnel) + `profile.dnanu.de` (public, tunnel). Record that ZITADEL uses the **shared host PostgreSQL**, contradicting nothing in §3.1 except that the DB is not yet in a `.20` container.
- **`OpenCode.md` §10** — replace "custom Authentik page" with the accurate mechanism: *nginx-served per-user WG directory, gated by oauth2-proxy forward-auth against ZITADEL OIDC*.
- **`OpenCode.md` §3.2 / §4.4** — add `auth.dnanu.de` to the tunnel-hosted CNAME list. Router port table is **unchanged** (still 25/tcp + 51820/udp).
- **`OpenCode.md` §12 (1% manual)** — add: (a) first login at `auth.dnanu.de` as `admin` → rotate bootstrap password; (b) create the `profile-page` OIDC app, copy client ID/secret; (c) create the 9 family users → each receives an init-code email → sets their own password.
- **`TODO/05-Identity-Access/todo.md`** — tick what landed; keep open: per-service OIDC clients (F17), containerization (F16), the `first.last` **mail** rename.
- **`Changes.md`** — session entry recording the Authentik→ZITADEL switch, D1 and D2.

---

## 4. ⚠️ VERIFY list — builder/verifier must confirm before merge

| ID | Item | How |
|---|---|---|
| **V1** | `services.zitadel` options behave as read for 2.71.7: service starts, console renders through nginx, Host header intact, gRPC-Web/HTTP2 OK | `systemctl status zitadel`; `journalctl -u zitadel`; load `https://auth.dnanu.de/ui/console` in a browser |
| **V2** | Key precedence between `settings` and `extraSettingsPaths` (F5) — and that **no key is written in both** | inspect the two `--config` paths in `systemctl cat zitadel`; confirm the sops YAML holds **only** the two `Password` keys |
| **V3** | `masterKeyFile` is **exactly 32 bytes**, no trailing newline; owned by `zitadel` (F4/F6) | `wc -c` and `stat -c '%U:%G %a'` on `config.sops.secrets.zitadel_master_key.path` |
| **V4** | oauth2-proxy emits `X-Auth-Request-Preferred-Username` = `first.last` for `provider = "oidc"` (F9) | `journalctl -u oauth2-proxy`; nginx `log_format` capturing `$authuser` for one request. **Fallback documented in §3.5.** |
| **V5** | End-to-end forward-auth: unauthenticated → 307 to `/oauth2/start` → ZITADEL login → back to `/dumitru.nanu/` with the QRs | browser, off-VPN |
| **V6** | Invite flow: admin creates a user → init-code email arrives → user sets password → logs in. (`AllowRegister = false` — verify the register link is **absent**.) | ZITADEL console + a real mailbox |
| **V7** | RAM on the Dell (6 GB, ARC capped at 1 GiB) with zitadel + postgres + oauth2-proxy | `free -m`, `systemd-cgtop` under login load. If it thrashes: add a 4 GB swapfile and **record it** — do **not** silently change `zfsArcMax`. |
| **V8** | Postfix on `127.0.0.1:25` accepts ZITADEL (`mynetworks`) and relays via Resend; `From: app@dnanu.de` is accepted | trigger a password-reset mail to `admin@dnanu.de`, check the postfix log |
| **V9** | Sign-out chain: `/logout` → `/oauth2/sign_out` → `https://auth.dnanu.de/oidc/v1/end_session` (both post-logout URIs registered) | browser; confirm re-visiting `/` re-prompts for login |
| **V10** | PostgreSQL is still **127.0.0.1-only**; `enableTCPIP` untouched (F3) | `ss -ltnp \| grep 5432` → `127.0.0.1` / `::1` only |
| **V11** | Full system closure builds with **zero warnings** (esp. the `trustedProxyIP` warning, F11); `nix flake check` green | `nix flake check`; `nixos-rebuild build` |

---

## 5. Verification (run after deploy; feeds §13)

1. `systemctl --failed` empty; `zitadel`, `oauth2-proxy`, `postgresql` all active.
2. `ss -ltnp | grep -E '8080|4180|5432'` → **127.0.0.1 only**, nothing on `0.0.0.0`.
3. `dig @10.0.10.2 auth.dnanu.de` → `10.0.0.2` (internal rewrite, §3.7).
4. `dig auth.dnanu.de @1.1.1.1` → Cloudflare proxy IPs (public tunnel path).
5. `dig @10.0.10.2 auth.nanulab.de` → `10.0.0.2`; `curl -kI https://auth.nanulab.de/` → **301** to `auth.dnanu.de`.
6. On VPN: `curl -kI https://auth.dnanu.de/` → 200/302, login page renders.
7. **Off-VPN (cellular, tunnel off):** `https://auth.dnanu.de` reachable and the login page renders — this is the invite-flow lifeline (D1).
8. **Off-VPN:** `https://profile.dnanu.de` → 307 → ZITADEL login → after login lands on `/<first.last>/` showing exactly that user's QRs.
9. Cross-user read as a normal user: `GET /adela.nanu/index.html` while logged in as `dumitru.nanu` → **403**. As `admin` → **200**.
10. Path traversal: `GET /../../etc/passwd`, `GET /..%2f..%2fetc/passwd` → **403/404**, never a file.
11. Admin login → console → Users lists `admin` + the family users created so far.
12. Password recovery: "Forgot password" → mail arrives in that user's mailbox → reset works.
13. Router port check unchanged: only **25/tcp + 51820/udp** forwarded.
14. `nix flake check` green; full closure builds with **zero warnings**.

---

## 6. Deliverable checklist for the builder

- [ ] Branch `feat/zitadel-idp`, one commit per numbered step in §2 (two deploy passes, one PR).
- [ ] **Created:** `modules/services/zitadel.nix`, `modules/services/oauth2-proxy.nix`, `modules/services/profile-page.nix`.
- [ ] **Modified:** `users.nix`, `modules/system/sops.nix`, `modules/networking/wireguard.nix`, `modules/networking/adguard.nix`, `modules/networking/cloudflare.nix`, `modules/services/cloudflare-dns.nix`, `hosts/homelab/configuration.nix`, `OpenCode.md`, `TODO/05-Identity-Access/todo.md`, `Changes.md`.
- [ ] **Deleted:** `modules/services/ios-profile.nix`.
- [ ] **Not** created: any flake input; any blueprints dir; any Redis config; any new PostgreSQL instance or container; any hand-written `auth_request` block.
- [ ] `users.nix` helper is named `idpUsername`, not `zitadelUsername`.
- [ ] No key appears in **both** `services.zitadel.settings` and the sops YAML (F5).
- [ ] PR body records every ⚠️ VERIFY result and the RAM figure from **V7**.
- [ ] **`reviewer` sign-off required** — this touches sops, the public `auth.dnanu.de` surface, and per-user file authorization.

---

## 7. Explicitly out of scope

- Containerizing ZITADEL/postgres into the `.10`/`.20` zones (needs the container milestone — F16).
- OIDC clients for Nextcloud / HA / Jellyfin / Glance / arrs (F17 — one per service, when that service is built).
- The `first.last` **mail** rename (separate milestone; `email` stays short-name here).
- WG v5 QR re-render / peer renumber (separate milestone).
- Declarative user provisioning via the ZITADEL Management API (v2 research item — there is no blueprint equivalent).
- LDAP / SAML / external IdP federation.
- Making `auth.nanulab.de` a real second issuer (impossible — F7/D1).
