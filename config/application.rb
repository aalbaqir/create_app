require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module CaptionApp
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 7.2.
    config.load_defaults 7.2

    # API-only configuration
    config.api_only = true

    # CORS Configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:3001'  # Adjust according to your frontend
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
  end
end
