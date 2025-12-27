# Nerve - Background Job Monitoring

## Overview

Nerve monitors your background jobs across Sidekiq, Solid Queue, Resque, DelayedJob, and GoodJob. Track queue health, job failures, latency, and throughput in real-time.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                                NERVE                                         │
│                     "Your async backbone"                                    │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐   │
│   │                                                                      │   │
│   │     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │   │
│   │     │   SIDEKIQ   │  │ SOLID QUEUE │  │   RESQUE    │               │   │
│   │     │             │  │             │  │             │               │   │
│   │     │  Jobs: 1.2M │  │  Jobs: 500K │  │  Jobs: 300K │               │   │
│   │     │  Failed: 23 │  │  Failed: 5  │  │  Failed: 12 │               │   │
│   │     └─────────────┘  └─────────────┘  └─────────────┘               │   │
│   │                                                                      │   │
│   │     Queue Health                                                     │   │
│   │     ─────────────                                                    │   │
│   │     default     ████████████████████░░░░  85%  ✅ Healthy           │   │
│   │     critical    ██████████████████████████ 100% ✅ Healthy           │   │
│   │     mailers     ████████░░░░░░░░░░░░░░░░  35%  ⚠️ Backing up        │   │
│   │     exports     ██░░░░░░░░░░░░░░░░░░░░░░  8%   ✅ Healthy           │   │
│   │                                                                      │   │
│   └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │   Queue     │  │    Job      │  │   Worker    │  │   Dead      │        │
│   │   Metrics   │  │  Tracking   │  │   Health    │  │    Jobs     │        │
│   │             │  │             │  │             │  │             │        │
│   │ Size, wait  │  │ Duration,   │  │ Active,     │  │ Retries,    │        │
│   │ throughput  │  │ failures    │  │ memory, CPU │  │ morgue      │        │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                              │
│   Features: Multi-adapter • Queue metrics • Job tracking • Worker health •  │
│             Dead job management • Latency alerts • Throughput tracking      │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **API** | Rails 8 API | Job & queue management |
| **Collector** | Ruby agent | Metrics collection |
| **Database** | PostgreSQL | Job records, queue stats |
| **Time-series** | TimescaleDB | Metrics history |
| **Cache** | Redis | Real-time stats |
| **Real-time** | ActionCable | Live dashboard updates |

---

## Supported Job Backends

| Backend | Status | Features |
|---------|--------|----------|
| **Sidekiq** | ✅ Full | Queues, jobs, workers, retries, dead jobs |
| **Solid Queue** | ✅ Full | Rails 8 native, queues, jobs, processes |
| **Resque** | ✅ Full | Queues, jobs, workers, failures |
| **DelayedJob** | ✅ Full | Jobs, workers, priorities |
| **GoodJob** | ✅ Full | Queues, jobs, cron, batches |

---

## Directory Structure

```
nerve/
├── README.md
├── Dockerfile
├── docker-compose.yml
├── .env.example
│
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── initializers/
│       └── adapters.rb
│
├── app/
│   ├── controllers/
│   │   ├── api/v1/
│   │   │   ├── queues_controller.rb
│   │   │   ├── jobs_controller.rb
│   │   │   ├── workers_controller.rb
│   │   │   ├── dead_jobs_controller.rb
│   │   │   ├── stats_controller.rb
│   │   │   └── adapters_controller.rb
│   │   └── internal/
│   │       └── collector_controller.rb
│   │
│   ├── models/
│   │   ├── adapter_config.rb
│   │   ├── queue_snapshot.rb
│   │   ├── job_record.rb
│   │   ├── job_execution.rb
│   │   ├── worker_snapshot.rb
│   │   ├── dead_job.rb
│   │   └── alert_threshold.rb
│   │
│   ├── services/
│   │   ├── adapters/
│   │   │   ├── base_adapter.rb
│   │   │   ├── sidekiq_adapter.rb
│   │   │   ├── solid_queue_adapter.rb
│   │   │   ├── resque_adapter.rb
│   │   │   ├── delayed_job_adapter.rb
│   │   │   └── good_job_adapter.rb
│   │   ├── metrics_aggregator.rb
│   │   ├── queue_health_checker.rb
│   │   ├── latency_analyzer.rb
│   │   └── throughput_calculator.rb
│   │
│   ├── jobs/
│   │   ├── collect_metrics_job.rb
│   │   ├── check_queue_health_job.rb
│   │   ├── cleanup_old_records_job.rb
│   │   └── sync_dead_jobs_job.rb
│   │
│   └── channels/
│       ├── queues_channel.rb
│       └── jobs_channel.rb
│
├── lib/
│   └── nerve/
│       ├── mcp/
│       │   ├── server.rb
│       │   └── tools/
│       │       ├── list_queues.rb
│       │       ├── queue_stats.rb
│       │       ├── list_failed_jobs.rb
│       │       ├── retry_job.rb
│       │       └── clear_queue.rb
│       └── sdk/
│           └── collector.rb
│
└── spec/
    ├── models/
    ├── services/
    └── adapters/
```

---

## Database Schema

