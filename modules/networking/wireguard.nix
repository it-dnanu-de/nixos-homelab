# WireGuard — declarative remote-access VPN (OpenCode.md §3.3, amended 2026-08-06).
# Replaces Tailscale SaaS. Kernel WireGuard, fully declarative peers,
# split-tunnel only (no exit node/NAT). One silent UDP port 51820.
#
# v4 (2026-08-06): 97 peers (7 admin admin3-9-vpn + 90 user), full pre-provision
# with real keypairs. v5: 10.0.80.0/24 subnet, server 10.0.80.2 (2026-08-08).
# Peers derived from users.nix helpers (wgPeers/wgPeerNames).
# Public keys in generated wireguard-pubkeys.nix.
# Per-user QR renderer writes /var/lib/mobileprofile/wg/<idpUsername>/.
# Served behind oauth2-proxy + ZITADEL at profile.dnanu.de/<idpUsername>/.
{
  config,
  lib,
  pkgs,
  settings,
  users,
  ...
}:
let
  inherit (lib) concatMap concatMapStringsSep groupBy mapAttrsToList nameValuePair;

  wgSettings = settings.network.wireguard;

  # Derive peers from users.nix: 97 WG peers (7 admin admin3-9 + 90 user).
  # Public keys from the generated wireguard-pubkeys.nix (imported in settings.nix).
  # Strict lookup — no fallback: a missing public key is an authoring bug that
  # must fail at eval time rather than silently produce a broken WireGuard peer.
  peers = map (p: p // {
    publicKey = wgSettings.peerPublicKeys.${p.hostname};
  }) users.wgPeers;

  # Group peers by user (e.g. { admin = [...]; dumitru = [...]; })
  peersByUser = groupBy (p: p.user) peers;

  # Build sops secret entries for every peer
  peerSecretAttrs = concatMap (p: [
    { name = "wireguard_peer_${p.name}_private"; value = { }; }
    { name = "wireguard_peer_${p.name}_psk"; value = { }; }
  ]) peers;

  # Bash fragment that renders one peer's .conf + .png. Called inside the
  # per-user loop. Sets MISSING if secrets are absent.
  renderPeerBlock = p: ''
    echo "    -> peer ${p.name} (${p.ip})" >&2
    priv="/run/secrets/wireguard_peer_${p.name}_private"
    psk="/run/secrets/wireguard_peer_${p.name}_psk"

    peer_missing=""
    [ ! -f "$priv" ] && peer_missing="$peer_missing wireguard_peer_${p.name}_private"
    [ ! -f "$psk" ]  && peer_missing="$peer_missing wireguard_peer_${p.name}_psk"

    if [ -n "$peer_missing" ]; then
      echo "      WARNING: skipping — missing secrets:$peer_missing" >&2
      MISSING="$MISSING ${p.name}"
      return
    fi

    conf="$user_out/${p.name}.conf"
    cat > "$conf" <<PEERCONF
[Interface]
PrivateKey = $(cat "$priv")
Address    = ${p.ip}/32
DNS        = 10.0.10.2  # AdGuard container (split-horizon)

