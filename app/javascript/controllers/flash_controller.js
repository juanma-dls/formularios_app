import { Controller } from "@hotwired/stimulus"

// Oculta el aviso después de unos segundos, o al tocar la cruz
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    if (this.delayValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    this.element.classList.add("flash-hiding")
    setTimeout(() => this.element.remove(), 200)
  }
}