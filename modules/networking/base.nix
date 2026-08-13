# Base networking: static IP, gateway, firewall, DNS.
# OpenCode.md §3.1 — server is static 10.0.0.2/24, gw 10.0.0.1.
# v4 (2026-08-06): ULA fd10::2/64 for Kea DHCPv6 DNS, accept_ra=1
# (keep SLAAC GUA for outbound v6/mail, no v6 forwarding).
# DHCP is now Kea (§3.1), not AdGuard.
# Open ports: 25/tcp (inbound SMTP), 51820/udp (WireGuard — §3.3).
{ settings, ... }:
{
  networking.useDHCP = false;
  networking.interfaces.${settings.network.interface} = {
    ipv4.addresses = [{
      address = settings.network.address;
      prefixLength = settings.network.prefixLength;
    }];
    # ULA for Kea DHCPv6 DNS (fd10::2/64); GUA comes from Speedport SLAAC.
    ipv6.addresses = [{
      address = "fd10::2";
      prefixLength = 64;
    }];
  };
  networking.defaultGateway = settings.network.gateway;

  time.timeZone = settings.timeZone;

  # Host uses AdGuard on loopback for split-horizon DNS correctness.
  networking.nameservers = [ "127.0.0.1" ];
  services.resolved.enable = false;

  # Belt-and-braces: ensure SLAAC GUA stays alive (needed for outbound v6 mail).
  # No v6 forwarding enabled, so accept_ra=1 is honored.
  boot.kernel.sysctl."net.ipv6.conf.${settings.network.interface}.accept_ra" = 1;

  # Explicitly disable IPv6 forwarding so SLAAC Router Advertisements are honored.
  # WireGuard only needs v4 forwarding (net.ipv4.ip_forward=1 in wireguard.nix).
  # This also defends against any future module that might enable v6 forwarding.
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = false;

  networking.firewall = {
    enable = true;
    # Only ports reachable from the public internet:
    # TCP 25 (inbound SMTP — MX), UDP 51820 (WireGuard endpoint).
    # Every other port is source-scoped to LAN/ULA/link-local via extraCommands
    # so the host enforces §3.2 itself, not just the router (defence-in-depth).
    allowedTCPPorts = [ 25 ];
    allowedUDPPorts = [ 51820 ];
    # WireGuard interface — all traffic trusted (how admin UIs are reached).
    trustedInterfaces = [ "wg0" ];

    # ── Source-scoped service ports (OpenCode.md §3.2, audit Finding 1) ──
    # extraCommands runs in the iptables backend context (just before the
    # final reject rule).  Each uses explicit -w-wrapped iptables/ip6tables
    # because source subnets differ between address families.
    # wg0 is already trustedInterfaces and needs no extra rules here.
    # LAN scope is 10.0.0.0/16 (covers all 9 container zones, §3.1).
    extraCommands = ''
      # TCP 53 (AGH DNS), 80 (HTTP→HTTPS redirect), 443 (nginx TLS),
      # 465 (submission SMTPS), 587 (submission), 993 (IMAPS)
      # — scoped to LAN / ULA / link-local.
      iptables  -w -A nixos-fw -p tcp -m multiport --dports 53,80,443,465,587,993 -s 10.0.0.0/16 -j nixos-fw-accept
      ip6tables -w -A nixos-fw -p tcp -m multiport --dports 53,80,443,465,587,993 -s fd10::/64  -j nixos-fw-accept
      ip6tables -w -A nixos-fw -p tcp -m multiport --dports 53,80,443,465,587,993 -s fe80::/64  -j nixos-fw-accept

      # UDP 53 (AGH DNS) — same scope
      iptables  -w -A nixos-fw -p udp --dport 53 -s 10.0.0.0/16 -j nixos-fw-accept
      ip6tables -w -A nixos-fw -p udp --dport 53 -s fd10::/64  -j nixos-fw-accept
      ip6tables -w -A nixos-fw -p udp --dport 53 -s fe80::/64  -j nixos-fw-accept

      # UDP 67 (Kea DHCPv4) — LAN unicast + DHCPDISCOVER broadcast (src 0.0.0.0:68)
      iptables -w -A nixos-fw -p udp --dport 67 -s 10.0.0.0/16 -j nixos-fw-accept
      iptables -w -A nixos-fw -p udp --dport 67 -s 0.0.0.0 -d 255.255.255.255 -j nixos-fw-accept

      # UDP 547 (Kea DHCPv6) — link-local scope (mirrors existing DHCPv6-client rule)
      ip6tables -w -A nixos-fw -p udp --dport 547 -s fe80::/64 -j nixos-fw-accept

      # TODO(build): zone isolation — nftables default-deny between the 9 zones
      # (§3.1): frontend→backend, backend→DB, HA→IoT, nginx→all. Backends host-side.
    '';
  };
}
