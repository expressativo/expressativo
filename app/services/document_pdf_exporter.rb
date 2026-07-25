# Renderiza HTML a PDF usando Chrome headless (vía Ferrum/CDP).
# No depende de Node/Puppeteer: solo necesita el binario de Chrome en el sistema.
#
# Reutiliza una única instancia de Chrome por proceso de Puma: arrancar Chrome
# en cada petición es caro (~2-5s y ~200MB) y provoca DeadBrowserError bajo
# carga concurrente o con poca memoria en el contenedor. Como Ferrum no es
# thread-safe, el acceso se serializa con un Mutex.
class DocumentPdfExporter
  MUTEX = Mutex.new
  BROWSER_TIMEOUT = 15
  MAX_ATTEMPTS = 2

  class << self
    attr_reader :browser

    def with_browser
      MUTEX.synchronize do
        attempts = 0
        begin
          attempts += 1
          @browser ||= spawn_browser
          yield @browser
        rescue Ferrum::DeadBrowserError, Ferrum::ProcessTimeoutError, Ferrum::TimeoutError
          reset_browser
          retry if attempts < MAX_ATTEMPTS
          raise
        end
      end
    end

    def reset_browser
      @browser&.quit
    rescue StandardError
      # El navegador ya podía estar muerto; lo ignoramos.
    ensure
      @browser = nil
    end

    private

    def spawn_browser
      Ferrum::Browser.new(
        headless: true,
        dockerize: true,
        browser_options: { "no-sandbox" => nil },
        timeout: BROWSER_TIMEOUT
      )
    end
  end

  def self.call(html)
    new(html).call
  end

  def initialize(html)
    @html = html
  end

  def call
    self.class.with_browser do |browser|
      browser.go_to("data:text/html;charset=utf-8,#{ERB::Util.url_encode(@html)}")
      browser.network.wait_for_idle
      browser.pdf(encoding: :binary, print_background: true, format: :A4,
                  margin_top: 0.6, margin_bottom: 0.6, margin_left: 0.6, margin_right: 0.6)
    end
  end
end
