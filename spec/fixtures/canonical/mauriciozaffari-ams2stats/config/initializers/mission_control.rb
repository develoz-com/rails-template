# frozen_string_literal: true

# Mission Control - Jobs ships with HTTP basic auth enabled and closed by default,
# and ams2stats has no user model, so credentials are supplied via the environment.
MissionControl::Jobs.http_basic_auth_user = ENV.fetch("MISSION_CONTROL_HTTP_BASIC_AUTH_USER", "admin")
MissionControl::Jobs.http_basic_auth_password = ENV.fetch("MISSION_CONTROL_HTTP_BASIC_AUTH_PASSWORD", "")
