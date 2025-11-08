import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="calendar"
export default class extends Controller {
  static targets = [
    "modal",
    "modalTitle",
    "form",
    "publicationId",
    "publicationDate",
    "titleInput",
    "descriptionInput",
    "dateInput",
    "deleteButton",
    "createTaskButton"
  ];

  connect() {
    this.projectId = window.location.pathname.split('/')[2];
    this.isEditing = false;
  }

  openModal(event) {
    const date = event.currentTarget.dataset.date;
    
    // Resetear el formulario
    this.resetForm();
    
    // Configurar para nueva publicación
    this.isEditing = false;
    this.modalTitleTarget.textContent = "Nueva Publicación";
    this.publicationDateTarget.value = date;
    this.dateInputTarget.value = date;
    this.deleteButtonTarget.classList.add("hidden");
    this.createTaskButtonTarget.classList.add("hidden");
    
    // Mostrar modal
    this.modalTarget.classList.remove("hidden");
  }

  editPublication(event) {
    const element = event.currentTarget;
    const publicationId = element.dataset.publicationId;
    const title = element.dataset.publicationTitle;
    const description = element.dataset.publicationDescription;
    const date = element.dataset.publicationDate;
    const hasTask = element.dataset.publicationHasTask === "true";
    const taskId = element.dataset.publicationTaskId;
    
    // Si tiene tarea, redirigir al detalle de la tarea
    if (hasTask && taskId) {
      window.location.href = element.dataset.taskUrl;
      return;
    }
    
    // Configurar para edición
    this.isEditing = true;
    this.modalTitleTarget.textContent = "Editar Publicación";
    this.publicationIdTarget.value = publicationId;
    this.publicationDateTarget.value = date;
    this.titleInputTarget.value = title;
    this.descriptionInputTarget.value = description;
    this.dateInputTarget.value = date;
    
    // Mostrar botones de edición
    this.deleteButtonTarget.classList.remove("hidden");
    
    // Mostrar botón de crear tarea solo si no tiene tarea
    if (!hasTask) {
      this.createTaskButtonTarget.classList.remove("hidden");
    } else {
      this.createTaskButtonTarget.classList.add("hidden");
    }
    
    // Mostrar modal
    this.modalTarget.classList.remove("hidden");
  }

  closeModal() {
    this.modalTarget.classList.add("hidden");
    this.resetForm();
  }

  resetForm() {
    this.formTarget.reset();
    this.publicationIdTarget.value = "";
    this.isEditing = false;
  }

  async submitForm(event) {
    event.preventDefault();
    
    const formData = new FormData(this.formTarget);
    const data = {
      publication: {
        title: formData.get("title"),
        description: formData.get("description"),
        publication_date: formData.get("publication_date_display")
      }
    };
    
    try {
      let url, method;
      
      if (this.isEditing) {
        const publicationId = this.publicationIdTarget.value;
        url = `/projects/${this.projectId}/publications/${publicationId}`;
        method = "PATCH";
      } else {
        url = `/projects/${this.projectId}/publications`;
        method = "POST";
      }
      
      const response = await fetch(url, {
        method: method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        },
        body: JSON.stringify(data)
      });
      
      const result = await response.json();
      
      if (result.success) {
        // Recargar la página para mostrar los cambios
        window.location.reload();
      } else {
        alert("Error: " + result.errors.join(", "));
      }
    } catch (error) {
      console.error("Error:", error);
      alert("Ocurrió un error al guardar la publicación");
    }
  }

  async deletePublication() {
    if (!confirm("¿Estás seguro de eliminar esta publicación?")) {
      return;
    }
    
    const publicationId = this.publicationIdTarget.value;
    
    try {
      const response = await fetch(`/projects/${this.projectId}/publications/${publicationId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": this.getCSRFToken()
        }
      });
      
      const result = await response.json();
      
      if (result.success) {
        window.location.reload();
      } else {
        alert("Error al eliminar la publicación");
      }
    } catch (error) {
      console.error("Error:", error);
      alert("Ocurrió un error al eliminar la publicación");
    }
  }

  async createTask() {
    const publicationId = this.publicationIdTarget.value;
    
    if (!publicationId) {
      alert("Primero debes guardar la publicación");
      return;
    }
    
    if (!confirm("¿Crear una tarea en la lista 'Publicaciones' para esta publicación?")) {
      return;
    }
    
    try {
      const response = await fetch(`/projects/${this.projectId}/publications/${publicationId}/create_task`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.getCSRFToken()
        }
      });
      
      const result = await response.json();
      
      if (result.success) {
        alert(result.message);
        window.location.reload();
      } else {
        alert("Error: " + result.errors.join(", "));
      }
    } catch (error) {
      console.error("Error:", error);
      alert("Ocurrió un error al crear la tarea");
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}
