# frozen_string_literal: true

class HomeController < ApplicationController
  def index
  end

  def hot_tags
    @hot_tags = Tag.hot.where(locale: current_locale.to_s.split('-').first).limit(50).sample(5)
  end

  def active_authors
    @users = User.only_validated.active.where.not(id: current_user&.block_user_ids).where(locale: current_locale).limit(20).sample(5)
  end
end