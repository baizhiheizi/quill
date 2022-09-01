# frozen_string_literal: true

class EditorComponent < ApplicationComponent
  def initialize(draft_key: '')
    super

    @draft_key = draft_key
  end
end
