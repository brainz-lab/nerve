# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Nerve by Brainz Lab

Background job monitoring across Sidekiq, Solid Queue, Resque, DelayedJob, and GoodJob.

**Domain**: nerve.brainzlab.ai

**Tagline**: "Your async backbone"

**Status**: Not yet implemented - see nerve-claude-code-prompt.md for full specification

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          NERVE (Rails 8)                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Dashboard   │  │     API      │  │  MCP Server  │           │
│  │  (Hotwire)   │  │  (JSON API)  │  │   (Ruby)     │           │
│  │ /dashboard/* │  │  /api/v1/*   │  │   /mcp/*     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                           │                  │                   │
│                           ▼                  ▼                   │
│              ┌─────────────────────────────────────┐            │
│              │   PostgreSQL + TimescaleDB + Redis  │            │
│              └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
        ▲
        │ Metrics
┌───────┴───────┐
│ Job Backends  │
│ Sidekiq, etc  │
└───────────────┘
```

## Tech Stack

- **Backend**: Rails 8 API + Dashboard
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: PostgreSQL with TimescaleDB
- **Cache**: Redis (real-time stats)
- **Real-time**: ActionCable (live dashboard)
- **Collector**: Ruby agent in SDK

## Supported Job Backends

| Backend | Features |
|---------|----------|
| **Sidekiq** | Queues, jobs, workers, retries, dead jobs |
| **Solid Queue** | Rails 8 native, queues, jobs, processes |
| **Resque** | Queues, jobs, workers, failures |
| **DelayedJob** | Jobs, workers, priorities |
| **GoodJob** | Queues, jobs, cron, batches |

## Key Models

- **AdapterConfig**: Job backend configuration
- **Queue**: Queue metadata and metrics
- **Job**: Individual job tracking
- **Worker**: Worker process health
- **DeadJob**: Failed jobs in morgue
- **QueueMetric**: Time-series queue stats

## Metrics Tracked

- Queue size and wait time
- Job duration and failure rate
- Worker count and memory
- Throughput (jobs/minute)
- Retry and dead job counts

## Key Services

- **Adapters::Sidekiq**: Sidekiq metrics collector
- **Adapters::SolidQueue**: Solid Queue collector
- **Adapters::Resque**: Resque collector
- **QueueHealthChecker**: Health status evaluation

## MCP Tools

| Tool | Description |
|------|-------------|
| `nerve_queues` | List queue health and sizes |
| `nerve_jobs` | List recent jobs and status |
| `nerve_workers` | List active workers |
| `nerve_dead` | List dead/failed jobs |
| `nerve_retry` | Retry a dead job |

## API Endpoints

- `GET /api/v1/queues` - List queues with metrics
- `GET /api/v1/jobs` - List jobs
- `GET /api/v1/workers` - List workers
- `GET /api/v1/dead-jobs` - List dead jobs
- `POST /api/v1/dead-jobs/:id/retry` - Retry job
- `GET /api/v1/stats` - Aggregate statistics

Authentication: `Authorization: Bearer <key>` or `X-API-Key: <key>`
