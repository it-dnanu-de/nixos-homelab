# settings.nix — the single user file (migration contract, OpenCode.md §2)
#
# Every value used by modules is defined here.
# When moving to prod hardware, only this file, disko.nix, and
# hardware-configuration.nix change — everything else stays identical.

{
  hostName = "homelab";

  domains = {
    public = "dnanu.de";          # mail + blogs
    internal = "nanulab.de";     # VPN-only services (split-horizon DNS → 10.0.0.2)
    mail = "mail.dnanu.de";      # SMTP/IMAP/ManageSieve
    vpn = "vpn.dnanu.de";        # WireGuard endpoint (grey cloud, ddclient-managed)
  };

  email = {
    hey = "hey@dnanu.de";        # primary mailbox
    admin = "admin@dnanu.de";    # services admin
    acme = "admin@dnanu.de";     # Let's Encrypt registration
  };

  network = {
    interface = "enp10s0";       # verified on Dell live-ISO, prod may differ
    address = "10.0.0.2";
    prefixLength = 24;
    subnet = "10.0.0.0/24";      # LAN — allowed to reach local nginx TLS vhosts (AdGuard UI, profile)
    gateway = "10.0.0.1";
    # Admin LAN IPs are now derived from users.nix (admin block 10.0.0.3-9).
  };

  hostId = "2f69efe2";           # ZFS requires stable host ID — generate once, keep forever

  zfsArcMax = "1073741824";      # 1 GiB on the Dell's 6 GB; bump to 8–16 GiB on prod

  paths = {
    fast = "/fast";              # SSD pool (or dataset) — apps, databases, mail
    slow = "/slow";              # HDD pool — media, downloads
  };

  vpn = {
    forwardedPort = 0;           # AirVPN static port for downloaders — human sets from AirVPN dashboard after subscribing (1% manual; still need the subscription)
  };

  # WireGuard remote-access VPN (OpenCode.md §3.3, v4 10.0.10.0/24).
  # Server 10.0.10.2/24, endpoint vpn.dnanu.de:51820.
  # 97 peers (7 admin admin3-9-vpn + 90 user [user]+[user]1-9-vpn) —
  # fully pre-provisioned with real keypairs. admin0/1/2 are infra/router/server.
  # Naming: admin block .0-.9 (admin0=net addr, admin1=router, admin2=server,
  # admin3-9=WG peers). Users: base=[user]@.10-90 step 10 + [user]1-9.
  # Peers derived from users.nix; public keys in generated wireguard-pubkeys.nix.
  # Private keys + PSKs in sops (wireguard_peer_<hostname>-vpn_{private,psk} × 194).
  network.wireguard = {
    port = 51820;
    subnet = "10.0.10.0/24";
    address = "10.0.10.2";
    endpoint = "vpn.dnanu.de";
    # Public keys per-device hostname (97 entries, generated — public, safe in git).
    peerPublicKeys = import ./wireguard-pubkeys.nix;
  };

  sshPubKey = "ssh-ed25519 AAAA… placeholder";  # human populates with their real key
  # Note: SSH password authentication remains enabled — intentional by human ruling.

  cloudflare = {
    tunnelId = "734c3fa5-7b72-4cfb-8003-f1cab01743ee"; # local-config tunnel (recreated 2026-08-07 via API, config_src=local)
  };

  timeZone = "Europe/Berlin";
}
