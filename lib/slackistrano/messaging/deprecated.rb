# frozen_string_literal: true

module Slackistrano
  module Messaging
    class Deprecated < Base
      def initialize(
        env: nil, team: nil, channel: nil, token: nil, webhook: nil
      )
        run_locally do
          warn(
            '[slackistrano] You are using an outdated configuration that will' \
              ' be removed soon.'
          )
          warn(
            '[slackistrano] Please upgrade soon!' \
              ' <https://github.com/phallstrom/slackistrano>'
          )
        end

        super
      end

      def icon_url
        fetch(:slack_icon_url) || super
      end

      def icon_emoji
        fetch(:slack_icon_emoji) || super
      end

      def username
        fetch(:slack_username) || super
      end

      def deployer
        fetch(:slack_deploy_user) || super
      end

      def channels_for(action)
        fetch("slack_channel_#{action}".to_sym) || super
      end

      def payload_for_updating
        make_message(__method__, super)
      end

      def payload_for_reverting
        make_message(__method__, super)
      end

      def payload_for_updated
        make_message(__method__, super.merge(color: 'good'))
      end

      def payload_for_reverted
        make_message(__method__, super.merge(color: 'warning'))
      end

      def payload_for_failed
        make_message(__method__, super.merge(color: 'danger'))
      end

      private

      def make_message(method, options = {})
        action = method.to_s.sub('payload_for_', '')

        unless fetch(:slack_run, true) &&
               fetch("slack_run_#{action}".to_sym, true)
          return nil
        end

        attachment =
          options.merge(
            title: fetch(:"slack_title_#{action}"),
            pretext: fetch(:"slack_pretext_#{action}"),
            text: fetch(:"slack_msg_#{action}", options[:text]),
            fields: fetch(:"slack_fields_#{action}", []),
            fallback: fetch(:"slack_fallback_#{action}"),
            mrkdwn_in: %i[text pretext]
          )
            .reject { |_k, v| v.nil? }

        { attachments: [attachment] }
      end
    end
  end
end
