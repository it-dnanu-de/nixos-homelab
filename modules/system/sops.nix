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
      # Authelia authentication (OpenCode.md §7, plan §3)
      authelia_jwt = {
        owner = "authelia-main";
      };
      authelia_storage_key = {
        owner = "authelia-main";
      };
      authelia_users_yaml = {
        owner = "authelia-main";
        mode = "0400";
      };
      mobileca_key = {};
      mobileca_cert = {};
    };
  };
}
