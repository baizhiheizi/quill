# frozen_string_literal: true

class Collections::SubscribersController < Collections::BaseController
  def index
    @page, @subscribers = pagy @collection.subscribers
  end
end
