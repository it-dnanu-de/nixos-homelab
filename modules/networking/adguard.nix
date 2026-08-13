# AdGuard Home — LAN DNS only (DHCP retired to Kea, 2026-08-06).
# OpenCode.md §3.2, §3.4. mutableSettings=false → fully declarative.
#
# v4 (2026-08-06): DHCP migrated to Kea. AdGuard is DNS-only.
# Binds on 0.0.0.0:53 and [::]:53 for IPv6/ULA queries.
# Persistent clients derived from users.nix (isPeer filtered) +
# one static infra entry (router + server labeled in dashboard).
# runtime_sources.dhcp = false — no AGH lease DB; guest labels
# degrade to IP-only via rdns (accepted).
{ config, settings, users, lib, ... }:
let
  # Persistent clients — all users get named persistent clients keyed by IP (LAN+VPN).
  # Only device slots (isPeer=true), plus one static infra entry for router+server.
  persistentClients = lib.flatten (lib.mapAttrsToList (userName: userData:
    let
      ips = lib.flatten (lib.imap0 (idx: dev:
        let ip = users.userToIps userName (idx + 1);
        in if users.isPeer dev then [ ip.lan ip.vpn ] else [ ]
      ) userData.devices);
      tag = if userData.tier == "admin" then "user_admin" else "user_regular";
    in lib.optional (ips != []) {
      name = userName;
      ids = ips;
      tags = [ tag ];
      use_global_settings = true;
    }
  ) users.users) ++ [{
    # Static infra entry: router (10.0.0.1) + server LAN (10.0.0.2) + server VPN (10.0.80.2, WG v5)
    name = "infra";
    ids = [ "10.0.0.1" "10.0.0.2" "10.0.80.2" ];
    tags = [ "user_admin" ];
    use_global_settings = true;
  }];
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "127.0.0.1";
    port = 3000;
    settings = {
      users = [];
      dns = {
        bind_hosts = [ "0.0.0.0" "::" ];
        port = 53;
        ratelimit = 0;
        upstream_mode = "load_balance";
        upstream_dns = [
          "tls://one.one.one.one"
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
          "tls://dns.quad9.net"
        ];
        bootstrap_dns = [ "9.9.9.9" "149.112.112.112" ];
        fallback_dns = [ "1.1.1.1" ];
        enable_dnssec = true;
        cache_enabled = true;
        cache_size = 4194304;
        refuse_any = true;
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        rewrites = [
          # Wildcard matches apex + all subdomains (*.nanulab.de → nginx ingress container)
          # TODO(build): target the nginx ingress container (10.0.10.5) once containerized;
          # currently settings.network.address (host 10.0.0.2).
          { domain = "*.${settings.domains.internal}"; answer = settings.network.address; enabled = true; }
          { domain = settings.domains.mail; answer = settings.network.address; enabled = true; }
          { domain = "auth.${settings.domains.public}"; answer = settings.network.address; enabled = true; }
        ];
        safe_search.enabled = true;
        safe_search.bing = true;
        safe_search.duckduckgo = true;
        safe_search.ecosia = true;
        safe_search.google = true;
        safe_search.pixabay = true;
        safe_search.yandex = true;
        safe_search.youtube = true;
      };
      user_rules = [
        "@@||hotstream.app^$important"
        "@@||icanhazip.com^$important"
        "@@||hotplayer.app^$important"
        "@@||hdstreams.site^$important"
        "@@||resend.com^$important"
        "@@||ipify.org^$important"

      ];
      filters = [
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";  name = "AdGuard DNS filter"; id = 1; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt"; name = "1Hosts (Lite)"; id = 1785782586; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_5.txt";  name = "OISD Blocklist Small"; id = 1785782595; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_34.txt"; name = "HaGeZi's Normal Blocklist"; id = 1785782591; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";  name = "Peter Lowe's Blocklist"; id = 1785782599; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt"; name = "Steven Black's List"; id = 1785782601; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"; name = "Malicious URL Blocklist (URLHaus)"; id = 1785782596; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt"; name = "Phishing Army"; id = 1785782613; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt"; name = "Scam Blocklist by DurableNapkin"; id = 1785782611; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt";  name = "NoCoin Filter List"; id = 1785782616; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt"; name = "Dandelion Sprout's Anti-Malware List"; id = 1785782629; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt"; name = "AdGuard DNS Popup Hosts filter"; id = 1785782589; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt"; name = "Dandelion Sprout's Anti Push Notifications"; id = 1785782602; }
      ];
      # NO dhcp block — DHCP migrated to Kea (Decision B, 2026-08-06).
      # Persistent clients keyed by user (10 users, LAN+VPN IPs — IP-only ids).
      # Guests (10.0.0.100-200) have NO persistent client — labeled dynamically via rdns.
      clients = {
        persistent = persistentClients;
        runtime_sources = {
          whois = true;
          arp = false;
          rdns = true;
          dhcp = false;   # Kea manages DHCP — no AGH lease DB to read
          hosts = true;
        };
      };
    };
  };
}
