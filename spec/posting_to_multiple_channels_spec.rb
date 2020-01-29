# frozen_string_literal: true

require 'spec_helper'

describe Slackistrano do
  before(:all) { set(:slackistrano, channel: %w[one two]) }

  context 'when :slack_channel is an array' do
    %w[starting updating reverting updated reverted failed].each do |stage|
      it "posts to slack on slack:deploy:#{stage} in every channel" do
        expect_any_instance_of(Slackistrano::Capistrano).to(
          receive(:post).twice
        )

        Rake::Task["slack:deploy:#{stage}"].execute
      end
    end
  end
end
