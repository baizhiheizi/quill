# frozen_string_literal: true

class MilkdownEditorComponent < ApplicationComponent
  def initialize(draft_key: '', storage_endpoint: '')
    super

    @draft_key = draft_key
    @storage_endpoint = Settings.storage.endpoint
  end
end
