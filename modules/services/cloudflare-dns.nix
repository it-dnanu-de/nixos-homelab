# Cloudflare DNS — declarative zone management.
# Runs on activation: ensures every §4.4 DNS record exists via CF API.
# Static records (MX, SPF, DMARC, nanulab.de) are idempotent.
# DKIM is post-install (key changes per install).
{ config, pkgs, settings, ... }:
let
  cfToken = config.sops.secrets.cloudflare_api_token.path;

  dnsScript = pkgs.writeShellScriptBin "cloudflare-dns-sync" ''
    set -euo pipefail
    TOKEN="$(${pkgs.coreutils}/bin/cat $CREDENTIALS_DIRECTORY/cloudflare_api_token)"
    API="https://api.cloudflare.com/client/v4/zones"
    # --fail exits non-zero on HTTP 4xx/5xx so set -e catches API failures.
    # -sS keeps stderr visible (errors land in the journal — audit Finding 3).
    CURL() { ${pkgs.curl}/bin/curl -sS --fail -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

    Z_DNANU=$(CURL "$API?name=${settings.domains.public}" | ${pkgs.jq}/bin/jq -r '.result[0].id')
    Z_NANULAB=$(CURL "$API?name=${settings.domains.internal}" | ${pkgs.jq}/bin/jq -r '.result[0].id')

    upsert() {
      local zone=$1 type=$2 name=$3 content=$4 proxied=$5 ttl=$6
      local priority=""
      if [ $# -ge 7 ]; then priority="$7"; fi
      local response=$(CURL "$API/$zone/dns_records?type=$type&name=$name")
      local existing=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.result | length')
      # MX records require a `priority` field; build it into the body when given.
      local prio_json=""
      [ -n "$priority" ] && prio_json=",\"priority\":$priority"
      if [ "$existing" -gt 0 ]; then
        # Idempotent: skip when the first record already matches (content + proxied).
        local first_id=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.result[0].id')
        local cur_content=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.result[0].content // empty')
        local cur_proxied=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.result[0].proxied // false')
        if [ "$cur_content" = "$content" ] && [ "$cur_proxied" = "$proxied" ]; then
          echo "  up to date: $type $name -> $content"
        else
          # PATCH first match (content + proxied only; proxied records use TTL auto).
          CURL -X PATCH "$API/$zone/dns_records/$first_id" \
            -d "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"proxied\":$proxied$prio_json}" \
            > /dev/null
          echo "  updated: $type $name -> $content"
        fi
        if [ "$existing" -gt 1 ]; then
          echo "$response" | ${pkgs.jq}/bin/jq -r '.result[1:][].id // empty' | while read -r id; do
            [ -n "$id" ] || continue
            CURL -X DELETE "$API/$zone/dns_records/$id" > /dev/null || true
          done
        fi
      else
        CURL -X POST "$API/$zone/dns_records" \
          -d "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"proxied\":$proxied,\"ttl\":$ttl$prio_json}" \
          > /dev/null
        echo "  created: $type $name -> $content"
      fi
    }

    # Remove a record if present (idempotent) — used for records that must NOT exist publicly.
    # Tolerant: no-op (not an error) when no matching record exists.
    deleteRecord() {
      local zone=$1 type=$2 name=$3
      CURL "$API/$zone/dns_records?type=$type&name=$name" \
        | ${pkgs.jq}/bin/jq -r '.result[].id // empty' \
        | while read -r id; do
            [ -n "$id" ] || continue
            CURL -X DELETE "$API/$zone/dns_records/$id" > /dev/null || true
          done
      true
    }

    PUBLIC_IP4=$(${pkgs.curl}/bin/curl -sS --fail --interface ${settings.network.interface} https://api.ipify.org 2>/dev/null || echo "0.0.0.0")
    if [ "$PUBLIC_IP4" != "0.0.0.0" ]; then
      # dnanu.de / www / autoconfig / profile / mta-sts are served via the
      # cloudflared tunnel → they MUST be CNAMEs to the tunnel (proxied), NOT
      # A records. An A record on a tunnel-hosted name makes Cloudflare's edge
      # try to reach your origin IP directly and return 522.
      # (mail/vpn are grey-cloud A/AAAA records — handled below.)
      deleteRecord "$Z_DNANU" A "${settings.domains.public}"
      deleteRecord "$Z_DNANU" A "www.${settings.domains.public}"
      deleteRecord "$Z_DNANU" A "autoconfig.${settings.domains.public}"
      deleteRecord "$Z_DNANU" AAAA "${settings.domains.public}"
      deleteRecord "$Z_DNANU" AAAA "www.${settings.domains.public}"
      upsert "$Z_DNANU" CNAME "${settings.domains.public}" \
        "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
      upsert "$Z_DNANU" CNAME "www.${settings.domains.public}" \
        "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
      upsert "$Z_DNANU" CNAME "autoconfig.${settings.domains.public}" \
        "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
      upsert "$Z_DNANU" A "${settings.domains.vpn}" "$PUBLIC_IP4" false 120
      # profile.dnanu.de — CNAME to tunnel, proxied (cloudflared ingress §3.6)
      deleteRecord "$Z_DNANU" A "profile.${settings.domains.public}"
      upsert "$Z_DNANU" CNAME "profile.${settings.domains.public}" \
        "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
      # auth.dnanu.de — ZITADEL issuer, CNAME to tunnel (must not bypass nginx TLS)
      deleteRecord "$Z_DNANU" A "auth.${settings.domains.public}"
      upsert "$Z_DNANU" CNAME "auth.${settings.domains.public}" \
        "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1
    fi

    upsert "$Z_DNANU" MX "${settings.domains.public}" "${settings.domains.mail}" false 120 10
    upsert "$Z_DNANU" TXT "${settings.domains.public}" "v=spf1 -all" false 120
    upsert "$Z_DNANU" TXT "_dmarc.${settings.domains.public}" \
      "v=DMARC1; p=quarantine; pct=100; adkim=r; aspf=r; rua=mailto:${settings.email.admin}" false 120

    # MTA-STS (RFC 8461) — policy id = date of last policy change; bump when policy changes
    upsert "$Z_DNANU" TXT "_mta-sts.${settings.domains.public}" \
      "v=STSv1; id=20260806T000000" false 120
    # TLS-RPT (RFC 8460) — receive TLS failure reports at admin@
    upsert "$Z_DNANU" TXT "_smtp._tls.${settings.domains.public}" \
      "v=TLSRPTv1; rua=mailto:${settings.email.admin}" false 120
    # MTA-STS policy host — CNAME to the tunnel (proxied; CF edge cert covers *.dnanu.de)
    upsert "$Z_DNANU" CNAME "mta-sts.${settings.domains.public}" \
      "${settings.cloudflare.tunnelId}.cfargotunnel.com" true 1

    # nanulab.de services are VPN-only (nginx source allowlist); AdGuard
    # rewrites them locally to 10.0.0.2. Public records must NOT exist (leaks
    # internal naming, resolves to nothing reachable). Delete A + AAAA if present.
    deleteRecord "$Z_NANULAB" A "*.${settings.domains.internal}"
    deleteRecord "$Z_NANULAB" A "${settings.domains.internal}"
    deleteRecord "$Z_NANULAB" AAAA "*.${settings.domains.internal}"
    deleteRecord "$Z_NANULAB" AAAA "${settings.domains.internal}"
    upsert "$Z_NANULAB" MX "${settings.domains.internal}" "${settings.domains.mail}" false 120 10
  '';
in
{
  systemd.services.cloudflare-dkim-sync = {
    description = "Cloudflare DKIM TXT record sync";
    # rspamd.service generates the keypair in ExecStartPre — order after it.
    after = [ "rspamd.service" "network-online.target" "nss-lookup.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ curl jq coreutils gnugrep ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";   # survives boot-time DNS races
      RestartSec = "30s";
      StartLimitBurst = 5;
      LoadCredential = "cloudflare_api_token:${cfToken}";
    };
    script = ''
      set -euo pipefail
      DKIM_FILE="/var/dkim/${settings.domains.public}.mail.txt"
      [ -f "$DKIM_FILE" ] || { echo "no dkim key yet"; exit 0; }
      # Extract all quoted fragments and join them (format-agnostic — no paren parsing)
      VALUE=$(grep -o '"[^"]*"' "$DKIM_FILE" | tr -d '"\n')
      [ -n "$VALUE" ] || { echo "dkim parse failed"; exit 1; }
      TOKEN="$(cat "$CREDENTIALS_DIRECTORY/cloudflare_api_token")"
      API="https://api.cloudflare.com/client/v4/zones"
      CURL() { curl -sS --fail --retry 8 --retry-delay 5 --retry-all-errors --connect-timeout 10 \
                 -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }
      ZONE=$(CURL "$API?name=${settings.domains.public}" | jq -r '.result[0].id')
      REC=$(CURL "$API/$ZONE/dns_records?type=TXT&name=mail._domainkey.${settings.domains.public}")
      ID=$(echo "$REC" | jq -r '.result[0].id // empty')
      CUR=$(echo "$REC" | jq -r '.result[0].content // empty')
      if [ "$CUR" = "$VALUE" ]; then echo "DKIM up to date"; exit 0; fi
      BODY=$(jq -nc --arg c "$VALUE" '{type:"TXT",name:"mail._domainkey",content:$c,ttl:120}')
      if [ -n "$ID" ]; then
        CURL -X PATCH "$API/$ZONE/dns_records/$ID" -d "$BODY" > /dev/null  # in-place, no gap
        echo "DKIM updated"
      else
        CURL -X POST "$API/$ZONE/dns_records" -d "$BODY" > /dev/null
        echo "DKIM created"
      fi
    '';
  };


  systemd.services.cloudflare-dns-sync = {
    description = "Declarative Cloudflare DNS";
    wantedBy = [ "multi-user.target" ];
    # sops-nix must materialize /run/secrets/cloudflare_api_token before this runs
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${dnsScript}/bin/cloudflare-dns-sync";
      LoadCredential = "cloudflare_api_token:${cfToken}";
      RemainAfterExit = true;
      # --fail + set -e means HTTP errors are caught;
      # Restart=on-failure ensures convergence after transient API outages.
      Restart = "on-failure";
      RestartSec = "60s";
      StartLimitBurst = 5;
    };
  };

  # Daily convergence timer — catches manual dashboard drift (Finding 3).
  systemd.timers.cloudflare-dns-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; RandomizedDelaySec = "1h"; };
  };

  # DANE TLSA (3 1 1 SPKI SHA-256) — auto-synced from the ACME cert.
  # Triggers: ACME postRun (on renewal), daily timer, boot.
  # Gap: TTL 120s, DANE-enforcing senders tempfail+retry.
  # Zone-unsigned until DS lands at DENIC → TLSA ignored, safe to publish now.
  systemd.services.cloudflare-tlsa-sync = {
    description = "Cloudflare TLSA (DANE) record sync for ${settings.domains.mail}";
    after = [ "network-online.target" "nss-lookup.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ curl jq coreutils openssl ];
    # Failures after DS-lands-at-DENIC mean hard delivery failures from
    # DANE-enforcing senders — wire a Resend-based alert (Finding 7).
    onFailure = [ "cloudflare-tlsa-alert.service" ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "60s";
      StartLimitBurst = 5;
      LoadCredential = "cloudflare_api_token:${cfToken}";
    };
    script = ''
      set -euo pipefail
      CERT="/var/lib/acme/${settings.domains.mail}/cert.pem"
      [ -f "$CERT" ] || { echo "no cert yet"; exit 0; }
      HASH=$(openssl x509 -in "$CERT" -pubkey -noout \
             | openssl pkey -pubin -outform DER \
             | openssl dgst -sha256 -r | cut -d' ' -f1)
      # Cloudflare's TLSA records use a nested `data` object
      # (usage/selector/matching_type/certificate). A freeform "3 1 1 <hash>"
      # content string, or top-level usage/selector fields, both return 400
      # "usage is a required data field".
      CONTENT="3 1 1 $HASH"
      NAME="_25._tcp.${settings.domains.mail}"
      TOKEN="$(cat "$CREDENTIALS_DIRECTORY/cloudflare_api_token")"
      API="https://api.cloudflare.com/client/v4/zones"
      CURL() { curl -sS --fail --retry 8 --retry-delay 5 --retry-all-errors --connect-timeout 10 \
                 -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }
      ZONE=$(CURL "$API?name=${settings.domains.public}" | jq -r '.result[0].id')
      REC=$(CURL "$API/$ZONE/dns_records?type=TLSA&name=$NAME")
      ID=$(echo "$REC" | jq -r '.result[0].id // empty')
      # Compare via the structured certificate field (survives field ordering).
      CUR_CERT=$(echo "$REC" | jq -r '.result[0].data.certificate // empty' 2>/dev/null)
      if [ "$CUR_CERT" = "$HASH" ]; then echo "TLSA up to date"; exit 0; fi
      # TLSA for DANE-EE / SPKI / SHA-256 = usage 3, selector 1, matching_type 1.
      BODY=$(jq -nc --arg n "$NAME" --arg c "$HASH" \
        '{type:"TLSA",name:$n,data:{usage:3,selector:1,matching_type:1,certificate:$c},ttl:120}')
      if [ -n "$ID" ]; then
        CURL -X PATCH "$API/$ZONE/dns_records/$ID" -d "$BODY" > /dev/null
        echo "TLSA updated: $CONTENT"
      else
        CURL -X POST "$API/$ZONE/dns_records" -d "$BODY" > /dev/null
        echo "TLSA created: $CONTENT"
      fi
    '';
  };

  systemd.timers.cloudflare-tlsa-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; RandomizedDelaySec = "1h"; };
  };

  # TLSA-sync failure alert (Finding 7) — fires via OnFailure= on
  # cloudflare-tlsa-sync.  Sends a one-line email via Resend HTTPS API
  # (same channel as mail-queue-watch, zero marginal cost).
  # Critical after DS records land at DENIC: a stale TLSA means
  # DANE-enforcing senders see hard delivery failures.
  systemd.services.cloudflare-tlsa-alert = {
    description = "TLSA sync failure alert (Resend API)";
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = "resend_api_key:${config.sops.secrets.resend_api_key.path}";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
    path = with pkgs; [ curl jq inetutils ];
    script = ''
      set -euo pipefail
      # Rate-limit: at most one alert per 6h (same pattern as mail-queue-watch).
      # A crash-looping sync must not page every few minutes.
      STATE=/var/lib/tlsa-alert/last-sent
      NOW=$(date +%s)
      if [ -f "$STATE" ]; then
        LAST=$(cat "$STATE")
        if [ $(( NOW - LAST )) -lt 21600 ]; then
          echo "alert rate-limited (last sent $(( NOW - LAST ))s ago)"
          exit 0
        fi
      fi
      body="cloudflare-tlsa-sync FAILED on $(hostname) — check journal for details."
      curl -sS --fail -X POST "https://api.resend.com/emails" \
        -H "Authorization: Bearer $(cat "$CREDENTIALS_DIRECTORY/resend_api_key")" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc --arg b "$body" '{from:"alert@dnanu.de",to:["hey@dnanu.de"],subject:"[homelab] TLSA sync failure",text:$b}')" \
        > /dev/null
      mkdir -p /var/lib/tlsa-alert
      echo "$NOW" > "$STATE"
      echo "TLSA-failure alert sent"
    '';
  };

  environment.systemPackages = [ pkgs.jq ];
}
