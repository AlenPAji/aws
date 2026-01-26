# AWS S3 Metadata with Terraform

This project demonstrates how to use metadata with AWS S3 objects to store additional information about your files.

## What is S3 Metadata?

S3 metadata is a set of name-value pairs that provide additional information about an object stored in S3. There are two types of metadata:

### 1. System-Defined Metadata
Automatically set by S3 and cannot be modified:
- `Content-Type` - MIME type of the object
- `Content-Length` - Size of the object
- `Last-Modified` - Date the object was last modified
- `ETag` - Entity tag (checksum) of the object

### 2. User-Defined Metadata
Custom metadata you define with `x-amz-meta-` prefix:
- `x-amz-meta-author` - Author of the file
- `x-amz-meta-project` - Project name
- `x-amz-meta-version` - File version
- Any custom key-value pair you need

## Terraform Implementation

### Basic Metadata Example

```hcl
resource "aws_s3_object" "object" {
  bucket       = aws_s3_bucket.default.id
  key          = "document.pdf"
  source       = "document.pdf"
  content_type = "application/pdf"
  
  metadata = {
    author      = "John Doe"
    department  = "Engineering"
    project     = "ProjectX"
    version     = "1.0"
    created_by  = "terraform"
  }
}
```

### Common Metadata Attributes

```hcl
resource "aws_s3_object" "example" {
  bucket = aws_s3_bucket.default.id
  key    = "file.txt"
  source = "file.txt"
  
  # Standard HTTP headers
  content_type        = "text/plain"
  content_encoding    = "gzip"
  content_language    = "en-US"
  content_disposition = "attachment; filename=\"file.txt\""
  cache_control       = "max-age=3600"
  
  # Custom metadata
  metadata = {
    environment = "production"
    owner       = "team@example.com"
    cost_center = "12345"
  }
  
  # Tags (different from metadata)
  tags = {
    Environment = "Production"
    Team        = "Engineering"
  }
}
```

## Metadata vs Tags

| Feature | Metadata | Tags |
|---------|----------|------|
| **Purpose** | Object-level information | Resource management & billing |
| **Access** | Retrieved with object | Retrieved separately via API |
| **Use case** | File properties, content info | Organization, cost allocation |
| **Limit** | 2KB per object | 50 tags per object |
| **Naming** | `x-amz-meta-*` prefix | Key-value pairs |

## Use Cases

### 1. Document Management
```hcl
metadata = {
  document_id    = "DOC-12345"
  version        = "2.1"
  author         = "Jane Smith"
  department     = "Legal"
  classification = "confidential"
  expiry_date    = "2027-01-01"
}
```

### 2. Media Files
```hcl
metadata = {
  resolution  = "1920x1080"
  duration    = "120"
  codec       = "h264"
  bitrate     = "5000"
  camera      = "Canon EOS R5"
}
```

### 3. Data Processing
```hcl
metadata = {
  processed_date = "2026-01-27"
  processor      = "lambda-function-v2"
  source_system  = "data-pipeline"
  record_count   = "10000"
  checksum       = "abc123def456"
}
```

### 4. Version Control
```hcl
metadata = {
  version       = "3.2.1"
  git_commit    = "a1b2c3d4"
  build_number  = "1234"
  release_date  = "2026-01-27"
}
```

## Retrieving Metadata

### Using AWS CLI

```bash
# Get all metadata for an object
aws s3api head-object --bucket my-bucket --key my-file.txt

# Get specific metadata field
aws s3api head-object --bucket my-bucket --key my-file.txt --query 'Metadata.author'
```

### Using Terraform Output

```hcl
output "object_metadata" {
  value = aws_s3_object.object.metadata
}

output "content_type" {
  value = aws_s3_object.object.content_type
}
```

## Best Practices

1. **Use meaningful keys** - Make metadata self-documenting
2. **Keep it small** - Maximum 2KB total metadata per object
3. **Use lowercase** - Metadata keys are case-insensitive but stored lowercase
4. **Don't store sensitive data** - Metadata is not encrypted separately
5. **Use tags for billing** - Use S3 tags for cost allocation, not metadata
6. **Document your schema** - Maintain a list of standard metadata fields
7. **Validate values** - Ensure metadata values follow your conventions

## Common Content Types

```hcl
# Documents
content_type = "application/pdf"
content_type = "application/msword"
content_type = "application/vnd.ms-excel"

# Images
content_type = "image/jpeg"
content_type = "image/png"
content_type = "image/svg+xml"

# Video
content_type = "video/mp4"
content_type = "video/quicktime"

# Text
content_type = "text/plain"
content_type = "text/html"
content_type = "text/csv"

# JSON/XML
content_type = "application/json"
content_type = "application/xml"
```

## Updating Metadata

To update metadata, you must re-upload the object or copy it in place:

```bash
# Copy object to itself with new metadata
aws s3 cp s3://bucket/key s3://bucket/key --metadata author="New Author" --metadata-directive REPLACE
```

In Terraform, simply update the metadata block and apply:
```bash
terraform apply
```

## Limitations

- Maximum 2KB of user-defined metadata per object
- Metadata keys are converted to lowercase
- Cannot update metadata without re-uploading or copying object
- Metadata is not encrypted separately from the object
- No metadata searching in S3 (use S3 Inventory or tags instead)

## Resources

- [AWS S3 Object Metadata](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingMetadata.html)
- [Terraform aws_s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)
- [S3 HTTP Headers](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUT.html)
