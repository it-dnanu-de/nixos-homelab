# users.nix — single source of truth for users, devices, and IP allocation.
# Consumed by: kea.nix (DHCP host reservations), adguard.nix (persistent clients),
# wireguard.nix (WG peers + QR renderer), nginx.nix (ACL allowlists).
#
# v5 (2026-08-12): [user]1-9 naming (base = [user], no number = username), full
# 10-slot-per-user block pre-provision. /16 zones (§3.1): users LAN .70, users VPN .80.
# blocks: admin=0, dumitru=10, adela=20, tiberiu=30, david=40, ramona=50,
# tibisor=60, iza=70, kerem=80, hannah=90.
#
# The human only edits `hostname` + `mac` per device. IPs are DERIVED from
# the user's block offset + device index (1-based). All helpers use pure builtins.
#
# IP allocation (v5, /16 LAN — users LAN .70, users VPN .80, guests .90):
#   admin   → LAN 10.0.70.0-9   · VPN 10.0.80.0-9   (admin/admin1/admin2 = infra/router/server)
#   dumitru → LAN 10.0.70.10-19 · VPN 10.0.80.10-19
#   adela   → LAN 10.0.70.20-29 · VPN 10.0.80.20-29
#   tiberiu → LAN 10.0.70.30-39 · VPN 10.0.80.30-39
#   david   → LAN 10.0.70.40-49 · VPN 10.0.80.40-49
#   ramona  → LAN 10.0.70.50-59 · VPN 10.0.80.50-59
#   tibisor → LAN 10.0.70.60-69 · VPN 10.0.80.60-69
#   iza     → LAN 10.0.70.70-79 · VPN 10.0.80.70-79
#   kerem   → LAN 10.0.70.80-89 · VPN 10.0.80.80-89
#   hannah  → LAN 10.0.70.90-99 · VPN 10.0.80.90-99
#   guests  → LAN 10.0.90.100-200 · DHCP pool, no VPN

