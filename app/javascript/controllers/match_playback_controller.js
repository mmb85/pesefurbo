// ==============================================================================
// app/javascript/controllers/match_playback_controller.js
//
// Reads the events JSON array already stored in the DB and reveals them
// one by one in the DOM at a fixed interval, simulating a live broadcast.
//
// Usage in HTML:
//   data-controller="match-playback"
//   data-match-playback-events-value="<%= @events_json %>"
//   data-match-playback-interval-value="2000"
//   data-match-playback-autoplay-value="true"
// ==============================================================================
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "feed",
    "homeScore",
    "awayScore",
    "minute",
    "homePossBar",
    "awayPossBar",
    "homeShots",
    "awayShots",
    "homeCorners",
    "awayCorners",
    "homeYellows",
    "awayYellows",
    "zoneIndicator",
    "statusBadge"
  ]

  static values = {
    events:   { type: Array,   default: [] },
    interval: { type: Number,  default: 1200 },
    autoplay: { type: Boolean, default: true }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  connect() {
    console.log("[MatchPlayback] connect()", this.element)
    console.log("[MatchPlayback] eventsValue length:", this.eventsValue.length)
    console.log("[MatchPlayback] autoplayValue:", this.autoplayValue)
    console.log("[MatchPlayback] intervalValue:", this.intervalValue)

    this.currentIndex = 0
    this.homeGoals    = 0
    this.awayGoals    = 0
    this.timer        = null

    if (!this.hasEventsValue) {
      console.warn("[MatchPlayback] No events data attribute present.")
      return
    }

    if (this.eventsValue.length === 0) {
      console.log("[MatchPlayback] No events to play for this match.")
      return
    }

    if (this.autoplayValue) {
      this.startPlayback()
    }
  }

  disconnect() {
    this.stopPlayback()
  }

  // ── Playback control ──────────────────────────────────────────────────────

  startPlayback() {
    if (this.timer) return // already running
    console.log("[MatchPlayback] startPlayback()", this.eventsValue.length, "events at", this.intervalValue, "ms")

    this.timer = setInterval(() => {
      if (this.currentIndex >= this.eventsValue.length) {
        this.stopPlayback()
        return
      }
      this.processEvent(this.eventsValue[this.currentIndex])
      this.currentIndex++
    }, this.intervalValue)
  }

  stopPlayback() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  togglePause() {
    if (this.timer) {
      this.stopPlayback()
    } else {
      this.startPlayback()
    }
    const btn = this.element.querySelector('[data-action*="togglePause"]')
    if (btn) btn.textContent = this.timer ? "⏸ PAUSA" : "▶ REANUDAR"
  }

  skipToEnd() {
    this.stopPlayback()
    while (this.currentIndex < this.eventsValue.length) {
      this.processEvent(this.eventsValue[this.currentIndex])
      this.currentIndex++
    }
  }

  // ── Event processing ──────────────────────────────────────────────────────

  processEvent(event) {
    if (!event) return
    console.log("[MatchPlayback] processEvent", event.event_type, event.minute)

    this.updateMinute(event.minute)
    this.updateZoneIndicator(event.payload?.zone, event.team)
    this.renderEventToFeed(event)
    this.updateStats(event)

    if (["goal", "penalty_goal", "own_goal", "long_shot_goal"].includes(event.event_type)) {
      this.updateScore(event)
    }

    if (event.event_type === "halftime") {
      this.showHalfTimeBanner()
    }

    if (event.event_type === "fulltime") {
      this.showFullTimeBanner()
    }
  }

  // ── DOM updates ───────────────────────────────────────────────────────────

  updateMinute(minute) {
    if (!this.hasMinuteTarget) return
    this.minuteTarget.textContent = `${minute}'`
    this.minuteTarget.classList.add("live")
  }

  updateScore(event) {
    if (event.team === "home") {
      this.homeGoals++
      if (this.hasHomeScoreTarget) {
        this.homeScoreTarget.textContent = this.homeGoals
        this.animateElement(this.homeScoreTarget)
      }
    } else {
      this.awayGoals++
      if (this.hasAwayScoreTarget) {
        this.awayScoreTarget.textContent = this.awayGoals
        this.animateElement(this.awayScoreTarget)
      }
    }
  }

  updateStats(event) {
    if (event.event_type !== "fulltime") return
    const p = event.payload || {}
    if (this.hasHomePossBarTarget && p.home_possession !== undefined) {
      this.homePossBarTarget.style.width = `${p.home_possession}%`
    }
    if (this.hasAwayPossBarTarget && p.away_possession !== undefined) {
      this.awayPossBarTarget.style.width = `${p.away_possession}%`
    }
  }

  updateZoneIndicator(zone, team) {
    if (!this.hasZoneIndicatorTarget || !zone) return
    this.zoneIndicatorTarget.querySelectorAll("[data-zone]").forEach(seg => {
      seg.classList.remove("active-home", "active-away")
      if (seg.dataset.zone === zone) {
        seg.classList.add(team === "home" ? "active-home" : "active-away")
      }
    })
  }

  renderEventToFeed(event) {
    if (!this.hasFeedTarget || !event.description) return

    const div = document.createElement("div")
    div.className = `nar-event ${this.eventClass(event.event_type)}`
    div.innerHTML = `
      <span class="nar-min">${event.minute}'</span>
      <span class="nar-text"></span>
    `
    this.feedTarget.prepend(div)
    this.typewriterEffect(div.querySelector(".nar-text"), event.description)
    this.feedTarget.scrollTop = 0
  }

  typewriterEffect(el, fullText) {
    if (!el) return
    el.textContent = ""
    let i = 0
    const iv = setInterval(() => {
      el.textContent += fullText[i] || ""
      i++
      if (i >= fullText.length) clearInterval(iv)
    }, 12)
  }

  showHalfTimeBanner() {
    const banner = document.getElementById("ht-banner")
    if (banner) {
      banner.classList.remove("hidden")
      setTimeout(() => banner.classList.add("hidden"), 5000)
    }
  }

  showFullTimeBanner() {
    const banner = document.getElementById("final-banner")
    if (banner) banner.classList.remove("hidden")
    const scoreEl = banner?.querySelector("[data-final-score]")
    if (scoreEl) scoreEl.textContent = `${this.homeGoals} – ${this.awayGoals}`
    if (this.hasMinuteTarget) {
      this.minuteTarget.textContent = "FIN"
      this.minuteTarget.classList.remove("live")
    }
  }

  animateElement(el) {
    el.classList.add("score-bump")
    setTimeout(() => el.classList.remove("score-bump"), 600)
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  eventClass(type) {
    const map = {
      goal:            "ev-goal",
      own_goal:        "ev-goal",
      penalty_goal:    "ev-goal",
      long_shot_goal:  "ev-goal",
      yellow_card:     "ev-card",
      red_card:        "ev-card",
      yellow_red:      "ev-card",
      substitution:    "ev-sub",
      injury:          "ev-injury",
      long_shot_miss:  "ev-longshot",
      long_shot_save:  "ev-longshot",
      long_shot_post:  "ev-longshot",
      halftime:        "ev-system",
      fulltime:        "ev-system",
      transition:      "ev-transition",
    }
    return map[type] || "ev-normal"
  }
}
