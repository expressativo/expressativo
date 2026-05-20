require "nokogiri"

# Sanitiza contenido SVG para poder embeberlo inline en el HTML.
# Elimina vectores de XSS: <script>, <foreignObject>, atributos on*, href/xlink:href
# con esquemas peligrosos (javascript:, data: que no sean imágenes) y referencias
# a entidades externas.
module SvgSanitizer
  module_function

  DANGEROUS_TAGS = %w[script foreignobject].freeze
  HREF_ATTRS = %w[href xlink:href].freeze
  DANGEROUS_SCHEMES = %w[javascript: vbscript: data:].freeze

  def sanitize(svg_content)
    return "" if svg_content.blank?

    doc = Nokogiri::XML(svg_content) { |c| c.nononet.noent.nocdata }
    root = doc.root
    return "" unless root && root.name.casecmp("svg").zero?

    strip_dangerous!(root)
    root.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  rescue Nokogiri::XML::SyntaxError
    ""
  end

  def strip_dangerous!(node)
    node.traverse do |child|
      next unless child.element?

      if DANGEROUS_TAGS.include?(child.name.downcase)
        child.remove
        next
      end

      child.attribute_nodes.each do |attr|
        name = attr.name.to_s.downcase
        if name.start_with?("on")
          attr.remove
        elsif HREF_ATTRS.include?(name) && dangerous_href?(attr.value)
          attr.remove
        end
      end
    end
  end

  def dangerous_href?(value)
    value = value.to_s.strip.downcase
    DANGEROUS_SCHEMES.any? { |s| value.start_with?(s) }
  end
end
