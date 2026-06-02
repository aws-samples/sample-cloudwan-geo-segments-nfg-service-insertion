# AWS Cloud WAN NFG Constraints — Lab-Validated Findings

## Overview

These constraints were discovered through lab testing of AWS Cloud WAN Network Function Groups (NFGs) with service insertion in dual-hop and single-hop modes. Some are documented in [AWS documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html), others were discovered via console validation errors during policy creation.

## Documented Constraints (from AWS docs)

| # | Constraint | Source |
|---|---|---|
| 1 | If an NFG is used by a send-via dual-hop action, it cannot be reused for a single-hop or send-to action | [Service Insertion docs](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html) |
| 2 | Send-via is bidirectional — specifying A→B automatically covers B→A | Service Insertion docs |
| 3 | One attachment per NFG per Region | Service Insertion docs |
| 4 | An attachment can be in a segment OR an NFG, not both | Service Insertion docs (Considerations) |
| 5 | Appliance mode must be enabled on the Inspection VPC attachment | Service Insertion docs (Considerations) |
| 6 | One VPC can have up to 5 core network attachments (different subnets/NFGs) | Service Insertion docs |

## Lab-Validated Constraints (not in public docs as of May 2026)

| # | Constraint | Console Error Message |
|---|---|---|
| 7 | A segment cannot participate in both single-hop and dual-hop send-via modes simultaneously | `segment X is used with multiple modes in send-via segment actions` |
| 8 | A segment pair can only use ONE NFG for all send-via actions between them | `Segments X and Y are configured to use network function group A but are also configured to use network function group B` |
| 9 | An NFG used in dual-hop send-via cannot also be used in send-to (requires separate Egress NFGs) | `the network function group X cannot be used in both dual-hop and either single-hop mode or send-to action` |
| 10 | CrossGeoNFG in dual-hop requires attachments in BOTH source and destination regions | Traffic blackholed if attachment missing in one region |
| 11 | Without a return route (appliance subnet → Core Network), traffic enters the appliance but cannot exit — 100% packet loss | No error — silent failure, discovered via connectivity testing |

## Impact on Architecture Decisions

### Single-Hop (Recommended for most use cases)
- 3 NFGs sufficient (one per geo + one cross-geo)
- NFG reuse with send-to is ALLOWED
- Single inspection pass (source-side)
- Lower cross-geo latency (~35ms NA↔EU)

### Dual-Hop
- 5 NFGs required (separate egress NFGs needed due to constraint #9)
- Double inspection (both source and destination)
- Higher cross-geo latency (~70ms NA↔EU)
- More complex policy management

### Multiple Global Networks (eliminates constraints #7-10 entirely)
- Each network uses only 1 NFG
- No cross-geo segment actions = no mode conflicts
- Simplest possible configuration
- Trade-off: no native cross-geo routing within Cloud WAN

## Critical Design Learning: Inspection VPC Routing

Two route tables per inspection VPC are **required**:

```
┌─────────────────────────────────────────────┐
│ Inspection VPC                              │
│                                             │
│  CWAN Subnet (hosts Cloud WAN ENI)          │
│  Route Table: 10.0.0.0/8 → Appliance ENI   │
│         ↓                                   │
│  Appliance Subnet (hosts firewall/EC2)      │
│  Route Table: 10.0.0.0/8 → Core Network    │
│                                             │
└─────────────────────────────────────────────┘
```

Without the return route on the appliance subnet, traffic enters the appliance but has no path back to Cloud WAN — resulting in 100% packet loss with no error message.

## References

- [AWS Cloud WAN Service Insertion](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html)
- [Simplify global security inspection with AWS Cloud WAN Service Insertion (blog)](https://aws.amazon.com/blogs/networking-and-content-delivery/simplify-global-security-inspection-with-aws-cloud-wan-service-insertion/)
- [Cloud WAN Policy Examples - Service Insertion](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-examples-service-insertion.html)
