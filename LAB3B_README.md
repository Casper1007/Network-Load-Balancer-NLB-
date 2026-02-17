# Lab 3B — Japan Medical: Audit Evidence & Regulator-Ready Logging

## 🎯 Objective

このラボで学生が作るのは「システム」ではなく **証明（proof）**。

**Key Principles:**
- PHI は東京（ap-northeast-1）にのみ保存（APPIの考え方）
- São Paulo（sa-east-1）は 計算（compute）だけ
- 監査人に見せられる形で「誰が・いつ・何を・どこに」したかを証跡として出せる
- CloudFront/WAF/CloudTrail/ログを "一つの証拠パック" にまとめる

## 🧠 The Compliance-Audit Principle

**規制業界では「動いてる」より「証明できる」が勝つ。**
Global access ≠ Global storage.

## What "Good Evidence" Looks Like

監査・法務・セキュリティが欲しいのは、だいたいこの 6 点:

### 1. Data Residency Proof
- RDS が Tokyo にあること
- クロスリージョンに DB が無いこと
- **Script:** `malgus_data_residency_enhanced.py`

### 2. Access Trail
- 誰が API を叩いたか（個人情報は含めない）
- **Logs:** CloudFront standard logs → S3

### 3. Change Trail
- 誰がセキュリティ設定を変えたか（CloudTrail）
- **Script:** `malgus_cloudtrail_last_changes.py`

### 4. Network Corridor Proof
- São Paulo → Tokyo の経路が TGW であること
- **Script:** `malgus_network_corridor_proof.py`

### 5. Edge Security Proof
- CloudFront + WAF が前段にあり、直ALBが閉じていること
- **Script:** `malgus_waf_summary.py`

### 6. Retention / Immutability Posture
- 監査ログは改ざんされない場所に保存されること
- **Implementation:** S3 versioning + lifecycle policies

## 📁 Infrastructure Overview

### Logging Infrastructure (Tokyo - ap-northeast-1)

All audit logs are stored in Tokyo to maintain data residency compliance:

```
S3 Buckets (All with Versioning Enabled):
├── chrisbarm-cloudtrail-logs-[account-id]
│   ├── tokyo/          # Tokyo region events
│   └── saopaulo/       # São Paulo region events
├── chrisbarm-cloudfront-logs-[account-id]
│   └── saopaulo-cf/    # CloudFront access logs
├── chrisbarm-waf-logs-[account-id]
│   └── WAF block/allow events
└── chrisbarm-flowlogs-[account-id]
    ├── tokyo/          # Tokyo VPC flow logs
    └── saopaulo/       # São Paulo VPC flow logs
```

### CloudTrail Configuration

**Tokyo Trail:**
- Management events: ✅
- Global service events: ✅
- Log file validation: ✅ (immutability proof)
- S3 destination: Tokyo bucket
- Lifecycle: 90 days → Glacier, 7 years retention

**São Paulo Trail:**
- Management events: ✅
- Global service events: ❌ (Tokyo handles)
- Log file validation: ✅
- S3 destination: Tokyo bucket (with prefix)

### CloudFront + WAF

**CloudFront:**
- Access logging: ✅ → Tokyo S3 bucket
- WAF association: ✅
- Custom header: X-Origin-Verify (origin protection)

**WAF (us-east-1 for CloudFront):**
- Rate limiting: 2000 requests/5min per IP
- AWS Managed Rules: Core Rule Set
- AWS Managed Rules: Known Bad Inputs
- Logging: CloudWatch Logs `aws-waf-logs-liberdade`

### VPC Flow Logs

**Tokyo VPC:**
- Traffic type: ALL
- Destination: S3 (Tokyo bucket)
- Format: Default

**São Paulo VPC:**
- Traffic type: ALL
- Destination: S3 (Tokyo bucket)
- Format: Default

## 🚀 Quick Start

### 1. Deploy Infrastructure

```bash
# Deploy Tokyo (main region with RDS)
cd Lab3b
terraform init
terraform apply

# Deploy São Paulo (compute region)
cd saopaulo
terraform init
terraform apply
```

### 2. Generate Audit Evidence

```bash
# Run all audit gates
chmod +x run_audit_gates.sh
./run_audit_gates.sh

# Or run individual scripts:
python3 malgus_data_residency_enhanced.py
python3 malgus_network_corridor_proof.py
python3 malgus_audit_evidence_package.py
```

### 3. Review Evidence Package

```bash
# Evidence will be in:
ls -la audit_evidence_*/

# Files generated:
# - data_residency_proof.json
# - network_corridor_proof.json
# - audit_evidence_package.json
# - AUDIT_README.md
# - audit_evidence_bundle_[timestamp].zip
```

## 📊 Audit Evidence Scripts

