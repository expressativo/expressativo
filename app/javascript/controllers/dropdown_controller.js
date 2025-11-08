import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dropdown"
export default class extends Controller {
    static targets = ["menu", "button"];
    static values = {
        placement: { type: String, default: "bottom" },
        offset: { type: Number, default: 10 }
    };

    initialize() {
        console.log("DropdownController inicializado");
    }

    connect() {
        // Cerrar dropdown al hacer clic fuera
        this.boundHide = this.hide.bind(this);
        document.addEventListener("click", this.boundHide);
        
        // Cerrar dropdown con tecla Escape
        this.boundHideWithEscape = this.hideWithEscape.bind(this);
        document.addEventListener("keydown", this.boundHideWithEscape);
    }

    disconnect() {
        document.removeEventListener("click", this.boundHide);
        document.removeEventListener("keydown", this.boundHideWithEscape);
    }

    toggle(event) {
        event.stopPropagation();
        
        const isHidden = this.menuTarget.classList.contains("hidden");
        
        if (isHidden) {
            this.show();
        } else {
            this.close();
        }
    }

    show() {
        this.menuTarget.classList.remove("hidden");
        this.menuTarget.classList.add("block");
        
        // Agregar animación de entrada si existe
        if (this.menuTarget.classList.contains("opacity-0")) {
            this.menuTarget.classList.remove("opacity-0");
            this.menuTarget.classList.add("opacity-100");
        }
        
        // Posicionar el dropdown según el placement
        this.positionMenu();
        
        // Actualizar aria-expanded
        if (this.hasButtonTarget) {
            this.buttonTarget.setAttribute("aria-expanded", "true");
        }
    }

    close() {
        this.menuTarget.classList.add("hidden");
        this.menuTarget.classList.remove("block");
        
        // Agregar animación de salida si existe
        if (this.menuTarget.classList.contains("opacity-100")) {
            this.menuTarget.classList.remove("opacity-100");
            this.menuTarget.classList.add("opacity-0");
        }
        
        // Actualizar aria-expanded
        if (this.hasButtonTarget) {
            this.buttonTarget.setAttribute("aria-expanded", "false");
        }
    }

    hide(event) {
        // No cerrar si el clic fue dentro del dropdown
        if (!this.element.contains(event.target)) {
            this.close();
        }
    }

    hideWithEscape(event) {
        if (event.key === "Escape") {
            this.close();
        }
    }

    positionMenu() {
        if (!this.hasButtonTarget) return;
        
        const buttonRect = this.buttonTarget.getBoundingClientRect();
        const menuRect = this.menuTarget.getBoundingClientRect();
        
        // Resetear estilos de posición
        this.menuTarget.style.top = "";
        this.menuTarget.style.bottom = "";
        this.menuTarget.style.left = "";
        this.menuTarget.style.right = "";
        
        switch (this.placementValue) {
            case "top":
                this.menuTarget.style.bottom = `${buttonRect.height + this.offsetValue}px`;
                break;
            case "bottom":
                this.menuTarget.style.top = `${buttonRect.height + this.offsetValue}px`;
                break;
            case "left":
                this.menuTarget.style.right = `${buttonRect.width + this.offsetValue}px`;
                break;
            case "right":
                this.menuTarget.style.left = `${buttonRect.width + this.offsetValue}px`;
                break;
            default:
                this.menuTarget.style.top = `${buttonRect.height + this.offsetValue}px`;
        }
    }

    // Método para seleccionar un item del dropdown
    selectItem(event) {
        const item = event.currentTarget;
        const value = item.dataset.value;
        
        // Remover clase active de todos los items
        this.menuTarget.querySelectorAll("[data-dropdown-item]").forEach(el => {
            el.classList.remove("bg-gray-100", "dark:bg-gray-600");
        });
        
        // Agregar clase active al item seleccionado
        item.classList.add("bg-gray-100", "dark:bg-gray-600");
        
        // Actualizar el texto del botón si existe
        if (this.hasButtonTarget && item.textContent) {
            const buttonText = this.buttonTarget.querySelector("[data-dropdown-button-text]");
            if (buttonText) {
                buttonText.textContent = item.textContent.trim();
            }
        }
        
        // Emitir evento personalizado con el valor seleccionado
        this.element.dispatchEvent(new CustomEvent("dropdown:select", {
            detail: { value: value, text: item.textContent.trim() },
            bubbles: true
        }));
        
        // Cerrar el dropdown después de seleccionar
        this.close();
    }
}
