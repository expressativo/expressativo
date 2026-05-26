import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "submit", "emojiPicker", "fileInput", "attachments"]
  static values = { membersUrl: String }

  connect() {
    this.setupTribute()
    this.boundKeydown = this.handleKeydown.bind(this)
    this.inputTarget.addEventListener("keydown", this.boundKeydown)
    this.autoGrow()
    this.boundInput = this.autoGrow.bind(this)
    this.inputTarget.addEventListener("input", this.boundInput)
    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
  }

  disconnect() {
    if (this.tribute) this.tribute.detach(this.inputTarget)
    this.inputTarget.removeEventListener("keydown", this.boundKeydown)
    this.inputTarget.removeEventListener("input", this.boundInput)
    document.removeEventListener("click", this.boundOutsideClick)
  }

  reset() {
    this.inputTarget.value = ""
    this.autoGrow()
    this.closeEmojiPicker()
    if (this.hasAttachmentsTarget) this.attachmentsTarget.innerHTML = ""
    const input = this.inputTarget
    input.focus()
    requestAnimationFrame(() => input.focus())
    setTimeout(() => input.focus(), 0)
    setTimeout(() => input.focus(), 50)
  }

  handleKeydown(event) {
    if (event.key !== "Enter") return
    if (event.shiftKey) return
    if (this.tribute && this.tribute.isActive) return

    event.preventDefault()
    if (!this.canSubmit()) return
    this.element.requestSubmit()
  }

  canSubmit() {
    if (this.inputTarget.value.trim().length > 0) return true
    if (this.hasAttachmentsTarget && this.attachmentsTarget.querySelector("input[type='hidden']")) return true
    return false
  }

  autoGrow() {
    const el = this.inputTarget
    el.style.height = "auto"
    const max = 200
    el.style.height = Math.min(el.scrollHeight, max) + "px"
  }

  applyMarkdown(event) {
    event.preventDefault()
    const { prefix = "", suffix = "", placeholder = "" } = event.params
    const ta = this.inputTarget
    const start = ta.selectionStart
    const end = ta.selectionEnd
    const had = end > start
    const selected = had ? ta.value.slice(start, end) : placeholder
    const before = ta.value.slice(0, start)
    const after = ta.value.slice(end)
    ta.value = before + prefix + selected + suffix + after
    const cursorStart = before.length + prefix.length
    ta.focus()
    ta.setSelectionRange(cursorStart, cursorStart + selected.length)
    this.autoGrow()
  }

  applyLinePrefix(event) {
    event.preventDefault()
    const { prefix = "", numbered = false } = event.params
    const ta = this.inputTarget
    const start = ta.selectionStart
    const end = ta.selectionEnd
    const lineStart = ta.value.lastIndexOf("\n", start - 1) + 1
    const lineEndIdx = ta.value.indexOf("\n", end)
    const actualEnd = lineEndIdx === -1 ? ta.value.length : lineEndIdx
    const before = ta.value.slice(0, lineStart)
    const block = ta.value.slice(lineStart, actualEnd)
    const after = ta.value.slice(actualEnd)
    const lines = block.length === 0 ? [""] : block.split("\n")
    const transformed = lines.map((line, i) => {
      const p = numbered ? `${i + 1}. ` : prefix
      return p + line
    }).join("\n")
    ta.value = before + transformed + after
    ta.focus()
    ta.setSelectionRange(before.length + transformed.length, before.length + transformed.length)
    this.autoGrow()
  }

  applyCodeBlock(event) {
    event.preventDefault()
    const ta = this.inputTarget
    const start = ta.selectionStart
    const end = ta.selectionEnd
    const selected = end > start ? ta.value.slice(start, end) : "código"
    const before = ta.value.slice(0, start)
    const after = ta.value.slice(end)
    const lead = before.length === 0 || before.endsWith("\n") ? "" : "\n"
    const tail = after.length === 0 || after.startsWith("\n") ? "" : "\n"
    const block = `${lead}\`\`\`\n${selected}\n\`\`\`${tail}`
    ta.value = before + block + after
    const cursorStart = before.length + lead.length + 4
    ta.focus()
    ta.setSelectionRange(cursorStart, cursorStart + selected.length)
    this.autoGrow()
  }

  async toggleEmojiPicker(event) {
    event.preventDefault()
    event.stopPropagation()
    if (!this.hasEmojiPickerTarget) return
    const wrapper = this.emojiPickerTarget
    if (wrapper.hidden) {
      await this.ensureEmojiPicker()
      if (!wrapper.querySelector("emoji-picker")) {
        const picker = document.createElement("emoji-picker")
        picker.classList.add("light")
        picker.addEventListener("emoji-click", e => {
          this.insertEmoji(e.detail.unicode)
          this.closeEmojiPicker()
        })
        wrapper.appendChild(picker)
      }
      wrapper.hidden = false
    } else {
      this.closeEmojiPicker()
    }
  }

  closeEmojiPicker() {
    if (this.hasEmojiPickerTarget) this.emojiPickerTarget.hidden = true
  }

  handleOutsideClick(event) {
    if (!this.hasEmojiPickerTarget || this.emojiPickerTarget.hidden) return
    if (this.element.contains(event.target)) return
    this.closeEmojiPicker()
  }

  async ensureEmojiPicker() {
    if (window.customElements.get("emoji-picker")) return
    await import("emoji-picker-element")
  }

  insertEmoji(unicode) {
    const ta = this.inputTarget
    const start = ta.selectionStart
    const end = ta.selectionEnd
    const before = ta.value.slice(0, start)
    const after = ta.value.slice(end)
    ta.value = before + unicode + after
    const pos = start + unicode.length
    ta.focus()
    ta.setSelectionRange(pos, pos)
    this.autoGrow()
  }

  openFileDialog(event) {
    event.preventDefault()
    if (this.hasFileInputTarget) this.fileInputTarget.click()
  }

  onFilesSelected(event) {
    const files = Array.from(event.target.files || [])
    files.forEach(file => this.uploadFile(file))
    event.target.value = ""
  }

  uploadFile(file) {
    if (!this.hasAttachmentsTarget) return
    const maxBytes = 25 * 1024 * 1024
    if (file.size > maxBytes) {
      this.showAttachmentError(file, "Supera 25 MB")
      return
    }

    const id = `up-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
    const chip = this.buildChip(id, file)
    this.attachmentsTarget.appendChild(chip)

    const upload = new DirectUpload(file, "/rails/active_storage/direct_uploads", {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener("progress", (e) => this.updateProgress(chip, e))
      }
    })

    upload.create((error, blob) => {
      if (chip.dataset.cancelled === "true") return
      if (error) {
        this.markChipError(chip, "Error")
        return
      }
      const hidden = document.createElement("input")
      hidden.type = "hidden"
      hidden.name = "message[files][]"
      hidden.value = blob.signed_id
      chip.appendChild(hidden)
      this.markChipReady(chip)
    })
  }

  buildChip(id, file) {
    const wrap = document.createElement("div")
    wrap.dataset.chip = "true"
    wrap.dataset.uploadId = id
    wrap.className = "relative inline-flex items-center gap-2 pl-2 pr-7 py-1 bg-gray-100 border border-gray-200 rounded-md text-xs text-gray-700 max-w-[14rem] overflow-hidden"

    const isImage = file.type.startsWith("image/")
    if (isImage) {
      const img = document.createElement("img")
      img.src = URL.createObjectURL(file)
      img.className = "w-6 h-6 rounded object-cover flex-shrink-0"
      img.onload = () => URL.revokeObjectURL(img.src)
      wrap.appendChild(img)
    } else {
      const icon = document.createElement("span")
      icon.className = "w-6 h-6 rounded bg-white border border-gray-200 flex items-center justify-center flex-shrink-0"
      icon.innerHTML = '<svg class="w-3.5 h-3.5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>'
      wrap.appendChild(icon)
    }

    const name = document.createElement("span")
    name.className = "truncate"
    name.title = file.name
    name.textContent = file.name
    wrap.appendChild(name)

    const progressWrap = document.createElement("div")
    progressWrap.dataset.progressWrap = "true"
    progressWrap.className = "absolute left-0 right-0 bottom-0 h-0.5 bg-gray-200"
    const bar = document.createElement("div")
    bar.dataset.progress = "true"
    bar.className = "h-full bg-indigo-500 transition-[width]"
    bar.style.width = "0%"
    progressWrap.appendChild(bar)
    wrap.appendChild(progressWrap)

    const remove = document.createElement("button")
    remove.type = "button"
    remove.title = "Quitar"
    remove.dataset.action = "click->chat-form#removeAttachment"
    remove.className = "absolute right-1 top-1/2 -translate-y-1/2 w-5 h-5 rounded-full bg-white border border-gray-200 text-gray-500 hover:text-red-600 hover:border-red-300 inline-flex items-center justify-center"
    remove.innerHTML = '<svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>'
    wrap.appendChild(remove)

    return wrap
  }

  updateProgress(chip, event) {
    const bar = chip.querySelector("[data-progress]")
    if (!bar || !event.lengthComputable) return
    const pct = (event.loaded / event.total) * 100
    bar.style.width = `${pct}%`
  }

  markChipReady(chip) {
    const wrap = chip.querySelector("[data-progress-wrap]")
    if (wrap) wrap.remove()
  }

  markChipError(chip, label) {
    chip.classList.remove("bg-gray-100", "border-gray-200")
    chip.classList.add("bg-red-50", "border-red-200")
    const wrap = chip.querySelector("[data-progress-wrap]")
    if (wrap) wrap.remove()
    const tag = document.createElement("span")
    tag.className = "ml-1 text-[10px] text-red-600 font-medium"
    tag.textContent = label
    chip.appendChild(tag)
  }

  showAttachmentError(file, label) {
    if (!this.hasAttachmentsTarget) return
    const chip = this.buildChip(`err-${Date.now()}`, file)
    this.attachmentsTarget.appendChild(chip)
    this.markChipError(chip, label)
  }

  removeAttachment(event) {
    event.preventDefault()
    const chip = event.currentTarget.closest("[data-chip]")
    if (!chip) return
    chip.dataset.cancelled = "true"
    chip.remove()
  }

  setupTribute() {
    if (!this.membersUrlValue) return

    this.tribute = new Tribute({
      trigger: "@",
      values: (text, cb) => this.fetchMembers(text, cb),
      lookup: "label",
      fillAttr: "handle",
      selectTemplate: item => `@${item.original.handle}`,
      menuItemTemplate: item => `<span class="font-semibold">${item.original.label}</span> <span class="text-gray-500 text-xs">@${item.original.handle}</span>`,
      menuContainer: document.body,
      noMatchTemplate: () => `<span class="text-xs text-gray-500 p-2 block">Sin coincidencias</span>`
    })
    this.tribute.attach(this.inputTarget)
  }

  async fetchMembers(query, callback) {
    try {
      const url = `${this.membersUrlValue}?q=${encodeURIComponent(query || "")}`
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return callback([])
      const data = await response.json()
      callback(data)
    } catch (e) {
      callback([])
    }
  }
}
