import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "modal", "taskTitle", "todoSelect", "taskNotes", "notesField", "notesToggleIcon", "templatePicker", "templateList", "templateId"]
  static values = {
    projectId: String,
    todos: Array,
    templates: { type: Array, default: [] },
    columnId: { type: String, default: "" },
    enableSelection: { type: Boolean, default: false }
  }

  connect() {
    this.selectedText = ""
    this.columnListElement = null

    if (this.enableSelectionValue) {
      this._handleMouseup = this.handleMouseup.bind(this)
      document.addEventListener("mouseup", this._handleMouseup)
    }
  }

  disconnect() {
    if (this._handleMouseup) {
      document.removeEventListener("mouseup", this._handleMouseup)
    }
  }

  handleMouseup(event) {
    if (this.hasMenuTarget && this.menuTarget.contains(event.target)) return
    if (this.modalTarget.contains(event.target)) return

    setTimeout(() => {
      const selection = window.getSelection()
      const text = selection.toString().trim()

      if (text.length > 0 && this.selectionInComments(selection)) {
        this.selectedText = text
        this.showMenu(selection)
      } else {
        this.hideMenu()
      }
    }, 10)
  }

  selectionInComments(selection) {
    try {
      return this.element.contains(selection.anchorNode) || this.element.contains(selection.focusNode)
    } catch {
      return false
    }
  }

  showMenu(selection) {
    if (!this.hasMenuTarget) return

    const range = selection.getRangeAt(0)
    const rect = range.getBoundingClientRect()
    const menu = this.menuTarget

    menu.classList.remove("hidden")

    requestAnimationFrame(() => {
      const menuHeight = menu.offsetHeight
      const menuWidth = menu.offsetWidth

      let top = rect.top - menuHeight - 8
      if (top < 8) top = rect.bottom + 8

      let left = rect.left + (rect.width / 2) - (menuWidth / 2)
      left = Math.max(8, Math.min(left, window.innerWidth - menuWidth - 8))

      menu.style.top = `${top}px`
      menu.style.left = `${left}px`
    })
  }

  hideMenu() {
    if (this.hasMenuTarget) this.menuTarget.classList.add("hidden")
  }

  openFromSelection() {
    this.openModal({ prefillTitle: this.selectedText })
  }

  openFromColumn(event) {
    const columnWrapper = event.currentTarget.closest("[data-column-id]")
    this.columnListElement = columnWrapper?.querySelector('[data-kanban-target="column"]') || null
    this.columnCountElement = columnWrapper?.querySelector("[data-column-task-count]") || null

    this.openModal({
      columnId: event.params.columnId,
      prefillTitle: ""
    })
  }

  openModal({ columnId = "", prefillTitle = "" } = {}) {
    this.hideMenu()
    this.columnIdValue = columnId

    const select = this.todoSelectTarget
    select.innerHTML = '<option value="">— Selecciona una lista —</option>'
    this.todosValue.forEach(todo => {
      const option = document.createElement("option")
      option.value = todo.id
      option.textContent = todo.name
      select.appendChild(option)
    })

    this.taskTitleTarget.value = prefillTitle
    this.clearTemplate()
    this.renderTemplatePicker()

    this.modalTarget.classList.remove("hidden")
    this.taskTitleTarget.focus()
    if (prefillTitle) this.taskTitleTarget.select()
  }

  renderTemplatePicker() {
    if (!this.hasTemplatePickerTarget || this.templatesValue.length === 0) return

    const list = this.templateListTarget
    list.innerHTML = ""

    const blankBtn = this.buildTemplateButton("Tarea en blanco", null, true)
    list.appendChild(blankBtn)

    this.templatesValue.forEach(template => {
      list.appendChild(this.buildTemplateButton(template.name, template))
    })

    this.templatePickerTarget.classList.remove("hidden")
  }

  buildTemplateButton(label, template, isBlank = false) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.dataset.action = "click->create-task-modal#selectTemplate"
    btn.dataset.templateData = template ? JSON.stringify(template) : ""
    btn.className = isBlank
      ? "inline-flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border border-gray-200 text-gray-600 hover:border-purple-300 hover:bg-purple-50 hover:text-purple-700 transition-colors"
      : "inline-flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border border-gray-200 text-gray-600 hover:border-purple-300 hover:bg-purple-50 hover:text-purple-700 transition-colors"

    if (!isBlank) {
      btn.innerHTML = `<svg class="w-3 h-3 text-purple-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>${label}`
    } else {
      btn.textContent = label
    }

    return btn
  }

  selectTemplate(event) {
    const raw = event.currentTarget.dataset.templateData
    const template = raw ? JSON.parse(raw) : null

    // Highlight selected button
    this.templateListTarget.querySelectorAll("button").forEach(btn => {
      btn.classList.remove("border-purple-400", "bg-purple-50", "text-purple-700")
    })
    event.currentTarget.classList.add("border-purple-400", "bg-purple-50", "text-purple-700")

    if (template) {
      if (template.title) this.taskTitleTarget.value = template.title
      this.templateIdTarget.value = template.id
    } else {
      this.taskTitleTarget.value = ""
      this.templateIdTarget.value = ""
    }
    this.taskTitleTarget.focus()
  }

  clearTemplate() {
    if (this.hasTemplateIdTarget) this.templateIdTarget.value = ""
    if (this.hasTemplatePickerTarget) this.templatePickerTarget.classList.add("hidden")
  }

  toggleNotes() {
    const field = this.notesFieldTarget
    const icon = this.notesToggleIconTarget
    const hidden = field.classList.toggle("hidden")
    icon.innerHTML = hidden
      ? '<path d="M12 5v14M5 12h14"/>'
      : '<path d="M5 12h14"/>'
    if (hidden) this.taskNotesTarget.value = ""
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.notesFieldTarget.classList.add("hidden")
    this.notesToggleIconTarget.innerHTML = '<path d="M12 5v14M5 12h14"/>'
    this.taskNotesTarget.value = ""
    this.selectedText = ""
    this.columnIdValue = ""
    this.columnListElement = null
    this.columnCountElement = null
    this.clearTemplate()
  }

  backdropClick(event) {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  async createTask(event) {
    event.preventDefault()

    const todoId = this.todoSelectTarget.value
    const title = this.taskTitleTarget.value.trim()

    if (!todoId) {
      this.todoSelectTarget.focus()
      return
    }
    if (!title) {
      this.taskTitleTarget.focus()
      return
    }

    const url = `/projects/${this.projectIdValue}/todos/${todoId}/tasks`
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const fromBoard = this.columnIdValue !== ""

    const formData = new FormData()
    formData.append("task[title]", title)
    const notes = this.taskNotesTarget.value.trim()
    if (notes) formData.append("task[notes]", notes)
    if (fromBoard) {
      formData.append("column_id", this.columnIdValue)
      formData.append("from", "board")
    }
    const templateId = this.hasTemplateIdTarget ? this.templateIdTarget.value : ""
    if (templateId) formData.append("template_id", templateId)

    const submitBtn = event.submitter || event.target.querySelector('[type="submit"]')
    if (submitBtn) submitBtn.disabled = true

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          ...(fromBoard ? { Accept: "application/json" } : {})
        },
        body: formData,
        redirect: fromBoard ? "manual" : "follow"
      })

      if (fromBoard) {
        if (response.ok) {
          const data = await response.json()
          if (data.task_html && this.columnListElement) {
            this.columnListElement.insertAdjacentHTML("beforeend", data.task_html)
          }
          if (this.columnCountElement && data.task_count != null) {
            this.columnCountElement.textContent = data.task_count
          }
          this.closeModal()
          this.showToast(`Tarea creada en "${data.todo_name}"`)
        } else {
          this.showToast("Error al crear la tarea", "error")
        }
      } else if (response.ok || response.type === "opaqueredirect") {
        const todoName = this.todoSelectTarget.options[this.todoSelectTarget.selectedIndex].text
        this.closeModal()
        this.showToast(`Tarea creada en "${todoName}"`)
      } else {
        this.showToast("Error al crear la tarea", "error")
      }
    } catch {
      this.showToast("Error al crear la tarea", "error")
    } finally {
      if (submitBtn) submitBtn.disabled = false
    }
  }

  showToast(message, type = "success") {
    const container = document.getElementById("toasts")
    if (!container) return

    const color = type === "success"
      ? "bg-green-100 text-green-800 border-green-200"
      : "bg-red-100 text-red-800 border-red-200"

    const toast = document.createElement("div")
    toast.className = `border ${color} px-4 py-2 rounded-lg text-sm shadow-sm pointer-events-auto`
    toast.textContent = message
    container.appendChild(toast)
    setTimeout(() => toast.remove(), 4000)
  }
}
