# AWS S3 Access Control - ACLs and Bucket Policies

This project demonstrates how to control access to AWS S3 buckets using bucket policies and public access block settings. This README covers all S3 access control mechanisms including ACLs, bucket policies, IAM policies, and more.

---

## 📁 What This Project Does

This Terraform configuration creates:

1. **S3 Bucket** - A private bucket named `policy-only-bucket-123456`
2. **Public Access Block** - Restricts public access with specific settings
3. **Bucket Policy** - Grants specific permissions to an IAM user

### Resources Created

```hcl
✅ aws_s3_bucket.bucket
✅ aws_s3_bucket_public_access_block.block_public
✅ aws_s3_bucket_policy.policy
```

---

## 🔐 S3 Access Control Mechanisms

AWS S3 provides **5 main ways** to control access to your buckets and objects. Understanding when to use each is crucial for security.

---

## 1️⃣ IAM Policies (Identity-Based)

### What It Is
Permissions attached to **IAM users, groups, or roles** that define what they can do with S3 resources.

### How It Works
- Attached to IAM identities (users/roles/groups)
- Controls what actions that identity can perform
- Works across multiple buckets and AWS services

### Example IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

### When to Use
- ✅ Controlling access for AWS users/roles
- ✅ Managing permissions for AWS services (Lambda, EC2, etc.)
- ✅ Cross-bucket permissions for a user
- ✅ Most common and recommended approach

### Terraform Example
```hcl
resource "aws_iam_user_policy" "s3_access" {
  name = "s3-access-policy"
  user = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}
```

---

## 2️⃣ Bucket Policies (Resource-Based)

### What It Is
Permissions attached **directly to an S3 bucket** that define who can access it and what they can do.

### How It Works
- Attached to the bucket itself (not users)
- Can grant access to other AWS accounts
- Can make bucket public or grant anonymous access
- Supports conditions (IP restrictions, time-based, etc.)

### Example Bucket Policy (Used in This Project)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSpecificAccount",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::899673281289:user/alen_aws"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::policy-only-bucket-123456/*"
    }
  ]
}
```

### When to Use
- ✅ Granting access to **other AWS accounts** (cross-account)
- ✅ Making buckets/objects **public**
- ✅ Restricting access by **IP address**
- ✅ Adding **conditions** (MFA, VPC endpoint, SSL only)
- ✅ Centralized bucket-level permissions

### Advanced Examples

#### Public Read Access
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-public-bucket/*"
    }
  ]
}
```

#### IP-Based Restriction
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        }
      }
    }
  ]
}
```

#### Require SSL/HTTPS Only
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

### Terraform Implementation
```hcl
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = file("${path.module}/policy.json")
}
```

---

## 3️⃣ Access Control Lists (ACLs) - Legacy

### What It Is
An older, simpler way to grant basic read/write permissions to AWS accounts or the public.

### How It Works
- Grants coarse-grained permissions (READ, WRITE, FULL_CONTROL)
- Can be applied to buckets or individual objects
- Limited to predefined groups (Authenticated Users, All Users, Log Delivery)
- **AWS recommends disabling ACLs** and using bucket policies instead

### Predefined ACL Groups
- `private` - Owner gets FULL_CONTROL, no one else
- `public-read` - Owner gets FULL_CONTROL, everyone gets READ
- `public-read-write` - Owner gets FULL_CONTROL, everyone gets READ and WRITE
- `authenticated-read` - Owner gets FULL_CONTROL, authenticated AWS users get READ
- `aws-exec-read` - Owner gets FULL_CONTROL, EC2 gets READ for AMI bundles
- `log-delivery-write` - Log Delivery group gets WRITE permissions

### ACL Permissions
- `READ` - List objects (bucket) or read object data (object)
- `WRITE` - Create, overwrite, delete objects (bucket only)
- `READ_ACP` - Read the ACL
- `WRITE_ACP` - Write the ACL
- `FULL_CONTROL` - All of the above

### When to Use (Rarely)
- ⚠️ **Legacy applications** that require ACLs
- ⚠️ **S3 server access logging** (Log Delivery group needs WRITE permission)
- ❌ **Not recommended** for modern applications (use bucket policies instead)

### Why ACLs Are Deprecated
- Limited functionality compared to bucket policies
- Less flexible (no conditions, no deny statements)
- Harder to audit and manage
- AWS best practice: **Disable ACLs** and use bucket policies/IAM policies

### Terraform Example (Not Recommended)
```hcl
# Bucket ACL (legacy)
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"  # or "public-read", "public-read-write"
}

# Object ACL (legacy)
resource "aws_s3_object" "file" {
  bucket = aws_s3_bucket.bucket.id
  key    = "file.txt"
  source = "file.txt"
  acl    = "public-read"
}

