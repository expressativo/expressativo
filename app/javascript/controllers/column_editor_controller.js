import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="column-editor"
export default class extends Controller {
  static targets = ["title", "input", "form", "newColumnTitle"];
  static values = {
    columnId: Number,
    boardId: Number,
    projectId: Number,
    updateUrl: String,
    createUrl: String
  };

  connect() {
    // Inicialización si es necesaria
  }

  // Edición inline de título de columna
  editTitle(event) {
    event.preventDefault();
    const titleElement = this.titleTarget;
    const currentTitle = titleElement.textContent.trim();
    
    // Crear input para edición
    const input = document.createElement("input");
    input.type = "text";
    input.value = currentTitle;
    input.className = "border border-gray-300 rounded px-2 py-1 w-full focus:outline-none focus:ring-2 focus:ring-blue-500";
    
    // Reemplazar título con input
    titleElement.replaceWith(input);
    input.focus();
    input.select();
    
    // Guardar al perder foco o presionar Enter
    const saveTitle = () => {
      const newTitle = input.value.trim();
      
      if (newTitle && newTitle !== currentTitle) {
        this.updateColumnTitle(newTitle, input);
      } else {
        // Restaurar título original
        input.replaceWith(titleElement);
      }
    };
    
    input.addEventListener("blur", saveTitle);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        input.blur();
      } else if (e.key === "Escape") {
        input.replaceWith(titleElement);
      }
    });
  }

  // Actualizar título de columna via AJAX
  updateColumnTitle(newTitle, inputElement) {
    const url = this.updateUrlValue;
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    
    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        column: {
          title: newTitle
        }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Crear nuevo elemento de título
        const newTitleElement = document.createElement("h3");
        newTitleElement.className = "font-semibold text-gray-700 cursor-pointer hover:text-blue-600";
        newTitleElement.dataset.columnEditorTarget = "title";
        newTitleElement.dataset.action = "click->column-editor#editTitle";
        newTitleElement.textContent = data.title;
        
        inputElement.replaceWith(newTitleElement);
      } else {
        alert("Error al actualizar: " + data.errors.join(", "));
        inputElement.focus();
      }
    })
    .catch(error => {
      console.error("Error:", error);
      alert("Error al actualizar la columna");
      inputElement.focus();
    });
  }

  // Crear nueva columna
  createColumn(event) {
    event.preventDefault();
    
    const titleInput = this.newColumnTitleTarget;
    const title = titleInput.value.trim();
    
    if (!title) {
      alert("El título de la columna es requerido");
      return;
    }
    
    const url = this.createUrlValue;
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        column: {
          title: title
        }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Recargar la página para mostrar la nueva columna
        window.location.reload();
      } else {
        alert("Error al crear columna: " + data.errors.join(", "));
      }
    })
    .catch(error => {
      console.error("Error:", error);
      alert("Error al crear la columna");
    });
  }

  // Cancelar creación de columna
  cancelCreate() {
    this.formTarget.classList.add("hidden");
    this.newColumnTitleTarget.value = "";
  }

  // Mostrar formulario de nueva columna
  showForm() {
    this.formTarget.classList.remove("hidden");
    this.newColumnTitleTarget.focus();
  }
}
