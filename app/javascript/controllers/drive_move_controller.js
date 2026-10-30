import { Controller } from "@hotwired/stimulus"

export const DRAG_TYPE = "application/x-tivo-drive-item"

// Mover documentos y carpetas entre carpetas (estilo Google Drive).
// - "Mover a…" en el menú de cada tarjeta abre un modal con el árbol de carpetas.
// - Arrastrar una tarjeta sobre una carpeta (o sobre el botón "Volver") la mueve ahí.
// El servidor responde con turbo_stream: quita la tarjeta y muestra un toast.
// Connects to data-controller="drive-move"
export default class extends Controller {
  static targets = ["modal", "form", "title", "option", "submit", "dropzone"]

  // --- Modal "Mover a…" ------------------------------------------------------

  open({ params: { url, kind, id, folderId, name } }) {
    this.formTarget.action = url
    this.titleTarget.textContent = `Mover “${name}”`

    this.optionTargets.forEach((option) => {
      const radio = option.querySelector("input")
      const pathIds = option.dataset.pathIds.split(" ").filter(Boolean)
      const isCurrent = option.dataset.folderId === String(folderId ?? "")
      // Una carpeta no puede ir dentro de sí misma ni de sus subcarpetas.
      option.hidden = kind === "folder" && pathIds.includes(String(id))
      radio.disabled = isCurrent
      radio.checked = false
      option.querySelector("[data-current-label]").classList.toggle("hidden", !isCurrent)
    })

    this.submitTarget.disabled = true
    this.modalTarget.classList.remove("hidden")
  }

  selectionChanged() {
    this.submitTarget.disabled = !this.formTarget.querySelector("input[name='folder_id']:checked")
  }

  submitted(event) {
    if (event.detail.success) this.close()
  }

  close() {
    if (this.hasModalTarget) this.modalTarget.classList.add("hidden")
  }

  backdropClick(event) {
    if (event.target === this.modalTarget) this.close()
  }

  // --- Drag & drop -----------------------------------------------------------

  dragStart(event) {
    const card = event.currentTarget
    this.dragging = { url: card.dataset.moveUrl, kind: card.dataset.moveKind, id: card.dataset.moveId }
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData(DRAG_TYPE, this.dragging.id)
    card.classList.add("opacity-50")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50")
    this.dragging = null
    this.dropzoneTargets.forEach((zone) => zone.classList.remove("drive-drop-target"))
  }

  dragOver(event) {
    if (!this.canDrop(event.currentTarget)) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("drive-drop-target")
  }

  dragLeave(event) {
    if (event.currentTarget.contains(event.relatedTarget)) return
    event.currentTarget.classList.remove("drive-drop-target")
  }

  async drop(event) {
    const zone = event.currentTarget
    if (!this.canDrop(zone)) return
    event.preventDefault()
    zone.classList.remove("drive-drop-target")

    // La tarjeta puede desaparecer antes de que llegue su dragend.
    const { url } = this.dragging
    this.dragging = null

    const body = new FormData()
    body.append("folder_id", zone.dataset.folderId)

    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body
    })
    window.Turbo.renderStreamMessage(await response.text())
  }

  canDrop(zone) {
    if (!this.dragging) return false
    // Soltar una carpeta sobre sí misma no hace nada.
    return !(this.dragging.kind === "folder" && zone.dataset.folderId === this.dragging.id)
  }
}
