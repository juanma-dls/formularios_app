require "google/apis"

Google::Apis.logger = ActiveSupport::Logger.new($stdout, level: Logger::WARN)