# Granting specific permissions (legacy)
resource "aws_s3_bucket_acl" "custom_acl" {
  bucket = aws_s3_bucket.bucket.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/global/AllUsers"
      }
      permission = "READ"
    }
  }
}
```

### Modern Alternative: Disable ACLs
```hcl
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"  # Disables ACLs
  }
}
```

---

## 4️⃣ S3 Block Public Access

### What It Is
A safety feature that prevents buckets from becoming accidentally public, even if ACLs or policies allow it.

### How It Works (Used in This Project)
Four independent settings that work as guardrails:

```hcl
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true   # Block public ACLs on bucket/objects
  block_public_policy     = false  # Don't block public bucket policies
  ignore_public_acls      = true   # Ignore any public ACLs
  restrict_public_buckets = false  # Don't restrict public bucket policies
}
```

### Settings Explained

#### 1. `block_public_acls`
- **true**: Prevents new public ACLs from being applied
- **false**: Allows public ACLs
- **Our setting**: `true` (blocks public ACLs)

#### 2. `block_public_policy`
- **true**: Prevents bucket policies that grant public access
- **false**: Allows public bucket policies
- **Our setting**: `false` (allows public policies if needed)

#### 3. `ignore_public_acls`
- **true**: Ignores existing public ACLs (treats them as private)
- **false**: Honors existing public ACLs
- **Our setting**: `true` (ignores any public ACLs)

#### 4. `restrict_public_buckets`
- **true**: Only bucket owner and AWS services can access public buckets
- **false**: Public bucket policies work normally
- **Our setting**: `false` (allows normal public access if policy allows)

### Common Configurations

#### Maximum Security (Recommended for most cases)
```hcl
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

#### Public Website Hosting
```hcl
block_public_acls       = true
block_public_policy     = false
ignore_public_acls      = true
restrict_public_buckets = false
```

#### Our Configuration (Selective Public Access)
```hcl
block_public_acls       = true   # No public ACLs allowed
block_public_policy     = false  # Public policies allowed
ignore_public_acls      = true   # Ignore any public ACLs
restrict_public_buckets = false  # Don't restrict public buckets
```

### When to Use
- ✅ **Always** - Should be enabled on all buckets by default
- ✅ Set at account level for new buckets
- ✅ Override at bucket level when needed (e.g., public websites)

---

## 5️⃣ Pre-Signed URLs (Temporary Access)

### What It Is
Temporary URLs that grant time-limited access to private S3 objects without changing permissions.

### How It Works
- Generated using AWS credentials
- Contains authentication information in the URL
- Expires after a specified time (seconds to days)
- No need to make objects public

### When to Use
- ✅ Temporary file downloads (reports, exports)
- ✅ Allowing users to upload directly to S3
- ✅ Sharing private files without making bucket public
- ✅ Granting time-limited access

### AWS CLI Example
```bash
# Generate pre-signed URL valid for 1 hour (3600 seconds)
aws s3 presign s3://my-bucket/private-file.pdf --expires-in 3600
```

### Terraform Example (using null_resource)
```hcl
resource "null_resource" "generate_presigned_url" {
  provisioner "local-exec" {
    command = "aws s3 presign s3://${aws_s3_bucket.bucket.id}/file.txt --expires-in 3600"
  }
}
```

### Python Boto3 Example
```python
import boto3
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')

try:
    # Generate pre-signed URL for GET (download)
    url = s3_client.generate_presigned_url(
        'get_object',
        Params={'Bucket': 'my-bucket', 'Key': 'file.txt'},
        ExpiresIn=3600  # 1 hour
    )
    print(url)
    
    # Generate pre-signed URL for PUT (upload)
    upload_url = s3_client.generate_presigned_url(
        'put_object',
        Params={'Bucket': 'my-bucket', 'Key': 'upload.txt'},
        ExpiresIn=3600
    )
except ClientError as e:
    print(e)
```

---

## 6️⃣ S3 Access Points

### What It Is
Named network endpoints attached to buckets that enforce specific permissions and network controls.

### How It Works
- Each access point has its own policy
- Can restrict access to specific VPCs
- Simplifies managing access to shared datasets
- Each access point gets its own DNS name

### When to Use
- ✅ Multiple applications accessing same bucket with different permissions
- ✅ VPC-only access requirements
- ✅ Large shared data lakes
- ✅ Simplified permission management

### Terraform Example
```hcl
resource "aws_s3_access_point" "app_access" {
  bucket = aws_s3_bucket.bucket.id
  name   = "my-app-access-point"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:user/app-user"
        }
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:us-east-1:123456789012:accesspoint/my-app-access-point/object/*"
      }
    ]
  })

  # Optional: VPC configuration
  vpc_configuration {
    vpc_id = aws_vpc.main.id
  }
}
```

---

## 7️⃣ S3 Object Ownership

### What It Is
Controls who owns objects uploaded to your bucket and whether ACLs are enabled.

### Ownership Settings

#### BucketOwnerEnforced (Recommended)
```hcl
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```
- **Disables ACLs** completely
- Bucket owner owns all objects
- Recommended for new buckets

