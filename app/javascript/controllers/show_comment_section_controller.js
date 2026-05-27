import { Controller } from "@hotwired/stimulus";

export default class extends Controller {  

  connect() {
    console.log("Show comment section controller connected");

    document.addEventListener('keydown', this.handleKeyDown.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
  }

  handleKeyDown(event) {
    // Si se presiona Escape
    if (event.key === 'Escape') {
      event.preventDefault();
      this.toggle();
    }
  }

  toggle() {
    const form = this.element.querySelector('form');
    const button = this.element.querySelector('#toggle-add-comment');
    form.classList.toggle('hidden');
    button.classList.toggle('hidden');
    
    // Si el formulario se está mostrando, enfocar el campo de texto
    if (!form.classList.contains('hidden')) {
      const editor = form.querySelector('lexxy-editor')
      if (editor) editor.focus()
    }
  }
}
