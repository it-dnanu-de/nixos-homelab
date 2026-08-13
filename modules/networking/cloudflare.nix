# cloudflared — Cloudflare tunnel for public web surfaces.
# OpenCode.md §3.6. Tunnels dnanu.de, www, autoconfig, profile, and auth
# to local nginx. profile/auth use https://127.0.0.1:443 (TLS at nginx).
# Tunnel routes created once in CF dashboard per §12 (1% manual).
{ config, settings, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels.${settings.cloudflare.tunnelId} = {
      credentialsFile = config.sops.secrets.cloudflared_tunnel_cred.path;
      # cloudflared connects to nginx over localhost TLS (https://127.0.0.1:443).
      # The LE cert is for *.dnanu.de (no IP SAN for 127.0.0.1) → skip TLS verify;
      # TLS is still terminated by nginx, cloudflared just needs to reach it.
      originRequest.noTLSVerify = true;
      ingress = {
        "${settings.domains.public}" = "http://127.0.0.1:8080";
        "www.${settings.domains.public}" = "http://127.0.0.1:8080";
        "autoconfig.${settings.domains.public}" = "http://127.0.0.1:8080";
        "mta-sts.${settings.domains.public}" = "http://127.0.0.1:8080";
        "profile.${settings.domains.public}" = "https://127.0.0.1:443";
        "auth.${settings.domains.public}" = "https://127.0.0.1:443";
      };
      default = "http_status:404";
    };
  };
}
