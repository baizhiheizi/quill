Hash: manual
# config/queue.yml

Solid Queue config.

Default:
- Dispatcher polling_interval 1s, batch_size 500.
- Workers consume queues [critical, default, low]. Threads from `SOLID_QUEUE_THREADS` (default 5). Processes from `JOB_CONCURRENCY` (default 1). Polling interval 0.1s.

Development: same as default with 1 process.
Test: queues "*", 1 thread, 1 process.
Production: same as default.