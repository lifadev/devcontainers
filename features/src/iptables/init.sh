#!/bin/bash

set -eux

iptables-restore <<EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF

NET_DEV="$(ip -4 route show default | awk '{print $5; exit}')"
HOST="$(ip -4 route show dev "$NET_DEV" scope link | awk 'NR==1{print $1; exit}')"

ipset create allowlist hash:net -exist
ipset flush allowlist

tr ',' '\n' <<<"$DOMAIN_ALLOWLIST" | while IFS= read -r domain; do
  if [[ "$domain" == "github.com" ]]; then
    curl --proto "=https" --tlsv1.2 -fsSL https://api.github.com/meta |
      jq -r '(.web + .api + .git)[]' |
      aggregate -q |
      while read -r cidr; do ipset add allowlist "$cidr" -exist; done
  fi
  getent ahostsv4 "$domain" |
    awk -vmask=/32 '{print $1 mask}' |
    aggregate -q |
    while read -r ip; do ipset add allowlist "$ip" -exist; done
done

iptables-restore <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT  -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -p udp --dport 53 -j ACCEPT
-A INPUT  -p udp --sport 53 -j ACCEPT
-A OUTPUT -p tcp --dport 22 -j ACCEPT
-A INPUT  -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
-A INPUT  -s $HOST -j ACCEPT
-A OUTPUT -d $HOST -j ACCEPT
-A OUTPUT -m set --match-set allowlist dst -j ACCEPT
-A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
COMMIT
EOF
