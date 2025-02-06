def random_species
  all_species = GameData::Species.keys
  random_species = all_species.sample
  return random_species
end

def generate_random_pokemon # It's a species, not a Pokémon class instance
  $game_variables[33] = random_species
end

def set_event_graphic_unown(event)
  # Retrieve the generated Pokémon species ID from variable 33
  species_id = $game_variables[33]

  # Check if the species ID is valid
  return unless species_id.is_a?(Symbol) && GameData::Species.exists?(species_id)

  name = GameData::Species.get(species_id).real_name
  first_letter = name[0].upcase
  # Filename (e.g., "uA.png" for Alcremie, "uZ.png" for Zygarde)
  filename = "u#{first_letter}.png"

  begin
    filename = "NPC 01" if nil_or_empty?(filename) # Fallback if uX.png is missing
    bitmap = AnimatedBitmap.new("Graphics/Characters/" + filename)
    bitmap.dispose
    event.character_name = filename
  rescue
    # Another fallback
    event.character_name = "NPC 01"
  end
end

def unown_do
  generate_random_pokemon
  event = get_character(1) # Replace with the correct event ID or reference
  set_event_graphic_unown(event)
end

class Pokemon
  attr_accessor :lexicon_lore_species
end

# Lexicon Lore Ability:
# Each Unown with this ability gets the species they were generated with
# and automatically Transforms into it on switch-in, similar to Ditto’s Imposter.
Battle::AbilityEffects::OnSwitchIn.add(:LEXICONLORE,
  proc { |ability, battler, battle, switch_in|
    next if !switch_in || battler.effects[PBEffects::Transform]

    target_species = battler.pokemon.lexicon_lore_species
    unless target_species
      # This shouldn't happen—every Unown with Lexicon Lore should have a species bound.
      return
    end

    target_data = GameData::Species.get(target_species)

    # Transformation sequence
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)

    # Create a dummy Pokémon to transform into (Transform requires a Battler, not a Pokémon)
    dummy_pokemon = Pokemon.new(target_species, battler.level)
    dummy_battler = Battle::Battler.new(battle, battler.index)
    dummy_battler.pbInitDummyPokemon(dummy_pokemon, battler.index)

    # Play transformation animation
    battle.pbAnimation(:FUTURESIGHT, battler, dummy_battler)
    pbWait(0.1)
    # Apply transformation
    battler.effects[PBEffects::Transform] = true
    battler.pbUpdate(true)
    battle.scene.pbChangePokemon(battler, dummy_pokemon)

    battle.pbDisplayPaused(_INTL("{1} channeled {2}'s form!", battler.pbThis, target_data.name))
  }
)

def unown_battle
  # Retrieve the species symbol from Variable 33
  target_species_symbol = $game_variables[33]

  unless GameData::Species.exists?(target_species_symbol)
    p "Invalid or maybe no species is stored in Variable 33."
    return
  end

  # Get the species name and first letter
  target_species_data = GameData::Species.get(target_species_symbol)
  target_name = target_species_data.name
  first_letter = target_name[0].upcase

  # Match the first letter to Unown's form (A=0, B=1, ..., Z=25, !=26, ?=27)
  case first_letter
  when "A".."Z"
    unown_form = first_letter.ord - "A".ord
  when "!"
    unown_form = 26
  when "?"
    unown_form = 27
  else
    unown_form = 0  # Default to A if something went wrong
  end

  unown = Pokemon.new(:UNOWN, 20)
  unown.form = unown_form
  unown.lexicon_lore_species = target_species_symbol
  unown.ability = :LEXICONLORE

  # Set up battle rules
  setBattleRule("single")
  setBattleRule("canLose")

  # Start the battle
  WildBattle.start(unown)

  # Clear Variable 33 after the battle
  $game_variables[33] = nil
end
