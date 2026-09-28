import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Permite reordenar los elementos arrastrando y guarda el nuevo orden
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      animation: 150,
      onEnd: () => this.save()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  save() {
    const ids = [...this.element.querySelectorAll(":scope > [data-field-id]")].map((el) => el.dataset.fieldId)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify({ ids })
    }).then((response) => {
      if (!response.ok) window.location.reload()
    })
  }
}