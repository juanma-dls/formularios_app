import { Controller } from "@hotwired/stimulus"

// Numera las páginas del constructor, cuenta sus preguntas y permite contraerlas
export default class extends Controller {
  static targets = ["item", "firstHeader"]

  connect() {
    this.renumber()
  }

  itemTargetConnected() {
    this.scheduleRenumber()
  }

  itemTargetDisconnected() {
    this.scheduleRenumber()
  }

  scheduleRenumber() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => this.renumber())
  }

  renumber() {
    let page = 1
    const counts = { 1: 0 }

    this.itemTargets.forEach((item) => {
      if (item.hasAttribute("data-page-break")) {
        page += 1
        counts[page] = 0
      } else if (item.dataset.kind === "input") {
        counts[page] += 1
      }
      item.dataset.page = page
    })

    this.itemTargets.filter((item) => item.hasAttribute("data-page-break")).forEach((divider) => {
      divider.querySelector("[data-page-number]").textContent = divider.dataset.page
      divider.querySelector("[data-page-count]").textContent = this.countLabel(counts[divider.dataset.page])
    })

    if (this.hasFirstHeaderTarget) {
      this.firstHeaderTarget.hidden = page === 1
      this.firstHeaderTarget.querySelector("[data-page-count]").textContent = this.countLabel(counts[1])
    }
  }

  toggle(event) {
    const header = event.currentTarget.closest("[data-page]")
    const collapsed = header.toggleAttribute("data-collapsed")
    event.currentTarget.setAttribute("aria-expanded", String(!collapsed))

    this.itemTargets.forEach((item) => {
      if (item.dataset.page === header.dataset.page && !item.hasAttribute("data-page-break")) {
        item.hidden = collapsed
      }
    })
  }

  countLabel(count) {
    return count === 1 ? "1 pregunta" : `${count} preguntas`
  }
}