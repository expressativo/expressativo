import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = ["dropZone", "fileInput", "fileInfo"]

  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Prevenir comportamiento por defecto del navegador
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.preventDefaults.bind(this), false)
      document.body.addEventListener(eventName, this.preventDefaults.bind(this), false)
    })

    // Highlight drop zone cuando se arrastra un archivo sobre él
    ['dragenter', 'dragover'].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.highlight.bind(this), false)
    })

    ['dragleave', 'drop'].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.unhighlight.bind(this), false)
    })

    // Manejar el drop
    this.dropZoneTarget.addEventListener('drop', this.handleDrop.bind(this), false)
  }

  openFileSelector() {
    this.fileInputTarget.click()
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight(e) {
    this.dropZoneTarget.classList.add('border-blue-500', 'bg-blue-100')
  }

  unhighlight(e) {
    this.dropZoneTarget.classList.remove('border-blue-500', 'bg-blue-100')
  }

  handleDrop(e) {
    const dt = e.dataTransfer
    const files = dt.files

    if (files.length > 0) {
      this.fileInputTarget.files = files
      this.updateFileInfo(files[0])
    }
  }

  fileSelected(event) {
    if (event.target.files.length > 0) {
      this.updateFileInfo(event.target.files[0])
    }
  }

  updateFileInfo(file) {
    const fileSize = this.formatFileSize(file.size)
    this.fileInfoTarget.innerHTML = `
      <span class="font-semibold text-green-600">✓ Archivo seleccionado:</span><br>
      ${file.name} (${fileSize})
    `
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
}
