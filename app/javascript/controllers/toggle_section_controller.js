import { Controller } from "@hotwired/stimulus"

// Muestra una sección solo cuando la casilla está marcada
export default class extends Controller {
  static targets = ["checkbox", "section"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.sectionTarget.hidden = !this.checkboxTarget.checked
  }
}