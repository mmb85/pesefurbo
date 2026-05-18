// app/javascript/controllers/index.js
// Registers all Stimulus controllers in this directory with the application.

import { application } from "controllers/application"

import MatchPlaybackController from "controllers/match_playback_controller"
application.register("match-playback", MatchPlaybackController)

import NavigationController from "controllers/navigation_controller"
application.register("navigation", NavigationController)

import SquadPanelController from "controllers/squad_panel_controller"
application.register("squad-panel", SquadPanelController)
