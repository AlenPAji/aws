# AWS S3 Object Lock with Terraform

This project demonstrates how to implement AWS S3 Object Lock to protect objects from being deleted or overwritten for a fixed amount of time or indefinitely.

## What is S3 Object Lock?

S3 Object Lock is a feature that helps you store objects using a **Write Once Read Many (WORM)** model. It prevents object deletion or modification for a specified retention period or indefinitely.

### Key Use Cases

- **Regulatory Compliance** - Meet requirements like SEC 17a-4, FINRA, HIPAA
- **Data Protection** - Prevent accidental or malicious deletion
- **Legal Hold** - Preserve evidence for litigation
- **Audit Trails** - Maintain immutable records
- **Ransomware Protection** - Protect backups from encryption attacks

## Object Lock Modes

### 1. Governance Mode
- Users can't overwrite or delete objects unless they have special permissions
- Users with `s3:BypassGovernanceRetention` permission can modify retention settings
- Useful for internal policies where authorized users may need override capability

### 2. Compliance Mode
- **No one** can overwrite or delete objects, not even the root account
- Retention period cannot be shortened
- Most restrictive mode for regulatory compliance
- Can only extend retention period, never reduce it

## Retention Periods

### Retention Period
- Specifies a fixed time period during which an object remains locked
- Can be set in **days** or **years**
- Object cannot be deleted or modified until retention period expires

### Legal Hold
- Indefinite protection independent of retention period
- Can be applied or removed by users with `s3:PutObjectLegalHold` permission
- Useful for ongoing litigation or investigations
- No expiration date

## Terraform Implementation

### Step 1: Enable Object Lock on Bucket Creation

**Important:** Object Lock can **only** be enabled when creating a new bucket. It cannot be added to existing buckets.

```hcl
resource "aws_s3_bucket" "locked_bucket" {
  bucket = "my-locked-bucket-${random_id.suffix.hex}"
  
  object_lock_enabled = true
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

### Step 2: Configure Default Retention

```hcl
resource "aws_s3_bucket_object_lock_configuration" "config" {
  bucket = aws_s3_bucket.locked_bucket.id

  rule {
    default_retention {
      mode = "GOVERNANCE"  # or "COMPLIANCE"
      days = 30
    }
  }
}
```

### Step 3: Upload Object with Specific Retention

```hcl
resource "aws_s3_object" "protected_file" {
  bucket = aws_s3_bucket.locked_bucket.id
  key    = "important-document.pdf"
  source = "document.pdf"
  
  # Object-level retention settings
  object_lock_mode              = "COMPLIANCE"
  object_lock_retain_until_date = "2027-12-31T23:59:59Z"
  
  # Optional: Apply legal hold
  object_lock_legal_hold_status = "ON"
}
```

### Complete Example

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 Bucket with Object Lock enabled
resource "aws_s3_bucket" "compliance_bucket" {
  bucket = "compliance-bucket-${random_id.bucket_suffix.hex}"
  
  object_lock_enabled = true
  
  tags = {
    Purpose = "Compliance"
    WORM    = "Enabled"
  }
}

# Bucket versioning (required for Object Lock)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.compliance_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Object Lock configuration
resource "aws_s3_bucket_object_lock_configuration" "lock_config" {
  bucket = aws_s3_bucket.compliance_bucket.id

  rule {
    default_retention {
      mode  = "COMPLIANCE"
      years = 7  # Common for financial records
    }
  }
}

# Upload protected object
resource "aws_s3_object" "financial_record" {
  bucket = aws_s3_bucket.compliance_bucket.id
  key    = "records/2026/financial-report.pdf"
  source = "financial-report.pdf"
  
  # Inherit default retention from bucket
  # Or override with specific retention:
  # object_lock_mode              = "COMPLIANCE"
  # object_lock_retain_until_date = "2033-01-27T00:00:00Z"
}
```

## Retention Period Examples

### Using Days
```hcl
default_retention {
  mode = "GOVERNANCE"
  days = 90  # 90 days retention
}
```

### Using Years
```hcl
default_retention {
  mode = "COMPLIANCE"
  years = 5  # 5 years retention
}
```

### Object-Specific Retention
```hcl
resource "aws_s3_object" "contract" {
  bucket = aws_s3_bucket.locked_bucket.id
  key    = "contracts/2026-contract.pdf"
  source = "contract.pdf"
  
  object_lock_mode              = "COMPLIANCE"
  object_lock_retain_until_date = "2031-01-27T23:59:59Z"  # ISO 8601 format
}
```

## Legal Hold

Legal hold is independent of retention periods and can be applied/removed at any time by authorized users.

```hcl
resource "aws_s3_object" "evidence" {
  bucket = aws_s3_bucket.locked_bucket.id
  key    = "evidence/case-12345.pdf"
  source = "evidence.pdf"
  
  # Apply legal hold
  object_lock_legal_hold_status = "ON"  # or "OFF"
}
```

