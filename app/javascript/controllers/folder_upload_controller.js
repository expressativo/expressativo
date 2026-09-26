import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

const DIRECT_UPLOAD_URL = "/rails/active_storage/direct_uploads"
const CONCURRENCY = 3
const MAX_FILES = 500
const IGNORED_NAMES = [".DS_Store", "Thumbs.db", "desktop.ini"]

// Subida de carpetas completas (estilo Google Drive).
// - Botón "Subir carpeta" abre un <input webkitdirectory>.
// - Arrastrar carpetas/archivos sobre la sección también sube.
// Cada archivo se sube vía Direct Upload y al final se envía la estructura
// (path relativo + signed_id) al servidor, que crea carpetas y documentos.
// Connects to data-controller="folder-upload"
export default class extends Controller {
  static targets = ["input", "overlay"]
  static values = { url: String, parentFolderId: String }

  connect() {
    this.dragDepth = 0
    this.uploading = false
  }

  open() {
    if (this.uploading) return
    this.inputTarget.click()
  }

  selected(event) {
    const files = Array.from(event.target.files).map((file) => ({
      file,
      path: file.webkitRelativePath || file.name
    }))
    event.target.value = ""
    this.start(files)
  }

  // --- Drag & drop ---------------------------------------------------------

  dragenter(event) {
    if (!this.hasFiles(event)) return
    event.preventDefault()
    this.dragDepth++
    this.toggleOverlay(true)
  }

  dragover(event) {
    if (!this.hasFiles(event)) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  dragleave(event) {
    if (!this.hasFiles(event)) return
    this.dragDepth = Math.max(0, this.dragDepth - 1)
    if (this.dragDepth === 0) this.toggleOverlay(false)
  }

  async drop(event) {
    if (!this.hasFiles(event)) return
    event.preventDefault()
    this.dragDepth = 0
    this.toggleOverlay(false)
    if (this.uploading) return

    const entries = Array.from(event.dataTransfer.items || [])
      .map((item) => item.webkitGetAsEntry && item.webkitGetAsEntry())
      .filter(Boolean)

    let files
    if (entries.length > 0) {
      files = (await Promise.all(entries.map((entry) => this.readEntry(entry, "")))).flat()
    } else {
      files = Array.from(event.dataTransfer.files).map((file) => ({ file, path: file.name }))
    }
    this.start(files)
  }

  hasFiles(event) {
    return Array.from(event.dataTransfer?.types || []).includes("Files")
  }

  toggleOverlay(show) {
    if (this.hasOverlayTarget) this.overlayTarget.classList.toggle("hidden", !show)
  }

  async readEntry(entry, prefix) {
    const path = prefix ? `${prefix}/${entry.name}` : entry.name
    if (entry.isFile) {
      if (IGNORED_NAMES.includes(entry.name)) return []
      const file = await new Promise((resolve, reject) => entry.file(resolve, reject))
      return [{ file, path }]
    }
    if (entry.isDirectory) {
      const children = await this.readAllDirectoryEntries(entry.createReader())
      const nested = (await Promise.all(children.map((child) => this.readEntry(child, path)))).flat()
      // Carpeta vacía: se envía igual para que se cree (como en Drive).
      return nested.length > 0 ? nested : [{ path, directory: true }]
    }
    return []
  }

  // readEntries devuelve resultados por lotes: hay que llamarlo hasta que venga vacío.
  async readAllDirectoryEntries(reader) {
    const all = []
    while (true) {
      const batch = await new Promise((resolve, reject) => reader.readEntries(resolve, reject))
      if (batch.length === 0) break
      all.push(...batch)
    }
    return all
  }

  // --- Upload ------------------------------------------------------------------

  async start(items) {
    const directories = items.filter((item) => item.directory).map(({ path }) => ({ path, directory: true }))
    const files = items.filter(({ file }) => file && !IGNORED_NAMES.includes(file.name))
    if (files.length === 0 && directories.length === 0) return
    if (files.length > MAX_FILES) {
      alert(`Máximo ${MAX_FILES} archivos por subida (seleccionaste ${files.length}).`)
      return
    }

    this.uploading = true
    this.buildPanel(files.length)

    const totalBytes = files.reduce((sum, { file }) => sum + file.size, 0) || 1
    const loaded = new Array(files.length).fill(0)
    const results = new Array(files.length)
    let done = 0
    let failed = 0
    let next = 0

    const worker = async () => {
      while (next < files.length) {
        const index = next++
        const { file, path } = files[index]
        try {
          const blob = await this.directUpload(file, (bytes) => {
            loaded[index] = bytes
            this.updatePanel(loaded.reduce((a, b) => a + b, 0) / totalBytes, done, failed, files.length)
          })
          results[index] = { path, signed_id: blob.signed_id }
        } catch (error) {
          failed++
          console.error(`Error subiendo ${path}`, error)
        }
        loaded[index] = file.size
        done++
        this.updatePanel(loaded.reduce((a, b) => a + b, 0) / totalBytes, done, failed, files.length)
      }
    }

    await Promise.all(Array.from({ length: Math.min(CONCURRENCY, files.length) }, worker))

    const uploaded = results.filter(Boolean)
    if (files.length > 0 && uploaded.length === 0) {
      this.finishPanel("No se pudo subir ningún archivo.", true)
      this.uploading = false
      return
    }

    const entries = [...uploaded, ...directories]
    this.setPanelStatus("Organizando carpetas…")

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify({ parent_folder_id: this.parentFolderIdValue || null, entries })
      })
      const data = await response.json().catch(() => ({}))
      if (!response.ok) throw new Error(data.error || "Error al guardar la carpeta.")

