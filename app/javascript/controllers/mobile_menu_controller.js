import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "iconOpen", "iconClosed"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    this.iconOpenTargets.forEach((icon) => icon.classList.toggle("hidden"))
    this.iconClosedTargets.forEach((icon) => icon.classList.toggle("hidden"))
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.iconOpenTargets.forEach((icon) => icon.classList.remove("hidden"))
    this.iconClosedTargets.forEach((icon) => icon.classList.add("hidden"))
  }
}
