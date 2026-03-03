class HomeController < ActionController::API
  def index
    render json: {
      service: "Nerve",
      version: "0.1.0",
      status: "ok",
      description: "Background job monitoring for Sidekiq, Solid Queue, Resque, DelayedJob, and GoodJob"
    }
  end
end
