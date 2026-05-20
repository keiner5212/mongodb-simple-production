# MongoDB Simple Production

Single-node MongoDB 7.0 deployment on Debian EC2 with Docker Compose.

## Stack

- **mongo**: MongoDB 7.0 container with host bind-mounted volumes
- **mongo-backup**: Automated mongodump service (24h interval)