### malgus_data_residency_enhanced.py
**Purpose:** Prove PHI resides ONLY in Tokyo

**Checks:**
- RDS instances in Tokyo vs São Paulo
- RDS snapshots location
- S3 audit bucket locations

**Output:** `data_residency_proof.json`

### malgus_network_corridor_proof.py
**Purpose:** Prove controlled routing via TGW

**Checks:**
- Transit Gateways in both regions
- TGW peering attachment status
- TGW route tables
- No VPC peering connections (violation)

**Output:** `network_corridor_proof.json`

### malgus_audit_evidence_package.py
**Purpose:** Generate complete compliance package

**Includes:**
1. Change trail (CloudTrail events)
2. Edge security (CloudFront + WAF)
3. Flow log summary
4. ZIP bundle for auditors

**Output:** `audit_evidence_package.json` + ZIP bundle

## 🔍 What Auditors Will Check

### Data Residency Compliance ✅

```bash
# Verify RDS only in Tokyo
aws rds describe-db-instances --region ap-northeast-1
aws rds describe-db-instances --region sa-east-1  # Should be empty

# Verify S3 bucket locations
aws s3api get-bucket-location --bucket chrisbarm-cloudtrail-logs-[account-id]
# Expected: ap-northeast-1
```

### Change Trail Evidence ✅

```bash
# Verify CloudTrail is active
aws cloudtrail describe-trails --region ap-northeast-1
aws cloudtrail describe-trails --region sa-east-1

# Check recent events
aws cloudtrail lookup-events --max-results 10 --region ap-northeast-1
```

### Edge Security Evidence ✅

```bash
# Verify CloudFront distribution
aws cloudfront list-distributions

# Verify WAF association
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1

# Check CloudFront logs
aws s3 ls s3://chrisbarm-cloudfront-logs-[account-id]/saopaulo-cf/
```

### Network Corridor Evidence ✅

```bash
# Verify TGW peering
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1

# Check TGW routes
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id tgw-rtb-xxxxx \
  --filters "Name=state,Values=active" \
  --region ap-northeast-1
```

## 📝 Compliance Summary

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Data Residency | RDS in Tokyo only | `data_residency_proof.json` |
| Change Trail | CloudTrail + S3 (7yr) | CloudTrail logs in S3 |
| Access Trail | CloudFront logs | S3 access logs |
| Network Corridor | TGW peering only | `network_corridor_proof.json` |
| Edge Security | CloudFront + WAF | WAF logs in CloudWatch |
| Immutability | S3 versioning + lifecycle | S3 bucket config |

## 🎓 Interview Talking Points

**"How did you prove APPI compliance?"**
> "I implemented a comprehensive audit evidence system using CloudTrail for change tracking, VPC Flow Logs for network monitoring, and automated Python scripts to generate regulator-ready evidence packages. All logs are stored in Tokyo with S3 versioning for immutability, and I can prove data residency by showing RDS only exists in ap-northeast-1 with no cross-region replication."

**"What's your approach to cloud compliance?"**
> "Compliance is about proof, not just implementation. I automate evidence generation using boto3 scripts that query resource inventory across regions, validate Transit Gateway routing for network isolation, and bundle everything into timestamped JSON artifacts that auditors can verify. The key is making compliance auditable and reproducible."

**"How do you handle cross-region requirements?"**
> "For APPI compliance, we use a 'compute-only' architecture in São Paulo while keeping all PHI data in Tokyo. Transit Gateway provides the controlled corridor, CloudFront handles global access at the edge, and all audit logs centralize in Tokyo regardless of source region. This proves global accessibility doesn't require global storage."

## 🔧 Troubleshooting

### CloudTrail not logging
```bash
# Check trail status
aws cloudtrail get-trail-status --name chrisbarm-audit-trail-tokyo --region ap-northeast-1

# Verify S3 bucket policy
aws s3api get-bucket-policy --bucket chrisbarm-cloudtrail-logs-[account-id]
```

### WAF not blocking
```bash
# Check WAF logs
aws logs tail aws-waf-logs-liberdade --region us-east-1 --follow

# Verify CloudFront association
aws cloudfront get-distribution --id [DISTRIBUTION-ID] | jq '.Distribution.DistributionConfig.WebACLId'
```

### Flow Logs not appearing
```bash
# Check flow log status
aws ec2 describe-flow-logs --region ap-northeast-1

# Verify S3 permissions
aws s3api get-bucket-policy --bucket chrisbarm-flowlogs-[account-id]
```

## 📚 Additional Resources

- [APPI Guidelines](https://www.ppc.go.jp/en/)
- [AWS Compliance Programs](https://aws.amazon.com/compliance/)
- [CloudTrail Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

---

**Lab 3B Complete! 証明できるインフラが完成 🎌**
