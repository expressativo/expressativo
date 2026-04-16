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
    this.initializeHeaderDropZones();
  }

  disconnect() {
    this.sortableInstances?.forEach(instance => instance.destroy());
    this.cleanupHeaderDropZones();
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
          
          // Resaltar columnas de destino (todas excepto la de origen)
          const sourceColumn = event.from;
          this.columnTargets.forEach((col) => {
            if (col !== sourceColumn) {
              col.classList.add('drop-target-highlight');
            }
          });
        },

      onEnd: (event) => {
          event.item.classList.remove('sortable-drag');
          
          // Remover resaltado de todas las columnas
          this.columnTargets.forEach((col) => {
            col.classList.remove('drop-target-highlight');
          });
          
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

  initializeHeaderDropZones() {
    this._headerHandlers = [];

    const headers = this.element.querySelectorAll('.column-drag-handle');
    headers.forEach((header) => {
      const columnWrapper = header.closest('[data-column-id]');
      if (!columnWrapper) return;

      const columnId = columnWrapper.dataset.columnId;
      const taskList = columnWrapper.querySelector('[data-kanban-target="column"]');
      if (!taskList) return;

      const highlightClasses = ['bg-purple-50', 'border-b-purple-500', 'ring-2', 'ring-purple-300', 'ring-inset'];

      const onDragOver = (e) => {
        if (!this.isDragging) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        header.classList.remove('border-gray-300');
        header.classList.add(...highlightClasses);
      };

      const onDragLeave = () => {
        header.classList.remove(...highlightClasses);
        header.classList.add('border-gray-300');
      };

      const onDrop = (e) => {
        e.preventDefault();
        header.classList.remove(...highlightClasses);
        header.classList.add('border-gray-300');

        const draggedItem = this.element.querySelector('.sortable-drag') ||
                            this.element.querySelector('.task-card[style*="position"]');

        // SortableJS expone el elemento arrastrado
        const sortableDragged = Sortable.dragged;
        if (!sortableDragged) return;

        const sourceList = sortableDragged.parentElement;

        // Insertar al inicio de la columna destino
        taskList.prepend(sortableDragged);

        // Obtener el taskId y actualizar posición
        const taskId = sortableDragged.dataset.taskId;
        this.updateTaskPosition(taskId, columnId, 0, sortableDragged);

        // Limpiar highlights
        this.columnTargets.forEach((col) => {
          col.classList.remove('drop-target-highlight');
        });
      };

      header.addEventListener('dragover', onDragOver);
      header.addEventListener('dragleave', onDragLeave);
      header.addEventListener('drop', onDrop);

      this._headerHandlers.push({ header, onDragOver, onDragLeave, onDrop });
    });
  }

  cleanupHeaderDropZones() {
    this._headerHandlers?.forEach(({ header, onDragOver, onDragLeave, onDrop }) => {
      header.removeEventListener('dragover', onDragOver);
      header.removeEventListener('dragleave', onDragLeave);
      header.removeEventListener('drop', onDrop);
    });
    this._headerHandlers = [];
  }

  getCsrfToken() {
    return document.querySelector("[name='csrf-token']").content;
  }
}
