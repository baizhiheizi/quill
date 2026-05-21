# frozen_string_literal: true

require "test_helper"

class Articles::BatchUploadToArweaveJobTest < JobTestCase
  test "perform enqueues upload jobs for recently updated published articles" do
    article = articles(:published_paid)
    article.update_columns(updated_at: 1.hour.ago.beginning_of_hour + 30.minutes)

    assert_enqueued_with(job: Articles::UploadToArweaveJob, args: [ article.id ]) do
      Articles::BatchUploadToArweaveJob.perform_now
    end
  end
end
