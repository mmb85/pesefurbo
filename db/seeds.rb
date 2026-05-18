# ==============================================================================
# db/seeds.rb - PC Fútbol Database Seeds
# Organized by phases: Base Data → League Structure → Players → Contracts → 
# Performance Tracking → Tactics → Matches
# ==============================================================================
puts "🌱 Seeding PC Fútbol database..."

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 1: BASE DATA (Countries, Seasons, Competitions, Stadiums)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n📍 Phase 1: Creating base data..."

# ── Countries ────────────────────────────────────────────────────────────────
spain = Country.find_or_create_by!(code: "ESP") { |c| c.name = "España"; c.flag_emoji = "🇪🇸" }
brazil = Country.find_or_create_by!(code: "BRA") { |c| c.name = "Brasil";  c.flag_emoji = "🇧🇷" }
argentina = Country.find_or_create_by!(code: "ARG") { |c| c.name = "Argentina"; c.flag_emoji = "🇦🇷" }
portugal = Country.find_or_create_by!(code: "PRT") { |c| c.name = "Portugal"; c.flag_emoji = "🇵🇹" }
netherlands = Country.find_or_create_by!(code: "NLD") { |c| c.name = "Holanda"; c.flag_emoji = "🇳🇱" }
puts "✓ #{Country.count} countries created"

# ── Season ───────────────────────────────────────────────────────────────────
season = Season.find_or_create_by!(name: "1996/97") do |s|
  s.year_start = 1996; s.year_end = 1997
  s.starts_on = Date.new(1996, 9, 1); s.ends_on = Date.new(1997, 6, 30)
  s.current = true
end
puts "✓ Season '#{season.name}' created"

# ── Competition ───────────────────────────────────────────────────────────────
liga = Competition.find_or_create_by!(short_name: "Primera") do |c|
  c.name = "Primera División"
  c.competition_type = "league"
  c.tier = 1
  c.country = spain
end
puts "✓ Competition '#{liga.name}' created"

# ── CompetitionSeason ─────────────────────────────────────────────────────────
cs = CompetitionSeason.find_or_create_by!(competition: liga, season: season) do |c|
  c.rounds_total = 38
  c.teams_count = 20
  c.champions_spots = 2
  c.europa_spots = 3
  c.relegation_spots = 3
end
puts "✓ CompetitionSeason created (#{cs.rounds_total} rounds, #{cs.teams_count} teams)"

# ── Stadiums ───────────────────────────────────────────────────────────────────
bernabeu = Stadium.find_or_create_by!(name: "Santiago Bernabéu") do |s|
  s.city = "Madrid"; s.country = spain; s.capacity = 80_000; s.surface = "grass"
end
nou_camp = Stadium.find_or_create_by!(name: "Camp Nou") do |s|
  s.city = "Barcelona"; s.country = spain; s.capacity = 99_786; s.surface = "grass"
end
calderon = Stadium.find_or_create_by!(name: "Vicente Calderón") do |s|
  s.city = "Madrid"; s.country = spain; s.capacity = 54_960; s.surface = "grass"
end
puts "✓ #{Stadium.count} stadiums created"

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 2: CLUBS & LEAGUE STRUCTURE
# ──────────────────────────────────────────────────────────────────────────────
puts "\n🏟️ Phase 2: Setting up clubs and league structure..."

def create_club(attrs)
  Club.find_or_create_by!(abbr: attrs[:abbr]) do |c|
    attrs.each { |k, v| c.send(:"#{k}=", v) }
  end
end

# ── Clubs ────────────────────────────────────────────────────────────────────
real_madrid = create_club(
  name: "Real Madrid CF", short_name: "Real Madrid", abbr: "RMA",
  country: spain, stadium: bernabeu, primary_color: "#ffffff", secondary_color: "#ffd700",
  founded_year: 1902, is_player_club: true
)

barcelona = create_club(
  name: "FC Barcelona", short_name: "Barcelona", abbr: "BAR",
  country: spain, stadium: nou_camp, primary_color: "#a50044", secondary_color: "#004d98",
  founded_year: 1899, is_player_club: false
)

atletico = create_club(
  name: "Club Atlético de Madrid", short_name: "Atlético", abbr: "ATM",
  country: spain, stadium: calderon, primary_color: "#ce3524", secondary_color: "#ffffff",
  founded_year: 1903, is_player_club: false
)
puts "✓ #{Club.count} clubs created"