```ruby
# db/migrate/001_create_adapter_configs.rb

class CreateAdapterConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :adapter_configs, id: :uuid do |t|
      t.references :platform_project, type: :uuid, null: false
      
      t.string :name, null: false                # "Production Sidekiq"
      t.string :adapter_type, null: false        # sidekiq, solid_queue, resque, etc.
      t.boolean :enabled, default: true
      
      # Connection config (encrypted)
      t.jsonb :connection_config, default: {}
      # {
      #   redis_url: "redis://...",
      #   database_url: "postgres://...",
      #   namespace: "myapp"
      # }
      
      # Polling settings
      t.integer :poll_interval_seconds, default: 30
      
      # Last sync
      t.datetime :last_synced_at
      t.string :sync_status                      # syncing, synced, error
      t.text :sync_error
      
      t.timestamps
      
      t.index :platform_project_id
      t.index [:platform_project_id, :adapter_type]
    end
  end
end

# db/migrate/002_create_queue_snapshots.rb

class CreateQueueSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :queue_snapshots, id: :uuid do |t|
      t.references :adapter_config, type: :uuid, null: false, foreign_key: true
      
      t.datetime :captured_at, null: false
      t.string :queue_name, null: false
      
      # Size metrics
      t.integer :size, default: 0                # Current queue size
      t.integer :latency_ms, default: 0          # Oldest job wait time
      
      # Throughput (jobs/minute)
      t.integer :enqueued_count, default: 0      # Jobs added in period
      t.integer :processed_count, default: 0     # Jobs completed in period
      t.integer :failed_count, default: 0        # Jobs failed in period
      
      # Worker info
      t.integer :workers_count, default: 0       # Workers processing this queue
      t.integer :busy_workers, default: 0        # Currently busy
      
      t.index [:adapter_config_id, :captured_at]
      t.index [:adapter_config_id, :queue_name, :captured_at]
    end
    
    # TimescaleDB hypertable
    execute "SELECT create_hypertable('queue_snapshots', 'captured_at')"
    execute "SELECT add_compression_policy('queue_snapshots', INTERVAL '7 days')"
    execute "SELECT add_retention_policy('queue_snapshots', INTERVAL '30 days')"
  end
end

# db/migrate/003_create_job_records.rb

class CreateJobRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :job_records, id: :uuid do |t|
      t.references :adapter_config, type: :uuid, null: false, foreign_key: true
      
      # Job identification
      t.string :job_id, null: false              # Backend's job ID
      t.string :job_class, null: false           # UserMailer, ExportJob, etc.
      t.string :queue_name, null: false
      
      # Job details
      t.jsonb :arguments, default: []            # Job arguments (sanitized)
      t.integer :priority
      t.datetime :scheduled_at                   # For scheduled jobs
      
      # Execution tracking
      t.integer :attempts, default: 0
      t.integer :max_attempts
      t.datetime :last_executed_at
      t.integer :last_duration_ms
      
      # Status
      t.string :status, null: false              # pending, running, completed, failed, dead
      t.text :last_error
      t.text :last_backtrace
      
      # Timing
      t.datetime :enqueued_at
      t.datetime :started_at
      t.datetime :completed_at
      
      t.timestamps
      
      t.index [:adapter_config_id, :job_id], unique: true
      t.index [:adapter_config_id, :status]
      t.index [:adapter_config_id, :job_class]
      t.index [:adapter_config_id, :queue_name]
      t.index :enqueued_at
    end
  end
end

# db/migrate/004_create_job_executions.rb

class CreateJobExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :job_executions, id: :uuid do |t|
      t.references :job_record, type: :uuid, null: false, foreign_key: true
      
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration_ms
      
      t.string :status, null: false              # running, completed, failed
      t.string :worker_id                        # Which worker ran it
      t.string :process_id                       # Host process
      
      # Error info (if failed)
      t.text :error_message
      t.text :error_class
      t.text :backtrace
      
      # Memory/performance (if available)
      t.integer :memory_mb
      t.float :cpu_time
      
      t.index [:job_record_id, :started_at]
      t.index :started_at
    end
    
    # TimescaleDB for historical data
    execute "SELECT create_hypertable('job_executions', 'started_at')"
    execute "SELECT add_compression_policy('job_executions', INTERVAL '7 days')"
    execute "SELECT add_retention_policy('job_executions', INTERVAL '90 days')"
  end
end

# db/migrate/005_create_worker_snapshots.rb

class CreateWorkerSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :worker_snapshots, id: :uuid do |t|
      t.references :adapter_config, type: :uuid, null: false, foreign_key: true
      
      t.datetime :captured_at, null: false
      
      # Worker identification
      t.string :worker_id, null: false           # hostname:pid:tid
      t.string :hostname
      t.integer :pid
      t.string :process_tag                      # Sidekiq process tag
      
      # Status
      t.string :status, null: false              # idle, busy, quiet, stopping
      t.string :current_job_class                # If busy
      t.string :current_job_id
      t.datetime :job_started_at
      
      # Queues this worker processes
      t.string :queues, array: true, default: []
      t.integer :concurrency                     # Max threads/workers
      
      # Resource usage (if available)
      t.float :memory_mb
      t.float :cpu_percent
      
      # Stats
      t.integer :processed_count, default: 0     # Total jobs processed
      t.integer :failed_count, default: 0        # Total failures
      
      t.datetime :started_at                     # When worker started
      
      t.index [:adapter_config_id, :captured_at]
      t.index [:adapter_config_id, :worker_id, :captured_at]
    end
    
    execute "SELECT create_hypertable('worker_snapshots', 'captured_at')"
    execute "SELECT add_retention_policy('worker_snapshots', INTERVAL '7 days')"
  end
end

# db/migrate/006_create_dead_jobs.rb

class CreateDeadJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :dead_jobs, id: :uuid do |t|
      t.references :adapter_config, type: :uuid, null: false, foreign_key: true
      
      # Job info
      t.string :job_id, null: false
      t.string :job_class, null: false
      t.string :queue_name, null: false
      t.jsonb :arguments, default: []
      
      # Failure info
      t.text :error_message, null: false
      t.text :error_class
      t.text :backtrace
      
      # History
      t.integer :retry_count, default: 0
      t.datetime :first_failed_at
      t.datetime :last_failed_at
      t.datetime :died_at, null: false
      
      # Original job data (for retry)
      t.jsonb :original_payload, default: {}
      
      # Management
      t.string :status, default: 'dead'          # dead, retrying, discarded
      t.datetime :retried_at
      t.datetime :discarded_at
      t.string :discarded_by
      
      t.timestamps
      
      t.index [:adapter_config_id, :died_at]
      t.index [:adapter_config_id, :job_class]
      t.index [:adapter_config_id, :status]
    end
  end
end

# db/migrate/007_create_alert_thresholds.rb

class CreateAlertThresholds < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_thresholds, id: :uuid do |t|
      t.references :adapter_config, type: :uuid, null: false, foreign_key: true
      
      t.string :name, null: false
      t.boolean :enabled, default: true
      
      # What to monitor
      t.string :metric_type, null: false         # queue_size, latency, failure_rate, dead_jobs
      t.string :queue_name                       # Specific queue or nil for all
      t.string :job_class                        # Specific job class or nil for all
      
      # Threshold
      t.string :operator, null: false            # gt, gte, lt, lte, eq
      t.float :threshold_value, null: false
      t.string :threshold_unit                   # jobs, ms, percent, count
      
      # Alert config
      t.integer :evaluation_window_seconds, default: 300  # 5 minutes
      t.integer :consecutive_breaches, default: 1         # Alert after N breaches
      
      # Link to Signal
      t.uuid :signal_alert_id
      
      # State
      t.integer :current_breach_count, default: 0
      t.datetime :last_triggered_at
      t.datetime :last_resolved_at
      
      t.timestamps
      
      t.index [:adapter_config_id, :enabled]
    end
  end
end
```

---

## Models

