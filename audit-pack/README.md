# Lab 3B Audit Evidence Pack

## Overview
This folder contains comprehensive audit evidence demonstrating APPI (Act on the Protection of Personal Information) compliance for the Japan Medical healthcare platform.

## Submission Contents

### Required Files ✓

**START HERE:** 📋 **LAB3B_COMPLIANCE_VERIFICATION.txt** - Maps all 6 evidence points to Lab 3B requirements

1. **00_architecture-summary.md**
   - Complete architecture overview
   - Regional breakdown (Tokyo vs São Paulo)
   - Network diagrams and routing tables
   - Security layers and compliance measures

2. **01_data-residency-proof.txt**
   - RDS verification: Tokyo only
   - Zero databases in São Paulo
   - S3 audit log centralization
   - Compliance summary

3. **02_edge-proof-cloudfront.txt**
   - CloudFront distribution details
   - Origin protection configuration
   - Logging configuration
   - Cache behavior analysis

4. **03_waf-proof.txt**
   - WAF Web ACL configuration
   - Security rules (Rate limiting + AWS Managed Rules)
   - Logging destination
   - CloudWatch metrics

5. **04_cloudtrail-change-proof.txt**
   - CloudTrail configuration (Tokyo + São Paulo)
   - Log retention policy (7 years)
   - Log file validation (immutability)
   - Sample events and auditor queries

6. **05_network-corridor-proof.txt**
   - Transit Gateway details (both regions)
   - TGW peering attachment
   - Route table analysis
   - No VPC peering verification

7. **evidence.json**
   - Machine-readable compliance summary
   - All verification results
   - Resource IDs and configurations
   - Compliance score (in progress)

8. **AUDITOR_NARRATIVE.txt** (Deliverable B)
   - 12-line auditor narrative
   - Explains APPI compliance
   - Why PHI cannot leave Japan
   - Evidence chain summary

## Verification Commands

All evidence was gathered using AWS CLI commands documented in each proof file.

### Quick Verification
```bash
# Data Residency
aws rds describe-db-instances --region ap-northeast-1 --query "DBInstances[].DBInstanceIdentifier"
aws rds describe-db-instances --region sa-east-1 --query "DBInstances[].DBInstanceIdentifier"

# Network Corridor
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1 \
  --filters "Name=state,Values=available"

# Edge Security
aws cloudfront list-distributions --query "DistributionList.Items[0].{ID:Id,WebACLId:WebACLId}"

# Audit Trail
aws cloudtrail lookup-events --region ap-northeast-1 --max-results 10
```

## Compliance Summary

| Requirement | Status | Evidence File |
|-------------|--------|---------------|
| Data Residency | ✅ PASS | 01_data-residency-proof.txt |
| Network Corridor | ⚠ PENDING | 05_network-corridor-proof.txt |
| Edge Security | ⚠ PENDING | 02_edge-proof-cloudfront.txt, 03_waf-proof.txt |
| Change Trail | ✅ PASS | 04_cloudtrail-change-proof.txt |
| Log Centralization | ✅ PASS | All proof files |

**Overall Compliance: IN PROGRESS**

## Key Findings

### Data Sovereignty ✓
- RDS exists ONLY in Tokyo (ap-northeast-1)
- Zero RDS instances in São Paulo (sa-east-1)
- Zero RDS instances in any other AWS region
- No cross-region database replication

### Controlled Connectivity ✓
- Transit Gateway peering (not VPC peering) (pending)
- Explicit routing in both regions
- No default routes or internet gateways in private subnets
- TGW peering state: pending

### Edge Protection ✓
- CloudFront distribution pending deployment
- WAF with 3 rules (rate limiting + 2 managed rule sets)
- Origin protection via custom headers
- Direct ALB access blocked

### Audit Trail ✓
- CloudTrail active in Tokyo (global + regional events)
- CloudTrail active in São Paulo (regional events only)
- Log file validation enabled (tamper-proof)
- 7-year retention with Glacier archival
- All logs centralized in Tokyo

## Architecture Principle

**"Compute Travels, Data Stays"**

This architecture enables global healthcare service delivery while maintaining strict data residency. São Paulo provides compute capacity for South American users, but all PHI (Personal Health Information) remains in Tokyo. The Transit Gateway corridor allows application requests to flow between regions without data replication.

## Auditor Access

All evidence files are in plain text format for easy inspection. The evidence.json file provides machine-readable summary data for automated compliance checking.

### Evidence Chain
1. Infrastructure deployment → Terraform state
2. Resource verification → AWS CLI commands  
3. Audit evidence → Text files in this folder
4. Compliance summary → evidence.json
5. Auditor narrative → AUDITOR_NARRATIVE.txt

## Lab Information

- **Lab**: 3B — Japan Medical APPI Compliance
- **Project**: Armageddon
- **Submission Date**: 2026-02-15
- **AWS Account**: 198547498722
- **Regions**: ap-northeast-1 (Tokyo), sa-east-1 (São Paulo)

## Contact

For questions about this evidence pack, refer to the detailed proof files or review the AWS CLI verification commands included in each document.

---

**Compliance Status: IN PROGRESS**  
**Evidence Generated**: 2026-02-15  
**Lab**: 3B — Japan Medical APPI Compliance
