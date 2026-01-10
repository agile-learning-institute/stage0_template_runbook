# Stage0 Runbook Template

This is a GitHub Template Repository for creating your own runbook collection using the [Stage0 Runbook System](https://github.com/agile-learning-institute/stage0_runbooks).

## Quick Start

1. **Use this template** to create your own repository
2. **[Configure your Dockerfile](Dockerfile)** - Uncomment sections for tools your runbooks need (AWS CLI, GitHub CLI, Docker, Terraform, etc.)
3. **[Configure your docker-compose.yaml](docker-compose.yaml)** - Uncomment sections for your deployment pattern (packaged runbooks or volume mounts)
4. **Update the Makefile** - Set `CONTAINER_IMAGE` to your GHCR image name (line 12)
5. **Build and deploy**:
   ```sh
   make container  # Build your custom image with runbooks
   make deploy     # Deploy the system
   ```

## Development

For local development and testing with volume-mounted runbooks:

```sh
make api    # Start API server with local runbooks mounted
make open   # Open the web UI in your browser
make down   # Stop services
```

Test your runbooks:
```sh
make validate RUNBOOK=./runbooks/MyRunbook.md
make execute RUNBOOK=./runbooks/MyRunbook.md DATA='{"env_vars":{"VAR1":"value1"}}'
```

## Configuration Files

- **[Dockerfile](Dockerfile)** - Package your runbooks and install required tools. Uncomment sections for AWS CLI, GitHub CLI, Docker, Terraform, or add your own tools.

- **[docker-compose.yaml](docker-compose.yaml)** - Configure your deployment. Choose between packaged runbooks (production) or volume mounts (development). Add resource limits, Docker socket access, or custom configurations as needed.

- **[Makefile](Makefile)** - Update `CONTAINER_IMAGE` with your GHCR image name. All other commands work as-is.

## Additional Resources

- [Stage0 Runbooks Documentation](https://github.com/agile-learning-institute/stage0_runbooks)
- [Runbook Format Specification](https://github.com/agile-learning-institute/stage0_runbook_api/blob/main/RUNBOOK.md)
- [API Repository](https://github.com/agile-learning-institute/stage0_runbook_api)
- [SPA Repository](https://github.com/agile-learning-institute/stage0_runbook_spa)
