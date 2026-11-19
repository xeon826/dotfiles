#!/bin/bash
# IPv4-only network namespace for FreeTube (blocks YouTube's IPv6 address-based bans).
# FreeTubeApp/FreeTube#7906: YouTube rate-limits/bans IPv6 addresses for logged-out
# API clients; residential IPv4 is unaffected. Idempotent.
set -euo pipefail

NS=freetube4
VETH_HOST=veth-ft-host
VETH_NS=veth-ft
SUBNET_HOST=10.77.0.1
SUBNET_NS=10.77.0.2
IFACE=eno1

up() {
  if ! ip netns list | grep -q "^$NS "; then
    ip netns add "$NS"
  fi

  # Veth pair: create+move only when the namespace side doesn't exist yet
  if ! ip netns exec "$NS" ip link show "$VETH_NS" >/dev/null 2>&1; then
    if ip link show "$VETH_HOST" >/dev/null 2>&1; then
      ip link set "$VETH_NS" netns "$NS"
    else
      ip link add "$VETH_HOST" type veth peer name "$VETH_NS"
      ip link set "$VETH_NS" netns "$NS"
    fi
  fi

  ip addr replace "$SUBNET_HOST"/30 dev "$VETH_HOST"
  ip link set "$VETH_HOST" up
  ip netns exec "$NS" ip link set lo up
  ip netns exec "$NS" ip link set "$VETH_NS" up
  ip netns exec "$NS" ip addr replace "$SUBNET_NS"/30 dev "$VETH_NS"
  ip netns exec "$NS" ip route replace default via "$SUBNET_HOST"

  # Kill IPv6 inside the namespace
  ip netns exec "$NS" sysctl -q -w net.ipv6.conf.all.disable_ipv6=1
  ip netns exec "$NS" sysctl -q -w net.ipv6.conf.default.disable_ipv6=1
  ip netns exec "$NS" sysctl -q -w net.ipv6.conf.lo.disable_ipv6=1

  # NAT the namespace out through the LAN interface
  sysctl -q -w net.ipv4.ip_forward=1
  iptables -t nat -C POSTROUTING -s "$SUBNET_NS"/32 -o "$IFACE" -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s "$SUBNET_NS"/32 -o "$IFACE" -j MASQUERADE
  iptables -C FORWARD -i "$VETH_HOST" -o "$IFACE" -j ACCEPT 2>/dev/null || \
    iptables -I FORWARD 1 -i "$VETH_HOST" -o "$IFACE" -j ACCEPT
  iptables -C FORWARD -i "$IFACE" -o "$VETH_HOST" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
    iptables -I FORWARD 1 -i "$IFACE" -o "$VETH_HOST" -m state --state ESTABLISHED,RELATED -j ACCEPT

  echo "netns $NS ready"
}

down() {
  ip netns del "$NS" 2>/dev/null || true
  ip link del "$VETH_HOST" 2>/dev/null || true
  iptables -t nat -D POSTROUTING -s "$SUBNET_NS"/32 -o "$IFACE" -j MASQUERADE 2>/dev/null || true
  iptables -D FORWARD -i "$VETH_HOST" -o "$IFACE" -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -i "$IFACE" -o "$VETH_HOST" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
  echo "netns $NS removed"
}

case "${1:-up}" in
  up) up ;;
  down) down ;;
  *) echo "usage: $0 {up|down}"; exit 1 ;;
esac
