# frozen_string_literal: true

require "develoz"

module Develoz
  module Generators
    class AuthGenerator < Develoz::Generators::Base
      def self.source_root
        File.expand_path("templates", __dir__)
      end

      def add_bcrypt_gem
        add_gem "bcrypt"
      end

      def create_user_model
        template "app/models/user.rb.tt", "app/models/user.rb"
      end

      def create_current_model
        template "app/models/current.rb.tt", "app/models/current.rb"
      end

      def create_authentication_concern
        template "app/controllers/concerns/authentication.rb.tt",
                 "app/controllers/concerns/authentication.rb"
      end

      def create_sessions_controller
        template "app/controllers/sessions_controller.rb.tt",
                 "app/controllers/sessions_controller.rb"
      end

      def create_passwords_controller
        template "app/controllers/passwords_controller.rb.tt",
                 "app/controllers/passwords_controller.rb"
      end

      def create_passwords_mailer
        template "app/mailers/passwords_mailer.rb.tt",
                 "app/mailers/passwords_mailer.rb"
      end

      def create_sessions_views
        template "app/views/sessions/new.html.erb.tt",
                 "app/views/sessions/new.html.erb"
      end

      def create_passwords_views
        template "app/views/passwords/edit.html.erb.tt",
                 "app/views/passwords/edit.html.erb"
      end

      def create_passwords_mailer_views
        template "app/views/passwords_mailer/reset.html.erb.tt",
                 "app/views/passwords_mailer/reset.html.erb"
      end

      def create_users_migration
        template "db/migrate/create_users.rb.tt",
                 "db/migrate/create_users.rb"
      end

      def insert_auth_routes
        insert_route "resource :session, only: [:new, :create, :destroy]"
        insert_route "resources :passwords, param: :token, only: [:new, :create, :edit, :update]"
      end

      def create_sessions_request_spec
        template "spec/requests/sessions_spec.rb.tt",
                 "spec/requests/sessions_spec.rb"
      end

      def create_passwords_request_spec
        template "spec/requests/passwords_spec.rb.tt",
                 "spec/requests/passwords_spec.rb"
      end
    end
  end
end
