# frozen_string_literal: true

Rails.application.configure do
  config.active_job.queue_adapter = :good_job

  config.good_job.execution_mode = :external
  config.good_job.max_threads = 50
  config.good_job.enable_cron = true
  config.good_job.cron = {
    articles_batch_upload_to_arweave_job: {
      cron: '0 */1 * * *',
      class: 'Articles::BatchUploadToArweaveJob'
    },
    arweave_transactions_batch_accept_job: {
      cron: '*/15 * * * *',
      class: 'ArweaveTransactions::BatchAcceptJob'
    },
    currencies_sync_job: {
      cron: '*/5 * * * *',
      class: 'Currencies::SyncJob'
    },
    daily_statistics_generate_job: {
      cron: '0 0 * * *',
      class: 'DailyStatistics::GenerateJob'
    },
    mixin_network_snapshots_monitor_job: {
      cron: '* * * * *',
      class: 'MixinNetworkSnapshots::MonitorJob'
    },
    orders_batch_distribute_job: {
      cron: '*/10 * * * *',
      class: 'Orders::BatchDistributeJob'
    },
    transfers_cache_stats_job: {
      cron: '*/10 * * * *',
      class: 'Transfers::CacheStatsJob'
    },
    transfers_monitor_job: {
      cron: '*/15 * * * *',
      class: 'Transfers::MonitorJob'
    }
  }
end
