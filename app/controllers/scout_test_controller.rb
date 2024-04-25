class ScoutTestController < ApplicationController
  def index
    15.times do |i|
      sleep(1)
      Rails.logger.info "Slept for #{i} seconds"
    end
    render json: { message: "Hello, World!" }
  end
end