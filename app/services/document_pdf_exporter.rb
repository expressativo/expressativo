# Renderiza HTML a PDF usando Chrome headless (vía Ferrum/CDP).
# No depende de Node/Puppeteer: solo necesita el binario de Chrome en el sistema.
class DocumentPdfExporter
  def self.call(html)
    new(html).call
  end

  def initialize(html)
    @html = html
  end

  def call
    browser = Ferrum::Browser.new(headless: true, browser_options: { "no-sandbox" => nil }, timeout: 15)
    browser.go_to("data:text/html;charset=utf-8,#{ERB::Util.url_encode(@html)}")
    browser.network.wait_for_idle
    browser.pdf(encoding: :binary, print_background: true, format: :A4,
                margin_top: 0.6, margin_bottom: 0.6, margin_left: 0.6, margin_right: 0.6)
  ensure
    browser&.quit
  end
end
