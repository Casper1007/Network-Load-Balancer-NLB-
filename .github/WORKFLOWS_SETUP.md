# GitHub Actions CI/CD Setup Guide

## Overview
Three automated workflows have been configured for your Terraform infrastructure:

1. **terraform-plan.yml** - Runs on Pull Requests
2. **terraform-apply.yml** - Runs on Push to Main
3. **security-audit.yml** - Daily Security & Compliance Audits

---

## Step 1: Configure GitHub Secrets ⚙️

Your workflows require AWS credentials and configuration variables. Add these secrets to your GitHub repository:

### Required Secrets (CRITICAL)
```
AWS_ACCESS_KEY_ID          → Your AWS Access Key ID
AWS_SECRET_ACCESS_KEY      → Your AWS Secret Access Key
```

### Recommended Secrets (Needed for Audit Gates)
```
DOMAIN_NAME                → Your domain name (e.g., example.com)
ROUTE53_ZONE_ID           → Your Route53 Hosted Zone ID
CF_DISTRIBUTION_ID        → CloudFront Distribution ID
WAF_WEB_ACL_ARN           → WAF Web ACL ARN for CloudFront scope
LOG_BUCKET                → S3 bucket name for CloudFront logs
```

### How to Add Secrets
1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the values above

---

## Step 2: Workflow Triggers 🚀

### Terraform Plan (PR Validation)
**Triggered when:**
- Pull request opened/updated targeting `main` branch
- Changes to `*.tf`, `terraform.tfvars` files

**What it does:**
- ✅ Validates Terraform syntax
- ✅ Checks formatting (terraform fmt)
- ✅ Runs terraform plan
- ✅ Comments plan output on PR
- ✅ Runs TFLint for best practices

---

### Terraform Apply (Auto-Deploy)
**Triggered when:**
- Code is pushed/merged to `main` branch
- Changes to `*.tf`, `terraform.tfvars` files

**What it does:**
- ✅ Runs terraform validate & plan
- ✅ **Automatically applies changes** (no manual approval needed)
- ✅ Deploys to both Tokyo & São Paulo regions
- ✅ Runs audit gates to verify compliance
- ✅ Posts audit results as commit comments
- ✅ Generates release notes

---

### Security Audit (Daily + Manual)
**Triggered when:**
- Scheduled daily at 2 AM UTC
- Manual trigger (workflow_dispatch)
- Changes to `malgus_*.py` audit scripts

**What it does:**
- ✅ Data residency verification
- ✅ WAF block pattern analysis
- ✅ CloudTrail change audits
- ✅ Cost guardrail analysis
- ✅ Network corridor verification

---

## Step 3: Multi-Region Deployment 🌍

### Tokyo Region (Primary)
- Provider: `ap-northeast-1`
- Applied first in the main terraform workspace
- Main resources

### São Paulo Region (Secondary)
- Provider: `sa-east-1`
- Applied second (depends on Tokyo success)
- Peering and corridor setup

---

## Step 4: Monitoring & Artifacts 📊

All workflows upload artifacts for historical tracking:

- `terraform-state-*` - Terraform state snapshots
- `audit-results` - Gate check results, badge status, comments
- `deployment-changelog` - Git commit log of deployed changes

**Access artifacts:**
1. Go to repo → Actions → Select workflow run
2. Scroll to "Artifacts" section
3. Download to review or audit

---

## Step 5: Manual Workflow Triggers ⚡

You can manually trigger workflows without making changes:

1. Go to Actions tab
2. Select workflow (e.g., "Terraform Apply & Audit")
3. Click "Run workflow"
4. Confirm

Or use CLI:
```bash
gh workflow run terraform-apply.yml --ref main
```

---

## Common Issues & Troubleshooting 🔧

### "AWS credentials invalid"
- ❌ Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
- ❌ Ensure IAM user has required permissions:
  - `terraform:*` (all Terraform actions)
  - `ec2:*`, `waf:*`, `cloudfront:*`, `route53:*`, etc.

### "Terraform plan shows unexpected changes"
- ❌ Check `terraform.tfvars` is committed correctly
- ❌ Verify no local state drift
- ❌ Run `terraform plan` locally to compare

### "Audit gates fail"
- ❌ Verify all optional secrets are set (DOMAIN_NAME, ROUTE53_ZONE_ID, etc.)
- ❌ Check CloudFront distribution and WAF are properly deployed
- ❌ Review audit output in artifacts

### "TFLint errors are soft-fail"
- TFLint issues don't block PR or deployment
- Review suggestions in workflow output
- Update `.tflint.hcl` if you want stricter rules

---

## Advanced Configuration 🎯

### Disable Auto-Apply
To require manual approval before deployment, change `terraform-apply.yml`:
```yaml
- name: Terraform apply
  run: terraform apply tfplan.binary  # Remove -auto-approve
```
Then manually approve in Actions UI.

### Add Slack Notifications
Add this step to any workflow:
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
    text: 'Terraform deployment ${{ job.status }}'
```

### Schedule Deployment Windows
Edit cron in `terraform-apply.yml` to only deploy during business hours:
```yaml
on:
  schedule:
    - cron: '0 9 * * 1-5'  # 9 AM UTC, Mon-Fri only
```

---

## Next Steps ✅

1. **Add AWS Secrets** → Settings → Secrets and variables → Actions
2. **Add Optional Secrets** for audit gates (DOMAIN_NAME, etc.)
3. **Test PR workflow** → Create a dummy PR to validate
4. **Test apply workflow** → Merge a test PR to main
5. **Monitor artifact uploads** → Verify deployment state snapshots
6. **Review audit results** → Check commit comments for compliance status

---

## Useful Commands

```bash
# View workflow status locally
gh workflow list

# Check workflow runs
gh run list --workflow=terraform-plan.yml

# View full run logs
gh run view <run-id> --log

# Re-run a failed workflow
gh run rerun <run-id>
```

---

## Security Best Practices 🔐

✅ **DO:**
- Rotate AWS keys periodically
- Use IAM roles instead of access keys when possible
- Review audit results regularly
- Keep Terraform up to date

❌ **DON'T:**
- Commit AWS credentials to Git
- Use overly permissive IAM policies
- Disable audit checks
- Skip PR reviews

---

For more info, see:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS Credentials Action](https://github.com/aws-actions/configure-aws-credentials)
