require "bundler/setup"

require "active_support"
require "active_support/core_ext/time"
require "pry-byebug"
require "climate_control"

require "hash_struct"

Dir.glob(File.expand_path("support/**/*.rb", __dir__)).each do |file|
  require file
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.extend Macros
  config.include Helpers
end

Time.zone = "UTC"
