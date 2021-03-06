require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

module TypoBlog
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Setup the cache path
    config.action_controller.page_cache_directory = "#{::Rails.root.to_s}/public/cache/"
    config.cache_store=:file_store, "#{::Rails.root.to_s}/public/cache/"

    # I need the localization plugin to load first
    # Otherwise, I can't localize plugins <= localization
    # Forcing manually the load of the textfilters plugins fixes the bugs with apache in production.
    config.plugins = [ :localization, :all ]

    config.autoload_paths += %W(
      vendor/akismet
      app/apis
      lib
    ).map {|dir| "#{::Rails.root.to_s}/#{dir}"}.select { |dir| File.directory?(dir) }

    # Activate observers that should always be running
    config.active_record.observers = :email_notifier, :web_notifier

    # Filter sensitive parameters from the log file
    config.filter_parameters << :password
  end

  # Load included libraries.
  #require 'uuidtools'

  require 'action_web_service'
  require 'migrator'
  require 'rails_patch/active_record'
  require 'rails_patch/active_support'
  require 'vendor/plugins/typo_login_system/lib/login_system'
  require 'typo_version'
  $KCODE = 'u'
  require 'jcode'
  require 'transforms'

  $FM_OVERWRITE = true
  require 'filemanager'

  Date::DATE_FORMATS.merge!(
    :long_weekday => '%a %B %e, %Y %H:%M'
  )

  ActionMailer::Base.default :charset => 'utf-8'

  # Work around interpolation deprecation problem: %d is replaced by
  # {{count}}, even when we don't want them to.
  # FIXME: We should probably fully convert to standard Rails I18n.
  require 'i18n_interpolation_deprecation'
  class I18n::Backend::Simple
    def interpolate(locale, string, values = {})
      interpolate_without_deprecated_syntax(locale, string, values)
    end
  end

  if ::Rails.env != 'test'
    begin
      mail_settings = YAML.load(File.read("#{::Rails.root.to_s}/config/mail.yml"))

      ActionMailer::Base.delivery_method = mail_settings['method']
      ActionMailer::Base.server_settings = mail_settings['settings']
    rescue
      # Fall back to using sendmail by default
      ActionMailer::Base.delivery_method = :sendmail
    end
  end
end
