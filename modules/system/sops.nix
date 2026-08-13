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
      slskd_env = {};

      # ZITADEL — read by the zitadel process itself (no LoadCredential) → zitadel-owned
      zitadel_master_key = { owner = "zitadel"; group = "zitadel"; mode = "0400"; };
      zitadel_env         = { owner = "zitadel"; group = "zitadel"; mode = "0400"; };

      # ZITADEL / oauth2-proxy — read by systemd as root (LoadCredential / oneshot)
      zitadel_postgres_password  = {};
      zitadel_oidc_client_secret = {};
      oauth2_proxy_cookie_secret = {};
    };
  };
}
