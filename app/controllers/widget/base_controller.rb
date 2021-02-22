# frozen_string_literal: true

class Widget::BaseController < ApplicationController
  include Pagy::Backend

  layout 'widget'
end
