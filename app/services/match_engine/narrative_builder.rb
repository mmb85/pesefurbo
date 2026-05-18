# ==============================================================================
# app/services/match_engine/narrative_builder.rb
# ==============================================================================
require 'yaml'

module MatchEngine
  class NarrativeBuilder
    TEMPLATES = YAML.load_file(Rails.root.join('config', 'narratives.yml')).freeze

    def self.build(key, vars = {})
      templates = TEMPLATES[key.to_s] || TEMPLATES['build_up']
      # Select one of the four variants (or all if less than 4)
      template = templates.sample
      
      # Special handling for cases where we only have one player
      # If we have payload with player info, use it to replace placeholders
      # Enhanced placeholder replacement: use payload player if available (handles string/symbol keys)
      if vars[:payload]
        player_name = vars[:payload][:player] || vars[:payload]["player"]
        if player_name
          if (vars[:carrier] == "—" || vars[:carrier].nil?) && vars[:tackler] && vars[:tackler] != "—"
            vars[:carrier] = player_name
          elsif (vars[:tackler] == "—" || vars[:tackler].nil?) && vars[:carrier] && vars[:carrier] != "—"
            vars[:tackler] = player_name
          elsif vars[:carrier] == "—" && vars[:tackler] == "—"
            vars[:carrier] = player_name
          end
        end
      end
      
      # Final safety check to prevent double dashes in sentences
      result = template % default_vars.merge(vars)
      
      # If we still have "—" in the result, replace with a more appropriate placeholder
      if result.include?("— entra con dureza") || result.include?("— lanza el balón")
        # This is a fallback for cases where we still have placeholders
        result = result.gsub("—", "el jugador")
      end
      
      result
    rescue KeyError
      "#{vars[:team] || '—'} continúa con el balón."
    end

    def self.default_vars
      { carrier: "—", tackler: "—", keeper: "—", assister: "—", team: "—", score: "—" }
    end
  end
end
