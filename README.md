# Windows Server Active Directory Home Lab

A virtualized Active Directory environment built and run like the IT department of a small fictional company, **Harbor Logistics**. The lab covers domain services, networking, Group Policy, PowerShell automation, help desk scenarios, and security monitoring, and documents the reasoning and troubleshooting behind each step.

**Status:** Phase 1 complete (domain controller VM built). Phase 2 (Active Directory, DNS, DHCP) in progress.

## Network

```mermaid
flowchart LR
    NET((Internet)) --- HOST["Laptop (host)<br/>VirtualBox NAT"]
    HOST ---|"INTERNET adapter<br/>10.0.2.15 (DHCP)"| DC01["DC01<br/>Windows Server 2025<br/>172.16.0.1"]
    DC01 ---|"CORP-LAN<br/>172.16.0.0/24"| WS01["WS01<br/>Windows 11 (planned)"]
```

DC01 has two network adapters. One reaches the internet through VirtualBox NAT; the other sits on an internal network that only the lab VMs can see. Workstations connect only to the internal network, so all their traffic goes through infrastructure the "company" controls.

## Environment

| Component | Detail |
| --- | --- |
| Hypervisor | Oracle VirtualBox |
| Domain controller | DC01, Windows Server 2025 Standard Evaluation (Desktop Experience), 2 vCPU, 4 GB RAM, 60 GB disk |
| Internal network | CORP-LAN, 172.16.0.0/24 |
| Domain | corp.harborlogistics.internal |
| Clients | Windows 11 Enterprise (Phase 3) |

## Phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Planning and design | Done ([design decisions](docs/00-design.md)) |
| 1 | Build the domain controller VM | Done ([write-up](docs/01-dc-build.md)) |
| 2 | AD DS, DNS, DHCP, NAT routing | In progress |
| 3 | Join a Windows 11 client to the domain | Planned |
| 4 | OUs, users, groups, GPOs, file shares, PowerShell automation, mock help desk tickets | Planned |
| 5 | Audit logging, Sysmon, SIEM, simulated attacks and detections | Planned |

## Skills

Windows Server 2025 · Active Directory Domain Services · DNS · DHCP · TCP/IP addressing · VirtualBox · Group Policy · PowerShell · Troubleshooting and documentation

## Repository layout

```
docs/      one write-up per phase
images/    screenshots, prefixed by phase number
scripts/   PowerShell scripts (Phase 4)
tickets/   mock help desk tickets and resolutions (Phase 4)
```