### Managing Legal Hold via AWS CLI

```bash
# Apply legal hold
aws s3api put-object-legal-hold \
  --bucket my-bucket \
  --key evidence.pdf \
  --legal-hold Status=ON

# Remove legal hold
aws s3api put-object-legal-hold \
  --bucket my-bucket \
  --key evidence.pdf \
  --legal-hold Status=OFF

# Check legal hold status
aws s3api get-object-legal-hold \
  --bucket my-bucket \
  --key evidence.pdf
```

## Important Requirements

### 1. Versioning is Mandatory
Object Lock requires versioning to be enabled:

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.locked_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 2. Enable at Bucket Creation Only
```hcl
# ✅ CORRECT - Enable during creation
resource "aws_s3_bucket" "new_bucket" {
  bucket              = "my-new-locked-bucket"
  object_lock_enabled = true
}

# ❌ WRONG - Cannot enable on existing bucket
# This will fail if bucket already exists
```

### 3. Bucket Cannot Be Deleted Until Objects Expire
- All objects must be past their retention period
- All legal holds must be removed
- All object versions must be deleted

## Bypassing Governance Mode

Users with appropriate permissions can bypass governance mode:

```bash
# Delete object in governance mode (requires special permission)
aws s3api delete-object \
  --bucket my-bucket \
  --key protected-file.txt \
  --bypass-governance-retention
```

Required IAM permission:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:BypassGovernanceRetention",
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

**Note:** Compliance mode **cannot** be bypassed by anyone, including root account.

## Checking Object Lock Status

```bash
# Get object retention
aws s3api get-object-retention \
  --bucket my-bucket \
  --key my-file.txt

# Get legal hold status
aws s3api get-object-legal-hold \
  --bucket my-bucket \
  --key my-file.txt

# Get bucket object lock configuration
aws s3api get-object-lock-configuration \
  --bucket my-bucket
```

## Comparison: Governance vs Compliance

| Feature | Governance Mode | Compliance Mode |
|---------|----------------|-----------------|
| **Can be overridden** | Yes, with special permissions | No, never |
| **Retention shortening** | Yes, by authorized users | No |
| **Retention extension** | Yes | Yes |
| **Root account bypass** | Yes, if granted permission | No |
| **Use case** | Internal policies | Regulatory compliance |
| **Flexibility** | More flexible | Strictest protection |

## Compliance Examples by Industry

### Financial Services (SEC 17a-4)
```hcl
default_retention {
  mode  = "COMPLIANCE"
  years = 7  # SEC requires 6-7 years
}
```

### Healthcare (HIPAA)
```hcl
default_retention {
  mode  = "COMPLIANCE"
  years = 6  # HIPAA recommends 6 years
}
```

### General Business Records
```hcl
default_retention {
  mode = "GOVERNANCE"
  days = 2555  # ~7 years
}
```

## Best Practices

1. **Plan before enabling** - Object Lock cannot be disabled once enabled
2. **Use Compliance mode for regulations** - Don't use Governance for regulatory requirements
3. **Test with Governance first** - Practice with Governance mode before using Compliance
4. **Document retention policies** - Maintain clear policies on retention periods
5. **Use bucket-level defaults** - Set default retention at bucket level for consistency
6. **Monitor legal holds** - Track and document all legal holds
7. **Implement lifecycle policies** - Clean up expired objects automatically
8. **Use separate buckets** - Consider separate buckets for different retention needs
9. **Regular audits** - Audit object lock configurations regularly
10. **Train your team** - Ensure team understands immutability implications

## Costs

- No additional cost for Object Lock feature itself
- Standard S3 storage costs apply
- Costs for versioning (storing multiple versions)
- Cannot delete objects during retention = longer storage duration = higher costs

## Limitations

- Cannot be enabled on existing buckets
- Cannot be disabled once enabled
- Requires versioning to be enabled
- Compliance mode objects cannot be deleted by anyone
- Maximum retention period: 100 years
- Minimum retention period: 1 day

## Terraform Outputs

```hcl
output "bucket_name" {
  value = aws_s3_bucket.locked_bucket.id
}

output "object_lock_enabled" {
  value = aws_s3_bucket.locked_bucket.object_lock_enabled
}

output "retention_mode" {
  value = aws_s3_bucket_object_lock_configuration.lock_config.rule[0].default_retention[0].mode
}

output "retention_period" {
  value = aws_s3_bucket_object_lock_configuration.lock_config.rule[0].default_retention[0].days
}
```

## Resources

- [AWS S3 Object Lock Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
- [Terraform aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Terraform aws_s3_bucket_object_lock_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration)
- [SEC 17a-4 Compliance](https://www.sec.gov/rules/interp/2003/34-47806.htm)
- [WORM Storage Model](https://en.wikipedia.org/wiki/Write_once_read_many)
