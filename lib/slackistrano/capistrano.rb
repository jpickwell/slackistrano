# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'net/http'
require_relative 'messaging/base'

load File.expand_path('tasks/slack.rake', __dir__)

module Slackistrano
  class Capistrano
    extend Forwardable

    attr_reader :backend
    private :backend

    def_delegators :env, :fetch, :run_locally

    def initialize(env)
      @env = env
      config = fetch(:slackistrano, {})

      @messaging =
        if config
          opts = config.dup.merge(env: @env)
          klass = opts.delete(:klass) || Messaging::Default
          klass.new(opts)
        else
          Messaging::Null.new
        end
    end

    def run(action)
      this = self
      run_locally { this.process(action, self) }
    end

    def process(action, backend)
      @backend = backend
      payload = @messaging.payload_for(action)

      return if payload.nil?

      payload = {
        username: @messaging.username,
        icon_url: @messaging.icon_url,
        icon_emoji: @messaging.icon_emoji
      }.merge(payload)

      channels = Array(@messaging.channels_for(action))

      # default webhook channel
      channels = [nil] if !@messaging.via_slackbot? && channels.empty?

      channels.each { |channel| post(payload.merge(channel: channel)) }
    end

    private

    attr_reader :backend

    def post(payload)
      if dry_run?
        post_dry_run(payload)

        return
      end

      begin
        response = post_to_slack(payload)
      rescue StandardError => e
        response = nil

        backend.warn('[slackistrano] Error notifying Slack!')
        backend.warn("[slackistrano]   Error: #{e.inspect}")
      end

      return unless response && response.code !~ /^2/

      warn('[slackistrano] Slack API Failure!')
      warn("[slackistrano]   URI: #{response.uri}")
      warn("[slackistrano]   Code: #{response.code}")
      warn("[slackistrano]   Message: #{response.message}")

      unless response.message != response.body && response.body !~ /<html/
        return
      end

      warn("[slackistrano]   Body: #{response.body}")
    end

    def post_to_slack(payload = {})
      if @messaging.via_slackbot?
        post_to_slack_as_slackbot(payload)
      else
        post_to_slack_as_webhook(payload)
      end
    end

    def post_to_slack_as_slackbot(payload = {})
      team = @messaging.team
      token = @messaging.token
      channel = payload[:channel]
      uri =
        URI(
          CGI.escape(
            "https://#{team}.slack.com/services/hooks/slackbot" \
              "?token=#{token}&channel=#{channel}"
          )
        )

      text =
        (payload[:attachments] || [payload]).collect { |a| a[:text] }.join("\n")

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request_post(uri, text)
      end
    end

    def post_to_slack_as_webhook(payload = {})
      params = { 'payload' => payload.to_json }
      uri = URI(@messaging.webhook)

      Net::HTTP.post_form(uri, params)
    end

    def dry_run?
      ::Capistrano::Configuration.env.dry_run?
    end

    def post_dry_run(payload)
      backend.info('[slackistrano] Slackistrano Dry Run:')

      if @messaging.via_slackbot?
        backend.info("[slackistrano]   Team: #{@messaging.team}")
        backend.info("[slackistrano]   Token: #{@messaging.token}")
      else
        backend.info("[slackistrano]   Webhook: #{@messaging.webhook}")
      end

      backend.info("[slackistrano]   Payload: #{payload.to_json}")
    end
  end
end
