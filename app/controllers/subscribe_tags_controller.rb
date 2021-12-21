# frozen_string_literal: true

class SubscribeTagsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_tag

  def create
    current_user.create_action :subscribe, target: @tag
  end

  def destroy
    current_user.destroy_action :subscribe, target: @tag
  end

  private

  def load_tag
    @tag = Tag.find_by id: params[:id]
  end
end
