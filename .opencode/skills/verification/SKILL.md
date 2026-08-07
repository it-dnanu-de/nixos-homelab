---
name: verification
description: Use after any install or rebuild to confirm the system actually works — the §13 checklist. Also use when a change touches DNS, mail, TLS, or networking to prove it didn't break.
---

# Verification Suite (OpenCode.md §13)

Run after install or any network/mail/storage-affecting change. Report PASS / FAIL / SKIPPED with evidence.

## Connectivity & storage
```
zpool status                                  # pools healthy
dig @10.0.0.2 mail.dnanu.de                   # split-horizon: -> 10.0.0.2
dig mail.dnanu.de @1.1.1.1                    # public: -> home IP (grey cloud)
dig @10.0.0.2 *.nanulab.de                    # AdGuard rewrite -> 10.0.0.2
```

## Mail
```
swaks --to hey@dnanu.de --server <home-ip>    # inbound port 25 from outside
# send from iOS -> check Resend dashboard     # outbound relay works
# verify SPF/DKIM/DMARC records + DNSSEC for dnanu.de and nanulab.de
```

## Services (over VPN / LAN — *.nanulab.de is split-horizon)
```
curl -kI https://cloud.nanulab.de
curl -kI https://vault.nanulab.de
curl -kI https://photos.nanulab.de
# each *.nanulab.de service returns 200/3xx; guest IP -> 403; dead names -> 404
```

## Security
```
# qBittorrent IP-leak test (must show AirVPN exit IP, not the home IP)
restic check                                  # backup integrity
systemctl --failed                            # must be empty
# lid-close test on Dell (must NOT suspend)
```

## DNSSEC
`dig +dnssec +adflag dnanu.de @9.9.9.9` (AD bit set), `delv dnanu.de`, and the same for `nanulab.de`.
