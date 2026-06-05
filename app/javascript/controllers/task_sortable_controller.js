import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

// Connects to data-controller="task-sortable"
export default class extends Controller {
  static values = { urlTemplate: String };

  connect() {
    console.log("[task-sortable] connect", this.element);
    this.sortable = new Sortable(this.element, {
      animation: 150,
      handle: ".task-drag-handle",
      ghostClass: "bg-purple-50",
      dragClass: "opacity-50",
      onEnd: (event) => {
        console.log("[task-sortable] onEnd", event.oldIndex, "->", event.newIndex, event.item);
        this.handleDrop(event);
      }
    });
  }

  disconnect() {
    this.sortable?.destroy();
  }

  async handleDrop(event) {
    if (event.oldIndex === event.newIndex) return;

    const taskId = event.item.dataset.taskId;
    if (!taskId) return;

    const url = this.urlTemplateValue.replace(":id", taskId);

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ position: event.newIndex })
      });
      if (!response.ok) throw new Error("Error al actualizar la posición");
    } catch (e) {
      console.error(e);
      alert("Error al mover la tarea. Recarga la página.");
    }
  }
}
