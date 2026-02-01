# AWS S3 Static Website Hosting with Terraform

This project demonstrates how to host a static website on AWS S3 using Terraform, with proper public access configuration and bucket policies.

---

## 🌐 What This Project Does

Creates a **publicly accessible static website** hosted on Amazon S3 with:

1. **S3 Bucket** - Storage for website files
2. **Website Configuration** - Enables static website hosting with index and error pages
3. **Public Access Block** - Configured to allow public website access
4. **Bucket Policy** - Makes website content publicly readable

### Live Website
Once deployed, your website is accessible at:
```
http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com
```

---

## 📁 Project Structure

```
websiteHosting/
├── main.tf          # Terraform configuration
├── policy.json      # S3 bucket policy for public access
└── index.html       # Website homepage
```

---

## 🚀 Resources Created

### 1. S3 Bucket
```hcl
resource "aws_s3_bucket" "website" {
  bucket = "my-static-website-899673281289"
  
  tags = {
    Name        = "Static Website"
    Environment = "Dev"
  }
}
```

**Purpose:** Container for all website files

---

### 2. Website Configuration
```hcl
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
```

**What it does:**
- **index_document:** Default page shown when accessing the root URL or any directory
- **error_document:** Custom error page for 404 errors (optional)

**Result:** Enables static website hosting mode on the bucket

---

### 3. Public Access Block Settings
```hcl
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true   # Block public ACLs (we don't use ACLs)
  ignore_public_acls      = true   # Ignore any public ACLs
  block_public_policy     = false  # Allow public bucket policies (required!)
  restrict_public_buckets = false  # Allow public bucket access (required!)
}
```

**Why these settings?**
- ✅ `block_public_acls = true` - We don't use ACLs (modern approach)
- ✅ `ignore_public_acls = true` - Ignore any ACLs if present
- ✅ `block_public_policy = false` - **MUST be false** to allow public website
- ✅ `restrict_public_buckets = false` - **MUST be false** to allow public access

**Important:** For static websites, you MUST set `block_public_policy = false` and `restrict_public_buckets = false`!

---

