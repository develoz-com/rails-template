# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class PushGenerator < Develoz::Generators::Base
      class_option :pwa, type: :boolean, default: false

      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def ensure_pwa_prerequisite
        return if options[:pwa]

        say "develoz:push requires --pwa. Enabling PWA automatically.", :yellow
        require "generators/develoz/pwa/pwa_generator"
        pwa = PwaGenerator.new([], {}, destination_root: destination_root)
        PwaGenerator.public_instance_methods(false).each { |m| pwa.public_send(m) }
      end

      def add_web_push_gem
        add_gem "web-push"
      end

      def create_push_subscription_model
        template "app/models/push_subscription.rb.tt",
                 "app/models/push_subscription.rb"
      end

      def create_push_subscription_migration
        return if migration_exists?("create_push_subscriptions")

        template "db/migrate/create_push_subscriptions.rb.tt",
                 "db/migrate/#{next_migration_timestamp}_create_push_subscriptions.rb"
      end

      def create_push_notification_service
        template "app/services/push_notification_service.rb.tt",
                 "app/services/push_notification_service.rb"
      end

      def create_service_worker_push_handlers
        template "app/views/pwa/sw_push_handlers.js.tt",
                 "app/views/pwa/sw_push_handlers.js"
      end

      def create_subscription_js
        template "app/javascript/pwa/subscription.js.tt",
                 "app/javascript/pwa/subscription.js"
      end

      def append_vapid_env
        append_env "VAPID_PUBLIC_KEY", ""
        append_env "VAPID_PRIVATE_KEY", ""
        append_env "VAPID_SUBJECT", "mailto:noreply@example.com"
      end
    end
  end
end
