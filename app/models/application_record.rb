# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  primary_abstract_class

  def self.ransackable_attributes(_auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(_auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  def self.ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object)
  end

  def self.ransackable_scopes(_auth_object = nil)
    []
  end
end
