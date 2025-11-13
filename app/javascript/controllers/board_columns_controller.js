import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

// Connects to data-controller="board-columns"
export default class extends Controller {
  static targets = ["container"];
  static values = {
    projectId: Number,
    boardId: Number
  };

  connect() {
    this.initializeSortable();
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }

  initializeSortable() {
    this.sortable = new Sortable(this.containerTarget, {
      animation: 150,
      handle: ".column-drag-handle",
      draggable: ".column-draggable",
      ghostClass: "column-ghost",
      dragClass: "column-drag",
      filter: ".column-add-new", // Excluir la columna de "Agregar"
      onEnd: this.handleDrop.bind(this)
    });
  }

  handleDrop(event) {
    const columnId = event.item.dataset.columnId;
    const newPosition = event.newIndex;

    if (!columnId) {
      console.error("No se encontró el ID de la columna");
      return;
    }

    this.updateColumnPosition(columnId, newPosition);
  }

  updateColumnPosition(columnId, newPosition) {
    const url = `/projects/${this.projectIdValue}/boards/${this.boardIdValue}/columns/${columnId}/update_position`;
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        position: newPosition
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        console.error("Error al actualizar posición:", data.error);
        // Recargar para revertir el cambio visual
        window.location.reload();
      }
    })
    .catch(error => {
      console.error("Error:", error);
      // Recargar para revertir el cambio visual
      window.location.reload();
    });
  }
}
