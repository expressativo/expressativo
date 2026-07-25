# Exporta un Document (rich_text / Lexxy) a PDF en Ruby puro usando Prawn.
#
# Recorre el HTML generado por ActionText con Nokogiri y lo va dibujando en el
# PDF bloque a bloque (h1/h2/h3, p, ul/ol, blockquote, pre, hr, table, figure).
# El texto inline (bold, italic, code, links) se traduce a `formatted_text` de
# Prawn. Las imágenes embebidas (ActiveStorage) se resuelven desde su
# `signed_id` en el src y se embeben desde el blob, sin HTTP.
#
# No depende de Chrome/Ferrum: menor uso de memoria y sin binarios externos.
class DocumentPdfExporter
  # Las fuentes AFM incluidas en Prawn cubren WinAnsi (incluye español).
  # Silenciamos el aviso sobre soporte limitado de UTF-8 fuera de WinAnsi.
  Prawn::Fonts::AFM.hide_m17n_warning = true if defined?(Prawn::Fonts::AFM)

  FONT_SIZE = 10.5
  BODY_FONT = "Helvetica"
  CODE_FONT = "Courier"
  MUTED_COLOR = "6B7280".freeze
  BORDER_COLOR = "E5E7EB".freeze
  CODE_BG = "F3F4F6".freeze
  LINK_COLOR = "4F46E5".freeze
  QUOTE_COLOR = "4B5563".freeze
  QUOTE_BORDER = "D1D5DB".freeze

  HEADING_SIZES = { "h1" => 18, "h2" => 14, "h3" => 12, "h4" => 11 }.freeze

  # Margen del documento en puntos (aprox. 1.7cm).
  MARGIN = 48

  def self.call(document)
    new(document).call
  end

  def initialize(document)
    @document = document
  end

  def call
    body_node = Nokogiri::HTML(html_content).at_css("body")

    Prawn::Document.new(page_size: "A4", margin: MARGIN) do |pdf|
      @pdf = pdf
      pdf.font BODY_FONT, size: FONT_SIZE
      render_header(pdf)
      body_node.children.each { |node| render_block(node, pdf) }
    end.render
  end

  private

  attr_reader :document, :pdf

  def html_content
    document.body&.to_html.presence || "<p>#{ERB::Util.h(document.name)}</p>"
  end

  # ---------- Cabecera del documento ----------

  def render_header(pdf)
    pdf.font(BODY_FONT, size: 20, style: :bold) { pdf.text document.name.to_s }
    meta = [ document.created_by&.full_name, formatted_date ].compact.join(" · ")
    if meta.present?
      pdf.move_down 3
      pdf.font(BODY_FONT, size: 9) { pdf.text meta, color: MUTED_COLOR }
    end
    pdf.move_down 8
    pdf.stroke_color BORDER_COLOR
    pdf.horizontal_rule
    pdf.move_down 12
  end

  def formatted_date
    I18n.l(document.updated_at, format: :long)
  rescue StandardError
    document.updated_at&.strftime("%d/%m/%Y")
  end

  # ---------- Dispatch de bloques ----------

  def render_block(node, pdf)
    return if node.text? && node.text.strip.empty?

    case node.name.downcase
    when "text"               then pdf.text node.text
    when *HEADING_SIZES.keys  then render_heading(node, pdf)
    when "p"                  then render_paragraph(node, pdf)
    when "ul"                 then render_list(node, pdf, ordered: false)
    when "ol"                 then render_list(node, pdf, ordered: true)
    when "blockquote"         then render_blockquote(node, pdf)
    when "pre"                then render_code(node, pdf)
    when "hr"                 then render_hr(pdf)
    when "table"              then render_table(node, pdf)
    when "figure"             then render_figure(node, pdf)
    when "div"
      # Algunos editores envuelven bloques en divs; descendemos recursivamente.
      node.children.each { |child| render_block(child, pdf) }
    else
      text = node.text
      pdf.text text if text.present?
    end
  end

  def render_heading(node, pdf)
    size = HEADING_SIZES[node.name.downcase]
    pdf.move_down 8
    pdf.font(BODY_FONT, size: size, style: :bold) do
      pdf.formatted_text inline_format_array(node), leading: 3
    end
    pdf.move_down 4
  end

  def render_paragraph(node, pdf)
    fragments = inline_format_array(node)
    return if fragments.empty?

    pdf.formatted_text fragments, align: :justify, leading: 3
    pdf.move_down 7
  end

  def render_list(node, pdf, ordered:)
    items = node.css("> li").to_a
    items.each_with_index do |li, idx|
      prefix = ordered ? "#{idx + 1}. " : "•  "
      pdf.formatted_text(
        [ { text: prefix } ].concat(inline_format_array(li)),
        indent_paragraph: 16, leading: 3
      )
      pdf.move_down 3
    end
    pdf.move_down 5 unless items.empty?
  end

  def render_blockquote(node, pdf)
    pdf.move_down 4
    pdf.indent(14) do
      pdf.stroke_color QUOTE_BORDER
      pdf.line_width = 2
      # Borde izquierdo: una línea vertical a la altura del bloque.
      top = pdf.cursor
      pdf.formatted_text(
        inline_format_array(node).map do |f|
          f.merge(styles: (f[:styles] || []) + [ :italic ], color: f[:color] || QUOTE_COLOR)
        end,
        leading: 3
      )
      bottom = pdf.cursor
      pdf.stroke_vertical_line(top, bottom, at: -10)
      pdf.line_width = 1
    end
    pdf.move_down 9
  end

  def render_code(node, pdf)
    code_text = node.text.to_s.chomp
    return if code_text.strip.empty?

    pdf.move_down 4
    pdf.font(CODE_FONT, size: 9) do
      height = pdf.height_of(code_text, leading: 2) + 16
      box_top = pdf.cursor
      # Fondo y texto dentro de un bounding_box para que el fondo respete alto.
      pdf.bounding_box([ pdf.bounds.left, box_top ], width: pdf.bounds.width, height: height) do
        pdf.fill_color CODE_BG
        pdf.fill_rectangle([ 0, height ], pdf.bounds.width, height)
        pdf.fill_color "111827"
        pdf.move_down 8
        pdf.text code_text, leading: 2
      end
    end
    pdf.move_down 10
  rescue StandardError => e
    Rails.logger.warn("[DocumentPdfExporter] pre omitido: #{e.message}")
    pdf.move_down 4
  end

  def render_hr(pdf)
    pdf.move_down 8
    pdf.stroke_color BORDER_COLOR
    pdf.horizontal_rule
    pdf.move_down 8
  end

  def render_table(node, pdf)
    rows = []
    header = false
    node.css("> tr, > thead > tr, > tbody > tr").each do |tr|
      cells = tr.css("th, td").map { |cell| cell.text.strip }
      header ||= tr.css("th").any?
      rows << cells
    end
    return if rows.empty?

    pdf.table(rows, width: pdf.bounds.width, header: header, cell_style: {
      borders: [ :top, :bottom ],
      border_color: BORDER_COLOR,
      border_width: 0.5,
      padding: 5,
      size: 10,
      inline_format: true
    }) do |table|
      table.row(0).background_color = "F9FAFB" if header
    end
    pdf.move_down 8
  rescue StandardError => e
    Rails.logger.warn("[DocumentPdfExporter] tabla omitida: #{e.message}")
    pdf.move_down 4
  end

  def render_figure(node, pdf)
    img = node.at_css("img")
    return render_attachment_link(node, pdf) unless img

    blob = blob_from_src(img["src"])
    return render_attachment_link(node, pdf) if blob.nil?

    embed_image(blob, pdf)
    render_caption(node, pdf)
  end

  def render_attachment_link(node, pdf)
    name = node.at_css(".attachment__name")&.text ||
           node.attr("data-filename") ||
           "archivo adjunto"
    pdf.move_down 4
    pdf.formatted_text([ { text: "📎 #{name}", styles: [ :italic ], color: MUTED_COLOR } ])
    pdf.move_down 6
  end

  def render_caption(node, pdf)
    caption = node.at_css("figcaption")&.text&.strip
    return if caption.blank?

    pdf.move_down 2
    pdf.font(BODY_FONT, size: 8) { pdf.text caption, align: :center, color: MUTED_COLOR }
    pdf.move_down 8
  end

  def embed_image(blob, pdf)
    data = blob.download
    return if data.blank?

    max_w = pdf.bounds.width
    max_h = pdf.bounds.height - 60
    # Si no cabe en la página actual, saltamos a la siguiente.
    pdf.start_new_page if pdf.cursor < 120
    pdf.image(StringIO.new(data), fit: [ max_w, max_h ], position: :center)
    pdf.move_down 6
  rescue StandardError => e
    Rails.logger.warn("[DocumentPdfExporter] imagen omitida: #{e.message}")
  end

  # Resuelve el blob de ActiveStorage desde el src del <img>.
  def blob_from_src(src)
    return nil if src.blank?

    return DataUriBlob.new(src) if src.start_with?("data:")

    if (m = src.match(%r{active_storage/(?:files|representations)/([^/]+)}))
      return ActiveStorage::Blob.find_signed(m[1])
    end

    nil
  rescue StandardError
    nil
  end

  # ---------- Inline formatting ----------

  # Construye el array de fragmentos que espera `Prawn::Document#formatted_text`.
  def inline_format_array(node, styles: [], color: nil)
    fragments = []
    node.children.each do |child|
      case child.name.downcase
      when "text"
        fragments << build_fragment(child.content, styles, color) if child.content.present?
      when "strong", "b"
        fragments.concat(inline_format_array(child, styles: styles + [ :bold ], color: color))
      when "em", "i"
        fragments.concat(inline_format_array(child, styles: styles + [ :italic ], color: color))
      when "u"
        fragments.concat(inline_format_array(child, styles: styles + [ :underline ], color: color))
      when "s", "strike", "del"
        fragments.concat(inline_format_array(child, styles: styles + [ :strikethrough ], color: color))
      when "code"
        fragments << build_fragment(child.text, styles, color || "111827", font: CODE_FONT)
      when "a"
        href = child["href"]
        frags = inline_format_array(child, styles: styles + [ :underline ], color: LINK_COLOR)
        frags = frags.map { |f| f.merge(link: href) } if href.present?
        fragments.concat(frags)
      when "br"
        fragments << { text: "\n" }
      when "img"
        next
      else
        fragments.concat(inline_format_array(child, styles: styles, color: color))
      end
    end
    fragments
  end

  def build_fragment(text, styles, color, font: nil)
    fragment = { text: normalize_whitespace(text) }
    fragment[:styles] = styles unless styles.empty?
    fragment[:color] = color if color
    fragment[:font] = font if font
    fragment
  end

  def normalize_whitespace(text)
    text.gsub(/\s+/, " ")
  end

  # Wrapper para soportar imágenes embebidas como data: URIs.
  class DataUriBlob
    def initialize(uri)
      @data = Base64.decode64(Regexp.last_match(2)) if uri =~ /^data:.+?;base64,(.+)$/
    end

    def download
      @data
    end
  end
end
