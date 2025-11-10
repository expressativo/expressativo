import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";
import html2canvas from "html2canvas";

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
    "day",
    "calendar"
  ];

  connect() {
    this.projectId = window.location.pathname.split('/')[2];
    this.isEditing = false;
    this.initializeSortable();
  }

  disconnect() {
    // Destruir instancias de Sortable al desconectar
    if (this.sortableInstances) {
      this.sortableInstances.forEach(sortable => sortable.destroy());
    }
  }

  initializeSortable() {
    this.sortableInstances = [];
    
    // Inicializar Sortable en cada día del calendario
    this.dayTargets.forEach(dayElement => {
      const publicationsContainer = dayElement.querySelector('[data-publications-container]');
      
      if (publicationsContainer) {
        const sortable = new Sortable(publicationsContainer, {
          group: 'publications',
          animation: 150,
          ghostClass: 'sortable-ghost',
          dragClass: 'sortable-drag',
          handle: '.publication-item',
          onEnd: this.handleDrop.bind(this)
        });
        
        this.sortableInstances.push(sortable);
      }
    });
  }

  async handleDrop(event) {
    const publicationElement = event.item;
    const publicationId = publicationElement.dataset.publicationId;
    const newDayElement = event.to.closest('[data-calendar-target="day"]');
    const newDate = newDayElement.dataset.date;
    
    try {
      const response = await fetch(`/projects/${this.projectId}/publications/${publicationId}/update_date`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ new_date: newDate })
      });
      
      const result = await response.json();
      
      if (!result.success) {
        alert('Error: ' + result.errors.join(', '));
        // Recargar para revertir el cambio visual
        window.location.reload();
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Ocurrió un error al mover la publicación');
      window.location.reload();
    }
  }

  openModal(event) {
    // Buscar el elemento day más cercano para obtener la fecha
    const dayElement = event.currentTarget.closest('[data-calendar-target="day"]');
    const date = dayElement ? dayElement.dataset.date : null;
    
    if (!date) return;
    
    // Resetear el formulario
    this.resetForm();
    
    // Configurar para nueva publicación
    this.isEditing = false;
    this.modalTitleTarget.textContent = "Nueva Publicación";
    this.publicationDateTarget.value = date;
    this.dateInputTarget.value = date;
    this.deleteButtonTarget.classList.add("hidden");
    
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

  // Helper para convertir colores a RGB
  getRGBColor(color) {
    if (!color || color === 'transparent' || color === 'rgba(0, 0, 0, 0)') {
      return color;
    }
    
    // Si ya es RGB o hex, devolverlo
    if (color.startsWith('rgb') || color.startsWith('#')) {
      return color;
    }
    
    // Convertir oklch u otros formatos a RGB usando un elemento temporal
    const temp = document.createElement('div');
    temp.style.color = color;
    temp.style.display = 'none';
    document.body.appendChild(temp);
    const rgb = window.getComputedStyle(temp).color;
    document.body.removeChild(temp);
    return rgb || color;
  }

  async exportCalendar(event) {
    const button = event.currentTarget;
    const format = button.dataset.format || 'png';
    const calendarElement = this.calendarTarget;
    
    // Mostrar mensaje de carga
    const originalText = button.textContent;
    button.textContent = 'Generando...';
    button.disabled = true;
    
    try {
      // Crear un contenedor temporal para la captura
      const tempContainer = document.createElement('div');
      tempContainer.style.position = 'absolute';
      tempContainer.style.left = '-9999px';
      tempContainer.style.top = '0';
      document.body.appendChild(tempContainer);
      
      // Clonar el calendario
      const clone = calendarElement.cloneNode(true);
      tempContainer.appendChild(clone);
      
      // Capturar usando ignoreElements para evitar problemas con oklch
      const canvas = await html2canvas(clone, {
        backgroundColor: '#ffffff',
        scale: 2,
        logging: false,
        useCORS: true,
        allowTaint: true,
        // Ignorar elementos SVG que pueden tener oklch
        ignoreElements: (element) => {
          return element.tagName === 'svg';
        },
        onclone: (clonedDoc) => {
          // Remover hojas de estilo de Tailwind que contienen oklch
          const tailwindSheets = clonedDoc.querySelectorAll('link[href*="tailwind"], style');
          tailwindSheets.forEach(sheet => sheet.remove());
          
          // Aplicar estilos inline con colores RGB
          const calendarClone = clonedDoc.querySelector('[data-calendar-target="calendar"]');
          if (calendarClone) {
            // Contenedor del calendario
            calendarClone.style.cssText = `
              border: 1px solid #d1d5db;
              border-radius: 0.5rem;
              overflow: hidden;
              background: #ffffff;
            `;
            
            // Header de días de la semana
            const weekdays = calendarClone.querySelector('.calendar-weekdays');
            if (weekdays) {
              weekdays.style.cssText = `
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                background-color: #f9fafb;
                border-bottom: 1px solid #d1d5db;
              `;
              
              weekdays.querySelectorAll('.calendar-weekday').forEach(day => {
                const computed = window.getComputedStyle(day);
                day.style.cssText = `
                  padding: ${computed.padding};
                  text-align: ${computed.textAlign};
                  font-weight: ${computed.fontWeight};
                  font-size: ${computed.fontSize};
                  color: ${this.getRGBColor(computed.color)};
                  background-color: ${this.getRGBColor(computed.backgroundColor)};
                  border-right: ${computed.borderRightWidth} ${computed.borderRightStyle} ${this.getRGBColor(computed.borderRightColor)};
                `;
              });
            }
            
            // Grid de días del mes
            const daysGrid = calendarClone.querySelector('.calendar-days-grid');
            if (daysGrid) {
              daysGrid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(7, 1fr);
              `;
            }
            
            // Celdas vacías
            calendarClone.querySelectorAll('.calendar-empty-cell').forEach(cell => {
              cell.style.cssText = `
                min-height: 120px;
                padding: 0.5rem;
                background-color: #f9fafb;
                border-right: 1px solid #e5e7eb;
                border-bottom: 1px solid #e5e7eb;
              `;
            });
            
            // Celdas de días
            calendarClone.querySelectorAll('.calendar-day-cell').forEach(cell => {
              cell.style.cssText = `
                min-height: 120px;
                padding: 0.5rem;
                background-color: #ffffff;
                border-right: 1px solid #e5e7eb;
                border-bottom: 1px solid #e5e7eb;
              `;
              
              // Header del día
              const dayHeader = cell.querySelector('.calendar-day-header');
              if (dayHeader) {
                dayHeader.style.cssText = `
                  display: flex;
                  justify-content: space-between;
                  align-items: flex-start;
                  margin-bottom: 0.5rem;
                  padding-left: 0.5rem;
                  border: 2px dashed #e5e7eb;
                  border-radius: 0.25rem;
                `;
              }
              
              // Número del día
              const dayNumber = cell.querySelector('.calendar-day-number');
              if (dayNumber) {
                dayNumber.style.cssText = `
                  color: #374151;
                  font-weight: 500;
                `;
              }
              
              // Día actual
              const dayToday = cell.querySelector('.calendar-day-today');
              if (dayToday) {
                dayToday.style.cssText = `
                  background-color: #2563eb;
                  color: #ffffff;
                  border-radius: 9999px;
                  width: 1.75rem;
                  height: 1.75rem;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  font-size: 0.875rem;
                  font-weight: 600;
                `;
              }
              
              // Contador de publicaciones
              const pubCount = cell.querySelector('.calendar-pub-count');
              if (pubCount) {
                pubCount.style.cssText = `
                  background-color: #dbeafe;
                  color: #1e40af;
                  font-size: 0.75rem;
                  padding: 0.25rem 0.5rem;
                  border-radius: 9999px;
                `;
              }
            });
            
            // Publicaciones
            calendarClone.querySelectorAll('.publication-item').forEach(pub => {
              pub.style.cssText = `
                background-color: #eff6ff;
                border-left: 2px solid #3b82f6;
                padding: 0.25rem 0.5rem;
                font-size: 0.75rem;
                border-radius: 0.25rem;
                margin-bottom: 4px;
              `;
              
              // Título de publicación
              const title = pub.querySelector('.publication-item-title');
              if (title) {
                title.style.cssText = `
                  font-weight: 500;
                  color: #111827;
                  overflow: hidden;
                  text-overflow: ellipsis;
                  white-space: nowrap;
                `;
              }
              
              // Indicador de tarea
              const taskIndicator = pub.querySelector('.publication-task-indicator');
              if (taskIndicator) {
                taskIndicator.style.cssText = `
                  display: flex;
                  align-items: center;
                  gap: 0.25rem;
                  color: #16a34a;
                  margin-top: 0.25rem;
                  font-size: 0.75rem;
                `;
              }
            });
          }
        }
      });
      
      // Limpiar el contenedor temporal
      document.body.removeChild(tempContainer);
      
      // Convertir a blob
      canvas.toBlob((blob) => {
        // Crear URL temporal
        const url = URL.createObjectURL(blob);
        
        // Crear link de descarga
        const link = document.createElement('a');
        const monthYearText = this.element.querySelector('h2').textContent.trim();
        // Convertir "Noviembre 2024" a "noviembre-2024"
        const fileName = monthYearText.toLowerCase().replace(/\s+/g, '-');
        link.download = `${fileName}.${format}`;
        link.href = url;
        link.click();
        
        // Limpiar
        URL.revokeObjectURL(url);
        
        // Restaurar botón
        button.textContent = originalText;
        button.disabled = false;
      }, `image/${format}`);
      
    } catch (error) {
      console.error('Error al exportar calendario:', error);
      alert('Ocurrió un error al exportar el calendario: ' + error.message);
      
      // Limpiar el contenedor temporal si existe
      if (tempContainer && tempContainer.parentNode) {
        document.body.removeChild(tempContainer);
      }
      
      button.textContent = originalText;
      button.disabled = false;
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}