      if (failed > 0) alert(`${failed} archivo(s) no se pudieron subir.`)
      window.Turbo.visit(data.redirect_url)
    } catch (error) {
      this.finishPanel(error.message, true)
    } finally {
      this.uploading = false
    }
  }

  directUpload(file, onProgress) {
    return new Promise((resolve, reject) => {
      const upload = new DirectUpload(file, DIRECT_UPLOAD_URL, {
        directUploadWillStoreFileWithXHR: (xhr) => {
          xhr.upload.addEventListener("progress", (e) => onProgress(e.loaded))
        }
      })
      upload.create((error, blob) => (error ? reject(error) : resolve(blob)))
    })
  }

  // --- Panel de progreso ---------------------------------------------------

  buildPanel(total) {
    this.panel?.remove()
    this.panel = document.createElement("div")
    this.panel.className = "fixed bottom-4 right-4 z-50 w-80 max-w-[calc(100vw-2rem)] bg-surface border-2 border-ink rounded-xl p-4 shadow-lg"
    this.panel.innerHTML = `
      <div class="flex items-center justify-between gap-2 mb-2">
        <p class="text-sm font-semibold text-ink" data-role="status">Subiendo ${total} archivo${total === 1 ? "" : "s"}…</p>
        <button type="button" data-role="close" class="hidden text-ink/50 hover:text-ink" aria-label="Cerrar">✕</button>
      </div>
      <div class="h-2 w-full bg-ink/10 rounded-full overflow-hidden">
        <div data-role="bar" class="h-full bg-brand transition-all" style="width: 0%"></div>
      </div>
      <p class="text-xs text-ink/60 mt-2" data-role="detail">0 de ${total}</p>
    `
    this.panel.querySelector("[data-role=close]").addEventListener("click", () => this.panel.remove())
    document.body.appendChild(this.panel)
  }

  updatePanel(fraction, done, failed, total) {
    if (!this.panel) return
    this.panel.querySelector("[data-role=bar]").style.width = `${Math.min(100, Math.round(fraction * 100))}%`
    const errors = failed > 0 ? ` · ${failed} con error` : ""
    this.panel.querySelector("[data-role=detail]").textContent = `${done} de ${total}${errors}`
  }

  setPanelStatus(text) {
    if (this.panel) this.panel.querySelector("[data-role=status]").textContent = text
  }

  finishPanel(text, isError) {
    if (!this.panel) return
    this.setPanelStatus(text)
    if (isError) this.panel.querySelector("[data-role=status]").classList.add("text-danger")
    this.panel.querySelector("[data-role=close]").classList.remove("hidden")
  }
}
