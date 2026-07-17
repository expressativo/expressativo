import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.editorReconnected = false;
    document.addEventListener("keydown", this.handleKeyDown);
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeyDown);
  }

  handleKeyDown(event) {
    // Si se presiona Escape
    if (event.key === "Escape") {
      event.preventDefault();
      this.toggle();
    }
  }

  toggle() {
    const form = this.element.querySelector("form");
    const button = this.element.querySelector("#toggle-add-comment");
    if (!form || !button) return;

    const formIsHidden = form.classList.contains("hidden");

    // Si el formulario está visible y el editor está enfocado, Escape solo quita el focus
    if (!formIsHidden) {
      const editor = form.querySelector("lexxy-editor");
      if (editor && document.activeElement === editor) {
        editor.blur();
        return;
      }
    }

    form.classList.toggle("hidden");
    button.classList.toggle("hidden");

    // Si el formulario se está mostrando, enfocar el editor
    if (!form.classList.contains("hidden")) {
      const editor = form.querySelector("lexxy-editor");
      if (!editor) return;

      if (!this.editorReconnected) {
        // El editor se inicializó estando oculto (display:none), lo que deja la
        // selección interna de Lexical en un estado inconsistente: al escribir,
        // el texto queda abajo y aparecen líneas vacías arriba. Forzar el reconnect
        // del editor ya visible lo re-inicializa correctamente. El prompt de
        // menciones se re-engancha solo al escribir "@" (mention_form_controller).
        editor.removeAttribute("connected");
        this.editorReconnected = true;
        requestAnimationFrame(() => requestAnimationFrame(() => editor.focus()));
      } else {
        editor.focus();
      }
    }
  }
}
