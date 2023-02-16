# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  primary_abstract_class

  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end
end
