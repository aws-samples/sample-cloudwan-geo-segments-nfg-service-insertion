#!/bin/bash
# Deploy Cloud WAN Geo-Segments NFG Lab
# Deploys across us-east-1 and eu-west-1

set -e

STACK_PREFIX="cloudwan-nfg-lab"

echo "=== Step 1: Deploy Cloud WAN Core Network ==="
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-core-network \
  --template-file templates/01-cloud-wan-core-network.yaml \
  --region us-east-1 \
  --no-fail-on-empty-changeset

CORE_NETWORK_ID=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_PREFIX}-core-network \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`CoreNetworkId`].OutputValue' \
  --output text)

echo "Core Network ID: ${CORE_NETWORK_ID}"
echo "Waiting for Core Network to become AVAILABLE..."
sleep 60

echo "=== Step 2: Deploy Workload VPCs ==="

# NA Prod (us-east-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-na-prod \
  --template-file templates/02-workload-vpcs.yaml \
  --region us-east-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-na-prod \
    VpcCidr=10.100.0.0/24 \
    CwanSubnetACidr=10.100.0.0/28 \
    CwanSubnetBCidr=10.100.0.16/28 \
    WorkloadSubnetCidr=10.100.0.128/25 \
    SegmentName=NorthAmericaProd01 \
  --no-fail-on-empty-changeset

# NA NonProd (us-east-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-na-nonprod \
  --template-file templates/02-workload-vpcs.yaml \
  --region us-east-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-na-nonprod \
    VpcCidr=10.101.0.0/24 \
    CwanSubnetACidr=10.101.0.0/28 \
    CwanSubnetBCidr=10.101.0.16/28 \
    WorkloadSubnetCidr=10.101.0.128/25 \
    SegmentName=NorthAmericaNonProd01 \
  --no-fail-on-empty-changeset

# EU Prod (eu-west-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-eu-prod \
  --template-file templates/02-workload-vpcs.yaml \
  --region eu-west-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-eu-prod \
    VpcCidr=10.102.0.0/24 \
    CwanSubnetACidr=10.102.0.0/28 \
    CwanSubnetBCidr=10.102.0.16/28 \
    WorkloadSubnetCidr=10.102.0.128/25 \
    SegmentName=EuropeProd01 \
  --no-fail-on-empty-changeset

echo "=== Step 3: Deploy Inspection VPCs ==="

# NA Inspection (us-east-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-inspection-na \
  --template-file templates/03-inspection-vpcs.yaml \
  --region us-east-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-inspection-na \
    VpcCidr=10.200.0.0/24 \
    CwanSubnetACidr=10.200.0.0/28 \
    CwanSubnetBCidr=10.200.0.16/28 \
    ApplianceSubnetCidr=10.200.0.128/25 \
    NfgName=NorthAmericaNFG01 \
  --no-fail-on-empty-changeset

# EU Inspection (eu-west-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-inspection-eu \
  --template-file templates/03-inspection-vpcs.yaml \
  --region eu-west-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-inspection-eu \
    VpcCidr=10.201.0.0/24 \
    CwanSubnetACidr=10.201.0.0/28 \
    CwanSubnetBCidr=10.201.0.16/28 \
    ApplianceSubnetCidr=10.201.0.128/25 \
    NfgName=EuropeNFG01 \
  --no-fail-on-empty-changeset

# CrossGeo NA (us-east-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-inspection-crossgeo-na \
  --template-file templates/03-inspection-vpcs.yaml \
  --region us-east-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-inspection-crossgeo-na \
    VpcCidr=10.202.0.0/24 \
    CwanSubnetACidr=10.202.0.0/28 \
    CwanSubnetBCidr=10.202.0.16/28 \
    ApplianceSubnetCidr=10.202.0.128/25 \
    NfgName=CrossGeoNFG01 \
  --no-fail-on-empty-changeset

# CrossGeo EU (eu-west-1)
aws cloudformation deploy \
  --stack-name ${STACK_PREFIX}-inspection-crossgeo-eu \
  --template-file templates/03-inspection-vpcs.yaml \
  --region eu-west-1 \
  --parameter-overrides \
    CoreNetworkId=${CORE_NETWORK_ID} \
    VpcName=lab-inspection-crossgeo-eu \
    VpcCidr=10.203.0.0/24 \
    CwanSubnetACidr=10.203.0.0/28 \
    CwanSubnetBCidr=10.203.0.16/28 \
    ApplianceSubnetCidr=10.203.0.128/25 \
    NfgName=CrossGeoNFG01 \
  --no-fail-on-empty-changeset

echo "=== Step 4: Deploy EC2 Appliances ==="
echo "Deploy appliances using template 04, then add CWAN RT routes manually."
echo "See template 04 outputs for ENI IDs needed for routing."
echo ""
echo "=== Deployment Complete ==="
echo "Next: Deploy EC2 appliances (template 04) and add CWAN subnet routes to appliance ENIs"
