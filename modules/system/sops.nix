{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      cloudflare_api_token = {};
      cloudflare_account_token = {};

      cloudflared_tunnel_cred = {};



      resend_api_key = {};
      mail_hey = {};
      mail_admin = {};
      # 9 family mailboxes (users.nix is the single source of truth)
      mail_dumitru = {};
      mail_adela = {};
      mail_tiberiu = {};
      mail_david = {};
      mail_ramona = {};
      mail_tibisor = {};
      mail_iza = {};
      mail_kerem = {};
      mail_hannah = {};
      airvpn_wg_conf = {};
      b2_account_id = {};
      b2_account_key = {};
      restic_password = {};
      nextcloud_admin_pass = {};
      nextcloud_aio_env = {};   # TODO(build): AIO env file (admin URL, ports, etc.)
      slskd_env = {};
      # Authentik (IdP) secrets — added at build time with the Authentik container
      authentik_secret_key = {};
      authentik_postgres_password = {};
      # per-user per-service password hashes (user_<name>_pass_<service>)
      # (Authelia + mobileca secrets removed 2026-08-08 — Authelia dropped, .mobileconfig dropped)
    };
  };
}
