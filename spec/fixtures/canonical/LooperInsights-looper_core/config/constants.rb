# frozen_string_literal: true

## Assign all environment variables used by the Rails app to constants for easy access and tracking

AWS_ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
AWS_SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
AWS_EXPORTS_BUCKET = ENV.fetch('AWS_EXPORTS_BUCKET', 'looper.data.export')
AWS_EXPORTS_REGION = ENV.fetch('AWS_EXPORTS_REGION', 'eu-west-1')

# Web scraping via Zyte
CRAWLERA_API_USERNAME = ENV.fetch('CRAWLERA_API_USERNAME', nil)
CRAWLERA_API_URL = ENV.fetch('CRAWLERA_API_URL', nil)
CRAWLERA_APP_API_URL = ENV.fetch('CRAWLERA_APP_API_URL', nil)
CRAWLERA_PROJECT_ID = ENV.fetch('CRAWLERA_PROJECT_ID', nil)
CRAWLERA_API_ITEMS_LIMIT = ENV.fetch('CRAWLERA_API_ITEMS_LIMIT', 1000).to_i
CRAWLERA_HEADLESS_PROXY_HOST = ENV.fetch('CRAWLERA_HEADLESS_PROXY_HOST', nil)

DEBUG_HEADLESS_REQUESTS = ENV.fetch('DEBUG_HEADLESS_REQUESTS', nil) == 'true'

# SMPT Credentials
SMTP_USERNAME = ENV.fetch('SMTP_USERNAME', nil)
SMTP_PASSWORD = ENV.fetch('SMTP_PASSWORD', nil)
SMTP_ADDRESS = ENV.fetch('SMTP_ADDRESS', nil)

# true: Upload artworks to our s3; false: Store artwork URL as is;
UPLOAD_AUDIT_ARTWORKS = ENV.fetch('UPLOAD_AUDIT_ARTWORKS', nil) == 'true'

# Database configuration
DATABASE_HOST = ENV.fetch('DATABASE_HOST', 'localhost')
DATABASE_PORT = ENV.fetch('DATABASE_PORT', 5432)
DATABASE_NAME = ENV.fetch('DATABASE_NAME', 'core')
DATABASE_USER = ENV.fetch('DATABASE_USER', 'core')
DATABASE_PASSWORD = ENV.fetch('DATABASE_PASSWORD', 'core')
TEST_DATABASE_NAME = ENV.fetch('TEST_DATABASE_NAME', "#{DATABASE_NAME}_test")

# Redis configuration
# Use different Redis databases for parallel test processes to avoid conflicts
REDIS_URL = ENV.fetch('REDIS_URL', "redis://localhost:6379/#{ENV.fetch('TEST_ENV_NUMBER', 1)}")

COGNITO_REGION = ENV.fetch('COGNITO_REGION', nil)
COGNITO_USERPOOL_ID = ENV.fetch('COGNITO_USERPOOL_ID', nil)
COGNITO_APP_DOMAIN = ENV.fetch('COGNITO_APP_DOMAIN', nil)
COGNITO_CLIENT_ID = ENV.fetch('COGNITO_CLIENT_ID', nil)
COGNITO_AUTHENTICATION_BYPASS = ENV.fetch('COGNITO_AUTHENTICATION_BYPASS', nil) == 'true'

# Skip migrations on given occasions
SKIP_MIGRATIONS = ENV.fetch('SKIP_MIGRATIONS', nil) == 'true'

# APP configuration
RAILS_ENV = ENV.fetch('RAILS_ENV', nil)
RAILS_MAX_THREADS = ENV.fetch('RAILS_MAX_THREADS', `nproc || echo 2`.strip.to_i * 5)
SERVER_PORT = ENV.fetch('SERVER_PORT', 3000)
HOST = ENV.fetch('APP_HOST') { ENV.fetch('HOST', "localhost:#{SERVER_PORT}") }
ENVIRONMENTS = {
  local: HOST,
  dev: 'admin.core.dev.looperinsights.com',
  test: 'admin.core.test.looperinsights.com',
  production: 'admin.data.looperinsights.com'
}.freeze
ENVIRONMENT = ENV.fetch('ENVIRONMENT', 'local')
# How much time to cache cognito sessions information
# Default is 1 day (86400 seconds)
SESSION_EXPIRES_IN = ENV.fetch('SESSION_EXPIRES_IN', 86_400).to_i
# "info" includes generic and useful information about system operation, but avoids logging too much
# information to avoid inadvertent exposure of personally identifiable information (PII). If you
# want to log everything, set the level to "debug".
RAILS_LOG_LEVEL = ENV.fetch('RAILS_LOG_LEVEL', 'info')