```ruby
# app/models/adapter_config.rb

class AdapterConfig < ApplicationRecord
  belongs_to :platform_project, class_name: 'Platform::Project'
  
  has_many :queue_snapshots, dependent: :destroy
  has_many :job_records, dependent: :destroy
  has_many :worker_snapshots, dependent: :destroy
  has_many :dead_jobs, dependent: :destroy
  has_many :alert_thresholds, dependent: :destroy
  
  validates :name, presence: true
  validates :adapter_type, presence: true, inclusion: { 
    in: %w[sidekiq solid_queue resque delayed_job good_job] 
  }
  
  encrypts :connection_config
  
  scope :enabled, -> { where(enabled: true) }
  
  def adapter
    @adapter ||= adapter_class.new(self)
  end
  
  def sync!
    update!(sync_status: 'syncing')
    
    adapter.sync
    
    update!(
      sync_status: 'synced',
      last_synced_at: Time.current,
      sync_error: nil
    )
  rescue => e
    update!(
      sync_status: 'error',
      sync_error: e.message
    )
    raise
  end
  
  def queues
    queue_snapshots
      .where('captured_at > ?', 5.minutes.ago)
      .select('DISTINCT ON (queue_name) *')
      .order(:queue_name, captured_at: :desc)
  end
  
  def workers
    worker_snapshots
      .where('captured_at > ?', 2.minutes.ago)
      .select('DISTINCT ON (worker_id) *')
      .order(:worker_id, captured_at: :desc)
  end
  
  def overall_stats
    recent = queue_snapshots.where('captured_at > ?', 5.minutes.ago)
    
    {
      total_queued: recent.sum(:size),
      total_processed: recent.sum(:processed_count),
      total_failed: recent.sum(:failed_count),
      max_latency_ms: recent.maximum(:latency_ms),
      workers_active: workers.where(status: 'busy').count,
      workers_total: workers.count
    }
  end
  
  private
  
  def adapter_class
    case adapter_type
    when 'sidekiq' then Adapters::SidekiqAdapter
    when 'solid_queue' then Adapters::SolidQueueAdapter
    when 'resque' then Adapters::ResqueAdapter
    when 'delayed_job' then Adapters::DelayedJobAdapter
    when 'good_job' then Adapters::GoodJobAdapter
    end
  end
end

# app/models/queue_snapshot.rb

class QueueSnapshot < ApplicationRecord
  belongs_to :adapter_config
  
  validates :queue_name, presence: true
  validates :captured_at, presence: true
  
  scope :for_queue, ->(name) { where(queue_name: name) }
  scope :recent, -> { where('captured_at > ?', 1.hour.ago) }
  
  def healthy?
    latency_ms < 60_000 && size < 10_000  # Customizable thresholds
  end
  
  def self.throughput_per_minute(queue_name, period: 1.hour)
    for_queue(queue_name)
      .where('captured_at > ?', period.ago)
      .group("time_bucket('1 minute', captured_at)")
      .sum(:processed_count)
  end
end

# app/models/job_record.rb

class JobRecord < ApplicationRecord
  belongs_to :adapter_config
  
  has_many :executions, class_name: 'JobExecution', dependent: :destroy
  
  validates :job_id, presence: true
  validates :job_class, presence: true
  validates :queue_name, presence: true
  validates :status, presence: true
  
  enum :status, {
    pending: 'pending',
    scheduled: 'scheduled',
    running: 'running',
    completed: 'completed',
    failed: 'failed',
    dead: 'dead'
  }
  
  scope :by_class, ->(klass) { where(job_class: klass) }
  scope :by_queue, ->(queue) { where(queue_name: queue) }
  scope :recent_failures, -> { failed.where('last_executed_at > ?', 24.hours.ago) }
  
  def duration
    return nil unless completed_at && started_at
    completed_at - started_at
  end
  
  def wait_time
    return nil unless started_at && enqueued_at
    started_at - enqueued_at
  end
  
  def self.failure_rate(period: 1.hour)
    recent = where('enqueued_at > ?', period.ago)
    total = recent.count
    return 0.0 if total.zero?
    
    (recent.failed.count.to_f / total * 100).round(2)
  end
  
  def self.average_duration(job_class, period: 1.hour)
    completed
      .by_class(job_class)
      .where('completed_at > ?', period.ago)
      .average(:last_duration_ms)
      &.round || 0
  end
end

# app/models/dead_job.rb

class DeadJob < ApplicationRecord
  belongs_to :adapter_config
  
  validates :job_id, presence: true
  validates :job_class, presence: true
  validates :error_message, presence: true
  
  scope :recent, -> { order(died_at: :desc) }
  scope :by_class, ->(klass) { where(job_class: klass) }
  scope :actionable, -> { where(status: 'dead') }
  
  def retry!
    adapter_config.adapter.retry_dead_job(self)
    update!(status: 'retrying', retried_at: Time.current)
  end
  
  def discard!(user: nil)
    adapter_config.adapter.discard_dead_job(self)
    update!(
      status: 'discarded',
      discarded_at: Time.current,
      discarded_by: user
    )
  end
  
  def self.group_by_error
    group(:error_class, :error_message)
      .select(:error_class, :error_message, 'COUNT(*) as count', 'MAX(died_at) as latest')
      .order('count DESC')
  end
end

# app/models/alert_threshold.rb

class AlertThreshold < ApplicationRecord
  belongs_to :adapter_config
  
  validates :name, presence: true
  validates :metric_type, presence: true, inclusion: {
    in: %w[queue_size latency failure_rate dead_jobs throughput]
  }
  validates :operator, presence: true, inclusion: {
    in: %w[gt gte lt lte eq]
  }
  validates :threshold_value, presence: true, numericality: true
  
  scope :enabled, -> { where(enabled: true) }
  
  def evaluate!
    current_value = fetch_current_value
    breached = check_breach(current_value)
    
    if breached
      self.current_breach_count += 1
      
      if current_breach_count >= consecutive_breaches
        trigger_alert!(current_value) unless recently_triggered?
      end
    else
      if current_breach_count > 0
        resolve_alert! if last_triggered_at.present?
      end
      self.current_breach_count = 0
    end
    
    save!
  end
  
  private
  
  def fetch_current_value
    case metric_type
    when 'queue_size'
      fetch_queue_size
    when 'latency'
      fetch_latency
    when 'failure_rate'
      fetch_failure_rate
    when 'dead_jobs'
      fetch_dead_jobs_count
    when 'throughput'
      fetch_throughput
    end
  end
  
  def fetch_queue_size
    scope = adapter_config.queue_snapshots.where('captured_at > ?', 5.minutes.ago)
    scope = scope.for_queue(queue_name) if queue_name.present?
    scope.sum(:size)
  end
  
  def fetch_latency
    scope = adapter_config.queue_snapshots.where('captured_at > ?', 5.minutes.ago)
    scope = scope.for_queue(queue_name) if queue_name.present?
    scope.maximum(:latency_ms) || 0
  end
  
  def fetch_failure_rate
    scope = adapter_config.job_records.where('enqueued_at > ?', evaluation_window_seconds.seconds.ago)
    scope = scope.by_queue(queue_name) if queue_name.present?
    scope = scope.by_class(job_class) if job_class.present?
    
    total = scope.count
    return 0.0 if total.zero?
    
    (scope.failed.count.to_f / total * 100).round(2)
  end
  
  def fetch_dead_jobs_count
    scope = adapter_config.dead_jobs.actionable
    scope = scope.by_class(job_class) if job_class.present?
    scope.count
  end
  
  def fetch_throughput
    scope = adapter_config.queue_snapshots
      .where('captured_at > ?', evaluation_window_seconds.seconds.ago)
    scope = scope.for_queue(queue_name) if queue_name.present?
    scope.sum(:processed_count)
  end
  
  def check_breach(value)
    case operator
    when 'gt' then value > threshold_value
    when 'gte' then value >= threshold_value
    when 'lt' then value < threshold_value
    when 'lte' then value <= threshold_value
    when 'eq' then value == threshold_value
    end
  end
  
  def recently_triggered?
    last_triggered_at.present? && last_triggered_at > 5.minutes.ago
  end
  
  def trigger_alert!(current_value)
    update!(last_triggered_at: Time.current)
    
    Signal::Client.trigger_alert(
      source: 'nerve',
      title: "#{name}: #{metric_type} threshold breached",
      message: "Current value: #{current_value}, Threshold: #{operator} #{threshold_value}",
      severity: determine_severity,
      data: {
        adapter_id: adapter_config_id,
        metric_type: metric_type,
        queue_name: queue_name,
        job_class: job_class,
        current_value: current_value,
        threshold: threshold_value
      }
    )
  end
  
  def resolve_alert!
    update!(last_resolved_at: Time.current)
    
    Signal::Client.resolve_alert(
      source: 'nerve',
      title: "#{name}: threshold resolved"
    )
  end
  
  def determine_severity
    case metric_type
    when 'dead_jobs' then 'critical'
    when 'failure_rate' then 'major'
    when 'latency', 'queue_size' then 'minor'
    else 'minor'
    end
  end
end
```

