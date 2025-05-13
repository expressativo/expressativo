import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["menu"];

    initialize() {
        console.log("NavbarDropdownController registrado correctamente");
    }

    toggle(event) {
        event.stopPropagation();
        this.menuTarget.classList.toggle("hidden");
    }

    hide(event) {
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.add("hidden");
        }
    }

    hideWithEscape(event) {
        if (event.key === "Escape") {
            this.menuTarget.classList.add("hidden");
        }
    }
}
