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
      airvpn_wg_conf = {};
      b2_account_id = {};
      b2_account_key = {};
      restic_password = {};
      nextcloud_admin_pass = {};
      vaultwarden_admin_token = {};
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