---

## Adapters

```ruby
# app/services/adapters/base_adapter.rb

module Adapters
  class BaseAdapter
    attr_reader :config
    
    def initialize(config)
      @config = config
    end
    
    def sync
      sync_queues
      sync_workers
      sync_dead_jobs
    end
    
    def sync_queues
      raise NotImplementedError
    end
    
    def sync_workers
      raise NotImplementedError
    end
    
    def sync_dead_jobs
      raise NotImplementedError
    end
    
    def retry_dead_job(dead_job)
      raise NotImplementedError
    end
    
    def discard_dead_job(dead_job)
      raise NotImplementedError
    end
    
    def clear_queue(queue_name)
      raise NotImplementedError
    end
    
    def pause_queue(queue_name)
      raise NotImplementedError
    end
    
    protected
    
    def connection
      raise NotImplementedError
    end
    
    def capture_time
      Time.current
    end
  end
end

# app/services/adapters/sidekiq_adapter.rb

module Adapters
  class SidekiqAdapter < BaseAdapter
    def sync_queues
      captured_at = capture_time
      
      Sidekiq::Queue.all.each do |queue|
        config.queue_snapshots.create!(
          captured_at: captured_at,
          queue_name: queue.name,
          size: queue.size,
          latency_ms: (queue.latency * 1000).to_i,
          enqueued_count: count_enqueued(queue.name),
          processed_count: processed_in_window(queue.name),
          failed_count: failed_in_window(queue.name)
        )
      end
      
      # Also capture scheduled and retry sets
      capture_scheduled_set(captured_at)
      capture_retry_set(captured_at)
    end
    
    def sync_workers
      captured_at = capture_time
      
      Sidekiq::Workers.new.each do |process_id, thread_id, work|
        worker_id = "#{process_id}:#{thread_id}"
        
        config.worker_snapshots.create!(
          captured_at: captured_at,
          worker_id: worker_id,
          hostname: extract_hostname(process_id),
          pid: extract_pid(process_id),
          status: 'busy',
          current_job_class: work.dig('payload', 'class'),
          current_job_id: work.dig('payload', 'jid'),
          job_started_at: Time.at(work['run_at']),
          queues: work['queues'] || []
        )
      end
      
      # Also capture process info
      Sidekiq::ProcessSet.new.each do |process|
        config.worker_snapshots.create!(
          captured_at: captured_at,
          worker_id: process['identity'],
          hostname: process['hostname'],
          pid: process['pid'],
          process_tag: process['tag'],
          status: process['quiet'] ? 'quiet' : 'idle',
          queues: process['queues'],
          concurrency: process['concurrency'],
          started_at: Time.at(process['started_at'])
        )
      end
    end
    
    def sync_dead_jobs
      Sidekiq::DeadSet.new.each do |job|
        dead_job = config.dead_jobs.find_or_initialize_by(job_id: job.jid)
        
        dead_job.assign_attributes(
          job_class: job.klass,
          queue_name: job.queue,
          arguments: sanitize_args(job.args),
          error_message: job['error_message'],
          error_class: job['error_class'],
          backtrace: job['error_backtrace']&.first(20)&.join("\n"),
          retry_count: job['retry_count'] || 0,
          first_failed_at: job['failed_at'] ? Time.at(job['failed_at']) : nil,
          last_failed_at: job['failed_at'] ? Time.at(job['failed_at']) : nil,
          died_at: Time.at(job.at),
          original_payload: job.item
        )
        
        dead_job.save!
      end
    end
    
    def retry_dead_job(dead_job)
      dead_set = Sidekiq::DeadSet.new
      job = dead_set.find_job(dead_job.job_id)
      job&.retry
    end
    
    def discard_dead_job(dead_job)
      dead_set = Sidekiq::DeadSet.new
      job = dead_set.find_job(dead_job.job_id)
      job&.delete
    end
    
    def clear_queue(queue_name)
      Sidekiq::Queue.new(queue_name).clear
    end
    
    def get_job(job_id)
      # Check queues
      Sidekiq::Queue.all.each do |queue|
        job = queue.find_job(job_id)
        return job if job
      end
      
      # Check scheduled
      Sidekiq::ScheduledSet.new.find_job(job_id)
    end
    
    private
    
    def connection
      @connection ||= Sidekiq.redis_pool
    end
    
    def count_enqueued(queue_name)
      # Count jobs enqueued in the last polling interval
      Sidekiq::Queue.new(queue_name).size
    end
    
    def processed_in_window(queue_name)
      stats = Sidekiq::Stats.new
      stats.processed
    end
    
    def failed_in_window(queue_name)
      stats = Sidekiq::Stats.new
      stats.failed
    end
    
    def capture_scheduled_set(captured_at)
      scheduled = Sidekiq::ScheduledSet.new
      
      config.queue_snapshots.create!(
        captured_at: captured_at,
        queue_name: '_scheduled',
        size: scheduled.size
      )
    end
    
    def capture_retry_set(captured_at)
      retries = Sidekiq::RetrySet.new
      
      config.queue_snapshots.create!(
        captured_at: captured_at,
        queue_name: '_retries',
        size: retries.size
      )
    end
    
    def sanitize_args(args)
      # Remove sensitive data
      args.map do |arg|
        if arg.is_a?(Hash)
          arg.transform_values { |v| v.to_s.length > 100 ? '[TRUNCATED]' : v }
        else
          arg.to_s.length > 100 ? '[TRUNCATED]' : arg
        end
      end
    end
    
    def extract_hostname(process_id)
      process_id.split(':').first
    end
    
    def extract_pid(process_id)
      process_id.split(':')[1].to_i
    end
  end
end

# app/services/adapters/solid_queue_adapter.rb

module Adapters
  class SolidQueueAdapter < BaseAdapter
    def sync_queues
      captured_at = capture_time
      
      # Get queue stats from Solid Queue
      SolidQueue::Queue.all.each do |queue|
        ready_count = SolidQueue::ReadyExecution.where(queue_name: queue.name).count
        oldest = SolidQueue::ReadyExecution.where(queue_name: queue.name).minimum(:created_at)
        latency_ms = oldest ? ((Time.current - oldest) * 1000).to_i : 0
        
        config.queue_snapshots.create!(
          captured_at: captured_at,
          queue_name: queue.name,
          size: ready_count,
          latency_ms: latency_ms,
          enqueued_count: count_enqueued_since(queue.name),
          processed_count: count_processed_since(queue.name),
          failed_count: count_failed_since(queue.name)
        )
      end
      
      # Scheduled jobs
      scheduled_count = SolidQueue::ScheduledExecution.count
      config.queue_snapshots.create!(
        captured_at: captured_at,
        queue_name: '_scheduled',
        size: scheduled_count
      )
    end
    
    def sync_workers
      captured_at = capture_time
      
      SolidQueue::Process.all.each do |process|
        config.worker_snapshots.create!(
          captured_at: captured_at,
          worker_id: process.id.to_s,
          hostname: process.hostname,
          pid: process.pid,
          status: process_status(process),
          queues: process.queues || [],
          started_at: process.created_at
        )
      end
      
      # Get currently executing jobs
      SolidQueue::ClaimedExecution.includes(:job).each do |claimed|
        config.worker_snapshots.create!(
          captured_at: captured_at,
          worker_id: claimed.process_id.to_s,
          status: 'busy',
          current_job_class: claimed.job.class_name,
          current_job_id: claimed.job_id.to_s,
          job_started_at: claimed.created_at
        )
      end
    end
    
    def sync_dead_jobs
      SolidQueue::FailedExecution.includes(:job).each do |failed|
        job = failed.job
        
        dead_job = config.dead_jobs.find_or_initialize_by(job_id: job.id.to_s)
        
        dead_job.assign_attributes(
          job_class: job.class_name,
          queue_name: job.queue_name,
          arguments: sanitize_args(job.arguments),
          error_message: failed.error.dig('message'),
          error_class: failed.error.dig('exception_class'),
          backtrace: failed.error.dig('backtrace')&.first(20)&.join("\n"),
          died_at: failed.created_at,
          original_payload: job.arguments
        )
        
        dead_job.save!
      end
    end
    
    def retry_dead_job(dead_job)
      failed = SolidQueue::FailedExecution.find_by(job_id: dead_job.job_id)
      failed&.retry
    end
    
    def discard_dead_job(dead_job)
      failed = SolidQueue::FailedExecution.find_by(job_id: dead_job.job_id)
      failed&.discard
    end
    
    def clear_queue(queue_name)
      SolidQueue::ReadyExecution.where(queue_name: queue_name).delete_all
    end
    
    private
    
    def count_enqueued_since(queue_name)
      SolidQueue::Job
        .where(queue_name: queue_name)
        .where('created_at > ?', config.poll_interval_seconds.seconds.ago)
        .count
    end
    
    def count_processed_since(queue_name)
      # Solid Queue doesn't keep completed jobs by default
      # Would need custom tracking
      0
    end
    
    def count_failed_since(queue_name)
      SolidQueue::FailedExecution
        .joins(:job)
        .where(jobs: { queue_name: queue_name })
        .where('solid_queue_failed_executions.created_at > ?', config.poll_interval_seconds.seconds.ago)
        .count
    end
    
    def process_status(process)
      if SolidQueue::ClaimedExecution.where(process_id: process.id).exists?
        'busy'
      else
        'idle'
      end
    end
    
    def sanitize_args(args)
      return [] unless args.is_a?(Hash)
      
      args.transform_values do |v|
        v.to_s.length > 100 ? '[TRUNCATED]' : v
      end
    end
  end
end

# app/services/adapters/resque_adapter.rb

module Adapters
  class ResqueAdapter < BaseAdapter
    def sync_queues
      captured_at = capture_time
      
      Resque.queues.each do |queue_name|
        size = Resque.size(queue_name)
        
        config.queue_snapshots.create!(
          captured_at: captured_at,
          queue_name: queue_name,
          size: size,
          latency_ms: calculate_latency(queue_name)
        )
      end
      
      # Failed jobs queue
      config.queue_snapshots.create!(
        captured_at: captured_at,
        queue_name: '_failed',
        size: Resque::Failure.count
      )
    end
    
    def sync_workers
      captured_at = capture_time
      
      Resque.workers.each do |worker|
        job = worker.job
        
        config.worker_snapshots.create!(
          captured_at: captured_at,
          worker_id: worker.id,
          hostname: worker.hostname,
          pid: worker.pid,
          status: job ? 'busy' : 'idle',
          current_job_class: job&.dig('payload', 'class'),
          current_job_id: job&.dig('payload', 'args')&.first,
          job_started_at: job ? Time.at(job['run_at']) : nil,
          queues: worker.queues
        )
      end
    end
    
    def sync_dead_jobs
      (0...Resque::Failure.count).each do |i|
        failure = Resque::Failure.all(i, 1).first
        next unless failure
        
        dead_job = config.dead_jobs.find_or_initialize_by(
          job_id: failure['payload']['args'].first.to_s
        )
        
        dead_job.assign_attributes(
          job_class: failure['payload']['class'],
          queue_name: failure['queue'],
          arguments: failure['payload']['args'],
          error_message: failure['error'],
          error_class: failure['exception'],
          backtrace: failure['backtrace']&.first(20)&.join("\n"),
          died_at: Time.parse(failure['failed_at']),
          original_payload: failure['payload']
        )
        
        dead_job.save!
      end
    end
    
    def retry_dead_job(dead_job)
      # Find and requeue
      (0...Resque::Failure.count).each do |i|
        failure = Resque::Failure.all(i, 1).first
        if failure['payload']['args'].first.to_s == dead_job.job_id
          Resque::Failure.requeue(i)
          return
        end
      end
    end
    
    def discard_dead_job(dead_job)
      (0...Resque::Failure.count).each do |i|
        failure = Resque::Failure.all(i, 1).first
        if failure['payload']['args'].first.to_s == dead_job.job_id
          Resque::Failure.remove(i)
          return
        end
      end
    end
    
    def clear_queue(queue_name)
      Resque.remove_queue(queue_name)
    end
    
    private
    
    def calculate_latency(queue_name)
      oldest = Resque.peek(queue_name)
      return 0 unless oldest && oldest['enqueued_at']
      
      ((Time.current - Time.at(oldest['enqueued_at'])) * 1000).to_i
    end
  end
end
```

