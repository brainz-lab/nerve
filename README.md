# Nerve

Background job monitoring for Sidekiq, Solid Queue, and more.

[![CI](https://github.com/brainz-lab/nerve/actions/workflows/ci.yml/badge.svg)](https://github.com/brainz-lab/nerve/actions/workflows/ci.yml)
[![CodeQL](https://github.com/brainz-lab/nerve/actions/workflows/codeql.yml/badge.svg)](https://github.com/brainz-lab/nerve/actions/workflows/codeql.yml)
[![codecov](https://codecov.io/gh/brainz-lab/nerve/graph/badge.svg)](https://codecov.io/gh/brainz-lab/nerve)
[![License: OSAaSy](https://img.shields.io/badge/License-OSAaSy-blue.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red.svg)](https://www.ruby-lang.org)

## Quick Start

```bash
# Install SDK with brainzlab-rails
gem 'brainzlab-rails'

# Job monitoring starts automatically
# View queues at https://nerve.brainzlab.ai/dashboard
```

## Installation

### With Docker

```bash
docker pull brainzllc/nerve:latest

docker run -d \
  -p 3000:3000 \
  -e DATABASE_URL=postgres://user:pass@host:5432/nerve \
  -e REDIS_URL=redis://host:6379/8 \
  -e RAILS_MASTER_KEY=your-master-key \
  brainzllc/nerve:latest
```

### Local Development

```bash
bin/setup
bin/rails server
```

## Configuration

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection | Yes |
| `REDIS_URL` | Redis for real-time stats | Yes |
| `RAILS_MASTER_KEY` | Rails credentials | Yes |
| `BRAINZLAB_PLATFORM_URL` | Platform URL for auth | Yes |

### Tech Stack

- **Ruby** 3.4.7 / **Rails** 8.1
- **PostgreSQL** 16 with TimescaleDB
- **Redis** 7 (real-time stats)
- **Hotwire** (Turbo + Stimulus) / **Tailwind CSS**
- **ActionCable** (live dashboard)

## Usage

### Supported Job Backends

| Backend | Features |
|---------|----------|
| **Sidekiq** | Queues, jobs, workers, retries, dead jobs |
| **Solid Queue** | Rails 8 native, queues, jobs, processes |
| **Resque** | Queues, jobs, workers, failures |
| **DelayedJob** | Jobs, workers, priorities |
| **GoodJob** | Queues, jobs, cron, batches |

### Metrics Tracked

- Queue size and wait time
- Job duration and failure rate
- Worker count and memory usage
- Throughput (jobs/minute)
- Retry and dead job counts

### Dashboard Features

- Real-time queue monitoring
- Job execution timeline
- Worker health status
- Dead job management
- Retry failed jobs

### Alerting

Get notified when:
- Queue size exceeds threshold
- Job failure rate spikes
- Workers go offline
- Jobs stuck in retry loop

## API Reference

### Queues
- `GET /api/v1/queues` - List queues with metrics
- `GET /api/v1/queues/:name/jobs` - List jobs in queue

### Jobs
- `GET /api/v1/jobs` - List jobs
- `GET /api/v1/jobs/:id` - Job details

### Workers
- `GET /api/v1/workers` - List workers
- `GET /api/v1/workers/:id` - Worker details

### Dead Jobs
- `GET /api/v1/dead-jobs` - List dead jobs
- `POST /api/v1/dead-jobs/:id/retry` - Retry job
- `DELETE /api/v1/dead-jobs/:id` - Delete job

### MCP Tools

| Tool | Description |
|------|-------------|
| `nerve_queues` | List queue health and sizes |
| `nerve_jobs` | List recent jobs and status |
| `nerve_workers` | List active workers |
| `nerve_dead` | List dead/failed jobs |
| `nerve_retry` | Retry a dead job |

Full documentation: [docs.brainzlab.ai/products/nerve](https://docs.brainzlab.ai/products/nerve/overview)

## Self-Hosting

### Docker Compose

```yaml
services:
  nerve:
    image: brainzllc/nerve:latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/nerve
      REDIS_URL: redis://redis:6379/8
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      BRAINZLAB_PLATFORM_URL: http://platform:3000
    depends_on:
      - db
      - redis
```

### Testing

```bash
bin/rails test
bin/rubocop
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development setup and contribution guidelines.

## License

This project is licensed under the [OSAaSy License](LICENSE).
