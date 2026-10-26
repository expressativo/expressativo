# Genera las capturas del README (docs/screenshots) con Chromium headless.
# Uso: ver la sección "Screenshots" del README.
require "ferrum"
require "fileutils"
out = "docs/screenshots"
FileUtils.mkdir_p(out)
b = Ferrum::Browser.new(browser_path: "/usr/bin/chromium", window_size: [1440, 900], timeout: 30,
                        browser_options: { "no-sandbox" => nil, "force-device-scale-factor" => "2" })
base = "http://localhost:3000"
b.go_to("#{base}/users/sign_in")
b.at_css("input[name='user[email]']").focus.type("ana@demo.test")
b.at_css("input[name='user[password]']").focus.type("password123")
b.at_css("form [type=submit]").click
sleep 2
puts "after login: #{b.current_url}"
# Ocultar los avisos de permisos de notificaciones en las capturas
b.evaluate("localStorage.setItem('push_permission_dismissed','1'); sessionStorage.setItem('chat_notifier_permission_dismissed','1')")
pages = ARGV.each_slice(2).to_a
pages.each do |name, path|
  b.go_to("#{base}#{path}")
  sleep 1.5
  # Cerrar avisos de permisos de notificaciones si aparecen
  b.evaluate("document.querySelectorAll(\"[data-role=dismiss]\").forEach(el => el.click())")
  sleep 0.5
  b.screenshot(path: "#{out}/#{name}.png", format: "png")
  puts "#{name}: #{b.current_url}"
end
b.quit
