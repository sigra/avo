module Avo
  class Configuration
    include ResourceConfiguration

    attr_writer :app_name
    attr_writer :branding
    attr_writer :root_path
    attr_writer :cache_store
    attr_writer :logger
    attr_writer :turbo
    attr_writer :pagination
    attr_writer :explicit_authorization
    attr_accessor :timezone
    attr_accessor :per_page
    attr_accessor :per_page_steps
    attr_accessor :via_per_page
    attr_accessor :locale
    attr_accessor :currency
    attr_accessor :default_view_type
    attr_accessor :license_key
    attr_accessor :authorization_methods
    attr_accessor :authenticate
    attr_accessor :current_user
    attr_accessor :id_links_to_resource
    attr_accessor :full_width_container
    attr_accessor :full_width_index_view
    attr_accessor :cache_resources_on_index_view
    attr_accessor :cache_resource_filters
    attr_accessor :context
    attr_accessor :display_breadcrumbs
    attr_accessor :hide_layout_when_printing
    attr_accessor :initial_breadcrumbs
    attr_accessor :home_path
    attr_accessor :search_debounce
    attr_accessor :view_component_path
    attr_accessor :display_license_request_timeout_error
    attr_accessor :current_user_resource_name
    attr_accessor :raise_error_on_missing_policy
    attr_writer :disabled_features
    attr_accessor :buttons_on_form_footers
    attr_accessor :main_menu
    attr_accessor :profile_menu
    attr_accessor :model_resource_mapping
    attr_reader :resource_default_view
    attr_accessor :authorization_client
    attr_accessor :field_wrapper_layout
    attr_accessor :sign_out_path_name
    attr_accessor :resources
    attr_accessor :prefix_path
    attr_accessor :resource_parent_controller
    attr_accessor :mount_avo_engines
    attr_accessor :default_url_options
    attr_accessor :click_row_to_view_record
    attr_accessor :alert_dismiss_time
    attr_accessor :is_admin_method
    attr_accessor :is_developer_method
    attr_accessor :search_results_count
    attr_accessor :first_sorting_option

    def initialize
      @root_path = "/avo"
      @app_name = ::Rails.application.class.to_s.split("::").first.underscore.humanize(keep_id_suffix: true)
      @timezone = "UTC"
      @per_page = 24
      @per_page_steps = [12, 24, 48, 72]
      @via_per_page = 8
      @locale = nil
      @currency = "USD"
      @default_view_type = :table
      @license_key = nil
      @current_user = proc {}
      @authenticate = proc {}
      @explicit_authorization = false
      @authorization_methods = {
        index: "index?",
        show: "show?",
        edit: "edit?",
        new: "new?",
        update: "update?",
        create: "create?",
        destroy: "destroy?"
      }
      @id_links_to_resource = false
      @full_width_container = false
      @full_width_index_view = false
      @cache_resources_on_index_view = Avo::PACKED
      @cache_resource_filters = false
      @context = proc {}
      @initial_breadcrumbs = proc {
        add_breadcrumb I18n.t("avo.home").humanize, avo.root_path
      }
      @display_breadcrumbs = true
      @hide_layout_when_printing = false
      @home_path = nil
      @search_debounce = 300
      @view_component_path = "app/components"
      @display_license_request_timeout_error = true
      @current_user_resource_name = "user"
      @raise_error_on_missing_policy = false
      @disabled_features = []
      @buttons_on_form_footers = false
      @main_menu = nil
      @profile_menu = nil
      @model_resource_mapping = {}
      @resource_default_view = Avo::ViewInquirer.new("show")
      @authorization_client = :pundit
      @field_wrapper_layout = :inline
      @resources = nil
      @resource_parent_controller = "Avo::ResourcesController"
      @mount_avo_engines = true
      @cache_store = computed_cache_store
      @logger = default_logger
      @turbo = default_turbo
      @default_url_options = []
      @pagination = {}
      @click_row_to_view_record = false
      @alert_dismiss_time = 5000
      @is_admin_method = :is_admin?
      @is_developer_method = :is_developer?
      @search_results_count = 8
      @first_sorting_option = :desc # :desc or :asc
    end

    def current_user_method(&block)
      @current_user = block if block.present?
    end

    def current_user_method=(method)
      @current_user = method if method.present?
    end

    def authenticate_with(&block)
      @authenticate = block if block.present?
    end

    def set_context(&block)
      @context = block if block.present?
    end

    def set_initial_breadcrumbs(&block)
      @initial_breadcrumbs = block if block.present?
    end

    def namespace
      if Avo.configuration.root_path.present?
        Avo.configuration.root_path.delete "/"
      else
        root_path.delete "/"
      end
    end

    def root_path
      return "" if @root_path === "/"

      @root_path
    end

    def disabled_features
      Avo::ExecutionContext.new(target: @disabled_features).handle
    end

    def feature_enabled?(feature)
      !disabled_features.map(&:to_sym).include?(feature.to_sym)
    end

    def branding
      Avo::Configuration::Branding.new(**@branding || {})
    end

    def app_name
      Avo::ExecutionContext.new(target: @app_name).handle
    end

    def license=(value)
      if Rails.env.development?
        puts "[Avo DEPRECATION WARNING]: The `config.license` configuration option is no longer supported and will be removed in future versions. Please discontinue its use and solely utilize the `license_key` instead."
      end
    end

    def license
      gems = Gem::Specification.map {|gem| gem.name}

      @license ||= if gems.include?("avo-advanced")
        "advanced"
      elsif gems.include?("avo-pro")
        "pro"
      elsif gems.include?("avo")
        "community"
      end
    end

    def resource_default_view=(view)
      @resource_default_view = Avo::ViewInquirer.new(view.to_s)
    end

    def cache_store
      Avo::ExecutionContext.new(
        target: @cache_store,
        production_rejected_cache_stores: %w[ActiveSupport::Cache::MemoryStore ActiveSupport::Cache::NullStore]
      ).handle
    end

    # When not in production or test we'll just use the MemoryStore which is good enough.
    # When running in production we'll use Rails.cache if it's not ActiveSupport::Cache::MemoryStore or ActiveSupport::Cache::NullStore.
    # If it's one of rejected cache stores, we'll use the FileStore.
    # We decided against the MemoryStore in production because it will not be shared between multiple processes (when using Puma).
    def computed_cache_store
      -> {
        if Rails.env.production?
          if Rails.cache.class.to_s.in?(production_rejected_cache_stores)
            ActiveSupport::Cache.lookup_store(:file_store, Rails.root.join("tmp", "cache"))
          else
            Rails.cache
          end
        elsif Rails.env.test?
          Rails.cache
        else
          ActiveSupport::Cache.lookup_store(:memory_store)
        end
      }
    end

    def logger
      Avo::ExecutionContext.new(target: @logger).handle
    end

    def default_logger
      -> {
        file_logger = ActiveSupport::Logger.new(Rails.root.join("log", "avo.log"))

        file_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        file_logger.formatter = proc do |severity, time, progname, msg|
          "[Avo->] #{time}: #{msg}\n".tap do |i|
            puts i
          end
        end

        file_logger
      }
    end

    def turbo
      Avo::ExecutionContext.new(target: @turbo).handle
    end

    def default_turbo
      -> do
        {
          instant_click: true
        }
      end
    end

    def pagination
      Avo::ExecutionContext.new(target: @pagination).handle
    end

    def default_locale
      @locale || I18n.default_locale
    end

    def explicit_authorization
      Avo::ExecutionContext.new(target: @explicit_authorization).handle
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end
end