rec {
  # User block base offsets (LAN base = .70, VPN base = .80 — mirrors)
  blocks = {
    admin   = { lan = 0;  vpn = 0;  };  # .0-.9
    dumitru = { lan = 10; vpn = 10; };  # .10-.19
    adela   = { lan = 20; vpn = 20; };  # .20-.29
    tiberiu = { lan = 30; vpn = 30; };  # .30-.39
    david   = { lan = 40; vpn = 40; };  # .40-.49
    ramona  = { lan = 50; vpn = 50; };  # .50-.59
    tibisor = { lan = 60; vpn = 60; };  # .60-.69
    iza     = { lan = 70; vpn = 70; };  # .70-.79
    kerem   = { lan = 80; vpn = 80; };  # .80-.89
    hannah  = { lan = 90; vpn = 90; };  # .90-.99
  };

  users = {
    # ── admin (10 slots: admin .0 network address, admin1 .1 router, admin2 .2 server, admin3-9 devices) ──
    admin = {
      tier = "admin";
      devices = [
        { hostname = "admin";  mac = null;               role = "infra";   note = "network address (.0) — not a real device"; }
        { hostname = "admin1"; mac = null;               role = "infra";   note = "router (Speedport, .1) — not a real device"; }
        { hostname = "admin2"; mac = null;               role = "server";  note = "dell homelab — WG server 10.0.80.2 (.2)"; }
        { hostname = "admin3"; mac = "2c:9c:58:60:c8:25";                 note = "Arch PC (.3)"; }
        { hostname = "admin4"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .4)"; }
        { hostname = "admin5"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .5)"; }
        { hostname = "admin6"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .6)"; }
        { hostname = "admin7"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .7)"; }
        { hostname = "admin8"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .8)"; }
        { hostname = "admin9"; mac = "TODO";                               note = "TBS — fill MAC here (spare device .9)"; }
      ];
    };

    # ── dumitru (10 slots: dumitru .10 base, dumitru1-9 .11-.19 spare) ──
    dumitru = {
      tier = "user";
      devices = [
        { hostname = "dumitru";  mac = "f6:5b:6b:f3:0e:87"; note = "iPhone 17 Pro (.10)"; }
        { hostname = "dumitru1"; mac = "TODO";               note = "TBS — fill MAC here (spare device .11)"; }
        { hostname = "dumitru2"; mac = "TODO";               note = "TBS — fill MAC here (spare device .12)"; }
        { hostname = "dumitru3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .13)"; }
        { hostname = "dumitru4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .14)"; }
        { hostname = "dumitru5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .15)"; }
        { hostname = "dumitru6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .16)"; }
        { hostname = "dumitru7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .17)"; }
        { hostname = "dumitru8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .18)"; }
        { hostname = "dumitru9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .19)"; }
      ];
    };

    # ── adela (10 slots: adela .20 base, adela1 .21 TV, adela2 .22 Air, adela3-9 spare) ──
    adela = {
      tier = "user";
      devices = [
        { hostname = "adela";  mac = "fe:02:26:df:0c:50"; note = "iPhone XS (.20)"; }
        { hostname = "adela1"; mac = "00:c3:f4:ea:fe:a6"; note = "Samsung TV (.21)"; }
        { hostname = "adela2"; mac = "68:79:c4:29:1d:44"; note = "Philips Air (.22)"; }
        { hostname = "adela3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .23)"; }
        { hostname = "adela4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .24)"; }
        { hostname = "adela5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .25)"; }
        { hostname = "adela6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .26)"; }
        { hostname = "adela7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .27)"; }
        { hostname = "adela8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .28)"; }
        { hostname = "adela9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .29)"; }
      ];
    };

    # ── tiberiu (10 slots: tiberiu .30 base, tiberiu1-9 spare) ──
    tiberiu = {
      tier = "user";
      devices = [
        { hostname = "tiberiu";  mac = "da:08:7b:fe:cf:d7"; note = "Galaxy S22U (.30)"; }
        { hostname = "tiberiu1"; mac = "TODO";               note = "TBS — fill MAC here (spare device .31)"; }
        { hostname = "tiberiu2"; mac = "TODO";               note = "TBS — fill MAC here (spare device .32)"; }
        { hostname = "tiberiu3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .33)"; }
        { hostname = "tiberiu4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .34)"; }
        { hostname = "tiberiu5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .35)"; }
        { hostname = "tiberiu6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .36)"; }
        { hostname = "tiberiu7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .37)"; }
        { hostname = "tiberiu8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .38)"; }
        { hostname = "tiberiu9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .39)"; }
      ];
    };

    # ── david (10 slots: david .40 base, david1 .41 Xbox, david2-9 spare) ──
    david = {
      tier = "user";
      devices = [
        { hostname = "david";  mac = "76:6f:b2:93:10:ce"; note = "iPhone 17 Pro Max (.40)"; }
        { hostname = "david1"; mac = "c4:9d:ed:c9:9a:13"; note = "Xbox One (.41)"; }
        { hostname = "david2"; mac = "TODO";               note = "TBS — fill MAC here (spare device .42)"; }
        { hostname = "david3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .43)"; }
        { hostname = "david4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .44)"; }
        { hostname = "david5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .45)"; }
        { hostname = "david6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .46)"; }
        { hostname = "david7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .47)"; }
        { hostname = "david8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .48)"; }
        { hostname = "david9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .49)"; }
      ];
    };

    # ── ramona (10 slots: ramona .50 base, ramona1-9 spare) ──
    ramona = {
      tier = "user";
      devices = [
        { hostname = "ramona";  mac = "56:ea:b4:79:06:61"; note = "iPhone 11 (.50)"; }
        { hostname = "ramona1"; mac = "TODO";               note = "TBS — fill MAC here (spare device .51)"; }
        { hostname = "ramona2"; mac = "TODO";               note = "TBS — fill MAC here (spare device .52)"; }
        { hostname = "ramona3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .53)"; }
        { hostname = "ramona4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .54)"; }
        { hostname = "ramona5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .55)"; }
        { hostname = "ramona6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .56)"; }
        { hostname = "ramona7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .57)"; }
        { hostname = "ramona8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .58)"; }
        { hostname = "ramona9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .59)"; }
      ];
    };

    # ── tibisor (10 slots: tibisor .60 base, tibisor1-9 spare) ──
    tibisor = {
      tier = "user";
      devices = [
        { hostname = "tibisor";  mac = "26:05:a5:6c:e2:56"; note = "iPhone 14 (.60)"; }
        { hostname = "tibisor1"; mac = "TODO";               note = "TBS — fill MAC here (spare device .61)"; }
        { hostname = "tibisor2"; mac = "TODO";               note = "TBS — fill MAC here (spare device .62)"; }
        { hostname = "tibisor3"; mac = "TODO";               note = "TBS — fill MAC here (spare device .63)"; }
        { hostname = "tibisor4"; mac = "TODO";               note = "TBS — fill MAC here (spare device .64)"; }
        { hostname = "tibisor5"; mac = "TODO";               note = "TBS — fill MAC here (spare device .65)"; }
        { hostname = "tibisor6"; mac = "TODO";               note = "TBS — fill MAC here (spare device .66)"; }
        { hostname = "tibisor7"; mac = "TODO";               note = "TBS — fill MAC here (spare device .67)"; }
        { hostname = "tibisor8"; mac = "TODO";               note = "TBS — fill MAC here (spare device .68)"; }
        { hostname = "tibisor9"; mac = "TODO";               note = "TBS — fill MAC here (spare device .69)"; }
      ];
    };

    # ── iza (10 slots: iza .70 base, iza1-9 spare — ALL MACs TODO) ──
    iza = {
      tier = "user";
      devices = [
        { hostname = "iza";  mac = "TODO"; note = "iPhone 15 (.70) — TBS: fill MAC here"; }
        { hostname = "iza1"; mac = "TODO"; note = "TBS — fill MAC here (spare device .71)"; }
        { hostname = "iza2"; mac = "TODO"; note = "TBS — fill MAC here (spare device .72)"; }
        { hostname = "iza3"; mac = "TODO"; note = "TBS — fill MAC here (spare device .73)"; }
        { hostname = "iza4"; mac = "TODO"; note = "TBS — fill MAC here (spare device .74)"; }
        { hostname = "iza5"; mac = "TODO"; note = "TBS — fill MAC here (spare device .75)"; }
        { hostname = "iza6"; mac = "TODO"; note = "TBS — fill MAC here (spare device .76)"; }
        { hostname = "iza7"; mac = "TODO"; note = "TBS — fill MAC here (spare device .77)"; }
        { hostname = "iza8"; mac = "TODO"; note = "TBS — fill MAC here (spare device .78)"; }
        { hostname = "iza9"; mac = "TODO"; note = "TBS — fill MAC here (spare device .79)"; }
      ];
    };

    # ── kerem (10 slots: kerem .80 base, kerem1-9 spare — ALL MACs TODO) ──
    kerem = {
      tier = "user";
      devices = [
        { hostname = "kerem";  mac = "TODO"; note = "iPhone 16 Pro (.80) — TBS: fill MAC here"; }
        { hostname = "kerem1"; mac = "TODO"; note = "TBS — fill MAC here (spare device .81)"; }
        { hostname = "kerem2"; mac = "TODO"; note = "TBS — fill MAC here (spare device .82)"; }
        { hostname = "kerem3"; mac = "TODO"; note = "TBS — fill MAC here (spare device .83)"; }
        { hostname = "kerem4"; mac = "TODO"; note = "TBS — fill MAC here (spare device .84)"; }
        { hostname = "kerem5"; mac = "TODO"; note = "TBS — fill MAC here (spare device .85)"; }
        { hostname = "kerem6"; mac = "TODO"; note = "TBS — fill MAC here (spare device .86)"; }
        { hostname = "kerem7"; mac = "TODO"; note = "TBS — fill MAC here (spare device .87)"; }
        { hostname = "kerem8"; mac = "TODO"; note = "TBS — fill MAC here (spare device .88)"; }
        { hostname = "kerem9"; mac = "TODO"; note = "TBS — fill MAC here (spare device .89)"; }
      ];
    };

    # ── hannah (10 slots: hannah .90 base, hannah1-9 spare — ALL MACs TODO) ──
    hannah = {
      tier = "user";
      devices = [
        { hostname = "hannah";  mac = "TODO"; note = "iPhone 15 Pro (.90) — TBS: fill MAC here"; }
        { hostname = "hannah1"; mac = "TODO"; note = "TBS — fill MAC here (spare device .91)"; }
        { hostname = "hannah2"; mac = "TODO"; note = "TBS — fill MAC here (spare device .92)"; }
        { hostname = "hannah3"; mac = "TODO"; note = "TBS — fill MAC here (spare device .93)"; }
        { hostname = "hannah4"; mac = "TODO"; note = "TBS — fill MAC here (spare device .94)"; }
        { hostname = "hannah5"; mac = "TODO"; note = "TBS — fill MAC here (spare device .95)"; }
        { hostname = "hannah6"; mac = "TODO"; note = "TBS — fill MAC here (spare device .96)"; }
        { hostname = "hannah7"; mac = "TODO"; note = "TBS — fill MAC here (spare device .97)"; }
        { hostname = "hannah8"; mac = "TODO"; note = "TBS — fill MAC here (spare device .98)"; }
        { hostname = "hannah9"; mac = "TODO"; note = "TBS — fill MAC here (spare device .99)"; }
      ];
    };
  };

  # Guest DHCP range (no VPN, no persistent client — dynamic pool .100-.200)
  guests = {
    lanStart = "10.0.90.100";
    lanEnd   = "10.0.90.200";   # .201-.254 unassigned
  };

  # Given a user name + device index (1-based), derive LAN and VPN IPs.
  # Example: userToIps "adela" 2 → { lan = "10.0.70.21"; vpn = "10.0.80.21"; }
  userToIps = userName: idx:
    let block = blocks.${userName};
    in {
      lan = "10.0.70.${toString (block.lan + idx - 1)}";
      vpn = "10.0.80.${toString (block.vpn + idx - 1)}";
    };

  # ── v4 helpers (pure builtins only — no lib available at import time) ──

  # isPeer: true for device slots (role=="device" or no role), false for infra/server roles.
  isPeer = dev: (dev.role or "device") == "device";

  # wgPeers: all WG peers — 7 admin (admin3-9) + 90 user = 97 total.
  wgPeers = builtins.concatLists (builtins.map (userName:
    let
      userData = users.${userName};
      devs = userData.devices;
      n = builtins.length devs;
    in
      builtins.catAttrs "peer" (builtins.genList (i:
        let
          dev = builtins.elemAt devs i;
          ips = userToIps userName (i + 1);
        in
          if isPeer dev then {
            peer = {
              hostname = dev.hostname;
              name = "${dev.hostname}-vpn";
              ip = ips.vpn;
              lan = ips.lan;
              user = userName;
              admin = userData.tier == "admin";
            };
          } else {}
      ) n)
  ) (builtins.attrNames users));

  # wgPeerNames: sorted list of 97 peer names (e.g. ["admin3-vpn" "admin4-vpn" … "hannah9-vpn"]).
  wgPeerNames = builtins.map (p: p.name) wgPeers;

  # dhcpReservations: DHCP host reservations for devices with real MACs only → exactly 10:
  # admin3 .3 · dumitru .10 · adela .20 · adela1 .21 · adela2 .22 · tiberiu .30
  # david .40 · david1 .41 · ramona .50 · tibisor .60
  dhcpReservations = builtins.filter (r: r != null)
    (builtins.concatLists (builtins.map (userName:
      let
        userData = users.${userName};
        devs = userData.devices;
        n = builtins.length devs;
      in
        builtins.genList (i:
          let
            dev = builtins.elemAt devs i;
            ips = userToIps userName (i + 1);
          in
            if isPeer dev && dev.mac != "TODO" && dev.mac != null then {
              hostname = dev.hostname;
              mac = dev.mac;
              ip = ips.lan;
            } else null
        ) n
    ) (builtins.attrNames users)));
}