---

## Services

```ruby
# app/services/queue_health_checker.rb

class QueueHealthChecker
  THRESHOLDS = {
    latency_warning: 60_000,      # 1 minute
    latency_critical: 300_000,    # 5 minutes
    size_warning: 1_000,
    size_critical: 10_000,
    failure_rate_warning: 5,      # 5%
    failure_rate_critical: 25     # 25%
  }.freeze
  
  def initialize(adapter_config)
    @adapter_config = adapter_config
  end
  
  def check_all
    @adapter_config.queues.map do |queue|
      check_queue(queue)
    end
  end
  
  def check_queue(queue_snapshot)
    issues = []
    
    # Check latency
    if queue_snapshot.latency_ms >= THRESHOLDS[:latency_critical]
      issues << { type: 'latency', severity: 'critical', value: queue_snapshot.latency_ms }
    elsif queue_snapshot.latency_ms >= THRESHOLDS[:latency_warning]
      issues << { type: 'latency', severity: 'warning', value: queue_snapshot.latency_ms }
    end
    
    # Check size
    if queue_snapshot.size >= THRESHOLDS[:size_critical]
      issues << { type: 'size', severity: 'critical', value: queue_snapshot.size }
    elsif queue_snapshot.size >= THRESHOLDS[:size_warning]
      issues << { type: 'size', severity: 'warning', value: queue_snapshot.size }
    end
    
    # Calculate health status
    status = if issues.any? { |i| i[:severity] == 'critical' }
               'critical'
             elsif issues.any? { |i| i[:severity] == 'warning' }
               'warning'
             else
               'healthy'
             end
    
    {
      queue_name: queue_snapshot.queue_name,
      status: status,
      issues: issues,
      metrics: {
        size: queue_snapshot.size,
        latency_ms: queue_snapshot.latency_ms,
        throughput: queue_snapshot.processed_count
      }
    }
  end
  
  def overall_health
    results = check_all
    
    if results.any? { |r| r[:status] == 'critical' }
      'critical'
    elsif results.any? { |r| r[:status] == 'warning' }
      'warning'
    else
      'healthy'
    end
  end
end

# app/services/throughput_calculator.rb

class ThroughputCalculator
  def initialize(adapter_config)
    @adapter_config = adapter_config
  end
  
  def jobs_per_minute(period: 1.hour)
    snapshots = @adapter_config.queue_snapshots
                               .where('captured_at > ?', period.ago)
    
    total_processed = snapshots.sum(:processed_count)
    minutes = period / 60
    
    (total_processed.to_f / minutes).round(2)
  end
  
  def jobs_per_minute_by_queue(period: 1.hour)
    @adapter_config.queue_snapshots
                   .where('captured_at > ?', period.ago)
                   .group(:queue_name)
                   .sum(:processed_count)
                   .transform_values { |v| (v.to_f / (period / 60)).round(2) }
  end
  
  def throughput_series(period: 24.hours, interval: '1 hour')
    @adapter_config.queue_snapshots
                   .where('captured_at > ?', period.ago)
                   .group("time_bucket('#{interval}', captured_at)")
                   .sum(:processed_count)
  end
  
  def peak_throughput(period: 24.hours)
    throughput_series(period: period, interval: '5 minutes').values.max || 0
  end
end

# app/services/latency_analyzer.rb

class LatencyAnalyzer
  def initialize(adapter_config)
    @adapter_config = adapter_config
  end
  
  def current_latencies
    @adapter_config.queues.each_with_object({}) do |queue, hash|
      hash[queue.queue_name] = queue.latency_ms
    end
  end
  
  def average_latency(queue_name: nil, period: 1.hour)
    scope = @adapter_config.queue_snapshots.where('captured_at > ?', period.ago)
    scope = scope.for_queue(queue_name) if queue_name
    
    scope.average(:latency_ms)&.round || 0
  end
  
  def p95_latency(queue_name: nil, period: 1.hour)
    scope = @adapter_config.queue_snapshots.where('captured_at > ?', period.ago)
    scope = scope.for_queue(queue_name) if queue_name
    
    # Use TimescaleDB percentile function
    scope.pick(Arel.sql("percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms)"))&.round || 0
  end
  
  def latency_trend(queue_name, period: 24.hours)
    @adapter_config.queue_snapshots
                   .for_queue(queue_name)
                   .where('captured_at > ?', period.ago)
                   .group("time_bucket('1 hour', captured_at)")
                   .average(:latency_ms)
                   .transform_values(&:round)
  end
  
  def slowest_queues(limit: 5)
    @adapter_config.queues
                   .order(latency_ms: :desc)
                   .limit(limit)
                   .pluck(:queue_name, :latency_ms)
  end
end
```

