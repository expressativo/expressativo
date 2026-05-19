module DocumentsHelper
  IMAGE_TYPES = %w[image/png image/jpeg image/jpg image/gif image/webp image/svg+xml image/bmp image/avif].freeze
  PDF_TYPES = %w[application/pdf].freeze
  VIDEO_TYPES = %w[video/mp4 video/webm video/ogg video/quicktime].freeze
  AUDIO_TYPES = %w[audio/mpeg audio/mp3 audio/wav audio/ogg audio/x-m4a].freeze
  TEXT_TYPES = %w[text/plain text/markdown text/csv text/html application/json application/xml].freeze
  OFFICE_TYPES = %w[
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
  ].freeze
  ARCHIVE_TYPES = %w[application/zip application/x-rar-compressed application/x-7z-compressed application/gzip].freeze

  # Returns a symbol identifying the broad kind of file the document holds.
  # :rich_text, :image, :pdf, :video, :audio, :text, :office, :archive, :other
  def document_kind(document)
    return :rich_text if document.document_type == "document"
    return :other unless document.file.attached?

    content_type = document.file.content_type.to_s

    case content_type
    when *IMAGE_TYPES then :image
    when *PDF_TYPES then :pdf
    when *VIDEO_TYPES then :video
    when *AUDIO_TYPES then :audio
    when *TEXT_TYPES then :text
    when *OFFICE_TYPES then :office
    when *ARCHIVE_TYPES then :archive
    else :other
    end
  end

  # Returns true if Active Storage can produce a preview/variant for this document's file.
  def document_previewable?(document)
    return false unless document.file.attached?

    kind = document_kind(document)
    return true if kind == :image
    return document.file.previewable? if [ :pdf, :video ].include?(kind)

    false
  end

  # Renders a thumbnail <img> for the document, or nil if not previewable.
  def document_thumbnail_tag(document, size: [ 600, 400 ], **html_options)
    return nil unless document_previewable?(document)

    file = document.file
    src =
      if document_kind(document) == :image
        if file.content_type == "image/svg+xml"
          url_for(file)
        else
          url_for(file.representation(resize_to_limit: size))
        end
      else
        url_for(file.preview(resize_to_limit: size))
      end

    image_tag(src, **html_options)
  rescue StandardError
    nil
  end

  # Returns a coloured icon component (svg) appropriate for the document kind.
  def document_kind_icon(document, css_class: "w-10 h-10")
    kind = document_kind(document)
    palette = {
      rich_text: { bg: "bg-blue-50", color: "text-blue-600" },
      image:     { bg: "bg-purple-50", color: "text-purple-600" },
      pdf:       { bg: "bg-red-50", color: "text-red-600" },
      video:     { bg: "bg-pink-50", color: "text-pink-600" },
      audio:     { bg: "bg-amber-50", color: "text-amber-600" },
      text:      { bg: "bg-slate-50", color: "text-slate-600" },
      office:    { bg: "bg-emerald-50", color: "text-emerald-600" },
      archive:   { bg: "bg-yellow-50", color: "text-yellow-700" },
      other:     { bg: "bg-gray-100", color: "text-gray-500" }
    }[kind]

    svg_path = document_kind_svg_path(kind)

    content_tag(:div, class: "rounded-lg flex items-center justify-center #{palette[:bg]} #{palette[:color]} #{css_class}") do
      content_tag(:svg, raw(svg_path), xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.6", class: "w-1/2 h-1/2")
    end
  end

  def document_kind_label(document)
    case document_kind(document)
    when :rich_text then "Documento"
    when :image     then "Imagen"
    when :pdf       then "PDF"
    when :video     then "Video"
    when :audio     then "Audio"
    when :text      then "Texto"
    when :office    then "Office"
    when :archive   then "Comprimido"
    else "Archivo"
    end
  end

  def document_file_extension(document)
    return nil unless document.file.attached?

    File.extname(document.file.filename.to_s).delete(".").upcase.presence
  end

  def document_size(document)
    return nil unless document.file.attached?

    number_to_human_size(document.file.byte_size)
  end

  private

  def document_kind_svg_path(kind)
    case kind
    when :image
      '<path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>'
    when :pdf
      '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>'
    when :video
      '<path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>'
    when :audio
      '<path stroke-linecap="round" stroke-linejoin="round" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2z"/>'
    when :text
      '<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h7"/>'
    when :office
      '<path stroke-linecap="round" stroke-linejoin="round" d="M9 17v-6h6v6m2 4H7a2 2 0 01-2-2V5a2 2 0 012-2h10a2 2 0 012 2v14a2 2 0 01-2 2z"/>'
    when :archive
      '<path stroke-linecap="round" stroke-linejoin="round" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/>'
    when :rich_text
      '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>'
    else
      '<path stroke-linecap="round" stroke-linejoin="round" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>'
    end
  end
end
