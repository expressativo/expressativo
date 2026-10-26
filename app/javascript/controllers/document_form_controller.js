import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-form"
// Atajos del editor de documentos: Cmd/Ctrl+S guarda y Enter en el título
// salta al cuerpo en vez de enviar el formulario.
//
// Con autosave activo (borradores de texto) cada cambio se sincroniza con el
// back unos instantes después de dejar de escribir. Al crear, el primer
// autoguardado da de alta el documento y el formulario pasa a editarlo, así
// que recargar la página no pierde nada.
export default class extends Controller {
  static targets = ["status"]
  static values = {
    autosave: Boolean,
    delay: { type: Number, default: 1200 }
  }

  connect() {
    this.dirty = false
    this.saving = false
    this.uploads = 0
    this.submitting = false
    this.beforeUnload = this.beforeUnload.bind(this)
    window.addEventListener("beforeunload", this.beforeUnload)
  }

  disconnect() {
    clearTimeout(this.timer)
    window.removeEventListener("beforeunload", this.beforeUnload)
  }

  save(event) {
    event.preventDefault()
    this.element.requestSubmit()
  }

  submit(event) {
    // Si hay un autoguardado en vuelo (p. ej. el que crea el documento),
    // esperar a que termine para no crearlo dos veces.
    if (this.saving) {
      event.preventDefault()
      this.resubmit = true
      return
    }

    this.submitting = true
    clearTimeout(this.timer)
  }

  focusBody(event) {
    const body = this.element.querySelector(".lexxy-editor__content")
    if (!body) return

    event.preventDefault()
    body.focus()
  }

  // lexxy:change y input del título
  changed() {
    if (!this.autosaveValue || this.submitting) return

    this.dirty = true
    this.setStatus("pending", "Cambios sin guardar")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.autosave(), this.delayValue)
  }

  uploadStarted() {
    this.uploads++
  }

  uploadEnded() {
    this.uploads = Math.max(0, this.uploads - 1)
  }

  async autosave() {
    if (!this.dirty || this.submitting) return
    // Esperar a que suban las imágenes: el cuerpo aún no tiene el blob final.
    if (this.saving || this.uploads > 0) {
      this.timer = setTimeout(() => this.autosave(), this.delayValue)
      return
    }
    if (!this.persisted && this.isEmpty) return

    this.dirty = false
    this.saving = true
    this.setStatus("saving", "Guardando…")

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        body: this.formData(),
        headers: { Accept: "application/json", "X-CSRF-Token": this.csrfToken },
        credentials: "same-origin"
      })

      if (response.status === 409) {
        // Ya no es borrador (se publicó en otra pestaña): dejar de autoguardar.
        this.autosaveValue = false
        this.setStatus("error", "Publicado: guarda los cambios a mano")
        return
      }
      if (response.status === 422) {
        // Error de validación (p. ej. nombre repetido): se reintenta al volver a editar.
        const errors = await response.json().catch(() => ({}))
        const message = Object.values(errors).flat()[0]
        this.dirty = true
        this.setStatus("error", message ? `No se guardó: ${message}` : "No se pudo guardar")
        return
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const payload = await response.json()
      if (!this.persisted) this.becomeEdit(payload)
      this.setStatus("saved", "Guardado")
    } catch (error) {
      this.dirty = true
      this.setStatus("error", "No se pudo guardar · reintentando")
      this.timer = setTimeout(() => this.autosave(), this.delayValue * 4)
    } finally {
      this.saving = false
      if (this.resubmit) {
        this.resubmit = false
        this.element.requestSubmit()
      }
    }
  }

  // El documento ya existe: el formulario actualiza en vez de crear y la URL
  // apunta a la edición, para que recargar abra el documento guardado.
  becomeEdit({ url, edit_url }) {
    this.element.action = url

    let method = this.element.querySelector("input[name='_method']")
    if (!method) {
      method = document.createElement("input")
      method.type = "hidden"
      method.name = "_method"
      this.element.prepend(method)
    }
    method.value = "patch"

    window.history.replaceState(window.history.state, "", edit_url)
  }

  beforeUnload(event) {
    if (!this.dirty || this.submitting || !this.autosaveValue) return

    // Último intento antes de salir; keepalive deja terminar la petición.
    if (this.persisted && this.uploads === 0) {
      clearTimeout(this.timer)
      fetch(this.element.action, {
        method: "POST",
        body: this.formData(),
        headers: { Accept: "application/json", "X-CSRF-Token": this.csrfToken },
        credentials: "same-origin",
        keepalive: true
      })
      this.dirty = false
      return
    }

    event.preventDefault()
    event.returnValue = ""
  }

  formData() {
    const data = new FormData(this.element)
    data.append("autosave", "1")
    return data
  }

  setStatus(state, text) {
    if (!this.hasStatusTarget) return

    this.statusTarget.dataset.state = state
    this.statusTarget.querySelector("[data-label]").textContent = text
  }

  get persisted() {
    return this.element.querySelector("input[name='_method']")?.value === "patch"
  }

  get isEmpty() {
    const name = this.element.querySelector("[name='document[name]']")?.value.trim()
    const body = this.element.querySelector(".lexxy-editor__content")?.textContent.trim()
    const media = this.element.querySelector(".lexxy-editor__content img, .lexxy-editor__content action-text-attachment")
    return !name && !body && !media
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
