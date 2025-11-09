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
          ghostClass: 'opacity-50',
          dragClass: 'shadow-lg',
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

  async exportCalendar(event) {
    const format = event.currentTarget.dataset.format || 'png';
    const calendarElement = this.calendarTarget;
    
    // Mostrar mensaje de carga
    const originalText = event.currentTarget.textContent;
    event.currentTarget.textContent = 'Generando...';
    event.currentTarget.disabled = true;
    
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
          // Remover todas las hojas de estilo SOLO del documento clonado
          const styleSheets = clonedDoc.querySelectorAll('link[rel="stylesheet"], style');
          styleSheets.forEach(sheet => sheet.remove());
          
          // Aplicar estilos básicos inline
          const calendarClone = clonedDoc.querySelector('[data-calendar-target="calendar"]');
          if (calendarClone) {
            calendarClone.style.cssText = `
              border: 1px solid #d1d5db;
              border-radius: 8px;
              overflow: hidden;
              background: white;
            `;
            
            // Estilos para el header de días
            const daysHeader = calendarClone.querySelector('.grid.grid-cols-7');
            if (daysHeader) {
              daysHeader.style.cssText = `
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                background: #f9fafb;
                border-bottom: 1px solid #d1d5db;
              `;
              
              daysHeader.querySelectorAll('div').forEach(day => {
                day.style.cssText = `
                  padding: 12px;
                  text-align: center;
                  font-weight: 600;
                  font-size: 14px;
                  color: #374151;
                  border-right: 1px solid #d1d5db;
                `;
              });
            }
            
            // Estilos para los días del mes
            const daysGrid = calendarClone.querySelectorAll('.grid.grid-cols-7')[1];
            if (daysGrid) {
              daysGrid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(7, 1fr);
              `;
              
              // Aplicar estilos a TODAS las celdas (incluyendo las vacías del inicio)
              const allCells = daysGrid.querySelectorAll('div');
              allCells.forEach(dayCell => {
                // Verificar si es una celda vacía del inicio del mes
                const isEmpty = dayCell.classList.contains('bg-gray-50') || 
                               (!dayCell.hasAttribute('data-calendar-target') && 
                                !dayCell.hasAttribute('data-date'));
                
                if (isEmpty) {
                  // Estilos para celdas vacías
                  dayCell.style.cssText = `
                    min-height: 120px;
                    padding: 8px;
                    background: #f9fafb;
                    border-right: 1px solid #e5e7eb;
                    border-bottom: 1px solid #e5e7eb;
                  `;
                } else if (dayCell.hasAttribute('data-calendar-target') || dayCell.hasAttribute('data-date')) {
                  // Estilos para celdas con días
                  dayCell.style.cssText = `
                    min-height: 120px;
                    padding: 8px;
                    border-right: 1px solid #e5e7eb;
                    border-bottom: 1px solid #e5e7eb;
                    background: white;
                  `;
                  
                  // Número del día
                  const dayNumber = dayCell.querySelector('span');
                  if (dayNumber) {
                    if (dayNumber.classList.contains('bg-blue-600')) {
                      dayNumber.style.cssText = `
                        background: #2563eb;
                        color: white;
                        border-radius: 9999px;
                        width: 28px;
                        height: 28px;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 14px;
                        font-weight: 600;
                      `;
                    } else {
                      dayNumber.style.cssText = `
                        color: #374151;
                        font-weight: 500;
                      `;
                    }
                  }
                  
                  // Publicaciones
                  const publications = dayCell.querySelectorAll('.publication-item');
                  publications.forEach(pub => {
                    pub.style.cssText = `
                      background: #eff6ff;
                      border-left: 2px solid #3b82f6;
                      padding: 4px 8px;
                      font-size: 12px;
                      border-radius: 4px;
                      margin-bottom: 4px;
                    `;
                    
                    const title = pub.querySelector('div');
                    if (title) {
                      title.style.cssText = `
                        font-weight: 500;
                        color: #1f2937;
                      `;
                    }
                  });
                }
              });
            }
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
        event.currentTarget.textContent = originalText;
        event.currentTarget.disabled = false;
      }, `image/${format}`);
      
    } catch (error) {
      console.error('Error al exportar calendario:', error);
      alert('Ocurrió un error al exportar el calendario: ' + error.message);
      
      // Limpiar el contenedor temporal si existe
      if (tempContainer && tempContainer.parentNode) {
        document.body.removeChild(tempContainer);
      }
      
      event.currentTarget.textContent = originalText;
      event.currentTarget.disabled = false;
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}
