import { Controller } from "@hotwired/stimulus"
import GLightbox from "glightbox"

export default class extends Controller {
  connect() {
    this.initializeLightbox()
    this.addEventListener()
  }

  disconnect() {
    this.removeEventListener()
  }

  initializeLightbox() {
    // Destruir instancia anterior si existe
    if (this.lightbox) {
      this.lightbox.destroy()
    }

    this.lightbox = GLightbox({
      selector: ".glightbox",
      touchNavigation: true,
      loop: true,
      autoplayVideos: true,
      zoomable: true,
      draggable: true,
      preload: true,
      openEffect: "zoom",
      closeEffect: "zoom",
      slideEffect: "slide",
      moreLength: 0,
      moreText: "",
      descPosition: "bottom",
      plyr: {
        config: {
          controls: ["play-large", "play", "progress", "current-time", "mute", "volume", "fullscreen"],
          tooltips: { controls: true, seek: true },
        },
      },
    })
  }

  addEventListener() {
    // Reinitialize cuando Turbo carga nuevo contenido
    document.addEventListener("turbo:load", this.handleTurboLoad.bind(this))
  }

  removeEventListener() {
    document.removeEventListener("turbo:load", this.handleTurboLoad.bind(this))
  }

  handleTurboLoad() {
    this.initializeLightbox()
  }
}
