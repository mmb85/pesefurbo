# ==============================================================================
# db/seeds.rb - PC Fútbol Database Seeds
# Modified to use csv_lite_optimized.csv for team and player data
# ==============================================================================

require 'csv'
require_relative '../config/environment'

# -------------------------------------------------------------------------
# PHASE 1: BASE DATA (Countries, Season, Competition, CompetitionSeason)
# -------------------------------------------------------------------------

# Create countries
spain = Country.find_or_create_by!(code: 'ESP') do |c|
  c.name = 'España'
  c.flag_emoji = '🇪🇸'
end

# Create season
puts "Creating season 1996/97..."
season = Season.find_or_create_by!(name: '1996/97') do |s|
  s.year_start = 1996
  s.year_end = 1997
  s.starts_on = Date.new(1996, 9, 1)
  s.ends_on = Date.new(1997, 6, 30)
  s.current = true
end

# Create competition (Primera División)
puts "Creating competition Primera División..."
liga = Competition.find_or_create_by!(short_name: 'Primera') do |c|
  c.name = 'Primera División'
  c.competition_type = 'league'
  c.tier = 1
  c.country = spain
end

# Create competition season
puts "Creating competition season for Primera División 1996/97..."
cs = CompetitionSeason.find_or_create_by!(competition: liga, season: season) do |c|
  c.rounds_total = 38
  c.teams_count = 20
  c.champions_spots = 2
  c.europa_spots = 3
  c.relegation_spots = 3
end

# -------------------------------------------------------------------------
# PHASE 2: POSITION MAPPING
# -------------------------------------------------------------------------

# Map CSV position codes to internal positions
POSITION_MAPPING = {
  'GK' => 'GK',
  'CB' => 'CB',
  'LB' => 'LB',
  'RB' => 'RB',
  'DM' => 'DM',
  'CM' => 'CM',
  'AM' => 'AM',
  'ST' => 'ST',
  'LW' => 'LW',
  'RW' => 'RW',
  'DEF' => 'CB',
  'POR' => 'GK',
  'DFC' => 'CB',
  'LI' => 'LW',
  'LD' => 'RW',
  'MCO' => 'ST',
  'ED' => 'ST',
  'II' => 'AM',
  'MP' => 'CM',
  'DC' => 'CB',
  'ID' => 'CM',
  'PIV' => 'DM'
}.freeze

# -------------------------------------------------------------------------
# PHASE 3: PROCESS CSV DATA
# -------------------------------------------------------------------------

CLUB_ABBR_MAPPING = {
  "CD Tenerife" => "TEN",
  "Hércules CF" => "HER",
  "SD Compostela" => "COM",
  "Real Oviedo" => "OVI",
  "Real Sporting de Gijón" => "SPO",
  "Valencia CF" => "VAL",
  "RC Celta de Vigo" => "CEL",
  "RC Deportivo de La Coruña" => "DEP",
  "CF Extremadura" => "EXT",
  "RCD Espanyol" => "ESP",
  "Real Sociedad" => "RSO",
  "Atlético de Madrid" => "ATM",
  "Real Racing Club" => "RAC",
  "Athletic Club" => "ATH",
  "Real Madrid CF" => "RMA",
  "Sevilla FC" => "SEV",
  "Rayo Vallecano" => "RAY",
  "Real Valladolid CF" => "VAD",
  "CD Logroñés" => "LOG",
  "Real Betis Balompié" => "BET",
  "Real Zaragoza" => "ZAR",
  "FC Barcelona" => "BAR"
}.freeze

CSV.foreach('csv_lite_optimized.csv', headers: true) do |row|
  # Skip rows with missing essential data
  next unless row['Equipo'].present? && row['Jugador'].present? && row['Posicion'].present? && row['Media'].present?

  team_name = row['Equipo'].strip
  club = Club.find_or_create_by!(name: team_name) do |c|
    c.short_name = team_name.split(' ').first
    c.abbr = CLUB_ABBR_MAPPING[team_name] || team_name[0..2].upcase
    c.country = spain
    # Create a generic stadium if none exists for this club
    c.stadium ||= Stadium.find_or_create_by!(name: 'Estadio Principal', city: 'Ciudad', country: spain)
  end

  # Split player name into first and last
  name_parts = row['Jugador'].strip.split(' ')
  first_name = name_parts[0]
  last_name = name_parts[1..-1].join(' ')

  # Map position and get average rating
  position = POSITION_MAPPING[row['Posicion'].strip] || 'ST'
  overall_rating = row['Media'].to_f

  # Create player
  player = Player.joins(:contracts).find_by(known_as: row['Jugador'].strip, contracts: { club_id: club.id })

  if player.nil?
    puts "Creating player #{row['Jugador']} for club #{team_name} with position #{position} and rating #{overall_rating}..."
    player = Player.create!(
      known_as: row['Jugador'].strip,
      first_name: first_name,
      last_name: last_name,
      position: position,
      overall_rating: overall_rating,
      nationality: spain,
      date_of_birth: Date.new(1990, 1, 1)
    )
  else
    puts "Player #{row['Jugador']} already exists for club #{team_name}, skipping player creation..."
  end

  # Create contract for the player
  puts "Creating contract for #{player.known_as} at #{club.name} with rating #{overall_rating}..."
  Contract.find_or_create_by!(player: player, club: club, season: season, active: true) do |c|
    c.starts_on = Date.today
    c.expires_on = Date.today + 3.years
    c.weekly_wage = overall_rating * 1200
    c.squad_number = 1
    c.role = 'starter'
  end

  # Populate player season stats with overall_rating
  puts = "Creating PlayerSeasonStat for #{player.known_as} at #{club.name}"
  PlayerSeasonStat.find_or_create_by!(player:, club:, competition_season: cs)
end

# -------------------------------------------------------------------------
# PHASE 4: SUMMARY
# -------------------------------------------------------------------------

puts "\n" + "=" * 80
puts "✅ SEED COMPLETE"
puts "=" * 80
puts "📊 Summary:"
puts "  • #{Country.count} Countries"
puts "  • #{Season.count} Seasons"
puts "  • #{Competition.count} Competitions"
puts "  • #{CompetitionSeason.count} Competition Seasons"
puts "  • #{Stadium.count} Stadiums"
puts "  • #{Club.count} Clubs"
puts "  • #{Player.count} Players"
puts "  • #{Contract.count} Contracts"
puts "  • #{PlayerSeasonStat.count} Player Season Stats"
puts "=" * 80