#### BucketOwnerPreferred
```hcl
rule {
  object_ownership = "BucketOwnerPreferred"
}
```
- ACLs enabled but bucket owner owns objects if `bucket-owner-full-control` ACL is used
- Good for migration from ACLs

#### ObjectWriter
```hcl
rule {
  object_ownership = "ObjectWriter"
}
```
- Object uploader owns the object (legacy behavior)
- ACLs fully enabled
- Not recommended

### When to Use
- ✅ **BucketOwnerEnforced** - For all new buckets (disables ACLs)
- ⚠️ **BucketOwnerPreferred** - When migrating from ACL-based permissions
- ❌ **ObjectWriter** - Only for legacy compatibility

---

## 📊 Access Control Decision Tree

```
Need to grant access to S3?
│
├─ Same AWS Account?
│  ├─ Yes → Use IAM Policy (attached to user/role)
│  └─ No → Use Bucket Policy (cross-account access)
│
├─ Make bucket public?
│  ├─ Yes → Use Bucket Policy with Principal: "*"
│  └─ No → Keep private
│
├─ Temporary access needed?
│  └─ Yes → Use Pre-Signed URLs
│
├─ VPC-only access?
│  └─ Yes → Use S3 Access Points with VPC config
│
├─ Multiple apps, different permissions?
│  └─ Yes → Use S3 Access Points
│
└─ Legacy application requiring ACLs?
   └─ Use ACLs (not recommended for new apps)
```

---

## 🎯 Best Practices

### 1. **Use IAM Policies as Default**
- Most flexible and powerful
- Easiest to audit
- Works with AWS services

### 2. **Enable Block Public Access**
- Always enable at account level
- Override only when necessary (public websites)

### 3. **Disable ACLs**
- Use `BucketOwnerEnforced` object ownership
- Rely on bucket policies and IAM policies instead

### 4. **Use Bucket Policies for Cross-Account Access**
- When granting access to other AWS accounts
- When adding conditions (IP, MFA, SSL)

### 5. **Principle of Least Privilege**
- Grant minimum permissions needed
- Use specific resources, not wildcards
- Add conditions when possible

### 6. **Regular Audits**
- Use AWS Access Analyzer
- Review bucket policies quarterly
- Check for public buckets

### 7. **Encrypt Everything**
- Enable default encryption
- Enforce SSL/TLS in bucket policies

---

## 📋 What Our Configuration Does

### Current Setup
```hcl
✅ Creates S3 bucket: policy-only-bucket-123456
✅ Blocks public ACLs (block_public_acls = true)
✅ Allows public policies (block_public_policy = false)
✅ Ignores public ACLs (ignore_public_acls = true)
✅ Allows normal public bucket access (restrict_public_buckets = false)
✅ Grants specific IAM user access via bucket policy
```

### Access Control Flow
1. **IAM User**: `arn:aws:iam::899673281289:user/alen_aws`
2. **Allowed Actions**: GetObject, PutObject, DeleteObject
3. **Public ACLs**: Blocked
4. **Public Policies**: Allowed (but our policy is user-specific, not public)

---

## 🔧 Usage

### Initialize Terraform
```bash
terraform init
```

### Plan Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Upload File
```bash
aws s3 cp sample.txt s3://policy-only-bucket-123456/
```

### Verify Policy
```bash
aws s3api get-bucket-policy --bucket policy-only-bucket-123456
```

### Destroy Resources
```bash
terraform destroy
```

---

## 📁 Project Files

- `main.tf` - Terraform configuration for bucket, public access block, and policy
- `policy.json` - Bucket policy granting access to specific IAM user

---

## 🔒 Security Recommendations

### For Production
1. **Enable all Block Public Access settings**
   ```hcl
   block_public_acls       = true
   block_public_policy     = true
   ignore_public_acls      = true
   restrict_public_buckets = true
   ```

2. **Disable ACLs**
   ```hcl
   resource "aws_s3_bucket_ownership_controls" "ownership" {
     bucket = aws_s3_bucket.bucket.id
     rule {
       object_ownership = "BucketOwnerEnforced"
     }
   }
   ```

3. **Enable versioning**
   ```hcl
   resource "aws_s3_bucket_versioning" "versioning" {
     bucket = aws_s3_bucket.bucket.id
     versioning_configuration {
       status = "Enabled"
     }
   }
   ```

4. **Enable encryption**
   ```hcl
   resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
     bucket = aws_s3_bucket.bucket.id
     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm = "AES256"
       }
     }
   }
   ```

5. **Require SSL/HTTPS**
   ```json
   {
     "Effect": "Deny",
     "Principal": "*",
     "Action": "s3:*",
     "Resource": "arn:aws:s3:::my-bucket/*",
     "Condition": {
       "Bool": {
         "aws:SecureTransport": "false"
       }
     }
   }
   ```

---

## 📚 Resources

- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [Bucket Policies and User Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-iam-policies.html)
- [Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [ACLs (Legacy)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html)
- [Pre-Signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html)
- [S3 Access Points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html)
- [Terraform S3 Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
