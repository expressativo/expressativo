import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectedCount", "actionButtons"]

  connect() {
    this.updateUI()
  }

  toggleTask() {
    this.updateUI()
  }

  toggleAll(event) {
    const checked = event.target.checked

    // Find all checkboxes in the same todo group
    const todoGroup = event.target.closest('[data-todo-group]')
    if (todoGroup) {
      const checkboxes = todoGroup.querySelectorAll('[data-bulk-task-selector-target="checkbox"]')
      checkboxes.forEach(checkbox => {
        checkbox.checked = checked
      })
    }

    this.updateUI()
  }

  updateUI() {
    const selectedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = selectedCount
    }

    if (this.hasActionButtonsTarget) {
      if (selectedCount > 0) {
        this.actionButtonsTarget.classList.remove('hidden')
      } else {
        this.actionButtonsTarget.classList.add('hidden')
      }
    }
  }

  attachToColumn(event) {
    event.preventDefault()
    const columnId = event.target.dataset.columnId
    const selectedTaskIds = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    if (selectedTaskIds.length === 0) {
      return
    }

    // Create a form and submit it
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = event.target.dataset.url

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Add column_id
    const columnInput = document.createElement('input')
    columnInput.type = 'hidden'
    columnInput.name = 'column_id'
    columnInput.value = columnId
    form.appendChild(columnInput)

    // Add task_ids
    selectedTaskIds.forEach(taskId => {
      const taskInput = document.createElement('input')
      taskInput.type = 'hidden'
      taskInput.name = 'task_ids[]'
      taskInput.value = taskId
      form.appendChild(taskInput)
    })

    document.body.appendChild(form)
    form.submit()
  }
}
