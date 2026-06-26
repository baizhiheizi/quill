627
filter: user=find_by(mixin_uuid: user_id). approved: false if blank; if type=recent then payments(paid|completed) in last week or articles published last week; else payments(paid|completed) or only_published articles. Returns {approved:}.
