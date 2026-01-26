# AWS S3 Checksum with Terraform

This project demonstrates how to use checksums (ETags) with AWS S3 objects to ensure data integrity and enable automatic updates when file content changes.

## What is a Checksum?

A checksum is a calculated value used to verify the integrity of data. In AWS S3, the **ETag** (entity tag) serves as a checksum to:
- Verify file integrity during upload
- Detect file changes
- Enable efficient file synchronization
- Prevent duplicate uploads

## How It Works

### ETag in S3

When you upload a file to S3, AWS automatically generates an ETag:
- For simple uploads: ETag = MD5 hash of the file
- For multipart uploads: ETag = MD5 hash of concatenated MD5 hashes + part count

### Terraform Implementation

In this configuration, we use `filemd5()` function to compute the MD5 checksum:

```hcl
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.default.id
  key    = "my_file.txt"
  source = "my_file.txt"
  etag   = filemd5("my_file.txt")
}
```

**Benefits:**
1. **Automatic Updates**: Terraform detects when `my_file.txt` content changes and re-uploads it
2. **Data Integrity**: Ensures uploaded file matches local file
3. **Idempotency**: Prevents unnecessary uploads when content hasn't changed

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Create or modify `my_file.txt`:**
   ```bash
   echo "Hello, AWS!" > my_file.txt
   ```

3. **Apply configuration:**
   ```bash
   terraform apply
   ```

4. **Modify the file and reapply:**
   ```bash
   echo "Updated content" > my_file.txt
   terraform apply
   ```
   Terraform will detect the checksum change and upload the new version.

## Verification

You can verify the ETag in AWS:

```bash
aws s3api head-object --bucket <bucket-name> --key my_file.txt
```

Compare with local checksum:
```bash
md5sum my_file.txt
```

## Other Checksum Algorithms

AWS S3 also supports additional checksum algorithms for enhanced data integrity:

- **SHA-1**: `source_hash = filesha1("my_file.txt")`
- **SHA-256**: `source_hash = filesha256("my_file.txt")`
- **SHA-512**: Not directly supported by `aws_s3_object`

Example with SHA-256:
```hcl
resource "aws_s3_object" "object" {
  bucket      = aws_s3_bucket.default.id
  key         = "my_file.txt"
  source      = "my_file.txt"
  source_hash = filesha256("my_file.txt")
}
```

## Best Practices

1. **Always use checksums** for production deployments to ensure data integrity
2. **Use `etag`** for standard uploads (simple and efficient)
3. **Use `source_hash`** when you need specific hash algorithms
4. **Monitor changes** - Terraform will show when files will be re-uploaded due to checksum changes
5. **Version your buckets** - Enable S3 versioning to keep file history

## Files

- `main.tf` - Terraform configuration with checksum implementation
- `my_file.txt` - Sample file to upload
- `.gitignore` - Excludes Terraform state and lock files

## Resources

- [AWS S3 ETag Documentation](https://docs.aws.amazon.com/AmazonS3/latest/API/API_Object.html)
- [Terraform filemd5() Function](https://www.terraform.io/language/functions/filemd5)
- [AWS S3 Data Integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html)
