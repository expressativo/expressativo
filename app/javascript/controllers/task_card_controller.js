import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="task-card"
export default class extends Controller {
  static values = {
    url: String
  };

  connect() {
    this.element.style.cursor = "pointer";
  }

  open(event) {
    // No navegar si se hizo click en un botón o link
    if (event.target.closest('button') || event.target.closest('a')) {
      return;
    }

    // No navegar si se está arrastrando
    if (this.element.classList.contains('sortable-drag')) {
      return;
    }

    // Navegar a la URL de la tarea con query param from=board
    if (this.urlValue) {
      const url = new URL(this.urlValue, window.location.origin);
      url.searchParams.set('from', 'board');
      window.location.href = url.toString();
    }
  }
}
