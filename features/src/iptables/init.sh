#!/bin/bash

set -eux

sleep 5 #! wait for iptables to fill up (e.g., dockerd)

ALLOW_DOMAINS="${ALLOW_DOMAINS-}"
ALLOW_CIDR="${ALLOW_CIDR-}"

HOOKS=(
  "INPUT DEVCON-IN"
  "OUTPUT DEVCON-OUT"
  "FORWARD DEVCON-FWD"
)

for hook in "${HOOKS[@]}"; do
  read -r base target <<<"$hook"
  iptables -w -t filter -N "$target" 2>/dev/null || true
  iptables -w -t filter -D "$base" -j "$target" 2>/dev/null || true
  iptables -w -t filter -F "$target" 2>/dev/null
  iptables -w -t filter -I "$base" 1 -j "$target"
done

ipset create devcon hash:net -exist
ipset flush devcon

tr ',' '\n' <<<"$ALLOW_DOMAINS" | while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue
  if [[ "$domain" == "github.com" ]]; then
    curl --proto "=https" --tlsv1.2 -fsSL https://api.github.com/meta |
      jq -r '(.web + .api + .git)[]' |
      aggregate -q |
      while read -r cidr; do ipset add devcon "$cidr" -exist; done
  else
    getent ahostsv4 "$domain" |
      awk -vmask=/32 '{print $1 mask}' |
      while read -r ip; do ipset add devcon "$ip" -exist; done
  fi
done

tr ',' '\n' <<<"$ALLOW_CIDR" | while IFS= read -r cidr; do
  [[ -z "$cidr" ]] && continue
  ipset add devcon "$cidr" -exist
done

HOST_DEV="$(ip -4 route show default | awk '{print $5; exit}')"
HOST_CIDR="$(ip -4 route show dev "$HOST_DEV" scope link | awk 'NR==1{print $1; exit}')"

mapfile -t BRIDGES < <(
  ip -o link show type bridge |
    awk -F': ' '{print $2}' | awk '{print $1}' |
    while read -r dev; do
      ip -4 route show dev "$dev" scope link |
        awk -v dev="$dev" '{print dev, $1}'
    done
)

#? INPUT
iptables -w -t filter -A DEVCON-IN -i lo -j RETURN                          # h->h
iptables -w -t filter -A DEVCON-IN -i "$HOST_DEV" -s "$HOST_CIDR" -j RETURN # p->h
for bridge in "${BRIDGES[@]}"; do
  read -r dev cidr <<<"$bridge"
  iptables -w -t filter -A DEVCON-IN -i "$dev" -s "$cidr" -j RETURN # g->h
done
iptables -w -t filter -A DEVCON-IN -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN # h->* => h<-*
iptables -w -t filter -A DEVCON-IN -p tcp -j REJECT --reject-with tcp-reset             # ⓧ
iptables -w -t filter -A DEVCON-IN -p udp -j REJECT --reject-with icmp-admin-prohibited # ⓧ

#? FORWARD
iptables -w -t filter -A DEVCON-FWD -p tcp --dport 53 -j RETURN # g->*:53[tcp]
iptables -w -t filter -A DEVCON-FWD -p udp --dport 53 -j RETURN # g->*:53[udp]
for bridge in "${BRIDGES[@]}"; do
  read -r dev cidr <<<"$bridge"
  iptables -w -t filter -A DEVCON-FWD -i "$HOST_DEV" -s "$HOST_CIDR" -o "$dev" -d "$cidr" -j RETURN # p->g
  iptables -w -t filter -A DEVCON-FWD -i "$dev" -s "$cidr" -o "$HOST_DEV" -d "$HOST_CIDR" -j RETURN # g->p
  iptables -w -t filter -A DEVCON-FWD -i "$dev" -s "$cidr" -o "$dev" -d "$cidr" -j RETURN           # g->g (same bridge)
  iptables -w -t filter -A DEVCON-FWD -i "$dev" -m set --match-set devcon dst -j RETURN             # g->x
done
iptables -w -t filter -A DEVCON-FWD -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN # g->* <=> g<-*
iptables -w -t filter -A DEVCON-FWD -p tcp -j REJECT --reject-with tcp-reset             # ⓧ
iptables -w -t filter -A DEVCON-FWD -p udp -j REJECT --reject-with icmp-admin-prohibited # ⓧ

#? OUTPUT
iptables -w -t filter -A DEVCON-OUT -o lo -j RETURN                          # h->h
iptables -w -t filter -A DEVCON-OUT -p tcp --dport 53 -j RETURN              # h->*:53[tcp]
iptables -w -t filter -A DEVCON-OUT -p udp --dport 53 -j RETURN              # h->*:53[udp]
iptables -w -t filter -A DEVCON-OUT -o "$HOST_DEV" -d "$HOST_CIDR" -j RETURN # h->p
for bridge in "${BRIDGES[@]}"; do
  read -r dev cidr <<<"$bridge"
  iptables -w -t filter -A DEVCON-OUT -o "$dev" -d "$cidr" -j RETURN # h->g
done
iptables -w -t filter -A DEVCON-OUT -m set --match-set devcon dst -j RETURN              # h->x
iptables -w -t filter -A DEVCON-OUT -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN # h<-* => h->*
iptables -w -t filter -A DEVCON-OUT -p tcp -j REJECT --reject-with tcp-reset             # ⓧ
iptables -w -t filter -A DEVCON-OUT -p udp -j REJECT --reject-with icmp-admin-prohibited # ⓧ
