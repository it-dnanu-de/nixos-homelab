# profile.dnanu.de — per-user WireGuard QR directory, gated by oauth2-proxy.
# PLAN-zitadel.md §3.5. Static files: identity comes from an nginx variable
# ($upstream_http_x_auth_request_preferred_username), not a proxied header (F9).
# The auth_request scaffolding is injected by oauth2-proxy.nix — do not rewrite it.
# NO IP allowlist — reachable off-VPN via the cloudflared tunnel (D2).
{ settings, ... }:
{
  services.nginx.virtualHosts."profile.${settings.domains.public}" = {
    forceSSL    = true;
    useACMEHost = settings.domains.mail;    # F13 — cert is named mail.dnanu.de

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
        if ($authuser = "admin")  { set $denied 0; }
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
}
