require "bundler/setup"

require "active_support"
require "active_support/core_ext/time"
require "pry-byebug"
require "climate_control"

require "hash_struct"

RSpec.configure do |config|
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Time.zone = "UTC"
