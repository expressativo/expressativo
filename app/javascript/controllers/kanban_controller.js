import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

// Connects to data-controller="kanban"
export default class extends Controller {
  static targets = ["column"];
  static values = {
    updateUrl: String
  };

  connect() {
    console.log("Kanban controller conectado");
    this.initializeSortable();
  }

  disconnect() {
    // Limpiar instancias de Sortable
    this.sortableInstances?.forEach(instance => instance.destroy());
  }

  initializeSortable() {
    this.sortableInstances = [];
    this.isDragging = false;

    this.columnTargets.forEach((column) => {
      const sortable = new Sortable(column, {
        group: "shared", // Permite mover entre columnas
        animation: 150,
        ghostClass: "bg-blue-100",
        dragClass: "opacity-50",
        handle: ".task-card", // Toda la tarjeta es arrastrable
        delay: 100, // Pequeño delay para distinguir entre click y drag
        delayOnTouchOnly: true,
        
        onStart: (event) => {
          this.isDragging = true;
          event.item.classList.add('sortable-drag');
        },
        
        onEnd: (event) => {
          event.item.classList.remove('sortable-drag');
          this.handleDrop(event);
          
          // Resetear después de un pequeño delay
          setTimeout(() => {
            this.isDragging = false;
          }, 100);
        }
      });

      this.sortableInstances.push(sortable);
    });
  }

  handleDrop(event) {
    const taskId = event.item.dataset.taskId;
    const columnId = event.to.dataset.columnId;
    const newPosition = event.newIndex;

    console.log("Tarea movida:", { taskId, columnId, newPosition });

    // Enviar actualización al servidor
    this.updateTaskPosition(taskId, columnId, newPosition, event.item);
  }

  async updateTaskPosition(taskId, columnId, position, taskElement) {
    try {
      const response = await fetch(`/board_tasks/${taskId}/update_position`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCsrfToken()
        },
        body: JSON.stringify({
          column_id: columnId,
          position: position
        })
      });

      if (!response.ok) {
        throw new Error("Error al actualizar la posición");
      }

      // Obtener información sobre si es la última columna
      const responseData = await response.json();
      
      // Actualizar el badge de completado sin recargar la página
      this.updateCompletedBadge(taskElement, responseData.is_completed);
      
      console.log("✓ Posición actualizada exitosamente");
    } catch (error) {
      console.error("Error:", error);
      alert("Error al mover la tarea. Por favor, recarga la página.");
    }
  }

  updateCompletedBadge(taskElement, isCompleted) {
    // Buscar si ya existe un badge
    const existingBadge = taskElement.querySelector('.completed-badge');
    
    if (isCompleted) {
      // Si debe estar completada y no tiene badge, agregarlo
      if (!existingBadge) {
        const titleContainer = taskElement.querySelector('.flex.justify-between.items-start');
        if (titleContainer) {
          const badge = document.createElement('span');
          badge.className = 'completed-badge inline-flex items-center px-2 py-1 text-xs font-medium text-green-700 bg-green-100 rounded-full';
          badge.textContent = '✓ Completada';
          titleContainer.appendChild(badge);
        }
      }
    } else {
      // Si no debe estar completada y tiene badge, removerlo
      if (existingBadge) {
        existingBadge.remove();
      }
    }
  }

  getCsrfToken() {
    return document.querySelector("[name='csrf-token']").content;
  }
}
