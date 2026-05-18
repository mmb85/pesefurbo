// ==============================================================================
// app/javascript/controllers/squad_panel_controller.js
//
// Handles player selection in the squad panel and updates the stats card
// ==============================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["playerRow", "statsCard", "playerName", "playerMeta", "playerOvr", "statBars"]

  selectPlayer(event) {
    const row = event.currentTarget
    const playerData = JSON.parse(row.dataset.player)

    this.playerRowTargets.forEach(r => r.classList.remove("selected"))
    row.classList.add("selected")

    this.updateStatsCard(playerData)
  }

  updateStatsCard(player) {
    if (this.hasPlayerNameTarget) this.playerNameTarget.textContent = player.known_as
    if (this.hasPlayerMetaTarget) this.playerMetaTarget.textContent =
      `${player.position} · ${player.nationality} · ${player.age} años`
    if (this.hasPlayerOvrTarget) this.playerOvrTarget.textContent = player.overall_rating

    if (this.hasStatBarsTarget) {
      this.statBarsTarget.innerHTML = this.renderStatBars(player)
    }
  }

  renderStatBars(player) {
    const attrs = [
      ["Velocidad",   player.attr_speed],
      ["Disparo",     player.attr_shooting],
      ["Largo",       player.attr_long_shot],
      ["Regate",      player.attr_dribbling],
      ["Pase",        player.attr_passing],
      ["Físico",      player.attr_strength],
      ["Entrada",     player.attr_tackling],
    ]
    return attrs.map(([label, val]) => `
      <div class="stat-row">
        <span class="stat-lbl">${label}</span>
        <div class="stat-bar"><div class="stat-fill" style="width:${val}%"></div></div>
        <span class="stat-val">${val}</span>
      </div>
    `).join("")
  }
}
