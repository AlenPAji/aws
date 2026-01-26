# AWS S3 Storage Classes - Complete Guide

A simple guide to understanding S3 storage classes, organized from **most expensive to least expensive**. Each storage class is designed for different use cases based on how frequently you access your data.

## 💰 Cost Hierarchy (Highest to Lowest)

```
📊 COST SCALE
│
├─ 💸💸💸 S3 Standard (Most Expensive)
├─ 💸💸   S3 Intelligent-Tiering
├─ 💸💸   S3 Express One Zone
├─ 💸    S3 Standard-IA (Infrequent Access)
├─ 💸    S3 One Zone-IA
├─ 💵    S3 Glacier Instant Retrieval
├─ 💵    S3 Glacier Flexible Retrieval
└─ 💵    S3 Glacier Deep Archive (Least Expensive)
```

---

## 1️⃣ S3 Standard (💸💸💸)

**The Premium Tier - Instant Access Anytime**

### 📝 Simple Explanation
Like keeping all your files on your desk - instantly accessible but takes up premium space.

### ⚡ Key Features
- **Retrieval Time:** Milliseconds (instant)
- **Availability:** 99.99%
- **Durability:** 99.999999999% (11 9's)
- **Minimum Storage Duration:** None
- **Retrieval Fee:** None

### 💡 Best For
- Frequently accessed data
- Websites and mobile apps
- Content distribution
- Active databases
- Data analytics

### 💰 Pricing Example
- Storage: **~$0.023/GB per month**
- GET requests: $0.0004 per 1,000 requests
- PUT requests: $0.005 per 1,000 requests

### 📌 Use When
- You access data **daily or weekly**
- You need **immediate access** with no delays
- Performance is critical

### Terraform Example
```hcl
resource "aws_s3_object" "standard" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "active-data/current-report.pdf"
  source        = "report.pdf"
  storage_class = "STANDARD"
}
```

---

## 2️⃣ S3 Intelligent-Tiering (💸💸)

**The Smart Tier - Auto-Optimization**

### 📝 Simple Explanation
Like having a smart assistant who automatically moves your files between your desk and filing cabinet based on how often you use them.

### ⚡ Key Features
- **Retrieval Time:** Milliseconds (instant)
- **Auto-tiering:** Automatically moves data between tiers
- **Monitoring Fee:** $0.0025 per 1,000 objects
- **No Retrieval Fees:** For frequent and infrequent tiers
- **No Lifecycle Policies Needed:** Automatic optimization

### 🔄 How It Works
1. **Frequent Access Tier** (0-30 days) - Same price as Standard
2. **Infrequent Access Tier** (30-90 days) - 40% cheaper
3. **Archive Instant Access** (90-180 days) - 68% cheaper
4. **Archive Access** (180-365 days) - Optional, 71% cheaper
5. **Deep Archive Access** (365+ days) - Optional, 95% cheaper

### 💡 Best For
- Unpredictable access patterns
- Data with changing access frequency
- Cost optimization without manual management
- Unknown workloads

### 💰 Pricing Example
- Storage: **~$0.023/GB** (Frequent tier)
- Storage: **~$0.0125/GB** (Infrequent tier)
- Storage: **~$0.004/GB** (Archive Instant tier)
- Monitoring: $0.0025 per 1,000 objects

### 📌 Use When
- Access patterns are **unpredictable**
- You want **automatic cost optimization**
- You don't want to manage lifecycle policies
- Object size is **>128 KB** (charged minimum)

### Terraform Example
```hcl
resource "aws_s3_object" "intelligent" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "data/mixed-access-pattern.csv"
  source        = "data.csv"
  storage_class = "INTELLIGENT_TIERING"
}
```

---

## 3️⃣ S3 Express One Zone (💸💸)

**The Speed Demon - Ultra-Fast Single Zone**

### 📝 Simple Explanation
Like having a dedicated express lane for your most performance-critical files, but only in one location.

### ⚡ Key Features
- **Retrieval Time:** Single-digit milliseconds
- **Performance:** 10x faster than Standard
- **Availability:** 99.95% (single AZ)
- **Request Costs:** 50% lower than Standard
- **Durability:** 99.999999999% (within one AZ)

### 💡 Best For
- Latency-sensitive applications
- High-performance computing
- Machine learning training
- Analytics workloads requiring fast data access
- Applications that can't tolerate milliseconds of latency

### 💰 Pricing Example
- Storage: **~$0.16/GB per month** (higher than Standard)
- But: 50% lower request costs
- Optimized for: Compute-intensive workloads where speed matters

### 📌 Use When
- You need **ultra-low latency** (single-digit ms)
- Application is in the **same AWS region**
- High request rates
- Can accept single AZ durability

### ⚠️ Trade-off
Higher storage cost but saves on compute time and request costs for high-performance workloads.

### Terraform Example
```hcl
# Express One Zone requires directory bucket
resource "aws_s3_directory_bucket" "express" {
  bucket = "my-express-bucket--usw2-az1--x-s3"
  
  location {
    name = "usw2-az1"
    type = "AvailabilityZone"
  }
}
```

---

## 4️⃣ S3 Standard-IA (Infrequent Access) (💸)

**The Occasional Use Tier**

### 📝 Simple Explanation
Like keeping files in a nearby filing cabinet - quick to access but you pay a small fee each time you retrieve them.

### ⚡ Key Features
- **Retrieval Time:** Milliseconds
- **Availability:** 99.9%
- **Minimum Storage Duration:** 30 days
- **Minimum Object Size:** 128 KB
- **Retrieval Fee:** Yes ($0.01 per GB)

### 💡 Best For
- Backups
- Disaster recovery files
- Long-term storage accessed occasionally
- Data accessed less than once a month

### 💰 Pricing Example
- Storage: **~$0.0125/GB per month** (46% cheaper than Standard)
- Retrieval: $0.01 per GB retrieved
- PUT requests: $0.01 per 1,000 requests

### 📌 Use When
- Access data **once a month or less**
- Files are **larger than 128 KB**
- Can keep files for **at least 30 days**

### 💵 Cost Calculation
If you access less than **~50% of data per month**, IA is cheaper than Standard.

### Terraform Example
```hcl
resource "aws_s3_object" "backup" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "backups/monthly-backup.zip"
  source        = "backup.zip"
  storage_class = "STANDARD_IA"
}
```

---

## 5️⃣ S3 One Zone-IA (💸)

**The Budget Tier - Single Zone**

### 📝 Simple Explanation
Like Standard-IA but stored in only one location (instead of three), making it 20% cheaper but less resilient.

### ⚡ Key Features
- **Retrieval Time:** Milliseconds
- **Availability:** 99.5%
- **Durability:** 99.999999999% (in one AZ only)
- **Minimum Storage Duration:** 30 days
- **Minimum Object Size:** 128 KB
- **Retrieval Fee:** Yes ($0.01 per GB)

### 💡 Best For
- Reproducible data
- Secondary backup copies
- Data you can recreate if lost
- Non-critical infrequently accessed data

### 💰 Pricing Example
- Storage: **~$0.01/GB per month** (20% cheaper than Standard-IA)
- Retrieval: $0.01 per GB retrieved

### 📌 Use When
- Data can be **easily recreated**
- Don't need multi-AZ resilience
- Want the **cheapest infrequent access** option
- Not mission-critical data

### ⚠️ Risk
If the Availability Zone fails, you could lose your data. Only use for replaceable data!

### Terraform Example
```hcl
resource "aws_s3_object" "reproducible" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "temp/thumbnail-cache.jpg"
  source        = "thumbnail.jpg"
  storage_class = "ONEZONE_IA"
}
```

---

## 6️⃣ S3 Glacier Instant Retrieval (💵)

**The Archive Tier - Instant Access**

### 📝 Simple Explanation
Like storing files in a cold storage vault, but with a special "instant access" service - cheaper storage but higher retrieval fees.

### ⚡ Key Features
- **Retrieval Time:** Milliseconds (instant)
- **Availability:** 99.9%
- **Minimum Storage Duration:** 90 days
- **Minimum Object Size:** 128 KB
- **Retrieval Fee:** Yes ($0.03 per GB)

### 💡 Best For
- Archive data needing instant access
- Medical images
- News media assets
- User-generated content archives
- Data accessed once per quarter

### 💰 Pricing Example
- Storage: **~$0.004/GB per month** (68% cheaper than Standard)
- Retrieval: $0.03 per GB retrieved (3x more than IA)

### 📌 Use When
- Access data **quarterly or yearly**
- Need **instant access** when you do retrieve
- Can store for **at least 90 days**
- Retrieval is rare

### 💵 Cost Calculation
Break-even: If you retrieve less than **~13% of data per month**, Glacier Instant is cheaper than Standard-IA.

### Terraform Example
```hcl
resource "aws_s3_object" "archive" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "archives/2025-q4-reports.pdf"
  source        = "q4-reports.pdf"
  storage_class = "GLACIER_IR"
}
```

---

## 7️⃣ S3 Glacier Flexible Retrieval (💵)

**The Cold Storage Tier**

### 📝 Simple Explanation
Like storing boxes in a warehouse off-site - very cheap to store, but takes hours to retrieve when you need them.

### ⚡ Key Features
- **Retrieval Time:** Minutes to hours
  - Expedited: 1-5 minutes ($0.03/GB)
  - Standard: 3-5 hours ($0.01/GB)
  - Bulk: 5-12 hours ($0.0025/GB)
- **Minimum Storage Duration:** 90 days
- **Minimum Object Size:** 40 KB

### 💡 Best For
- Long-term backups
- Compliance archives
- Digital preservation
- Data accessed once or twice a year
- Regulatory archives

### 💰 Pricing Example
- Storage: **~$0.0036/GB per month** (84% cheaper than Standard)
- Retrieval (Standard): $0.01 per GB + $0.02 per 1,000 requests

### 📌 Use When
- Access data **once or twice per year**
- Can wait **3-5 hours** for retrieval
- Need to keep for **compliance** reasons
- Cost is more important than speed

### 🕐 Retrieval Options
- **Expedited:** Emergency access in 1-5 minutes
- **Standard:** Normal access in 3-5 hours (most common)
- **Bulk:** Cheapest, 5-12 hours for large amounts

### Terraform Example
```hcl
resource "aws_s3_object" "compliance" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "compliance/2023-tax-records.zip"
  source        = "tax-records.zip"
  storage_class = "GLACIER"
}
```

---

## 8️⃣ S3 Glacier Deep Archive (💵)

**The Ultra-Cold Tier - Cheapest Storage**

### 📝 Simple Explanation
Like storing boxes in a remote warehouse far away - incredibly cheap but takes up to 12 hours to retrieve.

### ⚡ Key Features
- **Retrieval Time:** 12-48 hours
  - Standard: 12 hours ($0.02/GB)
  - Bulk: 48 hours ($0.0025/GB)
- **Minimum Storage Duration:** 180 days (6 months)
- **Minimum Object Size:** 40 KB
- **Cheapest S3 Storage:** Yes!

### 💡 Best For
- Long-term data retention (7-10 years)
- Regulatory archives
- Magnetic tape replacement
- Data you rarely or never access
- Compliance archives

### 💰 Pricing Example
- Storage: **~$0.00099/GB per month** (95% cheaper than Standard!)
- Retrieval (Standard): $0.02 per GB + $0.05 per 1,000 requests

### 📌 Use When
- Access data **very rarely** (once a year or never)
- Can wait **12-48 hours** for retrieval
- Need to keep for **7+ years**
- Meeting regulatory requirements (e.g., financial records)
- Replacing tape backups

### 💵 Cost Comparison
Storing 1 TB for 7 years:
- **Standard:** ~$1,932
- **Deep Archive:** ~$83 (96% savings!)

### ⚠️ Important
If you delete before 180 days, you're charged for the full 180 days anyway!

### Terraform Example
```hcl
resource "aws_s3_object" "long_term" {
  bucket        = aws_s3_bucket.mybucket.id
  key           = "legal/2019-case-files.zip"
  source        = "case-files.zip"
  storage_class = "DEEP_ARCHIVE"
}
```

---

## 📊 Quick Comparison Table

| Storage Class | Retrieval Time | Min Storage | Retrieval Fee | Monthly Cost/GB | Best For |
|---------------|----------------|-------------|---------------|-----------------|----------|
| **S3 Standard** | Milliseconds | None | None | $0.023 | Daily access |
| **Intelligent-Tiering** | Milliseconds | None | None* | $0.023-$0.001 | Unknown patterns |
| **Express One Zone** | <10ms | None | None | $0.16 | Ultra-low latency |
| **Standard-IA** | Milliseconds | 30 days | $0.01/GB | $0.0125 | Monthly access |
| **One Zone-IA** | Milliseconds | 30 days | $0.01/GB | $0.01 | Replaceable data |
| **Glacier Instant** | Milliseconds | 90 days | $0.03/GB | $0.004 | Quarterly access |
| **Glacier Flexible** | 3-5 hours | 90 days | $0.01/GB | $0.0036 | Yearly access |
| **Deep Archive** | 12-48 hours | 180 days | $0.02/GB | $0.00099 | Rarely/never |

*Monitoring fee applies

---

## 🎯 Decision Tree - Which Storage Class Should I Use?

```
START: How often do I access this data?

├─ DAILY/WEEKLY
│  ├─ Need ultra-low latency? → Express One Zone
│  └─ Standard access → S3 Standard
│
├─ MONTHLY
│  ├─ Unpredictable pattern? → Intelligent-Tiering
│  ├─ Can recreate if lost? → One Zone-IA
│  └─ Need durability → Standard-IA
│
├─ QUARTERLY (every 3 months)
│  └─ Need instant access → Glacier Instant Retrieval
│
├─ YEARLY (1-2 times/year)
│  └─ Can wait hours → Glacier Flexible Retrieval
│
└─ RARELY/NEVER (compliance only)
   └─ Can wait 12+ hours → Glacier Deep Archive
```

---

## 💡 Smart Tips for Choosing

### 1. **Frequency Rule of Thumb**
- **Daily access:** Standard
- **Weekly access:** Standard or Intelligent-Tiering
- **Monthly access:** Standard-IA
- **Quarterly access:** Glacier Instant Retrieval
- **Yearly access:** Glacier Flexible Retrieval
- **Archival (7+ years):** Glacier Deep Archive

### 2. **Cost Optimization**
- Use **Lifecycle Policies** to automatically transition data
- Start with **Intelligent-Tiering** if unsure
- Consider **minimum storage duration** charges
- Factor in **retrieval costs**, not just storage

### 3. **Common Mistakes to Avoid**
- ❌ Don't use IA classes for files <128 KB (charged for 128 KB anyway)
- ❌ Don't use Deep Archive if you might need data soon (180-day minimum)
- ❌ Don't use One Zone-IA for critical data (single point of failure)
- ❌ Don't forget retrieval fees when calculating costs

---

## 🔄 Lifecycle Policy Example

Automatically transition data through storage classes:

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    id     = "auto-archive"
    status = "Enabled"

    # Start in Standard
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    # Move to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete after 7 years
    expiration {
      days = 2555  # ~7 years
    }
  }
}
```

---

## 💰 Real-World Cost Example

**Scenario:** Storing 1 TB of data for 1 year

| Storage Class | Storage Cost | Retrieval (10%) | Total Annual Cost |
|---------------|--------------|-----------------|-------------------|
| Standard | $276 | $0 | **$276** |
| Standard-IA | $150 | $10 | **$160** |
| Glacier Instant | $48 | $30 | **$78** |
| Glacier Flexible | $43 | $10 | **$53** |
| Deep Archive | $12 | $20 | **$32** |

*Assumes 10% of data retrieved once during the year*

---

## 📚 Resources

- [AWS S3 Storage Classes Overview](https://aws.amazon.com/s3/storage-classes/)
- [S3 Pricing Calculator](https://calculator.aws/#/addService/S3)
- [Terraform S3 Object Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)
- [S3 Lifecycle Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)

---

## 🎓 Remember

**The Golden Rule:** The less frequently you access data, the cheaper it should be to store, but the more expensive (in time or money) it is to retrieve.

Choose based on:
1. **Access frequency** - How often you need the data
2. **Retrieval speed** - How fast you need it back
3. **Durability needs** - Can you afford to lose it?
4. **Budget** - Balance storage vs retrieval costs
