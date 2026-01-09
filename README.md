# stage0_runbook_template

This is a GitHub Template Repo that you have used to create your own Custom, Deployable Runbook. Complete the following steps to customize it for your team:

## Template Setup Instructions

1. **Create a new repo using this template and clone it** (you're off to a great start!)
2. **Configure the Makefile** to provide the ghcr image name in `make container`
3. **Configure the Dockerfile** to install any CLI utilities your scripts may need (GitHub CLI, AWS CLI, etc.)
4. **Configure the docker-compose.yaml** to use the ghcr image you build
5. **Configure the GitHub Action docker-push workflow** to push your ghcr package
   - You will need to set up the ghcr package for this to work.

---

# Welcome

Write a warm welcome to the team's runbooks repo. This is where you write, test, and package runbooks for the team.

## Quick Start (Users Guide)

```sh
# Run the system with packaged runbooks.
make deploy

# Shut down the containers when you're done
make down
```

## Quick Start (Script Author Guide)

```sh
# Run the tool in Dev mode (mounts ./runbooks)
make dev

# Package runbooks into custom container
make container

# Open the WebUI 
make open

# Validate a runbook (assumes API is running in dev mode)
RUNBOOK=./runbooks/test-a-book.md ENV="[]" make validate

# Execute a runbook (assumes API is running)
RUNBOOK=./runbooks/test-a-book.md ENV="[]" make execute
```

---

# Customizing your Dockerfile

The base `stage0_runbook_api` image includes:
- Python 3.12 and pipenv
- zsh (required for runbook scripts)
- The runbook runner utility
- Flask API server with Gunicorn
- Prometheus metrics endpoint

For runbooks that need additional tools (like Docker CLI, GitHub CLI, AWS CLI, etc.), you can extend the base image. This is especially useful when you want to package approved tools with your runbook execution environment.

## Using the Extended Image

An extended image is available that includes Docker CLI and GitHub CLI:

```yaml
services:
  api:
    image: ghcr.io/agile-learning-institute/stage0_runbook_api:extended
    # ... rest of configuration
```

This image is useful for runbooks that need to:
- Build and push Docker images
- Interact with GitHub repositories
- Use Docker-in-Docker capabilities

**Note**: When using Docker CLI, you'll need to mount the Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Creating Custom Extended Images

You can create your own extended Dockerfile based on your specific needs. Here are common patterns:

### Pattern 1: Add Single Tool

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest

# Add your custom tool
RUN apt-get update && \
    apt-get install -y --no-install-recommends your-tool && \
    rm -rf /var/lib/apt/lists/*

# Or install from a package manager
RUN curl -fsSL https://your-tool-installer.sh | sh
```

### Pattern 2: Add Multiple Tools

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tool1 \
        tool2 \
        tool3 && \
    rm -rf /var/lib/apt/lists/*

# Install tools from other sources
RUN curl -fsSL https://tool-installer.sh | sh
```

### Pattern 3: Extend the Extended Image

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:extended

# Add additional tools beyond Docker CLI and GitHub CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        awscli \
        terraform && \
    rm -rf /var/lib/apt/lists/*
```

## Example: AWS CLI Extension

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest

# Install AWS CLI v2
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    rm -rf /var/lib/apt/lists/*

# Verify installation
RUN aws --version
```

## Example: Terraform Extension

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest

# Install Terraform
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        software-properties-common && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Verify installation
RUN terraform version
```

## Packaging Runbooks

You can package a collection of verified runbooks directly into a container image. This is useful for:
- Creating approved runbook collections
- Distributing runbooks without external volume mounts
- Ensuring runbook version consistency
- Creating immutable runbook execution environments

### Basic Runbook Packaging

Create a Dockerfile that packages runbooks:

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:latest

# Create directory for runbooks
RUN mkdir -p /opt/stage0/runbooks

# Copy runbooks folder into the container
# Assumes runbooks are in ./runbooks/ relative to build context
COPY runbooks/ /opt/stage0/runbooks/

# Set working directory to runbooks location for convenience
WORKDIR /opt/stage0/runbooks
```

Build and use:

```bash
# Build the image with runbooks
docker build -f Dockerfile -t my-runbooks:latest .

# Run a packaged runbook
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e GITHUB_TOKEN=$GITHUB_TOKEN \
    my-runbooks:latest \
    runbook execute --runbook /opt/stage0/runbooks/my-runbook.md
```

### Packaging with Tools

Combine tool extensions with runbook packaging:

```dockerfile
FROM ghcr.io/agile-learning-institute/stage0_runbook_api:extended

# Create directory for runbooks
RUN mkdir -p /opt/stage0/runbooks

# Copy runbooks
COPY runbooks/ /opt/stage0/runbooks/

# Set working directory
WORKDIR /opt/stage0/runbooks
```

This gives you:
- Docker CLI and GitHub CLI (from extended base)
- Your packaged runbooks
- All in one immutable image

### Reference Examples

The Stage0 Runbook API repository includes example Dockerfiles in the `samples/` directory that you can reference:

- **Dockerfile.extended**: Extends the base image with Docker CLI and GitHub CLI
- **Dockerfile.with-runbooks**: Packages a collection of runbooks into the container
- **Dockerfile.extended-with-runbooks**: Combines both approaches (tools and packaged runbooks)

See the [SRE Documentation](https://github.com/agile-learning-institute/stage0_runbooks/blob/main/SRE.md) for more details on these examples.

---

# Customizing your docker-compose

The `docker-compose.yaml` file configures how your runbook system runs. Here are common customization patterns:

## Basic Development Setup

For local development with volume-mounted runbooks:

```yaml
services:
  api:
    image: ghcr.io/agile-learning-institute/stage0_runbook_api:latest
    container_name: stage0_runbook_api
    restart: unless-stopped
    ports:
      - "8083:8083"
    environment:
      API_PORT: 8083
      RUNBOOKS_DIR: /workspace/runbooks
      ENABLE_LOGIN: "true"
      LOGGING_LEVEL: "INFO"
    volumes:
      - ./runbooks:/workspace/runbooks:ro
    working_dir: /workspace/runbooks
    command: runbook serve --runbooks-dir /workspace/runbooks --port 8083

  spa:
    image: ghcr.io/agile-learning-institute/stage0_runbook_spa:latest
    container_name: stage0_runbook_spa
    restart: unless-stopped
    ports:
      - "8084:80"
    environment:
      API_HOST: api
      API_PORT: 8083
    depends_on:
      api:
        condition: service_started
```

## Using Packaged Runbooks

When using packaged runbooks (built with your custom Dockerfile), you don't need volume mounts:

```yaml
services:
  api:
    image: ghcr.io/YOUR_ORG/YOUR_RUNBOOKS_IMAGE:latest
    environment:
      RUNBOOKS_DIR: /opt/stage0/runbooks
    command: runbook serve --runbooks-dir /opt/stage0/runbooks --port 8083
    # No volume mount needed - runbooks are in the image
```

## Using Extended Images with Docker Socket

If your runbooks need Docker CLI access:

```yaml
services:
  api:
    image: ghcr.io/agile-learning-institute/stage0_runbook_api:extended
    # ... other configuration
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Required for Docker CLI
      - ./runbooks:/workspace/runbooks:ro
```

## Production Configuration

For production deployments, consider:

```yaml
services:
  api:
    image: ghcr.io/YOUR_ORG/YOUR_RUNBOOKS_IMAGE:latest
    restart: always
    ports:
      - "127.0.0.1:8083:8083"  # Only expose to localhost, use reverse proxy
    environment:
      API_PORT: 8083
      RUNBOOKS_DIR: /opt/stage0/runbooks
      ENABLE_LOGIN: "false"  # MUST be false in production
      JWT_SECRET: "${JWT_SECRET}"  # From secrets manager
      JWT_ISSUER: "your-identity-provider"
      JWT_AUDIENCE: "runbook-api-production"
      LOGGING_LEVEL: "WARNING"
    volumes:
      # Only if not using packaged runbooks
      # - ./runbooks:/workspace/runbooks:ro
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8083/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Important Production Notes**:
- Set `ENABLE_LOGIN=false` to disable development login
- Use a strong, randomly generated `JWT_SECRET`
- Configure `JWT_ISSUER` and `JWT_AUDIENCE` to match your identity provider
- Use read-only volume mounts when possible
- Set appropriate resource limits
- Expose ports only to localhost and use a reverse proxy for TLS termination

For more detailed production deployment guidance, see the [SRE Documentation](https://github.com/agile-learning-institute/stage0_runbooks/blob/main/SRE.md).

---

## Additional Resources

- [Stage0 Runbooks SRE Documentation](https://github.com/agile-learning-institute/stage0_runbooks/blob/main/SRE.md)
- [API Repository](https://github.com/agile-learning-institute/stage0_runbook_api)
- [SPA Repository](https://github.com/agile-learning-institute/stage0_runbook_spa)
- [Runbook Format Specification](https://github.com/agile-learning-institute/stage0_runbook_api/blob/main/RUNBOOK.md)
