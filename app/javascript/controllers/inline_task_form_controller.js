import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="inline-task-form"
// Toggles between a "+ Agregar tarea" trigger and an inline form input.
export default class extends Controller {
  static targets = ["trigger", "form", "input"];

  show(event) {
    event?.preventDefault();
    this.triggerTarget.classList.add("hidden");
    this.formTarget.classList.remove("hidden");
    this.inputTarget.focus();
  }

  hide(event) {
    event?.preventDefault();
    this.formTarget.classList.add("hidden");
    this.triggerTarget.classList.remove("hidden");
    this.inputTarget.value = "";
  }
}
