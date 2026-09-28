import { Controller } from "@hotwired/stimulus"

// Muestra una página por vez; todo se envía junto al final
export default class extends Controller {
  static targets = ["page", "nav", "finish", "progress", "current", "bar"]

  connect() {
    this.index = 0
    if (this.pageTargets.length < 2) return

    this.navTargets.forEach((nav) => (nav.hidden = false))
    if (this.hasProgressTarget) this.progressTarget.hidden = false

    // Si el servidor devolvió errores, abrir en la página del primero
    const errorPage = this.pageTargets.findIndex((page) => page.querySelector("[data-has-error]"))
    this.show(errorPage >= 0 ? errorPage : 0, false)
  }

  next() {
    const validation = this.application.getControllerForElementAndIdentifier(this.element, "live-validation")
    if (validation && !validation.validateWithin(this.pageTargets[this.index])) return
    this.show(this.index + 1)
  }

  previous() {
    this.show(this.index - 1)
  }

  // Enter en un campo de una página intermedia avanza en lugar de enviar
  guard(event) {
    if (this.pageTargets.length > 1 && this.index < this.pageTargets.length - 1) {
      event.preventDefault()
      this.next()
    }
  }

  // Si la validación encuentra un error en otra página, se muestra esa página
  reveal(event) {
    const page = this.pageTargets.findIndex((p) => p.contains(event.detail.field))
    if (page >= 0 && page !== this.index) this.show(page, false)
  }

  show(index, scroll = true) {
    this.index = Math.max(0, Math.min(index, this.pageTargets.length - 1))
    this.pageTargets.forEach((page, i) => (page.hidden = i !== this.index))
    this.finishTarget.hidden = this.index !== this.pageTargets.length - 1

    if (this.hasCurrentTarget) this.currentTarget.textContent = this.index + 1
    if (this.hasBarTarget) this.barTarget.style.width = `${((this.index + 1) / this.pageTargets.length) * 100}%`
    if (scroll) this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}