## ADDED Requirements

### Requirement: Published content persists in application storage

The system SHALL store published article content in PostgreSQL and ActiveStorage. Article bodies MUST remain accessible to authorized readers through the existing Quill application without reliance on external permanence networks.

#### Scenario: Reader accesses paid article after purchase

- **WHEN** a reader with a valid order views a published paid article
- **THEN** the system serves the article body from application storage
- **AND** no external permanence network lookup is performed

#### Scenario: Author publishes an article

- **WHEN** an author publishes an article for the first time
- **THEN** the system persists the article in PostgreSQL and ActiveStorage
- **AND** the system does not enqueue any upload to an external permanence network

### Requirement: Article snapshots remain available

The system SHALL continue to create `ArticleSnapshot` records when article content changes, capturing title, intro, content, and digest in PostgreSQL JSON.

#### Scenario: Published article content is updated

- **WHEN** an author updates a published article's content
- **THEN** the system creates a new article snapshot with the updated content
- **AND** no external permanence upload is triggered

## REMOVED Requirements

### Requirement: Article content uploaded to Arweave on publish

**Reason**: Arweave permanence is unused and unmaintained; no users depend on on-chain copies.

**Migration**: Historical `arweave_transactions` rows are dropped with the table. On-chain data on Arweave, if any, remains independently but is no longer linked from Quill.

### Requirement: Hourly batch re-upload to Arweave

**Reason**: Batch upload job exists solely to mirror content to Arweave.

**Migration**: Remove `Articles::BatchUploadToArweaveJob` and its recurring schedule entry.

### Requirement: Arweave transaction acceptance polling

**Reason**: No new transactions will be created; polling is unnecessary.

**Migration**: Remove `ArweaveTransactions::BatchAcceptJob` and its recurring schedule entry.

### Requirement: Web3 Proof of Publishing panel on article pages

**Reason**: Panel displayed Arweave transaction IDs and links; feature is unused.

**Migration**: Remove `_blockchain_info` partial and its renders from article content views.

### Requirement: Mirror.xyz article import

**Reason**: Import path reads Mirror content from Arweave GraphQL; unused migration tool.

**Migration**: Remove dashboard import UI, `Users::Importable`, `ImportArticlesFromMirrorJob`, `ArweaveBot`, and `ArticleImportedNotifier`.
