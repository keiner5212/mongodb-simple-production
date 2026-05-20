# Hardware Recommendations

## EC2 Instance Types

| Use Case | Instance | vCPU | RAM | Price/mo |
|---|---|---|---|---|
| Development | t3.medium | 2 | 4 GiB | ~$30 |
| Small Production | t3.large | 2 | 8 GiB | ~$60 |
| Medium Production | r6i.xlarge | 4 | 32 GiB | ~$160 |
| Large Production | r6i.2xlarge | 8 | 64 GiB | ~$320 |

Prices are approximate (us-east-1, on-demand, Linux).

## Storage

Use [EBS Pricing Calculator](https://cloudburn.io/tools/amazon-ebs-pricing-calculator?storageGB=10&region=eu-north-1) to estimate costs.

Bind mounts to host directories:

| Purpose | Host Path | Estimate |
|---|---|---|
| Data + indexes | `/var/lib/mongodb/data` | Data size + 30% buffer |
| Config | `/var/lib/mongodb/config` | ~10 MB |
| Backups | `/var/backups/mongodb` | 2x largest backup |

gp3 recommended (cheaper, independent IOPS/throughput). For >16k IOPS needs, use io2.

## Memory

OS and services overhead on dedicated host:
- Debian + Docker: ~500-800 MB
- mongo-backup container: ~100-200 MB (idle)
- Total overhead: ~1 GB

Recommended `MONGO_MEMORY_LIMIT` (leave 1GB for OS):

| Instance | Total RAM | MONGO_MEMORY_LIMIT | WiredTiger Cache |
|---|---|---|---|
| t3.medium | 4 GiB | 3g | ~1.5 GB |
| t3.large | 8 GiB | 7g | ~3.5 GB |
| r6i.xlarge | 32 GiB | 30g | ~15 GB |
| r6i.2xlarge | 64 GiB | 62g | ~31 GB |

WiredTiger cache = 50% of `MONGO_MEMORY_LIMIT`.

## Network
- Security group: allow SSH (22) + MongoDB (27017) from trusted IPs only

## Scaling

Vertical: stop, change instance type, start

Horizontal (sharding): not covered by this stack
