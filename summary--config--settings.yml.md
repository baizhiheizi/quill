<file hash: 2026-06-24-manual</content>
<content>
# config/settings.yml summary

Top-level runtime settings:
- host: https://quill.im
- mixin_oauth_path
- launch_time
- icon_file
- blaze_enable
- app_name: Quill
- page_title / page_keywords / page_description
- twitter_account: with_quill  (used by all three layouts for Twitter Card meta)
- supported_assets: BTC, XIN, ETH, pUSD (UUIDs)
- whitelist: enable + mixin_id list
- pando: 4swap mtg_members + mtg_threshold
- storage.endpoint: https://assets.quill.im

Used by views via Settings.<key> and by services (e.g. Orders::DistributeService uses QuillBot.api.client_id).