### 4. Bucket Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForWebsite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-static-website-899673281289/*"
    }
  ]
}
```

**What it does:**
- **Principal: "*"** - Allows anyone (public access)
- **Action: "s3:GetObject"** - Allows reading/downloading objects
- **Resource:** Applies to all objects in the bucket (`/*`)

**Applied in Terraform:**
```hcl
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.website.id
  policy = file("${path.module}/policy.json")
  
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}
```

**Note:** `depends_on` ensures public access block is configured before applying the policy

---

## 🔧 Setup & Deployment

### Prerequisites
- AWS CLI configured
- Terraform installed
- AWS account with S3 permissions

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Review the Plan
```bash
terraform plan
```

Should show:
```
Plan: 4 to add, 0 to change, 0 to destroy.
```

### Step 3: Apply Configuration
```bash
terraform apply --auto-approve
```

### Step 4: Upload Website Files
```bash
# Upload index page
aws s3 cp index.html s3://my-static-website-899673281289/

# Optional: Upload error page
aws s3 cp error.html s3://my-static-website-899673281289/
```

### Step 5: Access Your Website
```bash
# Get website URL
echo "http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com"
```

Open the URL in your browser! 🎉

---

## 🌍 Website URL Format

S3 static website URLs follow this pattern:

```
http://<bucket-name>.s3-website.<region>.amazonaws.com
```

For this project:
```
http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com
```

**Note:** This is HTTP only. For HTTPS, you need CloudFront (covered later).

---

## 📝 Website Files

### index.html
```html
<!DOCTYPE html>
<html>
  <head>
    <title>S3 Website</title>
  </head>
  <body>
    <h1>🚀 S3 Static Website is Live!</h1>
  </body>
</html>
```

Simple homepage showing the website is working.

### error.html (Optional)
Create a custom error page:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>404 - Page Not Found</title>
  </head>
  <body>
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <a href="/">Go Home</a>
  </body>
</html>
```

---

## 🔍 Verification

### Check Bucket Configuration
```bash
aws s3api get-bucket-website --bucket my-static-website-899673281289
```

### Check Bucket Policy
```bash
aws s3api get-bucket-policy --bucket my-static-website-899673281289
```

### Check Public Access Block
```bash
aws s3api get-public-access-block --bucket my-static-website-899673281289
```

### List Uploaded Files
```bash
aws s3 ls s3://my-static-website-899673281289/
```

### Test Website Access
```bash
curl http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Access Denied" Error

**Problem:** Bucket policy or public access block misconfigured

**Solution:** Ensure:
```hcl
block_public_policy     = false  # MUST be false
restrict_public_buckets = false  # MUST be false
```

### Issue 2: "NoSuchWebsiteConfiguration"

**Problem:** Website hosting not enabled

**Solution:** Apply the Terraform configuration which includes `aws_s3_bucket_website_configuration`

### Issue 3: 403 Forbidden When Accessing Website

**Causes:**
1. Bucket policy not applied
2. Files not uploaded
3. Public access block preventing access

**Solutions:**
```bash
# Check if policy is applied
aws s3api get-bucket-policy --bucket my-static-website-899673281289

# Re-upload files with public-read ACL (if needed)
aws s3 cp index.html s3://my-static-website-899673281289/ --acl public-read

# Or rely on bucket policy (recommended)
aws s3 cp index.html s3://my-static-website-899673281289/
```

### Issue 4: Account-Level Block Public Access

**Error:** `public policies are prevented by the BlockPublicPolicy setting in S3 Block Public Access`

**Solution:** Check account-level settings:
```bash
aws s3control get-public-access-block --account-id 899673281289
```

If account-level blocking exists, disable it via AWS Console:
- S3 Console → Block Public Access settings for this account
- Uncheck "Block public and cross-account access..."

---

## 🎨 Expanding Your Website

### Add CSS
```bash
# Create style.css
cat > style.css << 'EOF'
body {
  font-family: Arial, sans-serif;
  text-align: center;
  padding: 50px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}
EOF

# Upload
aws s3 cp style.css s3://my-static-website-899673281289/
```

Update `index.html`:
```html
<head>
  <link rel="stylesheet" href="style.css">
</head>
```

### Add Multiple Pages
```bash
# Create about page
echo '<h1>About Us</h1>' > about.html
aws s3 cp about.html s3://my-static-website-899673281289/

# Access at:
# http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com/about.html
```

### Add Images
```bash
# Upload image
aws s3 cp logo.png s3://my-static-website-899673281289/images/

# Reference in HTML
<img src="images/logo.png" alt="Logo">
```

### Sync Entire Directory
```bash
# Sync local website folder to S3
aws s3 sync ./website/ s3://my-static-website-899673281289/ --delete
```

---

## 🔒 Security Best Practices

### 1. Read-Only Public Access
✅ Our policy only allows `s3:GetObject` (read)
❌ Never allow `s3:PutObject` or `s3:DeleteObject` publicly

### 2. Use HTTPS (via CloudFront)
For production, use CloudFront for:
- HTTPS/SSL support
- Custom domain names
- Better performance (CDN)
- DDoS protection

### 3. Enable Versioning
```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.website.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 4. Enable Logging
```hcl
resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.website.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "website-logs/"
}
```

### 5. Set Proper Content-Type
```bash
# Upload with correct MIME type
aws s3 cp index.html s3://my-static-website-899673281289/ \
  --content-type "text/html"

aws s3 cp style.css s3://my-static-website-899673281289/ \
  --content-type "text/css"
```

---

## 🌐 CORS (Cross-Origin Resource Sharing)

### What is CORS?

CORS is a security feature that controls which external domains can access resources from your S3 website. By default, browsers block requests from one domain to another (called cross-origin requests) unless the server explicitly allows it.

### When Do You Need CORS?

You need CORS configuration when:

- ✅ **Loading resources from S3 in a different domain** - Your website at `example.com` needs to load images/files from S3
- ✅ **AJAX/Fetch API calls** - JavaScript making requests to S3 from another domain
- ✅ **Web fonts** - Loading custom fonts from S3 to your website
- ✅ **API responses** - Accessing JSON/XML data stored in S3 from a web app
- ✅ **Canvas/WebGL** - Using images from S3 in HTML5 canvas

### Example Scenario

```
Your App:     https://myapp.com
S3 Bucket:    http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com

Without CORS: ❌ Browser blocks requests from myapp.com to S3
With CORS:    ✅ Requests allowed based on CORS rules
```

---

### CORS Configuration in Terraform

Add this to your `main.tf`:

```hcl
resource "aws_s3_bucket_cors_configuration" "website_cors" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
```

### CORS Rule Parameters Explained

#### 1. `allowed_methods`
HTTP methods permitted for cross-origin requests.

**Common values:**
```hcl
allowed_methods = ["GET"]              # Read-only (most common)
allowed_methods = ["GET", "HEAD"]      # Read + metadata
allowed_methods = ["GET", "PUT", "POST", "DELETE"]  # Full access (careful!)
```

**For static websites:** `["GET", "HEAD"]` is sufficient

#### 2. `allowed_origins`
Which domains can make cross-origin requests.

**Examples:**
```hcl
# Allow ALL origins (public website)
allowed_origins = ["*"]

# Allow specific domain only
allowed_origins = ["https://myapp.com"]

# Allow multiple domains
allowed_origins = [
  "https://myapp.com",
  "https://www.myapp.com",
  "https://staging.myapp.com"
]

# Allow all subdomains (not supported directly, list them individually)
allowed_origins = [
  "https://app1.example.com",
  "https://app2.example.com"
]
```

**Best Practice:** Be specific! Only use `["*"]` for truly public resources.

#### 3. `allowed_headers`
Which headers can be used in the actual request.

**Common values:**
```hcl
# Allow all headers (simple and permissive)
allowed_headers = ["*"]

# Specific headers only
allowed_headers = [
  "Authorization",
  "Content-Type",
  "x-amz-date",
  "x-amz-content-sha256"
]
```

#### 4. `expose_headers` (Optional)
Headers that browsers can access in the response.

**Common values:**
```hcl
# Expose ETag for caching
expose_headers = ["ETag"]

# Expose custom headers
expose_headers = [
  "ETag",
  "x-amz-meta-custom-header",
  "x-amz-request-id"
]
```

#### 5. `max_age_seconds` (Optional)
How long (in seconds) browsers can cache the CORS preflight response.

```hcl
max_age_seconds = 3000   # 50 minutes (common)
max_age_seconds = 86400  # 24 hours (maximum recommended)
```

**What it does:** Reduces preflight requests, improving performance.

---

### Multiple CORS Rules

You can define multiple rules for different use cases:

```hcl
resource "aws_s3_bucket_cors_configuration" "website_cors" {
  bucket = aws_s3_bucket.website.id

  # Rule 1: Public read access for GET requests
  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }

  # Rule 2: Specific domain for POST/PUT (uploads)
  cors_rule {
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://admin.myapp.com"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  # Rule 3: API domain for JSON data
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["https://api.myapp.com"]
    allowed_headers = ["Authorization", "Content-Type"]
    expose_headers  = ["Content-Length", "Content-Type"]
    max_age_seconds = 86400
  }
}
```

---

### CORS Configuration via AWS CLI

```bash
# Create CORS configuration file
cat > cors.json << 'EOF'
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF

# Apply CORS configuration
aws s3api put-bucket-cors \
  --bucket my-static-website-899673281289 \
  --cors-configuration file://cors.json

# View current CORS configuration
aws s3api get-bucket-cors \
  --bucket my-static-website-899673281289

# Delete CORS configuration
aws s3api delete-bucket-cors \
  --bucket my-static-website-899673281289
```

---

### Real-World CORS Examples

#### Example 1: Public Image Hosting
```hcl
cors_rule {
  allowed_methods = ["GET"]
  allowed_origins = ["*"]
  allowed_headers = ["*"]
  expose_headers  = ["Content-Length"]
  max_age_seconds = 86400
}
```
**Use case:** Hosting images/assets that any website can embed

#### Example 2: Web Font Hosting
```hcl
cors_rule {
  allowed_methods = ["GET"]
  allowed_origins = [
    "https://mywebsite.com",
    "https://www.mywebsite.com"
  ]
  allowed_headers = ["*"]
  max_age_seconds = 86400
}
```
**Use case:** Custom fonts loaded by your website (browsers require CORS for fonts!)

#### Example 3: JSON API Data
```hcl
cors_rule {
  allowed_methods = ["GET", "HEAD"]
  allowed_origins = [
    "https://app.example.com",
    "http://localhost:3000"  # For development
  ]
  allowed_headers = ["Authorization", "Content-Type"]
  expose_headers  = ["ETag", "Content-Type"]
  max_age_seconds = 3600
}
```
**Use case:** Fetching JSON data from S3 in a web application

#### Example 4: File Upload from Web App
```hcl
cors_rule {
  allowed_methods = ["PUT", "POST"]
  allowed_origins = ["https://upload.myapp.com"]
  allowed_headers = [
    "Content-Type",
    "Content-MD5",
    "x-amz-acl",
    "x-amz-meta-*"
  ]
  expose_headers  = ["ETag"]
  max_age_seconds = 3000
}
```
**Use case:** Direct browser uploads to S3 using pre-signed URLs

---

### Testing CORS Configuration

#### Using Browser Console
```javascript
// Open browser console on any website and run:
fetch('http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com/index.html')
  .then(response => response.text())
  .then(data => console.log(data))
  .catch(error => console.error('CORS Error:', error));
```

**Without CORS:** You'll see:
```
Access to fetch at '...' from origin 'https://example.com' has been blocked by CORS policy
```

**With CORS:** Request succeeds and returns data.

#### Using curl (Check Response Headers)
```bash
curl -I -X OPTIONS \
  -H "Origin: https://myapp.com" \
  -H "Access-Control-Request-Method: GET" \
  http://my-static-website-899673281289.s3-website.ap-south-1.amazonaws.com/
```

**Look for these headers in response:**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD
Access-Control-Max-Age: 3000
```

---

### CORS Troubleshooting

#### Issue 1: "No 'Access-Control-Allow-Origin' header"

**Cause:** CORS not configured or wrong origin

**Solution:**
```hcl
cors_rule {
  allowed_origins = ["*"]  # Or specific domain
  allowed_methods = ["GET"]
  allowed_headers = ["*"]
}
```

#### Issue 2: "Method Not Allowed"

**Cause:** HTTP method not in `allowed_methods`

**Solution:**
```hcl
# Add the missing method
allowed_methods = ["GET", "HEAD", "POST"]  # Add POST if needed
```

#### Issue 3: CORS Works in Postman but Not Browser

**Cause:** Browsers enforce CORS; Postman doesn't

**Solution:** This is normal. Configure CORS properly for browsers.

#### Issue 4: Wildcard with Credentials

**Error:** Cannot use wildcard origin with credentials

**Solution:**
```hcl
# Don't use "*" if sending credentials
allowed_origins = ["https://specific-domain.com"]
```

#### Issue 5: Font Loading Fails

**Cause:** Fonts require CORS headers

**Solution:**
```hcl
cors_rule {
  allowed_methods = ["GET"]
  allowed_origins = ["https://yourwebsite.com"]
  allowed_headers = ["*"]
}
```

---

### CORS Security Best Practices

#### 1. **Be Specific with Origins**
```hcl
# ❌ BAD: Too permissive
allowed_origins = ["*"]

# ✅ GOOD: Specific domains
allowed_origins = [
  "https://myapp.com",
  "https://www.myapp.com"
]
```

#### 2. **Limit Methods**
```hcl
# ❌ BAD: Allows modification
allowed_methods = ["GET", "PUT", "POST", "DELETE"]

# ✅ GOOD: Read-only for public
allowed_methods = ["GET", "HEAD"]
```

#### 3. **Don't Expose Sensitive Headers**
```hcl
# ❌ BAD: Exposes everything
expose_headers = ["*"]

# ✅ GOOD: Only necessary headers
expose_headers = ["ETag", "Content-Length"]
```

#### 4. **Use HTTPS Origins**
```hcl
# ❌ BAD: HTTP (insecure)
allowed_origins = ["http://myapp.com"]

# ✅ GOOD: HTTPS (secure)
allowed_origins = ["https://myapp.com"]
```

#### 5. **Separate Rules for Different Access Levels**
```hcl
# Public read
cors_rule {
  allowed_methods = ["GET"]
  allowed_origins = ["*"]
}

# Admin write (restricted)
cors_rule {
  allowed_methods = ["PUT", "DELETE"]
  allowed_origins = ["https://admin.myapp.com"]
}
```

---

### When NOT to Use CORS

You **don't need** CORS if:

- ❌ Users access S3 website **directly** (same origin)
- ❌ Server-side code making requests (CORS is browser-only)
- ❌ Mobile apps using AWS SDK (not browser-based)
- ❌ All resources on the same domain

---

### Complete Example with CORS

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "website" {
  bucket = "my-static-website-899673281289"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.website.id
  policy = file("${path.module}/policy.json")
  
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "website_cors" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
```

---

### CORS vs Bucket Policy

| Feature | CORS | Bucket Policy |
|---------|------|---------------|
| **Purpose** | Browser cross-origin requests | Resource access permissions |
| **Enforced By** | Browser | AWS S3 |
| **Controls** | Which domains can access | Who can access (authentication) |
| **Needed For** | JavaScript fetch/AJAX | All S3 access control |
| **Scope** | HTTP headers | IAM permissions |

**Both are needed:**
- **Bucket Policy** grants permission to access objects
- **CORS** tells browsers it's okay to make cross-origin requests

---

### CORS Headers Explained

When CORS is configured, S3 adds these headers to responses:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD
Access-Control-Allow-Headers: *
Access-Control-Expose-Headers: ETag
Access-Control-Max-Age: 3000
```

These headers tell the browser:
- ✅ Which origins are allowed
- ✅ Which HTTP methods are permitted
- ✅ Which headers can be sent
- ✅ Which response headers can be read
- ✅ How long to cache the preflight response

---

## 💰 Cost Considerations

### S3 Storage Costs
- **Storage:** ~$0.023 per GB/month (Standard class)
- **Requests:** $0.0004 per 1,000 GET requests
- **Data Transfer:** First 100 GB/month free, then $0.09/GB

### Example Monthly Cost
For a small website:
- 100 MB storage = $0.0023
- 10,000 page views = $0.004
- **Total: < $0.01/month** 🎉

### Cost Optimization
1. Use CloudFront (free tier: 1 TB/month transfer)
2. Enable S3 Intelligent-Tiering for infrequently accessed assets
3. Compress files (gzip) before uploading
4. Use caching headers

---

## 🚀 Next Steps

### Add Custom Domain (Route 53)
1. Register domain in Route 53
2. Create hosted zone
3. Point domain to S3 website endpoint
4. Bucket name must match domain name

### Enable HTTPS (CloudFront)
```hcl
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-Website"
  }
  
  enabled = true
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    
    viewer_protocol_policy = "redirect-to-https"
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

### Add Build Pipeline (CI/CD)
- GitHub Actions to auto-deploy on push
- S3 sync on every commit
- CloudFront cache invalidation

---

## 🧹 Cleanup

### Remove Website
```bash
# Delete all files from bucket
aws s3 rm s3://my-static-website-899673281289/ --recursive

# Destroy infrastructure
terraform destroy
```

**Note:** Terraform won't destroy a bucket with objects. Delete objects first!

---

## 📊 Monitoring

### CloudWatch Metrics
- **BucketSizeBytes** - Storage used
- **NumberOfObjects** - Object count
- **AllRequests** - Total requests

### Enable S3 Analytics
```bash
aws s3api put-bucket-analytics-configuration \
  --bucket my-static-website-899673281289 \
  --id website-analytics \
  --analytics-configuration file://analytics.json
```

---

## 📚 Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [S3 Website Endpoints](https://docs.aws.amazon.com/general/latest/gr/s3.html#s3_website_region_endpoints)
- [Terraform S3 Website Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration)
- [CloudFront + S3 Tutorial](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GettingStarted.SimpleDistribution.html)

---

## 🎯 Summary

You've successfully created:

✅ S3 bucket for static website hosting  
✅ Website configuration with index and error documents  
✅ Public access block settings (allowing public website)  
✅ Bucket policy for public read access  
✅ Uploaded HTML files  
✅ Live website accessible via S3 website endpoint  

**Your website is now live and accessible to anyone on the internet!** 🌐

---

## 🏷️ Tags

`#AWS` `#S3` `#Terraform` `#StaticWebsite` `#WebHosting` `#IaC` `#DevOps`