# ── ClubSeasons ────────────────────────────────────────────────────────────────
club_seasons_map = {}
[real_madrid, barcelona, atletico].each_with_index do |club, idx|
  club_season = ClubSeason.find_or_create_by!(club: club, competition_season: cs) do |s|
    s.budget_total     = [80_000_000, 65_000_000, 40_000_000][idx]
    s.budget_transfers = [30_000_000, 25_000_000, 15_000_000][idx]
    s.budget_wages     = [50_000_000, 40_000_000, 25_000_000][idx]
    s.team_morale      = 60
    s.expected_position = idx + 1
    s.board_confidence = 70
  end
  club_seasons_map[club.id] = club_season

  # Create ClubSeasonStanding
  ClubSeasonStanding.find_or_create_by!(club_season: club_season) do |s|
    s.position = idx + 1
  end
end
puts "✓ #{ClubSeason.count} club seasons created"

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 3: PLAYERS (Base Data Only)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n👥 Phase 3: Creating players..."

def create_player(attrs)
  Player.find_or_create_by!(known_as: attrs[:known_as]) do |p|
    attrs.each { |k, v| p.send(:"#{k}=", v) unless k == :known_as }
    p.known_as = attrs[:known_as]
  end
end

# ── Real Madrid squad ──────────────────────────────────────────────────────────
rm_players = [
  # GK
  { known_as: "Buyo", first_name: "Francisco", last_name: "Buyo", position: "GK",
    nationality: spain, date_of_birth: Date.new(1958, 9, 13), overall_rating: 81, potential: 81,
    attr_reflexes: 84, attr_handling: 80, attr_diving: 82, attr_kicking: 72, attr_command: 78,
    attr_speed: 40, attr_acceleration: 38, attr_stamina: 70, attr_strength: 72 },
  # Defenders
  { known_as: "R. Carlos", first_name: "Roberto", last_name: "Carlos", position: "LB",
    nationality: brazil, date_of_birth: Date.new(1973, 4, 10), overall_rating: 88, potential: 92,
    attr_speed: 93, attr_acceleration: 91, attr_stamina: 88, attr_strength: 82,
    attr_shooting: 75, attr_long_shot: 82, attr_passing: 80, attr_crossing: 88,
    attr_dribbling: 78, attr_ball_control: 80, attr_tackling: 80, attr_marking: 76,
    attr_heading: 72, attr_interceptions: 76, attr_vision: 76, attr_positioning: 78,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  { known_as: "Hierro", first_name: "Fernando", last_name: "Hierro", position: "CB",
    nationality: spain, date_of_birth: Date.new(1968, 3, 23), overall_rating: 87, potential: 87,
    attr_speed: 72, attr_acceleration: 70, attr_stamina: 85, attr_strength: 92,
    attr_heading: 90, attr_tackling: 88, attr_marking: 86, attr_interceptions: 84,
    attr_shooting: 76, attr_long_shot: 72, attr_passing: 76, attr_ball_control: 74,
    attr_dribbling: 55, attr_vision: 72, attr_positioning: 82, attr_crossing: 60,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  { known_as: "Sanchís", first_name: "Martín", last_name: "Vázquez Sanchís", position: "CB",
    nationality: spain, date_of_birth: Date.new(1965, 3, 23), overall_rating: 83, potential: 83,
    attr_speed: 68, attr_acceleration: 66, attr_stamina: 80, attr_strength: 84,
    attr_heading: 85, attr_tackling: 82, attr_marking: 84, attr_interceptions: 80,
    attr_passing: 72, attr_ball_control: 70, attr_vision: 68, attr_shooting: 60,
    attr_long_shot: 58, attr_dribbling: 50, attr_positioning: 78, attr_crossing: 55,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  { known_as: "Chendo", first_name: "Miguel", last_name: "Chendo", position: "RB",
    nationality: spain, date_of_birth: Date.new(1961, 9, 23), overall_rating: 78, potential: 78,
    attr_speed: 75, attr_acceleration: 73, attr_stamina: 76, attr_strength: 76,
    attr_tackling: 80, attr_marking: 78, attr_interceptions: 76,
    attr_passing: 70, attr_crossing: 72, attr_ball_control: 68,
    attr_heading: 70, attr_shooting: 55, attr_long_shot: 52, attr_dribbling: 62,
    attr_vision: 65, attr_positioning: 74, attr_reflexes: 40, attr_handling: 40,
    attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  # Midfielders
  { known_as: "Redondo", first_name: "Fernando", last_name: "Redondo", position: "DM",
    nationality: argentina, date_of_birth: Date.new(1969, 6, 6), overall_rating: 89, potential: 90,
    attr_passing: 92, attr_vision: 91, attr_ball_control: 90, attr_interceptions: 84,
    attr_tackling: 80, attr_dribbling: 80, attr_stamina: 84, attr_strength: 82,
    attr_speed: 72, attr_acceleration: 70, attr_shooting: 68, attr_long_shot: 72,
    attr_heading: 70, attr_marking: 76, attr_positioning: 82, attr_crossing: 70,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  { known_as: "Seedorf", first_name: "Clarence", last_name: "Seedorf", position: "CM",
    nationality: netherlands, date_of_birth: Date.new(1976, 4, 1), overall_rating: 84, potential: 93,
    attr_speed: 88, attr_acceleration: 86, attr_stamina: 84, attr_strength: 84,
    attr_shooting: 80, attr_long_shot: 82, attr_passing: 84, attr_vision: 82,
    attr_ball_control: 84, attr_dribbling: 82, attr_crossing: 78,
    attr_heading: 74, attr_tackling: 76, attr_marking: 70, attr_interceptions: 74,
    attr_positioning: 80, attr_reflexes: 40, attr_handling: 40, attr_diving: 40,
    attr_kicking: 40, attr_command: 40 },
  { known_as: "Figo", first_name: "Luís", last_name: "Figo", position: "AM",
    nationality: portugal, date_of_birth: Date.new(1972, 11, 4), overall_rating: 91, potential: 95,
    attr_speed: 90, attr_acceleration: 91, attr_stamina: 86, attr_strength: 80,
    attr_dribbling: 94, attr_ball_control: 92, attr_crossing: 91,
    attr_passing: 88, attr_vision: 87, attr_shooting: 80, attr_long_shot: 84,
    attr_heading: 74, attr_tackling: 68, attr_marking: 60, attr_interceptions: 70,
    attr_positioning: 82, attr_reflexes: 40, attr_handling: 40, attr_diving: 40,
    attr_kicking: 40, attr_command: 40 },
  { known_as: "Míchel", first_name: "Míchel", last_name: "González", position: "CM",
    nationality: spain, date_of_birth: Date.new(1963, 3, 22), overall_rating: 82, potential: 82,
    attr_passing: 84, attr_shooting: 80, attr_long_shot: 78, attr_crossing: 82,
    attr_vision: 82, attr_ball_control: 80, attr_dribbling: 78,
    attr_stamina: 72, attr_strength: 70, attr_speed: 68, attr_acceleration: 66,
    attr_heading: 66, attr_tackling: 64, attr_marking: 60, attr_interceptions: 66,
    attr_positioning: 76, attr_reflexes: 40, attr_handling: 40, attr_diving: 40,
    attr_kicking: 40, attr_command: 40 },
  # Strikers
  { known_as: "Míchel S.", first_name: "Michel", last_name: "Salgado", position: "ST",
    nationality: spain, date_of_birth: Date.new(1975, 10, 22), overall_rating: 86, potential: 89,
    attr_shooting: 86, attr_positioning: 88, attr_heading: 82,
    attr_speed: 82, attr_acceleration: 80, attr_stamina: 80, attr_strength: 80,
    attr_long_shot: 76, attr_dribbling: 76, attr_ball_control: 78,
    attr_passing: 72, attr_vision: 74, attr_crossing: 68,
    attr_tackling: 60, attr_marking: 52, attr_interceptions: 56,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  { known_as: "Raúl", first_name: "Raúl", last_name: "González Blanco", position: "SS",
    nationality: spain, date_of_birth: Date.new(1977, 6, 27), overall_rating: 90, potential: 96,
    attr_shooting: 90, attr_positioning: 93, attr_heading: 80,
    attr_speed: 84, attr_acceleration: 85, attr_stamina: 84, attr_strength: 76,
    attr_long_shot: 80, attr_dribbling: 86, attr_ball_control: 88,
    attr_passing: 78, attr_vision: 82, attr_crossing: 72,
    attr_tackling: 60, attr_marking: 50, attr_interceptions: 58,
    attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40 },
  # Bench
  { known_as: "Illgner", first_name: "Bodo", last_name: "Illgner", position: "GK",
    nationality: spain, date_of_birth: Date.new(1967, 4, 7), overall_rating: 84, potential: 84,
    attr_reflexes: 86, attr_handling: 84, attr_diving: 85, attr_kicking: 74, attr_command: 80,
    attr_speed: 42, attr_acceleration: 40, attr_stamina: 72, attr_strength: 74 },
]

# Default player attributes
DEFAULT_PLAYER_ATTRS = {
  preferred_foot: "right", attr_aggression: 70,
  attr_reflexes: 40, attr_handling: 40, attr_diving: 40, attr_kicking: 40, attr_command: 40,
  attr_shooting: 50, attr_long_shot: 50, attr_passing: 60, attr_crossing: 60,
  attr_dribbling: 60, attr_ball_control: 65, attr_vision: 65, attr_positioning: 65,
  attr_tackling: 60, attr_marking: 60, attr_interceptions: 60, attr_heading: 65,
  attr_speed: 70, attr_acceleration: 70, attr_stamina: 75, attr_strength: 75, growth_rate: 0
}

# Helper to create players for a club
def create_squad_for_club(club, players_data, season)
  players_data.each_with_index do |attrs, i|
    player = create_player(attrs.merge(
      market_value: (attrs[:overall_rating] * 800_000).to_d,
      **DEFAULT_PLAYER_ATTRS.merge(attrs.slice(*DEFAULT_PLAYER_ATTRS.keys))
    ))

    # Deactivate any existing active contracts for this player
    Contract.where(player: player, active: true).update_all(active: false)

    Contract.create!(
      player: player, 
      club: club, 
      active: true,
      season: season,
      starts_on: Date.new(1996, 7, 1),
      expires_on: Date.new(1999, 6, 30),
      weekly_wage: attrs[:overall_rating] * 1200,
      squad_number: i + 1,
      role: i < 11 ? "starter" : "squad"
    )
  end
end

# Create Real Madrid squad
create_squad_for_club(real_madrid, rm_players, season)

# Create Barcelona squad (simplified for demo)
barcelona_players = [
  { known_as: "Vítor Baía", first_name: "Vítor", last_name: "Baía", position: "GK",
    nationality: portugal, date_of_birth: Date.new(1969, 10, 15), overall_rating: 85, potential: 85,
    attr_reflexes: 87, attr_handling: 85, attr_diving: 86, attr_kicking: 75, attr_command: 82 },
  { known_as: "Sergi", first_name: "Sergi", last_name: "Barjuán", position: "LB",
    nationality: spain, date_of_birth: Date.new(1971, 12, 28), overall_rating: 82, potential: 82 },
  { known_as: "Abelardo", first_name: "Abelardo", last_name: "Fernández", position: "CB",
    nationality: spain, date_of_birth: Date.new(1970, 4, 19), overall_rating: 84, potential: 84 },
  { known_as: "Nadal", first_name: "Miguel Ángel", last_name: "Nadal", position: "CB",
    nationality: spain, date_of_birth: Date.new(1966, 7, 28), overall_rating: 83, potential: 83 },
  { known_as: "Ferrer", first_name: "Albert", last_name: "Ferrer", position: "RB",
    nationality: spain, date_of_birth: Date.new(1970, 6, 6), overall_rating: 81, potential: 81 },
  { known_as: "Guardiola", first_name: "Pep", last_name: "Guardiola", position: "DM",
    nationality: spain, date_of_birth: Date.new(1971, 1, 18), overall_rating: 88, potential: 88 },
  { known_as: "Luis Enrique", first_name: "Luis Enrique", last_name: "Martínez", position: "CM",
    nationality: spain, date_of_birth: Date.new(1970, 5, 8), overall_rating: 86, potential: 86 },
  { known_as: "Figo", first_name: "Luís", last_name: "Figo", position: "RW",
    nationality: portugal, date_of_birth: Date.new(1972, 11, 4), overall_rating: 89, potential: 93 },
  { known_as: "Stoichkov", first_name: "Hristo", last_name: "Stoichkov", position: "LW",
    nationality: spain, date_of_birth: Date.new(1966, 2, 8), overall_rating: 90, potential: 90 },
  { known_as: "Ronaldo", first_name: "Ronaldo", last_name: "Nazário", position: "ST",
    nationality: brazil, date_of_birth: Date.new(1976, 9, 18), overall_rating: 94, potential: 98 },
  { known_as: "Giovanni", first_name: "Giovanni", last_name: "Silva", position: "AM",
    nationality: brazil, date_of_birth: Date.new(1972, 2, 4), overall_rating: 83, potential: 83 },
  { known_as: "Angoy", first_name: "Carles", last_name: "Busquets", position: "GK",
    nationality: spain, date_of_birth: Date.new(1967, 7, 19), overall_rating: 76, potential: 76,
    attr_reflexes: 78, attr_handling: 76, attr_diving: 77, attr_kicking: 70, attr_command: 74 },
]
create_squad_for_club(barcelona, barcelona_players, season)

# Create Atlético squad (simplified for demo)
atletico_players = [
  { known_as: "Molina", first_name: "José Francisco", last_name: "Molina", position: "GK",
    nationality: spain, date_of_birth: Date.new(1970, 8, 8), overall_rating: 83, potential: 83,
    attr_reflexes: 85, attr_handling: 83, attr_diving: 84, attr_kicking: 73, attr_command: 80 },
  { known_as: "Santi", first_name: "Santiago", last_name: "Denia", position: "LB",
    nationality: spain, date_of_birth: Date.new(1974, 11, 4), overall_rating: 78, potential: 78 },
  { known_as: "Simeone", first_name: "Diego", last_name: "Simeone", position: "DM",
    nationality: argentina, date_of_birth: Date.new(1970, 4, 28), overall_rating: 85, potential: 85 },
  { known_as: "Solozábal", first_name: "Juan", last_name: "Solozábal", position: "CB",
    nationality: spain, date_of_birth: Date.new(1964, 10, 24), overall_rating: 80, potential: 80 },
  { known_as: "Toni", first_name: "Antonio", last_name: "Jiménez", position: "CB",
    nationality: spain, date_of_birth: Date.new(1970, 6, 10), overall_rating: 79, potential: 79 },
  { known_as: "López", first_name: "Roberto", last_name: "López", position: "RB",
    nationality: spain, date_of_birth: Date.new(1971, 11, 1), overall_rating: 77, potential: 77 },
  { known_as: "Vizcaíno", first_name: "José Luis", last_name: "Caminero", position: "CM",
    nationality: spain, date_of_birth: Date.new(1967, 11, 8), overall_rating: 84, potential: 84 },
  { known_as: "Kiko", first_name: "Francisco", last_name: "Narváez", position: "AM",
    nationality: spain, date_of_birth: Date.new(1972, 4, 26), overall_rating: 86, potential: 86 },
  { known_as: "Juninho", first_name: "Osvaldo", last_name: "Giroldo Júnior", position: "LW",
    nationality: brazil, date_of_birth: Date.new(1973, 2, 22), overall_rating: 87, potential: 87 },
  { known_as: "Milinko Pantić", first_name: "Milinko", last_name: "Pantić", position: "ST",
    nationality: spain, date_of_birth: Date.new(1966, 9, 5), overall_rating: 82, potential: 82 },
  { known_as: "Penev", first_name: "Lyuboslav", last_name: "Penev", position: "ST",
    nationality: spain, date_of_birth: Date.new(1966, 8, 31), overall_rating: 81, potential: 81 },
  { known_as: "Molina B", first_name: "Jesús", last_name: "Molina", position: "GK",
    nationality: spain, date_of_birth: Date.new(1968, 3, 3), overall_rating: 75, potential: 75,
    attr_reflexes: 77, attr_handling: 75, attr_diving: 76, attr_kicking: 69, attr_command: 73 },
]
create_squad_for_club(atletico, atletico_players, season)

puts "✓ #{Player.count} players created"

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 4: PLAYER-LEAGUE BINDING (Contracts + Stats)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n🔗 Phase 4: Creating player-league bindings..."

# Clear existing player season stats and fitness records
ActiveRecord::Base.connection.execute("TRUNCATE TABLE player_season_stats RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE player_fitnesses RESTART IDENTITY")

Player.all.each do |player|
  # Find the primary contract for this player in the current season
  primary_contract = player.contracts.find_by(season: season, active: true)
  next unless primary_contract

  club_season = club_seasons_map[primary_contract.club_id]
  next unless club_season

  # Create PlayerSeasonStat for the player's primary contract (stats start at 0)
  PlayerSeasonStat.find_or_create_by!(
    player: player,
    club: primary_contract.club,
    competition_season: cs
  ) do |pss|
    pss.appearances = 0 
    pss.starts = 0 
    pss.goals = 0 
    pss.assists = 0
    pss.shots = 0 
    pss.shots_on_target = 0 
    pss.clean_sheets = 0
    pss.goals_conceded = 0 
    pss.saves = 0 
    pss.yellow_cards = 0
    pss.red_cards = 0 
    pss.minutes_played = 0 
    pss.avg_rating = 0.0
  end

  # Create PlayerFitness for the player's primary contract
  PlayerFitness.find_or_create_by!(
    player: player, 
    club_season: club_season
  ) do |pf|
    pf.fitness = 100
    pf.morale = 50
    pf.injured = false
    pf.suspended = false
    pf.suspension_matches_remaining = 0
  end
end
puts "✓ #{PlayerSeasonStat.count} player season stats records created"
puts "✓ #{PlayerFitness.count} player fitness records created"

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 5: TACTICS (Team Formations)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n🎲 Phase 5: Setting up tactics..."

[real_madrid, barcelona, atletico].each do |club|
  club_season = club_seasons_map[club.id]
  Tactic.find_or_create_by!(club_season: club_season, active: true) do |t|
    t.name = "Default"
    t.formation = "4-4-2"
    t.mentality = "balanced"
    t.pressing = "medium"
    t.passing_style = "mixed"
    t.tempo = "normal"
    t.offside_trap = false
  end
end
puts "✓ #{Tactic.count} tactics created"

# ──────────────────────────────────────────────────────────────────────────────
# PHASE 6: MATCH FIXTURES (Wednesdays & Sundays)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n⚽ Phase 6: Creating match fixtures..."

fixtures = [
  # Round 1 (Wed Sep 15, Sun Sep 22)
  { round: 1, home: real_madrid, away: barcelona, kickoff: DateTime.new(1996, 9, 15, 19, 0, 0) },
  { round: 1, home: atletico, away: real_madrid, kickoff: DateTime.new(1996, 9, 22, 17, 0, 0) },
  # Round 2 (Wed Sep 29, Sun Oct 6)
  { round: 2, home: barcelona, away: atletico, kickoff: DateTime.new(1996, 9, 29, 19, 0, 0) },
  { round: 2, home: real_madrid, away: atletico, kickoff: DateTime.new(1996, 10, 6, 17, 0, 0) },
  # Round 3 (Wed Oct 13, Sun Oct 20)
  { round: 3, home: atletico, away: barcelona, kickoff: DateTime.new(1996, 10, 13, 19, 0, 0) },
  { round: 3, home: barcelona, away: real_madrid, kickoff: DateTime.new(1996, 10, 20, 17, 0, 0) },
]

fixtures.each do |f|
  Match.find_or_create_by!(
    competition_season: cs,
    home_club: f[:home],
    away_club: f[:away],
    round: f[:round]
  ) do |m|
    m.kickoff_at = f[:kickoff]
    m.status = "scheduled"
    m.stadium = f[:home].stadium
  end
end
puts "✓ #{Match.count} matches created"

# ──────────────────────────────────────────────────────────────────────────────
# SIMULATION (Optional: Run first match)
# ──────────────────────────────────────────────────────────────────────────────
first_match = Match.where(status: "scheduled").order(:kickoff_at).first
if first_match
  puts "\n⚡ Simulating first match: #{first_match.home_club.short_name} vs #{first_match.away_club.short_name}..."
  begin
    MatchEngine::Simulator.new(first_match).run!
    puts "✅ Result: #{first_match.reload.score}"
  rescue => e
    puts "⚠️ Simulation skipped (simulator not ready): #{e.message}"
  end
end

# ──────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────────────────────────────────────
puts "\n" + "="*80
puts "✅ SEED COMPLETE"
puts "="*80
puts "📊 Summary:"
puts "  • #{Country.count} Countries"
puts "  • #{Season.count} Seasons"
puts "  • #{Competition.count} Competitions"
puts "  • #{CompetitionSeason.count} Competition Seasons"
puts "  • #{Stadium.count} Stadiums"
puts "  • #{Club.count} Clubs"
puts "  • #{ClubSeason.count} Club Seasons"
puts "  • #{Player.count} Players"
puts "  • #{Contract.count} Contracts"
puts "  • #{PlayerSeasonStat.count} Player Season Stats"
puts "  • #{PlayerFitness.count} Player Fitness Records"
puts "  • #{Tactic.count} Tactics"
puts "  • #{Match.count} Matches"
puts "  • #{ClubSeasonStanding.count} Club Season Standings"
puts "="*80

