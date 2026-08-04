import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="document-preview"
//
// Muestra un preview grande del documento al hacer hover sobre la tarjeta.
// El popover se mueve a document.body para escapar del overflow-hidden de la
// tarjeta y se posiciona de forma fija junto a ella. Es pointer-events-none:
// solo sirve de vista previa, la tarjeta sigue siendo clicable.
export default class extends Controller {
  static targets = ["popover"];
  static values = {
    delay: { type: Number, default: 300 },
    offset: { type: Number, default: 12 }
  };

  connect() {
    if (!this.hasPopoverTarget) return;

    // Sacar el popover de la tarjeta (que tiene overflow-hidden) y moverlo al body
    this.popover = this.popoverTarget;
    document.body.appendChild(this.popover);

    this.showTimer = null;

    this.boundScheduleShow = this.scheduleShow.bind(this);
    this.boundHide = this.hide.bind(this);
    this.boundCancel = this.cancelAndHide.bind(this);

    this.element.addEventListener("mouseenter", this.boundScheduleShow);
    this.element.addEventListener("mouseleave", this.boundCancel);
    window.addEventListener("scroll", this.boundHide, true);
    window.addEventListener("resize", this.boundHide);
  }

  disconnect() {
    this.cancelTimer();

    if (this.popover) {
      this.popover.remove();
      this.popover = null;
    }

    this.element.removeEventListener("mouseenter", this.boundScheduleShow);
    this.element.removeEventListener("mouseleave", this.boundCancel);
    window.removeEventListener("scroll", this.boundHide, true);
    window.removeEventListener("resize", this.boundHide);
  }

  scheduleShow() {
    this.cancelTimer();
    this.showTimer = setTimeout(() => this.show(), this.delayValue);
  }

  cancelAndHide() {
    this.cancelTimer();
    this.hide();
  }

  cancelTimer() {
    if (this.showTimer) {
      clearTimeout(this.showTimer);
      this.showTimer = null;
    }
  }

  show() {
    if (!this.popover) return;

    this.positionPopover();
    this.popover.classList.remove("hidden");
    // Forzar reflow para que la transición de opacidad se vea
    this.popover.offsetHeight;
    this.popover.classList.remove("opacity-0", "scale-95");
    this.popover.classList.add("opacity-100", "scale-100");
  }

  hide() {
    if (!this.popover || this.popover.classList.contains("hidden")) return;

    this.popover.classList.add("opacity-0", "scale-95");
    this.popover.classList.remove("opacity-100", "scale-100");

    // Esperar a que termine la transición antes de ocultar del todo
    setTimeout(() => {
      if (this.popover && this.popover.classList.contains("opacity-0")) {
        this.popover.classList.add("hidden");
      }
    }, 150);
  }

  positionPopover() {
    const rect = this.element.getBoundingClientRect();
    const popover = this.popover;
    const offset = this.offsetValue;

    // Medir el popover (temporalmente visible fuera de pantalla si está hidden)
    const wasHidden = popover.classList.contains("hidden");
    if (wasHidden) {
      popover.classList.remove("hidden");
      popover.style.visibility = "hidden";
    }

    const pw = popover.offsetWidth;
    const ph = popover.offsetHeight;

    // Preferir la derecha de la tarjeta; si no cabe, la izquierda; si no, debajo
    let left = rect.right + offset;
    let top = rect.top;

    if (left + pw > window.innerWidth - offset) {
      left = rect.left - pw - offset;
    }
    if (left < offset) {
      left = Math.min(Math.max(rect.left, offset), window.innerWidth - pw - offset);
      top = rect.bottom + offset;
    }

    // Clampear verticalmente al viewport
    if (top + ph > window.innerHeight - offset) {
      top = Math.max(offset, window.innerHeight - ph - offset);
    }

    popover.style.left = `${left}px`;
    popover.style.top = `${top}px`;

    if (wasHidden) {
      popover.style.visibility = "";
      popover.classList.add("hidden");
    }
  }
}
