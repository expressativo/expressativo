// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

// En tu application.js
document.addEventListener("trix-initialize", function(event) {
  const toolbarElement = event.target.toolbarElement;
  
  // Buscar el botón de heading
  const headingButton = toolbarElement.querySelector("[data-trix-attribute='heading1']");
  
  if (headingButton) {
    // Crear dropdown con múltiples headings
    const dropdown = document.createElement("select");
    dropdown.innerHTML = `
      <option value="">Normal</option>
      <option value="heading1">H1</option>
      <option value="heading2">H2</option>
      <option value="heading3">H3</option>
      <option value="heading4">H4</option>
    `;
    
    dropdown.addEventListener("change", function() {
        console.log(this.value)

      if (this.value) {
        console.log(this.value)
        event.target.editor.activateAttribute(this.value);
      } else {
        console.log(this.value,"inside")

        event.target.editor.deactivateAttribute("heading1");
        event.target.editor.deactivateAttribute("heading2");
        event.target.editor.deactivateAttribute("heading3");
        event.target.editor.deactivateAttribute("heading4");
      }
    });
    
    headingButton.parentNode.replaceChild(dropdown, headingButton);
  }
});