[Peer]
PublicKey           = $SERVER_PUB
PresharedKey        = $(cat "$psk")
AllowedIPs          = 10.0.0.0/16  # server-routed P2P: all internal zones
Endpoint            = $ENDPOINT
PersistentKeepalive = 25
PEERCONF

    ${pkgs.qrencode}/bin/qrencode -t PNG -o "$user_out/${p.name}.png" < "$conf"
  '';

  # Generate per-user index.html — lists that user's peers only, with a tier note.
  tierNote = admin: if admin then "Admin tier — reaches all services including admin UIs"
                          else "User tier — reaches user-facing services (photos, vault, music, media, audio, books)";

  # Bash heredoc for a single user's index.html
  userIndexBlock = userName: userPeers: ''
    # ── index.html for ${userName} ──
    peer_html=""
    ${
      concatMapStringsSep "\n" (p: ''
        if [[ "$MISSING" != *"${p.name}"* ]]; then
          peer_html+="<tr><td>${p.name}</td><td><a href=\"${p.name}.conf\">${p.name}.conf</a></td><td><img src=\"${p.name}.png\" alt=\"QR for ${p.name}\" width=\"200\"></td></tr>"$'\n'
        else
          peer_html+="<tr><td>${p.name}</td><td colspan=\"2\" class=\"warn\">Config not available — secret keys missing</td></tr>"$'\n'
        fi
      '') (builtins.sort (a: b: a.name < b.name) userPeers)
    }

    tier="${tierNote (builtins.any (p: p.admin) userPeers)}"

    cat > "$user_out/index.html" <<INDEX
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>WireGuard — ${userName}</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 2rem; color: #222; }
  table { border-collapse: collapse; width: 100%; max-width: 800px; }
  th, td { padding: 0.75rem; border: 1px solid #ddd; text-align: left; }
  th { background: #f5f5f5; }
  img { max-width: 200px; height: auto; }
  a { color: #0366d6; }
  .warn { color: #cb2431; }
  .tier { font-size: 0.9rem; color: #666; margin-bottom: 1rem; }
  .logout { display: inline-block; margin-top: 1.5rem; font-size: 0.9rem; color: #666; }
  details { max-width: 800px; margin-top: 1.5rem; }
  details summary { cursor: pointer; font-weight: 600; }
  details ol { padding-left: 1.25rem; }
</style>
</head>
<body>
<h1>WireGuard — ${userName}</h1>
<p class="tier">$tier</p>
<table>
<tr><th>Device</th><th>Config</th><th>QR Code</th></tr>
${"\${peer_html}"}
</table>
<p><em>Scan QR in the WireGuard app → tap "Allow" → enable On-Demand (Wi‑Fi + Cellular).</em></p>
<details>
<summary>Setup guide — iOS / Android / PC</summary>
<ol>
  <li><strong>iOS:</strong> install WireGuard from the App Store → tap + → Create from QR code → scan the QR for this device → Allow → in the tunnel settings enable On-Demand for Wi‑Fi and Cellular.</li>
  <li><strong>Android:</strong> install WireGuard from Play Store / F-Droid → + → Scan from QR code → name the tunnel → toggle it on. Optional: use the tile in Quick Settings.</li>
  <li><strong>PC (Windows / macOS / Linux):</strong> install WireGuard → Add Tunnel → add from file → pick the <code>.conf</code> for this device → Activate. Split-tunnel is already set (only 10.0.0.0/16 goes through the VPN).</li>
</ol>
<p>Mail, calendar, contacts, and files are configured in the Nextcloud app (or native Mail / CalDAV / CardDAV / Files) — there is no .mobileconfig.</p>
</details>
<p class="logout"><a href="/logout">Sign out</a></p>
</body>
</html>
INDEX
  '';
in
{
  # ── sops secrets for server key + every peer ──────────────────────────
  sops.secrets = builtins.listToAttrs peerSecretAttrs // {
    wireguard_server_private = {
      restartUnits = [ "wireguard-wg0.service" ];
    };
  };

  # ── IP forwarding so peers can reach other LAN hosts ──────────────────
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # ── WireGuard interface ───────────────────────────────────────────────
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${wgSettings.address}/24" ];  # address from settings (10.0.80.2)
    listenPort = wgSettings.port;
    privateKeyFile = config.sops.secrets.wireguard_server_private.path;
    peers = map (p: {
      publicKey = p.publicKey;
      presharedKeyFile = config.sops.secrets."wireguard_peer_${p.name}_psk".path;
      allowedIPs = [ "${p.ip}/32" ];
      persistentKeepalive = 25;
    }) peers;
  };

  # ── Per-user profile renderer: .conf + QR PNG + index.html ────────────
  # v3: groups peers by user, writes per-user dirs under /var/lib/mobileprofile/wg/<user>/.
  # Each user sees only their own peers. Old shared /wg/index.html is removed.
  systemd.services.wireguard-profile-render = {
    description = "Render WireGuard peer configs and QR codes (per-user)";
    after = [ "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.wireguard-tools pkgs.qrencode pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      BASE=/var/lib/mobileprofile/wg
      echo "wireguard-profile-render: starting (per-user)" >&2

      # Fully regenerate the tree every boot. Drops stale short-name dirs
      # (pre-idpUsername) so admin cannot be served leftover paths.
      rm -rf "$BASE"
      mkdir -p "$BASE"

      # Derive server public key from the sops-decrypted private key
      SERVER_PRIV=/run/secrets/wireguard_server_private
      if [ ! -f "$SERVER_PRIV" ]; then
        echo "FATAL: wireguard_server_private not found — is sops-nix.service running?" >&2
        exit 1
      fi
      SERVER_PUB=$(wg pubkey < "$SERVER_PRIV")
      ENDPOINT="${wgSettings.endpoint}:${toString wgSettings.port}"

      # ── Per-user loop ──
    '' + concatMapStringsSep "\n" ({ name, value }: let userName = name; userPeers = value; in ''
      # ── User: ${userName} ──
      echo "  user ${userName} (${toString (builtins.length userPeers)} peer(s))" >&2
      user_out="$BASE/${users.idpUsername userName}"
      rm -rf "$user_out"
      mkdir -p "$user_out"

      MISSING=""
      ${concatMapStringsSep "\n  " renderPeerBlock (builtins.sort (a: b: a.name < b.name) userPeers)}

      ${userIndexBlock userName userPeers}

      if [ -n "$MISSING" ]; then
        cat >> "$user_out/index.html" <<MISSINGWARN
    <p class="warn"><strong>WARNING:</strong> Some peers skipped — secret keys not yet populated (placeholders in sops). Missing:$MISSING</p>
    MISSINGWARN
      fi
    '') (mapAttrsToList nameValuePair peersByUser) + ''

      # Secure output: root:nginx, 750 per-user dir, 640 files
      chown -R root:${config.users.groups.nginx.name} "$BASE"
      find "$BASE" -type d -exec chmod 750 {} \;
      find "$BASE" -type f -exec chmod 640 {} \;

      echo "wireguard-profile-render: done ($(find "$BASE" -name '*.conf' | wc -l) peers rendered)" >&2
    '';
  };
}
