# oauth2-proxy — forward-auth gateway for profile.dnanu.de against ZITADEL OIDC.
# PLAN-zitadel.md §3.4. provider = "oidc" (no "zitadel" enum). The nginx
# companion auto-generates /oauth2/, = /oauth2/auth, @redirectToAuth2ProxyLogin
# and the server-level auth_request — do not hand-roll any of that.
#
# Pass 2: replace clientID (and the sops zitadel_oidc_client_secret) with the
# values from the ZITADEL console (Project nanulab → Application profile-page).
{ config, settings, ... }:
let
  authHost    = "auth.${settings.domains.public}";      # auth.dnanu.de
  profileHost = "profile.${settings.domains.public}";   # profile.dnanu.de (D2)
in {
  services.oauth2-proxy = {
    enable   = true;
    provider = "oidc";                                   # NO "zitadel" provider exists (F8)
    oidcIssuerUrl = "https://${authHost}";               # must equal the `iss` claim byte-for-byte

    clientID         = "<PLACEHOLDER>";                  # filled pass 2 from ZITADEL console
    clientSecretFile = config.sops.secrets.zitadel_oidc_client_secret.path;
    cookie = {
      secretFile = config.sops.secrets.oauth2_proxy_cookie_secret.path;
      secure     = true;
      httpOnly   = true;
      expire     = "168h";
      refresh    = "1h";
    };

    redirectURL = "https://${profileHost}/oauth2/callback";   # = ${proxyPrefix}/callback (D2)
    httpAddress = "http://127.0.0.1:4180";                    # module default; explicit
    scope       = "openid profile email";

    upstream        = "static://202";     # pure auth_request mode — nothing is proxied through
    setXauthrequest = true;               # emits X-Auth-Request-User / -Email / -Preferred-Username
    passBasicAuth   = false;
    reverseProxy    = true;
    trustedProxyIP  = [ "127.0.0.1/32" "::1/128" ];   # else a build WARNING (F11)

    email.domains = [ settings.domains.public ];       # only @dnanu.de identities

    nginx = {
      domain = profileHost;                            # where /oauth2/* is mounted
      virtualHosts.${profileHost} = {
        allowed_email_domains = [ settings.domains.public ];
      };
    };
  };
}
