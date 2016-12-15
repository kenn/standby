module ActiveRecord
  module ConnectionHandling
    # Already defined in Rails 4.1+
    RAILS_ENV ||= -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"] || ENV["RACK_ENV"] }
  end
end
