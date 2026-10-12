# Phase 0: Design Decisions

I planned the network and naming before building anything, so every address and name in the lab has a reason behind it.

## The scenario

The lab represents **Harbor Logistics**, a small fictional company with three departments: IT, HR, and Finance. Every configuration choice answers the question "what would this company need?"

## Network plan

| Item | Value | Reasoning |
| --- | --- | --- |
| Domain name | corp.harborlogistics.internal | ICANN reserved the .internal top-level domain for private networks in 2024. The older habit of using .local conflicts with multicast DNS (mDNS), which Apple devices and some Linux systems use. |
| Internal subnet | 172.16.0.0/24 | A private (RFC 1918) range with 254 usable addresses, far more than the lab needs. |
| DC01 address | 172.16.0.1, static | Every client uses the domain controller for logins and DNS, so its address can never change. |
| DC01 default gateway | None on CORP-LAN | DC01 already reaches the internet through its NAT adapter. A second gateway makes Windows choose between two routes and causes hard-to-diagnose failures. |
| DC01 DNS | 127.0.0.1 | DC01 will be the DNS server for the domain, so it queries itself. |
| DHCP scope | 172.16.0.100 to 172.16.0.200 | Clients get addresses automatically; low addresses stay reserved for servers. |

## Naming conventions

| Type | Pattern | Example |
| --- | --- | --- |
| Domain controllers | DC + number | DC01 |
| Workstations | WS + number | WS01, WS02 |
| Network adapters | By purpose | INTERNET, CORP-LAN |
| VM snapshots | Machine, state, stage | DC01 clean - pre-AD |

Names that describe role and number tell an administrator what a machine does at a glance. Random names like WIN-439M4GGA92S tell them nothing.

## Why two network adapters on the DC

Workstations in a real office don't connect straight to the internet; their traffic passes through infrastructure IT controls, where it can be managed, filtered, and logged. DC01 plays that role here. Keeping CORP-LAN internal-only also means nothing I break in the lab can affect my home network.
