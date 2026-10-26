import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-form"
// Atajos del editor de documentos: Cmd/Ctrl+S guarda y Enter en el título
// salta al cuerpo en vez de enviar el formulario.
export default class extends Controller {
  save(event) {
    event.preventDefault()
    this.element.requestSubmit()
  }

  focusBody(event) {
    const body = this.element.querySelector(".lexxy-editor__content")
    if (!body) return

    event.preventDefault()
    body.focus()
  }
}
