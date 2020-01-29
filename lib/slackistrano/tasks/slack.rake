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
      # show the starting message as soon as possible
      before 'deploy:starting', 'slack:deploy:starting'

      # show the finished message as late as possible
      after 'deploy:finished', 'slack:deploy:finished'

      # For the above tasks, the earliest we could show the starting messages is
      # before the "deploy" and "deploy:rollback" tasks. The latest we can show
      # the finished messages is after those tasks.

      after 'deploy:failed', 'slack:deploy:failed'
    end

    desc 'Notify about starting deploy'
    task :starting do
      if fetch(:deploying)
        Slackistrano::Capistrano.new(self).run(:updating)
      else
        Slackistrano::Capistrano.new(self).run(:reverting)
      end
    end

    desc 'Notify about finished deploy'
    task :finished do
      if fetch(:deploying)
        Slackistrano::Capistrano.new(self).run(:updated)
      else
        Slackistrano::Capistrano.new(self).run(:reverted)
      end
    end

    desc 'Notify about failed deploy'
    task :failed do
      Slackistrano::Capistrano.new(self).run(:failed)
    end

    desc 'Test Slack integration'
    task test: %i[starting updating updated reverting reverted failed] do
      # all tasks run as dependencies
    end
  end
end
