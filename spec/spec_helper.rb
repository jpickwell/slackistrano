# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
$LOAD_PATH.unshift(__dir__)

require 'capistrano/all'
require 'capistrano/setup'

load 'capistrano_deploy_stubs.rake'

require 'slackistrano'
require 'slackistrano/capistrano'
require 'rspec'
require 'pry'

# Requires supporting files with custom matchers and macros, etc, in
# `./support/` and its subdirectories.
Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.fail_fast = 1
end

# Silence rake's '** Execute...' output
Rake.application.options.trace = false
