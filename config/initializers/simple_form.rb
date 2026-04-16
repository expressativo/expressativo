# frozen_string_literal: true

SimpleForm.setup do |config|
  # Default wrapper for Tailwind CSS
  config.wrappers :default, class: "mb-4 space-y-2" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: "text-gray-700 text-sm font-medium"
    b.use :input, class: "border-gray-300 border rounded-2xl focus:border-purple-500 focus:ring-purple-500 h-12 w-full px-4 bg-white", error_class: "border-red-500 focus:border-red-500 focus:ring-red-500"
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  # Wrapper for textarea inputs
  config.wrappers :textarea, class: "mb-4 space-y-2" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly

    b.use :label, class: "text-gray-700 text-sm font-medium"
    b.use :input, class: "border-gray-300 border rounded-2xl focus:border-purple-500 focus:ring-purple-500 w-full p-4 bg-white", error_class: "border-red-500 focus:border-red-500 focus:ring-red-500"
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  # Wrapper for boolean/checkbox inputs
  config.wrappers :boolean, class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper :custom_wrapper, tag: :div, class: "flex items-center gap-2" do |c|
      c.use :input, class: "h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-300 rounded cursor-pointer"
      c.use :label, class: "text-gray-700 text-sm font-medium cursor-pointer"
    end
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  # Wrapper for select inputs
  config.wrappers :select, class: "mb-4 space-y-2" do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: "text-gray-700 text-sm font-medium"
    b.use :input, class: "border-gray-300 border rounded-2xl focus:border-purple-500 focus:ring-purple-500 h-12 w-full px-4 bg-white appearance-none", error_class: "border-red-500 focus:border-red-500 focus:ring-red-500"
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  # Wrapper for file inputs
  config.wrappers :file, class: "mb-4 space-y-2" do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: "text-gray-700 text-sm font-medium"
    b.use :input, class: "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-3xl file:border-0 file:text-sm file:font-medium file:bg-purple-50 file:text-purple-700 hover:file:bg-purple-100 cursor-pointer"
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  # Inline form wrapper (label and input on the same line)
  config.wrappers :inline, class: "mb-4 flex items-center gap-4" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly

    b.use :label, class: "text-gray-700 text-sm font-medium whitespace-nowrap"
    b.use :input, class: "border-gray-300 border rounded-2xl focus:border-purple-500 focus:ring-purple-500 h-12 w-full px-4 bg-white", error_class: "border-red-500 focus:border-red-500 focus:ring-red-500"
    b.use :hint, wrap_with: { tag: :p, class: "text-gray-500 text-xs mt-1" }
    b.use :error, wrap_with: { tag: :p, class: "text-red-500 text-sm font-medium mt-1" }
  end

  config.default_wrapper = :default

  # Map input types to custom wrappers
  config.wrapper_mappings = {
    boolean: :boolean,
    text: :textarea,
    file: :file,
    select: :select,
    collection_select: :select
  }

  config.boolean_style = :inline
  config.button_class = "bg-purple-400 border border-transparent py-2 px-4 text-sm font-medium text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 rounded-3xl cursor-pointer"

  config.error_notification_tag = :div
  config.error_notification_class = "bg-red-50 border border-red-200 rounded-lg p-4 mb-6 text-red-700 text-sm"

  config.label_class = "text-gray-700 text-sm font-medium"
  config.browser_validations = false
  config.boolean_label_class = "cursor-pointer"
end
