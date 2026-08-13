# ZITADEL IdP — native nixos-26.05 module (package 2.71.7).
# OpenCode.md §9 / PLAN-zitadel.md §3.3. Host-side, bound behind nginx;
# no container infra in this milestone (F16). ExternalDomain is singular
# (auth.dnanu.de) — D1. Invite-only (AllowRegister = false).
{ config, lib, pkgs, settings, users, ... }:
let
  helpers  = import ../networking/nginx-helpers.nix { inherit lib settings users; };
  authHost = "auth.${settings.domains.public}";     # auth.dnanu.de  — the ONE ExternalDomain (D1)
  altHost  = "auth.${settings.domains.internal}";   # auth.nanulab.de — 301 redirect only
in {
  # ── PostgreSQL role + database (host postgres already enabled — F2/F3) ──
  services.postgresql = {
    ensureDatabases = [ "zitadel" ];
    ensureUsers = [{
      name = "zitadel";
      ensureDBOwnership = true;
      ensureClauses = { login = true; createdb = true; createrole = true; };
    }];
  };

  # ensureUsers cannot set a password. Apply it from sops, idempotently.
  # LoadCredential: systemd (root) opens the root-only secret; the unit
  # then drops to User=postgres (peer auth). Do not interpolate $pw into SQL.
  systemd.services.zitadel-db-password = {
    after = [ "postgresql.service" "sops-nix.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "zitadel.service" ];
    before = [ "zitadel.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      RemainAfterExit = true;
      LoadCredential = "pgpass:${config.sops.secrets.zitadel_postgres_password.path}";
    };
    script = ''
      pw=$(cat "$CREDENTIALS_DIRECTORY/pgpass")
      ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 \
        -c "ALTER ROLE zitadel WITH PASSWORD :'pw'" \
        -v pw="$pw"
    '';
  };

  systemd.services.zitadel = {
    after = [ "postgresql.service" "zitadel-db-password.service" ];
    requires = [ "postgresql.service" "zitadel-db-password.service" ];
  };

  # ── ZITADEL ────────────────────────────────────────────────
  services.zitadel = {
    enable        = true;
    tlsMode       = "external";     # nginx terminates TLS (also the module default)
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
          AllowRegister           = false;
          AllowExternalIDP        = false;
          AllowUsernamePassword   = true;
          HidePasswordReset       = false;
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

  # ── nginx vhosts ───────────────────────────────────────────
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
}
