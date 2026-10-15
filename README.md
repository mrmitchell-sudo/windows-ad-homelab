# Windows Server Active Directory Home Lab

A virtualized Active Directory environment built and run like the IT department of a small fictional company, **Harbor Logistics**. The lab covers domain services, networking, Group Policy, PowerShell automation, help desk scenarios, and security monitoring, and documents the reasoning and troubleshooting behind each step.

**Status:** Phase 4 complete. Harbor Logistics has department OUs, users created in bulk with PowerShell, a group-based department share, Group Policy for passwords, drives and workstation security, and four help desk tickets worked end to end. Phase 5 (security monitoring) is next.

## Network

```mermaid
flowchart LR
    NET((Internet)) --- HOST["Laptop (host)<br/>VirtualBox NAT"]
    HOST ---|"INTERNET adapter<br/>10.0.2.15 (DHCP)"| DC01["DC01<br/>Windows Server 2025<br/>172.16.0.1"]
    DC01 ---|"CORP-LAN<br/>172.16.0.0/24"| WS01["WS01<br/>Windows 11 Enterprise<br/>172.16.0.100 (DHCP)"]
```

DC01 has two network adapters. One reaches the internet through VirtualBox NAT; the other sits on an internal network that only the lab VMs can see. Workstations connect only to the internal network, so all their traffic goes through infrastructure the "company" controls.

## Environment

| Component | Detail |
| --- | --- |
| Hypervisor | Oracle VirtualBox |
| Domain controller | DC01, Windows Server 2025 Standard Evaluation (Desktop Experience), 2 vCPU, 4 GB RAM, 60 GB disk |
| Internal network | CORP-LAN, 172.16.0.0/24 |
| Domain | corp.harborlogistics.internal |
| Workstation | WS01, Windows 11 Enterprise Evaluation, 2 vCPU, 4 GB RAM, 64 GB disk, CORP-LAN only |

## Phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Planning and design | Done ([design decisions](docs/00-design.md)) |
| 1 | Build the domain controller VM | Done ([write-up](docs/01-dc-build.md)) |
| 2 | AD DS, DNS, DHCP, NAT routing | Done ([write-up](docs/02-ad-dns-dhcp.md)) |
| 3 | Join a Windows 11 client to the domain | Done ([write-up](docs/03-client-domain-join.md)) |
| 4 | OUs, users, groups, GPOs, file shares, PowerShell automation, mock help desk tickets | Done ([write-up](docs/04-users-groups-gpo.md), [tickets](tickets/)) |
| 5 | Audit logging, Sysmon, SIEM, simulated attacks and detections | Next |

## Skills

Windows Server 2025 · Windows 11 Enterprise · Active Directory Domain Services · Domain join and user onboarding · DNS (zones, forwarders, multi-homed DC registration) · DHCP (scopes, options, AD authorization) · RRAS / NAT routing · TCP/IP addressing · VirtualBox · OU design · Group Policy (security settings, drive maps, gpresult) · AGDLP and NTFS/share permissions · Access-Based Enumeration · PowerShell automation · Password and lockout policy · Least privilege · Windows event logs · Help desk triage · Troubleshooting and documentation

## Highlights

- Worked four help desk tickets end to end, including checking event 4740 for the source of a lockout before unlocking, and finding that a mapped drive survived after a user left the OU, which I fixed so the mapping is removed automatically ([tickets](tickets/)).
- Wrote PowerShell scripts that create users from a CSV and build a department share with AGDLP group nesting, both safe to re-run and with no passwords stored ([scripts](scripts/)).
- Isolated a client-side DNS and internet failure to swapped RRAS NAT interface roles by ruling out the firewall, DNS service and network profiles one at a time ([details](docs/03-client-domain-join.md#4-troubleshooting-dns-and-internet-failed-from-the-client)).
- Found and fixed a multi-homed domain controller registering its NAT address in DNS, which would have caused intermittent client logins and domain-join failures ([details](docs/02-ad-dns-dhcp.md#4-fix-dns-the-domain-controller-registered-its-nat-address)).
- Isolated an internet DNS failure to a host VPN and stale inherited forwarders by testing one variable at a time ([details](docs/02-ad-dns-dhcp.md#5-fix-dns-internet-names-resolved-to-the-wrong-address)).

## Repository layout

```
docs/      one write-up per phase
images/    screenshots, prefixed by phase number
scripts/   PowerShell scripts (domain promotion, bulk users, department shares)
tickets/   mock help desk tickets and resolutions
```