CACHING_DEV = ENV.fetch('CACHING_DEV', nil) == 'true' # Enable caching in development if set to "true"

# Read counters from counter-cache
COUNTER_CACHE_ENABLED = ENV.fetch('COUNTER_CACHE_ENABLED', false)

# Memcached configuration
MEMCACHIER_SERVERS = ENV.fetch('MEMCACHIER_SERVERS', '').split(',')
MEMCACHIER_USERNAME = ENV.fetch('MEMCACHIER_USERNAME', nil)
MEMCACHIER_PASSWORD = ENV.fetch('MEMCACHIER_PASSWORD', nil)

APP_NAME = ENV.fetch('APP_NAME', 'Webstores')

# Track released version
APP_VERSION = File.read('VERSION').strip

# React core UI URL
CORE_UI_URL = ENV.fetch('CORE_UI_URL', nil)

# Screenshot service endpoint URL
SCREENSHOT_URL = ENV.fetch('SCREENSHOT_URL', nil)

# Sentry error and performance monitoring
SENTRY_DSN = ENV.fetch('SENTRY_DSN', 'https://049ccfa1232f4710bce385d7bd77110c@o101996.ingest.us.sentry.io/224334')

# Selenium url for integration/system tests
SELENIUM_REMOTE_URL = ENV.fetch('SELENIUM_REMOTE_URL', 'http://localhost:4444/wd/hub')

# Tracking
HOTJAR_ID = ENV.fetch('HOTJAR_ID', nil)
GOOGLE_TAG_MANAGER_IDS = ENV.fetch('GOOGLE_TAG_MANAGER_IDS', '').split

# OpenAI API key for GPT requests
CHATGPT_API_KEY = ENV.fetch('CHATGPT_API_KEY', nil)

SPIDER_HEALTH_SLACK_WEBHOOK_URL = ENV.fetch('SPIDER_HEALTH_SLACK_WEBHOOK_URL', nil)

PRICING_POLICY_SLACK_WEBHOOK_URL = ENV.fetch('PRICING_POLICY_SLACK_WEBHOOK_URL', nil)

UNAVAILABLE_RETRY_SLACK_WEBHOOK_URL = ENV.fetch('UNAVAILABLE_RETRY_SLACK_WEBHOOK_URL', nil)

# Zyte SPM Proxy
CRAWLERA_SPM_HOST = ENV.fetch('CRAWLERA_SPM_HOST', 'looperinsights.crawlera.com')
CRAWLERA_SPM_PORT = ENV.fetch('CRAWLERA_SPM_PORT', '8010')
CRAWLERA_SPM_KEY = ENV.fetch('CRAWLERA_SPM_KEY', '12276f9df7b64dd0bd1a6f55192ac7a6')
CRAWLERA_SPM_CERTIFICATE = ENV.fetch('CRAWLERA_SPM_CERTIFICATE',
                                     File.join(File.expand_path('..', __dir__), 'config/zyte-ca.crt'))

# Zyte API Proxy
ZYTE_API_PROXY_HOST = ENV.fetch('ZYTE_API_PROXY_HOST', 'api.zyte.com')
ZYTE_API_PROXY_PORT = ENV.fetch('ZYTE_API_PROXY_PORT', '8011')
ZYTE_API_PROXY_KEY = ENV.fetch('ZYTE_API_PROXY_KEY', nil)
ZYTE_API_PROXY_CERTIFICATE = ENV.fetch('ZYTE_API_PROXY_CERTIFICATE',
                                       File.join(File.expand_path('..', __dir__), 'config/zyte-ca.crt'))

# Debug proxy requests
DEBUG_PROXY_REQUESTS = ENV.fetch('DEBUG_PROXY_REQUESTS', nil)

# Use legacy importer
USE_LEGACY_IMPORTER = ENV.fetch('USE_LEGACY_IMPORTER', nil) == 'true'

SIDEKIQ_MCP_TOKEN = ENV.fetch('SIDEKIQ_MCP_TOKEN', '4FYUylCOUw80OXUt6qkE7aNg4GExTeWH')
