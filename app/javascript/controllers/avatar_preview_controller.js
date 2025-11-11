import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-preview"
export default class extends Controller {
  static targets = ["image", "placeholder", "preview"]

  preview(event) {
    const file = event.target.files[0]
    
    if (file) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        // Si ya existe una imagen, actualizar su src
        if (this.hasImageTarget) {
          this.imageTarget.src = e.target.result
        } else {
          // Si no existe, crear una nueva imagen y reemplazar el placeholder
          const img = document.createElement('img')
          img.src = e.target.result
          img.className = 'w-24 h-24 rounded-full object-cover border-4 border-purple-200'
          img.dataset.avatarPreviewTarget = 'image'
          
          this.previewTarget.innerHTML = ''
          this.previewTarget.appendChild(img)
        }
      }
      
      reader.readAsDataURL(file)
    }
  }
}
