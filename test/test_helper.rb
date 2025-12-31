# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  
  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Channels", "app/channels"
end

ENV["RAILS_ENV"] ||= "test"
ENV["BRAINZLAB_SDK_ENABLED"] = "false"  # Disable SDK during tests to avoid database issues
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Stub PlatformClient for tests
class PlatformClient
  def self.validate_key(api_key)
    if api_key == "valid_key"
      {
        valid: true,
        project_id: "prj_test123",
        project_name: "Test Project",
        environment: "live",
        features: { nerve: true }
      }
    elsif api_key&.start_with?("nrv_")
      nil # Will be handled by find_project_by_api_key
    else
      { valid: false }
    end
  end

  def self.track_usage(project_id:, product:, metric:, count:)
    # Stub - do nothing in tests
    true
  end

  def self.get_project_config(platform_project_id:)
    {
      name: "Test Project",
      environment: "live"
    }
  end
end
