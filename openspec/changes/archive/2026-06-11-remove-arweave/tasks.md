## 1. Database migration

- [x] 1.1 Generate migration `DropArweaveTransactions` with `drop_table :arweave_transactions`
- [x] 1.2 Run `bin/rails db:migrate` locally and verify schema

## 2. Remove models and concerns

- [x] 2.1 Delete `app/models/arweave_transaction.rb`
- [x] 2.2 Delete `app/models/concerns/articles/arweavable.rb`
- [x] 2.3 Delete `app/models/concerns/users/importable.rb`
- [x] 2.4 Remove `include Articles::Arweavable`, `has_many :arweave_transactions`, and `upload_to_arweave_async` from `Article#do_first_publish`
- [x] 2.5 Remove `has_many :arweave_transactions` and `include Users::Importable` from `User`
- [x] 2.6 Remove `has_one :arweave_transaction` from `ArticleSnapshot`

## 3. Remove jobs and libs

- [x] 3.1 Delete `app/jobs/articles/upload_to_arweave_job.rb`
- [x] 3.2 Delete `app/jobs/articles/batch_upload_to_arweave_job.rb`
- [x] 3.3 Delete `app/jobs/arweave_transactions/batch_accept_job.rb`
- [x] 3.4 Delete `app/jobs/users/import_articles_from_mirror_job.rb`
- [x] 3.5 Delete `app/libs/arweave_bot.rb` and `app/libs/arweave_bot/` directory
- [x] 3.6 Remove `articles_batch_upload_to_arweave_job` and `arweave_transactions_batch_accept_job` from `config/recurring.yml`

## 4. Remove controllers, routes, and notifier

- [x] 4.1 Delete `app/controllers/admin/arweave_transactions_controller.rb`
- [x] 4.2 Delete `app/controllers/dashboard/imported_articles_controller.rb`
- [x] 4.3 Delete `app/notifiers/article_imported_notifier.rb`
- [x] 4.4 Remove `resources :arweave_transactions` from `config/routes/admin.rb`
- [x] 4.5 Remove `resources :imported_articles` from `config/routes/dashboard.rb`

## 5. Remove views and locales

- [x] 5.1 Delete `app/views/articles/_blockchain_info.html.erb` and remove renders from `_full_content` and `_partial_content`
- [x] 5.2 Delete `app/views/admin/arweave_transactions/` directory
- [x] 5.3 Remove AR Tx tab from `app/views/admin/articles/show.html.erb` and "AR Tx" from `app/views/admin/_aside.html.erb`
- [x] 5.4 Delete `app/views/dashboard/imported_articles/` and remove Mirror import link from `app/views/dashboard/articles/index.html.erb`
- [x] 5.5 Remove Arweave/Mirror locale keys from `config/locales/views.*.yml` and `config/locales/notifications.*.yml`

## 6. Remove gems and dependencies

- [x] 6.1 Remove `gem "arweave"` and `gem "graphql-client"` from `Gemfile`
- [x] 6.2 Run `bundle install` and commit updated `Gemfile.lock`

## 7. Remove tests and fixtures

- [x] 7.1 Delete `test/models/arweave_transaction_test.rb`
- [x] 7.2 Delete `test/fixtures/arweave_transactions.yml`
- [x] 7.3 Delete `test/jobs/articles/upload_to_arweave_job_test.rb`
- [x] 7.4 Delete `test/jobs/articles/batch_upload_to_arweave_job_test.rb`
- [x] 7.5 Delete `test/jobs/arweave_transactions/batch_accept_job_test.rb`
- [x] 7.6 Delete `test/jobs/users/import_articles_from_mirror_job_test.rb`
- [x] 7.7 Update `test/models/noticed_notification_test.rb` to remove `ArticleImportedNotifier` assertion

## 8. Update documentation

- [x] 8.1 Remove Arweave references from `AGENTS.md`
- [x] 8.2 Update `docs/explanation/architecture.md` (article lifecycle diagram and persistence section)
- [x] 8.3 Update `docs/reference/background-jobs.md` (remove Arweave jobs section)
- [x] 8.4 Update `.cursor/rules/project-overview.mdc`

## 9. Verify

- [x] 9.1 Run `bin/rubocop` on changed Ruby files
- [x] 9.2 Run `bin/rails test`
- [x] 9.3 Run `bin/rails zeitwerk:check`