---

## Controllers

```ruby
# app/controllers/api/v1/queues_controller.rb

module Api
  module V1
    class QueuesController < BaseController
      # GET /api/v1/adapters/:adapter_id/queues
      def index
        adapter = current_project_adapters.find(params[:adapter_id])
        queues = adapter.queues
        
        health_checker = QueueHealthChecker.new(adapter)
        
        render json: {
          queues: queues.map do |q|
            health = health_checker.check_queue(q)
            {
              name: q.queue_name,
              size: q.size,
              latency_ms: q.latency_ms,
              throughput: q.processed_count,
              workers: q.workers_count,
              status: health[:status],
              issues: health[:issues]
            }
          end,
          overall_health: health_checker.overall_health
        }
      end
      
      # GET /api/v1/adapters/:adapter_id/queues/:name
      def show
        adapter = current_project_adapters.find(params[:adapter_id])
        queue_name = params[:name]
        
        latest = adapter.queue_snapshots.for_queue(queue_name).recent.first
        
        render json: {
          name: queue_name,
          current: {
            size: latest&.size || 0,
            latency_ms: latest&.latency_ms || 0,
            throughput: latest&.processed_count || 0
          },
          history: {
            size: size_history(adapter, queue_name),
            latency: latency_history(adapter, queue_name),
            throughput: throughput_history(adapter, queue_name)
          }
        }
      end
      
      # POST /api/v1/adapters/:adapter_id/queues/:name/clear
      def clear
        adapter = current_project_adapters.find(params[:adapter_id])
        adapter.adapter.clear_queue(params[:name])
        
        render json: { cleared: true, queue: params[:name] }
      end
      
      private
      
      def current_project_adapters
        AdapterConfig.where(platform_project_id: current_project.id)
      end
      
      def size_history(adapter, queue_name)
        adapter.queue_snapshots
               .for_queue(queue_name)
               .where('captured_at > ?', 24.hours.ago)
               .group("time_bucket('1 hour', captured_at)")
               .average(:size)
      end
      
      def latency_history(adapter, queue_name)
        adapter.queue_snapshots
               .for_queue(queue_name)
               .where('captured_at > ?', 24.hours.ago)
               .group("time_bucket('1 hour', captured_at)")
               .average(:latency_ms)
      end
      
      def throughput_history(adapter, queue_name)
        adapter.queue_snapshots
               .for_queue(queue_name)
               .where('captured_at > ?', 24.hours.ago)
               .group("time_bucket('1 hour', captured_at)")
               .sum(:processed_count)
      end
    end
  end
end

# app/controllers/api/v1/dead_jobs_controller.rb

module Api
  module V1
    class DeadJobsController < BaseController
      # GET /api/v1/adapters/:adapter_id/dead_jobs
      def index
        adapter = current_project_adapters.find(params[:adapter_id])
        dead_jobs = adapter.dead_jobs.actionable.recent
        
        if params[:job_class].present?
          dead_jobs = dead_jobs.by_class(params[:job_class])
        end
        
        dead_jobs = dead_jobs.page(params[:page]).per(50)
        
        render json: {
          dead_jobs: dead_jobs.map { |j| serialize_dead_job(j) },
          total: adapter.dead_jobs.actionable.count,
          grouped_errors: adapter.dead_jobs.group_by_error.limit(10)
        }
      end
      
      # POST /api/v1/dead_jobs/:id/retry
      def retry
        dead_job = find_dead_job
        dead_job.retry!
        
        render json: { retried: true, job_id: dead_job.job_id }
      end
      
      # POST /api/v1/dead_jobs/:id/discard
      def discard
        dead_job = find_dead_job
        dead_job.discard!(user: current_user.email)
        
        render json: { discarded: true, job_id: dead_job.job_id }
      end
      
      # POST /api/v1/adapters/:adapter_id/dead_jobs/retry_all
      def retry_all
        adapter = current_project_adapters.find(params[:adapter_id])
        
        count = 0
        adapter.dead_jobs.actionable.find_each do |job|
          job.retry!
          count += 1
        end
        
        render json: { retried_count: count }
      end
      
      # POST /api/v1/adapters/:adapter_id/dead_jobs/discard_all
      def discard_all
        adapter = current_project_adapters.find(params[:adapter_id])
        
        count = adapter.dead_jobs.actionable.count
        adapter.dead_jobs.actionable.update_all(
          status: 'discarded',
          discarded_at: Time.current,
          discarded_by: current_user.email
        )
        
        render json: { discarded_count: count }
      end
      
      private
      
      def find_dead_job
        DeadJob.joins(:adapter_config)
               .where(adapter_configs: { platform_project_id: current_project.id })
               .find(params[:id])
      end
      
      def serialize_dead_job(job)
        {
          id: job.id,
          job_id: job.job_id,
          job_class: job.job_class,
          queue_name: job.queue_name,
          error_message: job.error_message,
          error_class: job.error_class,
          retry_count: job.retry_count,
          died_at: job.died_at,
          arguments: job.arguments
        }
      end
    end
  end
end

# app/controllers/api/v1/stats_controller.rb

module Api
  module V1
    class StatsController < BaseController
      # GET /api/v1/adapters/:adapter_id/stats
      def show
        adapter = current_project_adapters.find(params[:adapter_id])
        
        throughput_calc = ThroughputCalculator.new(adapter)
        latency_analyzer = LatencyAnalyzer.new(adapter)
        health_checker = QueueHealthChecker.new(adapter)
        
        render json: {
          overview: adapter.overall_stats,
          health: health_checker.overall_health,
          throughput: {
            jobs_per_minute: throughput_calc.jobs_per_minute,
            by_queue: throughput_calc.jobs_per_minute_by_queue,
            peak_24h: throughput_calc.peak_throughput
          },
          latency: {
            current: latency_analyzer.current_latencies,
            average: latency_analyzer.average_latency,
            p95: latency_analyzer.p95_latency,
            slowest_queues: latency_analyzer.slowest_queues
          },
          dead_jobs: {
            total: adapter.dead_jobs.actionable.count,
            last_24h: adapter.dead_jobs.where('died_at > ?', 24.hours.ago).count
          },
          workers: {
            total: adapter.workers.count,
            busy: adapter.workers.where(status: 'busy').count,
            idle: adapter.workers.where(status: 'idle').count
          }
        }
      end
      
      # GET /api/v1/adapters/:adapter_id/stats/history
      def history
        adapter = current_project_adapters.find(params[:adapter_id])
        period = (params[:hours] || 24).to_i.hours
        
        render json: {
          throughput: ThroughputCalculator.new(adapter).throughput_series(period: period),
          queue_sizes: queue_size_history(adapter, period),
          latencies: latency_history(adapter, period),
          failure_rate: failure_rate_history(adapter, period)
        }
      end
      
      private
      
      def current_project_adapters
        AdapterConfig.where(platform_project_id: current_project.id)
      end
      
      def queue_size_history(adapter, period)
        adapter.queue_snapshots
               .where('captured_at > ?', period.ago)
               .group("time_bucket('1 hour', captured_at)")
               .sum(:size)
      end
      
      def latency_history(adapter, period)
        adapter.queue_snapshots
               .where('captured_at > ?', period.ago)
               .group("time_bucket('1 hour', captured_at)")
               .maximum(:latency_ms)
      end
      
      def failure_rate_history(adapter, period)
        adapter.queue_snapshots
               .where('captured_at > ?', period.ago)
               .group("time_bucket('1 hour', captured_at)")
               .pluck(
                 Arel.sql("time_bucket('1 hour', captured_at)"),
                 Arel.sql("CASE WHEN SUM(processed_count) > 0 THEN (SUM(failed_count)::float / SUM(processed_count) * 100) ELSE 0 END")
               )
               .to_h
      end
    end
  end
end
```

