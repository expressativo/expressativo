import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="board-filter"
export default class extends Controller {
  static targets = ["dropdown", "button", "selectedText"];
  static values = {
    currentAssignee: String
  };

  connect() {
    // Cerrar dropdown al hacer click fuera
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this);
    document.addEventListener("click", this.closeOnClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside);
  }

  toggle(event) {
    event.stopPropagation();
    this.dropdownTarget.classList.toggle("hidden");
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden");
    }
  }

  filter(event) {
    event.preventDefault();
    const assigneeId = event.currentTarget.dataset.assigneeId;
    const assigneeName = event.currentTarget.dataset.assigneeName;
    
    // Construir URL con parámetro de filtro
    const url = new URL(window.location);
    
    if (assigneeId === "all") {
      // Remover filtro
      url.searchParams.delete("assignee_id");
    } else {
      // Aplicar filtro
      url.searchParams.set("assignee_id", assigneeId);
    }
    
    // Recargar página con filtro
    window.location.href = url.toString();
  }

  clearFilter(event) {
    event.preventDefault();
    const url = new URL(window.location);
    url.searchParams.delete("assignee_id");
    window.location.href = url.toString();
  }
}
