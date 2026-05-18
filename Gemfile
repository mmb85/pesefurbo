source "https://rubygems.org"
ruby "3.4.9"

gem "rails",           "~> 8.0"
gem "pg",              "~> 1.5"
gem "puma",            ">= 5.0"
gem "csv"                             # For CSV parsing in seeds.rb
gem "propshaft"                        # Asset pipeline Rails 8
gem "importmap-rails"                  # JS via importmap (no Node)
gem "turbo-rails"                      # Hotwire Turbo
gem "stimulus-rails"                   # Hotwire Stimulus
gem "tailwindcss-rails"                # Tailwind CSS
gem "solid_queue"                      # Background jobs (Rails 8 native)
gem "solid_queue_dashboard"          # Dashboard for monitoring Solid Queue jobs
gem "solid_cable"                      # ActionCable adapter (Rails 8 native)
gem "solid_cache"                      # Cache adapter (Rails 8 native)
gem "jbuilder"                         # JSON views
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end