---

## MCP Tools

```ruby
# lib/nerve/mcp/tools/list_queues.rb

module Nerve
  module Mcp
    module Tools
      class ListQueues < BaseTool
        TOOL_NAME = 'nerve_list_queues'
        DESCRIPTION = 'List all job queues and their current status'
        
        SCHEMA = {
          type: 'object',
          properties: {
            adapter: {
              type: 'string',
              description: 'Adapter name (optional)'
            }
          }
        }.freeze
        
        def call(args)
          adapters = project_adapters
          adapters = adapters.where(name: args[:adapter]) if args[:adapter]
          
          result = []
          
          adapters.each do |adapter|
            health_checker = QueueHealthChecker.new(adapter)
            
            adapter.queues.each do |queue|
              health = health_checker.check_queue(queue)
              
              result << {
                adapter: adapter.name,
                queue: queue.queue_name,
                size: queue.size,
                latency_ms: queue.latency_ms,
                latency_human: humanize_duration(queue.latency_ms),
                throughput: queue.processed_count,
                status: health[:status],
                issues: health[:issues].map { |i| "#{i[:type]}: #{i[:value]}" }
              }
            end
          end
          
          {
            queues: result,
            summary: {
              total_queued: result.sum { |q| q[:size] },
              unhealthy: result.count { |q| q[:status] != 'healthy' }
            }
          }
        end
        
        private
        
        def humanize_duration(ms)
          return '0ms' if ms.zero?
          
          if ms < 1000
            "#{ms}ms"
          elsif ms < 60_000
            "#{(ms / 1000.0).round(1)}s"
          else
            "#{(ms / 60_000.0).round(1)}m"
          end
        end
      end
      
      class QueueStats < BaseTool
        TOOL_NAME = 'nerve_queue_stats'
        DESCRIPTION = 'Get detailed statistics for job queues'
        
        SCHEMA = {
          type: 'object',
          properties: {
            queue_name: {
              type: 'string',
              description: 'Specific queue name (optional)'
            },
            period: {
              type: 'string',
              enum: ['1h', '6h', '24h', '7d'],
              default: '24h'
            }
          }
        }.freeze
        
        def call(args)
          adapter = project_adapters.first
          period = parse_period(args[:period])
          
          throughput_calc = ThroughputCalculator.new(adapter)
          latency_analyzer = LatencyAnalyzer.new(adapter)
          
          {
            overview: adapter.overall_stats,
            throughput: {
              jobs_per_minute: throughput_calc.jobs_per_minute(period: period),
              by_queue: throughput_calc.jobs_per_minute_by_queue(period: period)
            },
            latency: {
              average_ms: latency_analyzer.average_latency(
                queue_name: args[:queue_name],
                period: period
              ),
              p95_ms: latency_analyzer.p95_latency(
                queue_name: args[:queue_name],
                period: period
              )
            },
            workers: {
              total: adapter.workers.count,
              busy: adapter.workers.where(status: 'busy').count
            }
          }
        end
        
        private
        
        def parse_period(period_str)
          case period_str
          when '1h' then 1.hour
          when '6h' then 6.hours
          when '24h' then 24.hours
          when '7d' then 7.days
          else 24.hours
          end
        end
      end
      
      class ListFailedJobs < BaseTool
        TOOL_NAME = 'nerve_list_failed_jobs'
        DESCRIPTION = 'List failed/dead jobs'
        
        SCHEMA = {
          type: 'object',
          properties: {
            job_class: {
              type: 'string',
              description: 'Filter by job class'
            },
            limit: {
              type: 'integer',
              default: 20
            }
          }
        }.freeze
        
        def call(args)
          adapter = project_adapters.first
          
          dead_jobs = adapter.dead_jobs.actionable.recent
          dead_jobs = dead_jobs.by_class(args[:job_class]) if args[:job_class]
          dead_jobs = dead_jobs.limit(args[:limit] || 20)
          
          {
            dead_jobs: dead_jobs.map do |job|
              {
                id: job.id,
                job_class: job.job_class,
                queue: job.queue_name,
                error: job.error_message.truncate(200),
                error_class: job.error_class,
                retries: job.retry_count,
                died_at: job.died_at.iso8601
              }
            end,
            total_dead: adapter.dead_jobs.actionable.count,
            grouped_errors: adapter.dead_jobs.group_by_error.limit(5).map do |g|
              { error: g.error_message.truncate(100), count: g.count }
            end
          }
        end
      end
      
      class RetryJob < BaseTool
        TOOL_NAME = 'nerve_retry_job'
        DESCRIPTION = 'Retry a failed/dead job'
        
        SCHEMA = {
          type: 'object',
          properties: {
            job_id: {
              type: 'string',
              description: 'Dead job ID to retry'
            },
            retry_all: {
              type: 'boolean',
              description: 'Retry all dead jobs',
              default: false
            },
            job_class: {
              type: 'string',
              description: 'Retry all of a specific job class'
            }
          }
        }.freeze
        
        def call(args)
          adapter = project_adapters.first
          
          if args[:retry_all]
            count = retry_all_jobs(adapter, args[:job_class])
            { retried: count, message: "Retried #{count} jobs" }
          elsif args[:job_id]
            job = adapter.dead_jobs.find(args[:job_id])
            job.retry!
            { retried: 1, job_id: job.job_id, job_class: job.job_class }
          else
            { error: 'Provide job_id or retry_all: true' }
          end
        end
        
        private
        
        def retry_all_jobs(adapter, job_class = nil)
          scope = adapter.dead_jobs.actionable
          scope = scope.by_class(job_class) if job_class
          
          count = 0
          scope.find_each do |job|
            job.retry!
            count += 1
          end
          count
        end
      end
      
      class ClearQueue < BaseTool
        TOOL_NAME = 'nerve_clear_queue'
        DESCRIPTION = 'Clear all jobs from a queue (DESTRUCTIVE)'
        
        SCHEMA = {
          type: 'object',
          properties: {
            queue_name: {
              type: 'string',
              description: 'Queue name to clear'
            },
            confirm: {
              type: 'boolean',
              description: 'Must be true to confirm'
            }
          },
          required: ['queue_name', 'confirm']
        }.freeze
        
        def call(args)
          return { error: 'Must confirm: true to clear queue' } unless args[:confirm]
          
          adapter = project_adapters.first
          queue = adapter.queues.find { |q| q.queue_name == args[:queue_name] }
          
          return { error: "Queue '#{args[:queue_name]}' not found" } unless queue
          
          size_before = queue.size
          adapter.adapter.clear_queue(args[:queue_name])
          
          {
            cleared: true,
            queue: args[:queue_name],
            jobs_removed: size_before
          }
        end
      end
    end
  end
end
```

