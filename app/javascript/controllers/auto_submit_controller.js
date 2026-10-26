import { Controller } from "@hotwired/stimulus";

// Envía el formulario al cambiar un campo, sin botón de guardar.
// Con delay > 0 espera a que el usuario termine (útil en inputs de fecha,
// que disparan "change" por cada segmento editado).
export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } };

  disconnect() {
    clearTimeout(this.timeout);
  }

  submit() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue);
  }
}
