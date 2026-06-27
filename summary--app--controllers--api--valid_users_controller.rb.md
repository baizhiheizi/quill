627
filter: user=User.find_by(mixin_uuid: user_id). approved = false if blank; if type=recent, sum payments(paid|completed) in last week OR articles only_published in last week; else sum payments(paid|completed) OR articles only_published (all-time). Renders {approved:}.
