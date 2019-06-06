# frozen_string_literal: true

module Slackistrano
  module Messaging
    class Null < Base
      def payload_for_updating; end

      def payload_for_reverting; end

      def payload_for_updated; end

      def payload_for_reverted; end

      def payload_for_failed; end
    end
  end
end
