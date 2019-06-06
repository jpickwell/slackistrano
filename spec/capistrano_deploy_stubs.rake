# frozen_string_literal: true

namespace :deploy do
  task :starting
  task :started
  task :updating
  task :updated
  task :reverting
  task :reverted
  task :publishing
  task :published
  task :finishing
  task :finishing_rollback
  task :finished
  task :failed
end
