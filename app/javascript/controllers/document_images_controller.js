import { Controller } from "@hotwired/stimulus"

// Wraps every <img> in the rich-text document body with a download button overlay.
// Skips images already wrapped (e.g., GLightbox) or already processed.
export default class extends Controller {
  connect() {
    const images = this.element.querySelectorAll(
      "figure.attachment--preview a.glightbox img, img:not(.glightbox img)"
    )
    images.forEach(img => this.wrap(img))
  }

  wrap(img) {
    if (img.closest("a.glightbox")) return
    if (img.parentElement.classList.contains("image-wrapper")) return

    const wrapper = document.createElement("div")
    wrapper.className = "image-wrapper"

    const downloadBtn = document.createElement("a")
    downloadBtn.className = "image-download-btn"
    downloadBtn.innerHTML = `
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
      </svg>
      Descargar
    `

    img.parentNode.insertBefore(wrapper, img)
    wrapper.appendChild(img)
    wrapper.appendChild(downloadBtn)

    downloadBtn.addEventListener("click", (e) => {
      e.preventDefault()
      this.download(img.src, this.filename(img.src))
    })
  }

  download(url, filename) {
    fetch(url)
      .then(r => r.blob())
      .then(blob => {
        const link = document.createElement("a")
        link.href = window.URL.createObjectURL(blob)
        link.download = filename
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(link.href)
      })
      .catch(() => window.open(url, "_blank"))
  }

  filename(url) {
    const parts = url.split("/")
    return parts[parts.length - 1] || "imagen.jpg"
  }
}