---

## SDK Integration

```ruby
# lib/nerve/sdk/collector.rb

module Nerve
  module Sdk
    class Collector
      def initialize(api_key:, endpoint: 'https://nerve.brainzlab.ai')
        @api_key = api_key
        @endpoint = endpoint
        @adapter_type = detect_adapter
      end
      
      def start
        return unless @adapter_type
        
        Thread.new do
          loop do
            collect_and_send
            sleep polling_interval
          end
        end
      end
      
      private
      
      def detect_adapter
        if defined?(Sidekiq)
          'sidekiq'
        elsif defined?(SolidQueue)
          'solid_queue'
        elsif defined?(Resque)
          'resque'
        elsif defined?(Delayed::Job)
          'delayed_job'
        elsif defined?(GoodJob)
          'good_job'
        end
      end
      
      def collect_and_send
        data = case @adapter_type
               when 'sidekiq' then collect_sidekiq
               when 'solid_queue' then collect_solid_queue
               when 'resque' then collect_resque
               end
        
        send_to_api(data)
      rescue => e
        Rails.logger.error "[Nerve] Collection error: #{e.message}"
      end
      
      def collect_sidekiq
        {
          queues: Sidekiq::Queue.all.map do |q|
            {
              name: q.name,
              size: q.size,
              latency_ms: (q.latency * 1000).to_i
            }
          end,
          workers: Sidekiq::ProcessSet.new.map do |p|
            {
              id: p['identity'],
              hostname: p['hostname'],
              queues: p['queues'],
              concurrency: p['concurrency'],
              busy: p['busy']
            }
          end,
          stats: {
            processed: Sidekiq::Stats.new.processed,
            failed: Sidekiq::Stats.new.failed,
            dead: Sidekiq::DeadSet.new.size,
            retries: Sidekiq::RetrySet.new.size,
            scheduled: Sidekiq::ScheduledSet.new.size
          }
        }
      end
      
      def send_to_api(data)
        Faraday.post("#{@endpoint}/internal/collector") do |req|
          req.headers['Authorization'] = "Bearer #{@api_key}"
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            adapter_type: @adapter_type,
            collected_at: Time.current.iso8601,
            data: data
          }.to_json
        end
      end
      
      def polling_interval
        30 # seconds
      end
    end
  end
end

# Usage in Rails initializer:
# config/initializers/nerve.rb

if Rails.env.production?
  Nerve::Sdk::Collector.new(
    api_key: ENV['BRAINZLAB_API_KEY']
  ).start
end
```

---

## Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :adapters do
        resources :queues, only: [:index, :show] do
          member do
            post :clear
            post :pause
            post :resume
          end
        end
        
        resources :jobs, only: [:index, :show]
        
        resources :dead_jobs, only: [:index, :show] do
          member do
            post :retry
            post :discard
          end
          collection do
            post :retry_all
            post :discard_all
          end
        end
        
        resources :workers, only: [:index, :show]
        
        resource :stats, only: [:show] do
          get :history
        end
        
        resources :alert_thresholds
      end
    end
  end
  
  # Internal collector endpoint
  namespace :internal do
    post 'collector', to: 'collector#create'
  end
  
  # Health
  get 'health', to: 'health#show'
end
```

---

## Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  web:
    build: .
    ports:
      - "3009:3000"
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/nerve
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nerve.rule=Host(`nerve.brainzlab.localhost`)"

  worker:
    build: .
    command: bundle exec rake solid_queue:start
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/nerve
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  collector:
    build: .
    command: bundle exec rake nerve:collect
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/nerve
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: timescale/timescaledb:latest-pg16
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=nerve
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5439:5432"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Summary

### Nerve Features

| Feature | Description |
|---------|-------------|
| **Multi-Adapter** | Sidekiq, Solid Queue, Resque, DelayedJob, GoodJob |
| **Queue Metrics** | Size, latency, throughput |
| **Worker Monitoring** | Active/idle, memory, jobs processed |
| **Dead Jobs** | View, retry, discard, bulk actions |
| **Alerting** | Thresholds for size, latency, failure rate |
| **History** | TimescaleDB time-series storage |
| **Real-time** | ActionCable live updates |

### MCP Tools

| Tool | Description |
|------|-------------|
| `nerve_list_queues` | List all queues with status |
| `nerve_queue_stats` | Get detailed queue statistics |
| `nerve_list_failed_jobs` | List dead/failed jobs |
| `nerve_retry_job` | Retry failed jobs |
| `nerve_clear_queue` | Clear a queue (destructive) |

### Integration Points

| Product | Integration |
|---------|-------------|
| **Signal** | Alerts on queue health issues |
| **Synapse** | Monitor jobs during deploys |
| **Recall** | Correlate job logs with failures |

---

*Nerve = Your async backbone! ⚡*
