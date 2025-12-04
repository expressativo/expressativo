import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="task-status"
export default class extends Controller {
  static targets = ["dropdown", "button", "selectedText", "columnInput"];

  connect() {
    // Cerrar dropdown al hacer click fuera
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this);
    document.addEventListener("click", this.boundCloseOnClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside);
  }

  toggleDropdown(event) {
    event.stopPropagation();
    this.dropdownTarget.classList.toggle("hidden");
  }

  selectColumn(event) {
    event.preventDefault();
    event.stopPropagation();
    
    const columnId = event.currentTarget.dataset.columnId;
    const columnTitle = event.currentTarget.dataset.columnTitle;
    const boardTitle = event.currentTarget.dataset.boardTitle;

    // Actualizar el input hidden
    this.columnInputTarget.value = columnId;

    // Si existe el target selectedText (cuando no hay estatus previo)
    if (this.hasSelectedTextTarget) {
      this.selectedTextTarget.textContent = `${columnTitle} (${boardTitle})`;
      this.selectedTextTarget.classList.remove("text-gray-500");
      this.selectedTextTarget.classList.add("text-gray-900");
    }

    // Cerrar dropdown
    this.dropdownTarget.classList.add("hidden");
    
    // Enviar el formulario automáticamente para actualizar el estatus
    const form = this.element.closest("form");
    if (form) {
      form.requestSubmit();
    }
  }

  clearStatus(event) {
    event.preventDefault();
    event.stopPropagation();
    
    if (confirm("¿Estás seguro de que quieres quitar el estatus de esta tarea?")) {
      // Limpiar el column_id
      this.columnInputTarget.value = "";
      
      // Cerrar dropdown
      this.dropdownTarget.classList.add("hidden");
      
      // Enviar el formulario
      const form = this.element.closest("form");
      if (form) {
        form.requestSubmit();
      }
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden");
    }
  }
}
