# AWS Cloud WAN: Geo-Based Segments with NFG Service Insertion Lab

Deploy a multi-region AWS Cloud WAN network with geographic segment isolation and Network Function Group (NFG) service insertion for centralized traffic inspection.

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │        AWS Cloud WAN Global Network     │
                    │                                         │
  us-east-1         │   CNE: us-east-1    CNE: eu-west-1      │
  ┌────────────┐    │                                         │   ┌────────────┐
  │ NA-Prod    │───►│  Segments:          Segments:           │◄──│ EU-Prod    │
  │ 10.100.0/24│    │  NAProd01           EUProd01            │   │ 10.102.0/24│
  └────────────┘    │  NANonProd01        EUNonProd01         │   └────────────┘
  ┌────────────┐    │                                         │
  │ NA-NonProd │───►│  NFGs:              NFGs:               │
  │ 10.101.0/24│    │  NorthAmericaNFG01  EuropeNFG01         │
  └────────────┘    │  CrossGeoNFG01 (both regions)           │
                    │  NAEgressNFG01     EUEgressNFG01        │
  ┌────────────┐    │                                         │   ┌────────────┐
  │ Inspection │───►│  send-via dual-hop (inter-segment)      │◄──│ Inspection │
  │ NA         │    │  send-to (internet egress)              │   │ EU         │
  │ 10.200.0/24│    │                                         │   │ 10.201.0/24│
  └────────────┘    └─────────────────────────────────────────┘   └────────────┘
```

## Features Demonstrated

- **Geographic segment isolation** — segments restricted by edge-location
- **Dual-hop NFG inspection** — traffic inspected at both source and destination regions
- **Cross-geography inspection** — CrossGeoNFG with attachments in both regions
- **Separate egress NFGs** — required when using dual-hop (constraint #9)
- **Critical inspection VPC routing** — dual route table design for return traffic

## Prerequisites

- AWS account with Cloud WAN access
- AWS CLI configured
- Regions enabled: us-east-1, us-west-2, eu-west-1

## Deployment

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Deploy order:
1. `01-cloud-wan-core-network.yaml` — Global Network + Core Network + Policy
2. `02-workload-vpcs.yaml` — Spoke VPCs (deploy per region/segment)
3. `03-inspection-vpcs.yaml` — Inspection VPCs with dual route tables
4. `04-ec2-appliances.yaml` — Forwarding EC2 instances (simulating firewalls)
5. Manual step: Add CWAN subnet route → appliance ENI

## Templates

| Template | Purpose | Region |
|---|---|---|
| `01-cloud-wan-core-network.yaml` | Cloud WAN with 4 segments, 5 NFGs, 7 segment actions | us-east-1 (global) |
| `02-workload-vpcs.yaml` | Parameterized spoke VPC (reuse per workload) | Any |
| `03-inspection-vpcs.yaml` | Inspection VPC with appliance mode + dual RTs | Any |
| `04-ec2-appliances.yaml` | EC2 forwarding appliance (simulates firewall) | Any |

## NFG Constraints Documentation

See [docs/nfg-constraints.md](docs/nfg-constraints.md) for lab-validated findings on Cloud WAN NFG constraints, including undocumented behaviors discovered during testing.

## Key Design Decisions

1. **Why 5 NFGs instead of 3?** — Dual-hop NFGs cannot be reused for send-to actions. Separate egress NFGs are required.
2. **Why dual route tables in inspection VPCs?** — Without a return route (appliance subnet → Core Network), 100% packet loss occurs silently.
3. **Why appliance mode?** — Required for symmetric routing through inspection attachments.

## Single-Hop Alternative

For most production use cases, **single-hop is recommended** over dual-hop:
- 3 NFGs (vs 5)
- NFG reuse with send-to allowed
- Half the cross-geo latency (~35ms vs ~70ms)
- Simpler policy

## Cost (us-east-1 pricing)

- Cloud WAN Core Network Edge: $0.50/hour per region with attachments
- VPC Attachment: $0.065/hour per attachment (varies by region)
- Data Processing: $0.02/GB
- EC2 (t3.micro): ~$0.01/hour per appliance (lab only)

See [AWS Cloud WAN Pricing](https://aws.amazon.com/cloud-wan/pricing/) for current rates.

> **Note:** The inspection VPCs in this lab use EC2 instances configured as transparent packet forwarders (IP forwarding + iptables FORWARD ACCEPT) to emulate firewall behavior. In production, replace these with AWS Network Firewall or third-party appliances behind Gateway Load Balancer (GWLB).

## Cleanup

Delete stacks in reverse order:
```bash
# Delete EC2 appliances first
# Then inspection VPCs, workload VPCs, and finally core network
aws cloudformation delete-stack --stack-name cloudwan-nfg-lab-core-network --region us-east-1
```

## References

- [AWS Cloud WAN Service Insertion](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html)
- [Simplify global security inspection with AWS Cloud WAN](https://aws.amazon.com/blogs/networking-and-content-delivery/simplify-global-security-inspection-with-aws-cloud-wan-service-insertion/)
- [Cloud WAN Policy Examples](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-examples-service-insertion.html)
- [XM Cyber 22-Region Implementation](https://aws.amazon.com/blogs/networking-and-content-delivery/designing-for-global-scale-xm-cybers-22-region-aws-cloud-wan-implementation/)

## Author

Abhishek Kumar — AWS Networking TFC (Area of Depth)

## License

MIT-0
