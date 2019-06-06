# frozen_string_literal: true

namespace :load do
  task :defaults do
    set :slackistrano_default_hooks, true

    set :slackistrano, {}
  end
end

namespace :deploy do
  before(:starting, :check_slackistrano_hooks) do
    return unless fetch(:slackistrano_default_hooks)

    invoke 'slack:deploy:add_default_hooks'
  end
end

namespace :slack do
  namespace :deploy do
    task :add_default_hooks do
      before 'deploy:starting', 'slack:deploy:updating'
      before 'deploy:reverting', 'slack:deploy:reverting'
      after 'deploy:finishing', 'slack:deploy:updated'
      after 'deploy:finishing_rollback', 'slack:deploy:reverted'
      after 'deploy:failed', 'slack:deploy:failed'
    end

    desc 'Notify about updating deploy'
    task :updating do
      Slackistrano::Capistrano.new(self).run(:updating)
    end

    desc 'Notify about reverting deploy'
    task :reverting do
      Slackistrano::Capistrano.new(self).run(:reverting)
    end

    desc 'Notify about updated deploy'
    task :updated do
      Slackistrano::Capistrano.new(self).run(:updated)
    end

    desc 'Notify about reverted deploy'
    task :reverted do
      Slackistrano::Capistrano.new(self).run(:reverted)
    end

    desc 'Notify about failed deploy'
    task :failed do
      Slackistrano::Capistrano.new(self).run(:failed)
    end

    desc 'Test Slack integration'
    task test: %i[updating updated reverting reverted failed] do
      # all tasks run as dependencies
    end
  end
end
