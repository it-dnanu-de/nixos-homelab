# profile.dnanu.de — per-user WireGuard configs + QR codes.
# OpenCode.md §10 (2026-08-08): the profile page moves INSIDE Authentik (custom
# OIDC-gated page). The .mobileconfig generator is DROPPED (iOS/Android use native
# apps / Nextcloud). This module is a BUILD TARGET — the builder reworks it to
# Authentik auth (not Authelia below) when containerizing.
#
# WireGuard peer configs and QR codes are rendered by wireguard-profile-render
# oneshot (wireguard.nix) into /var/lib/mobileprofile/wg/<user>/.
{ config, settings, ... }:
{
  services.nginx.virtualHosts."profile.${settings.domains.public}" = {
    forceSSL = true;
    useACMEHost = settings.domains.public;   # *.dnanu.de wildcard cert
    # NO basicAuthFile — Authelia auth_request replaces shared basic auth (§10).

    # /auth — internal endpoint for nginx auth_request to Authelia's verify endpoint.
    # Authelia is mounted at /authelia (server.address path), so verify lives at
    # /authelia/api/verify. X-Original-URL must be the FULL absolute URL — Authelia
    # rejects sessions whose scheme isn't https (relative $request_uri breaks it).
    locations."= /auth" = {
      extraConfig = ''
        internal;
        proxy_pass http://127.0.0.1:9091/authelia/api/verify;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL $scheme://$host$request_uri;
        proxy_set_header X-Original-Method $request_method;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };

    # /authelia/ — proxy to Authelia login UI (mounted at /authelia on 9091).
    locations."/authelia/" = {
      proxyPass = "http://127.0.0.1:9091";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
      '';
    };

    # Named location: unauth'd requests land here → Authelia login with rd= return-to.
    locations."@authelia_login" = {
      extraConfig = ''
        return 302 /authelia/?rd=$scheme://$host$request_uri;
      '';
    };

    # Logout — clears the Authelia session cookie. Authelia's /api/logout expects
    # {"targetURL": ...} in the POST body and returns only safeTargetURL; the Authelia
    # frontend JS performs the redirect. Our profile pages carry a tiny logout script
    # that POSTs the targetURL then navigates to the site root (re-entering login).
    locations."= /logout" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:9091/authelia/api/logout;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
      '';
    };

    # Everything else under the vhost: gate via Authelia and serve the AUTHENTICATED
    # user's own files. root derives from $auth_user. try_files: real files
    # (dumitru-phone-vpn.png/.conf, linked relatively from index.html) resolve to
    # root + $uri; anything else falls back to that user's index.html. No URL can
    # reach another user's files.
    locations."/" = {
      extraConfig = ''
        auth_request /auth;
        auth_request_set $auth_user $upstream_http_remote_user;
        error_page 401 = @authelia_login;
        root /var/lib/mobileprofile/wg/$auth_user;
        try_files $uri /index.html =404;
        autoindex off;
        add_header Cache-Control "no-store";
      '';
    };
  };
}
