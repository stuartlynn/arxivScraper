require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Rack
  class GridFSConnectionError < StandardError ; end

  class GridFS
    VERSION = "0.2.0"

    def initialize(app, options = {})
      options = {
        :hostname => 'localhost',
        :port     => Mongo::Connection::DEFAULT_PORT,
        :prefix   => 'gridfs',
        :lookup   => :id
      }.merge(options)

      @app        = app
      @prefix     = options[:prefix].gsub(/^\//, '')
      @lookup     = options[:lookup]
      @db         = nil
      @debug      = options[:debug]
      @hostname, @port, @database, @username, @password = 
        options.values_at(:hostname, :port, :database, :username, :password)

      connect!
    end

    REQUEST_LOG_DIR = "./log/gridfs.log"

    def call(env)
      request = Rack::Request.new(env)
      if request.path_info =~ /^\/#{@prefix}\/(.+)$/
        gridfs_request($1)
      else
        @app.call(env)
      end
    end

    private
      def connect!
        Timeout::timeout(5) do
          @db = Mongo::Connection.new(@hostname, @port, :slave_ok => true).db(@database)
          @db.authenticate(@username, @password) if @username
        end
      rescue Exception => e
        raise Rack::GridFSConnectionError, "Unable to connect to the MongoDB server (#{e.to_s})"
      end

      def gridfs_request(identifier)
        ::File.open(REQUEST_LOG_DIR, 'wb') do |fh|
          fh.puts("Request for #{identifier}")
        end
        file = find_file(identifier)
        [200, {'Content-Type' => file.content_type}, file]
      rescue Mongo::GridFileNotFound, BSON::InvalidObjectId
        [404, {'Content-Type' => 'text/plain'}, ['File not found.']]
      end

      def find_file(identifier)
        case @lookup.to_sym
        when :id   then Mongo::Grid.new(@db).get(BSON::ObjectId.from_string(identifier))
        when :path then Mongo::GridFileSystem.new(@db).open(identifier, "r")
        end
      end

  end # GridFS class
end # Rack module


module ArxivScraper
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    config_mongo=YAML.load_file(Rails.root + 'config' + 'mongodb.yml')[RAILS_ENV]
     if RAILS_ENV=='production'
                config.middleware.insert_after Rack::Runtime, Rack::GridFS,
                  :prefix => 'file_store', :hostname => config_mongo["host"], :port => config_mongo['port'], :database => config_mongo['database'], :username=>config_mongo["username"], :password=>config_mongo["password"]

              else
                 config.middleware.insert_after Rack::Runtime, Rack::GridFS,
                    :prefix => 'file_store',  :database => config_mongo['database']
     end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
