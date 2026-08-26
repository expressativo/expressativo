# frozen_string_literal: true

SimpleForm.setup do |config|
  # Default wrapper — reuses the app's neo-brutalist .input/.label component classes
  config.wrappers :default, class: "form-field" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: "label"
    b.use :input, class: "input", error_class: "border-danger"
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs" }
    b.use :error, wrap_with: { tag: :p, class: "error-message" }
  end

  # Wrapper for textarea inputs
  config.wrappers :textarea, class: "form-field" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly

    b.use :label, class: "label"
    b.use :input, class: "textarea", error_class: "border-danger"
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs" }
    b.use :error, wrap_with: { tag: :p, class: "error-message" }
  end

  # Wrapper for boolean/checkbox inputs
  config.wrappers :boolean, class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper :custom_wrapper, tag: :div, class: "flex items-start gap-2" do |c|
      c.use :input, class: "mt-0.5 h-4 w-4 accent-brand border-2 border-ink rounded cursor-pointer"
      c.use :label, class: "text-ink text-sm font-semibold cursor-pointer select-none"
    end
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs ml-6" }
    b.use :error, wrap_with: { tag: :p, class: "error-message ml-6" }
  end

  # Wrapper for select inputs
  config.wrappers :select, class: "form-field" do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: "label"
    b.use :input, class: "input appearance-none", error_class: "border-danger"
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs" }
    b.use :error, wrap_with: { tag: :p, class: "error-message" }
  end

  # Wrapper for file inputs
  config.wrappers :file, class: "form-field" do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: "label"
    b.use :input, class: "block w-full text-sm text-ink/70 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-2 file:border-ink file:text-sm file:font-bold file:bg-brand-light file:text-brand-dark hover:file:bg-accent cursor-pointer"
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs" }
    b.use :error, wrap_with: { tag: :p, class: "error-message" }
  end

  # Inline form wrapper (label and input on the same line)
  config.wrappers :inline, class: "mb-4 flex items-center gap-3" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly

    b.use :label, class: "label whitespace-nowrap"
    b.use :input, class: "input", error_class: "border-danger"
    b.use :hint, wrap_with: { tag: :p, class: "text-ink/50 text-xs" }
    b.use :error, wrap_with: { tag: :p, class: "error-message" }
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
  config.button_class = "button"

  config.error_notification_tag = :div
  config.error_notification_class = "errors mb-4"

  config.label_class = "label"
  config.browser_validations = false
  config.boolean_label_class = "cursor-pointer"
end
