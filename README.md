# Backing Services (Infrastructure)

![Docker](https://img.shields.io/badge/Docker-Container-2496ED)
![Docker Compose](https://img.shields.io/badge/Orchestration-Compose-2496ED)
![SeaweedFS](https://img.shields.io/badge/Storage-SeaweedFS-blue)
![Nginx](https://img.shields.io/badge/Proxy-Nginx-009639)
![AWS CLI](https://img.shields.io/badge/Tools-AWS%20CLI-232F3E)
![License](https://img.shields.io/badge/License-MIT-green)

The **Backing Services** directory contains the foundational infrastructure and third-party dependencies required to run the **YouTube Data Hub** microservices locally. 

Instead of relying on costly cloud providers during development, this module provisions self-hosted, cloud-compatible alternatives (e.g., S3-compatible Object Storage).

## 🏗️ Architecture & Role

*   **Object Storage (SeaweedFS)**: A highly scalable, AWS S3-compatible object storage system. It acts as the primary data lake for storing large binary files such as YouTube video thumbnails.
*   **Edge Gateway (Nginx)**: A reverse proxy sitting in front of the storage layer. It provides security, hides internal service ports, and can be configured for hotlink protection or caching.
*   **Initialization Automation**: Ephemeral (short-lived) containers (like `s3-setup` using standard AWS CLI) that run on startup to automatically provision necessary resources like buckets and public read policies, ensuring zero manual setup.

### Design Philosophy
*   **Cloud Agnostic**: By using standard AWS S3 APIs internally, backend services (like YouTube Hub or Downloader) can seamlessly switch between this local SeaweedFS instance and real AWS S3/MinIO in production just by changing environment variables.
*   **Infrastructure as Code (IaC)**: Everything is defined in `docker-compose.yml`, ensuring that the development environment is perfectly reproducible across different machines.
*   **Network Isolation**: Backing services operate within a dedicated Docker network (`shared-services-network`) with static IP assignments to ensure reliable communication with the microservices layer.

## 🚀 Key Features

*   **S3 Drop-in Replacement**: Fully compatible with AWS SDKs.
*   **Auto-Provisioning**: Automatic creation of default buckets and IAM policies on the first boot.
*   **Secure Routing**: Internal ports (e.g., 9000, 8888) are isolated; traffic is strictly routed through the Nginx proxy.
*   **Persistent Storage**: Volume mapping ensures that data survives container restarts.

## 🛠️ Tech Stack

*   **Containerization**: Docker & Docker Compose
*   **Storage Backend**: SeaweedFS (`chrislusf/seaweedfs`)
*   **Reverse Proxy**: Nginx Alpine
*   **CLI Tools**: Amazon AWS CLI (for automated initialization)

## 📦 Prerequisites

*   Docker Engine (20.10+)
*   Docker Compose (V2+)

## ⚙️ Configuration

Configuration is managed via environment variables. Ensure you have an `.env` file in the root directory or adjacent to the `docker-compose.yml` file.

Example `.env` configuration:

```properties
# ---------------------------------------------------------------------------
# Storage Settings
# ---------------------------------------------------------------------------
# Where the physical files should be stored on the host machine
S3_DATA_PATH=./data/storage

# Port exposed to the host machine via Nginx Proxy
S3_API_PORT=9000

# The default bucket to be created automatically by the setup script
DEFAULT_BUCKET_NAME=youtube-thumbnails

# Root Administrator Credentials
S3_ROOT_USER=admin
S3_ROOT_PASSWORD=SuperSecretPassword123!

# Service Account Credentials (For Hub and Downloader to use)
S3_SVC_ACCESS_KEY=backend-svc
S3_SVC_SECRET_KEY=BackendServiceSecret456!
```

## 🏃‍♂️ Build & Run

Since these are pre-built Docker images, no compilation is required.

```bash
# 1. Navigate to the object storage directory
cd object-storage

# 2. Create the shared network if it doesn't exist yet (usually created by the platform script)
docker network create shared-services-network || true

# 3. Start the services in detached mode
docker-compose up -d
```

### Checking Service Status

To verify that the setup container successfully created the bucket:

```bash
docker logs s3-setup
```

*Note: The `s3-setup` container is designed to exit automatically after it finishes creating the buckets. This is normal and expected behavior.*

## 🔌 Exposed Ports & Network

Services in this module attach to the `shared-services-network`.

*   **S3 Proxy (Nginx)**: 
    *   **IP**: `172.16.10.20`
    *   **Port**: `${S3_API_PORT}` (Default: `9000`)
    *   *Usage*: All backend microservices should connect to this endpoint for S3 operations.
*   **S3 Core (SeaweedFS)**: 
    *   **IP**: `172.16.10.21`
    *   *Usage*: Internal storage engine. Do not connect directly from applications.

## 📜 License

MIT
