import { Controller } from "@hotwired/stimulus"
import GLightbox from "glightbox"

export default class extends Controller {
  connect() {
    this._turboLoadHandler = this.initializeLightbox.bind(this)
    document.addEventListener("turbo:load", this._turboLoadHandler)
    this.initializeLightbox()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._turboLoadHandler)
    if (this.lightbox) {
      this.lightbox.destroy()
    }
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
}
