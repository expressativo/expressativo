require "loofah"
require "set"

# Sanitiza contenido SVG para embeberlo inline en HTML.
#
# Estrategia: allowlist estricto de tags y atributos (en vez de blocklist),
# para cubrir vectores que el sanitizer anterior dejaba pasar:
#   - <style> con @keyframes y url('javascript:...')
#   - <foreignObject> con HTML embebido
#   - <animate>/<set> con attributeName="href" to="javascript:..."
#   - <use href="..."> con xlink a recursos externos
#   - <image href="data:text/html,..."> y similares
module SvgSanitizer
  module_function

  ALLOWED_TAGS = %w[
    svg g defs symbol use view title desc metadata
    path rect circle ellipse line polyline polygon
    text tspan textpath
    linearGradient radialGradient stop
    clipPath mask pattern marker
    filter feGaussianBlur feColorMatrix feComposite feOffset
    feMerge feMergeNode feBlend feFlood feMorphology feTurbulence
    feDisplacementMap feSpecularLighting feDiffuseLighting
    feDistantLight fePointLight feSpotLight feImage feTile
    feConvolveMatrix feComponentTransfer feFuncA feFuncR feFuncG feFuncB
  ].map(&:downcase).to_set.freeze

  EVENT_ATTR = /\Aon/i.freeze
  HREF_ATTRS = %w[href xlink:href].freeze

  # Esquemas seguros para href/xlink:href. Cualquier otra cosa (incluyendo
  # `javascript:`, `data:`, `vbscript:`, `file:`) se elimina.
  SAFE_HREF = %r{
    \A(?:
      https?:// |
      mailto: |
      \# |          # fragmentos internos
      / |           # rutas absolutas
      \./ |
      \.\./ |
      [^:]*\z       # cualquier cosa sin esquema (path relativo)
    )
  }xi.freeze

  def sanitize(svg_content)
    return "" if svg_content.blank?

    fragment = Loofah.xml_fragment(svg_content)
    fragment.scrub!(svg_scrubber)

    root = fragment.children.find { |c| c.element? && c.name.casecmp("svg").zero? }
    return "" unless root

    root.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  rescue Nokogiri::XML::SyntaxError, StandardError
    ""
  end

  def svg_scrubber
    Loofah::Scrubber.new do |node|
      next Loofah::Scrubber::CONTINUE unless node.element?

      unless ALLOWED_TAGS.include?(node.name.downcase)
        node.remove
        next Loofah::Scrubber::STOP
      end

      node.attribute_nodes.each do |attr|
        name = attr.name.to_s.downcase

        if name.match?(EVENT_ATTR)
          attr.remove
        elsif HREF_ATTRS.include?(name) && !SAFE_HREF.match?(attr.value.to_s.strip)
          attr.remove
        end
      end

      Loofah::Scrubber::CONTINUE
    end
  end
end
