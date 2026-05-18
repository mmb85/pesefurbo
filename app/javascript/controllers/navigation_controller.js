// ==============================================================================
// app/javascript/controllers/navigation_controller.js
//
// Handles tab switching (Partido / Liga / Táctica) without page reload
// using Turbo Frames — stays in the active tab across Turbo navigations.
// ==============================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { active: { type: String, default: "partido" } }

  connect() {
    this.showTab(this.activeValue)
  }

  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    this.activeValue = tab
    this.showTab(tab)
    // Update URL hash without navigation
    history.replaceState(null, "", `#${tab}`)
  }

  showTab(tabName) {
    this.tabTargets.forEach(t => {
      t.classList.toggle("tab-active", t.dataset.tab === tabName)
    })
    this.panelTargets.forEach(p => {
      p.style.display = p.dataset.panel === tabName ? "block" : "none"
    })
  }
}
