def random_pokemon
  all_species = GameData::Species.keys
  random_species = all_species.sample
  poke = Pokemon.new(random_species, rand(1..100))
  poke.reset_moves
  return poke
end

def generate_random_pokemon
  $game_variables[33] = random_pokemon
end

def set_event_graphic_unown(event)
  pokemon = $game_variables[33]
  return unless pokemon.is_a?(Pokemon)

  name = GameData::Species.get(pokemon.species).real_name
  first_letter = name[0].upcase
  filename = "u#{first_letter}.png"

  begin
    filename = "NPC 01" if nil_or_empty?(filename)
    bitmap = AnimatedBitmap.new("Graphics/Characters/" + filename)
    bitmap.dispose
    event.character_name = filename
  rescue
    event.character_name = "NPC 01"
  end
end

def unown_do
  generate_random_pokemon
  event = get_character(1)
  set_event_graphic_unown(event)
end

def unown_battle
  unown_pokemon = $game_variables[33]
  return unless unown_pokemon.is_a?(Pokemon)

  first_letter = unown_pokemon.speciesName.upcase

  case first_letter
  when "A".."Z"
    unown_form = first_letter.ord - "A".ord
  when "!"
    unown_form = 26
  when "?"
    unown_form = 27
  else
    unown_form = 0 # Default to A if something went wrong, probably crashed by this point :sobbing:
  end

  unown = Pokemon.new(:UNOWN, 20)
  unown.form = unown_form
  unown.lexicon_lore = unown_pokemon

  setBattleRule("single")
  setBattleRule("canLose")
  WildBattle.start(unown)

  $game_variables[33] = nil # empty variable at the end
end


# Lexicon Lore Ability:
# Each Unown with this ability gets the species they were generated with
# and automatically Transforms into it on switch-in, similar to Ditto’s Imposter.
Battle::AbilityEffects::OnSwitchIn.add(:LEXICONLORE,
  proc { |ability, battler, battle, switch_in|
    next if !switch_in || battler.effects[PBEffects::Transform]

    target_pokemon = battler.pokemon.lexicon_lore
    unless target_pokemon
      # This shouldn't happen—every Unown with Lexicon Lore should have a species bound.
      return
    end


    # Transformation sequence
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)

    # Create a dummy Pokémon to transform into (Transform requires a Battler, not a Pokémon)
    dummy_pokemon = target_pokemon
    #dummy_pokemon.reset_moves
    dummy_pokemon.level = battler.level
    dummy_battler = Battle::Battler.new(battle, battler.index)
    dummy_battler.pbInitDummyPokemon(dummy_pokemon, battler.index)

    # Play transformation animation
    battle.pbAnimation(:FUTURESIGHT, battler, dummy_battler)
    battler.pbLexiconTransform(dummy_battler)
    pbWait(0.1)
    # Apply transformation

    battler.effects[PBEffects::Transform] = true
    battler.pbUpdate(true)
    battle.scene.pbChangePokemon(battler, dummy_pokemon)

    battle.pbDisplayPaused(_INTL("{1} channeled {2}'s form!", battler.pbThis, dummy_pokemon.name))
  }
)

class Pokemon
  attr_accessor :lexicon_lore
end


class Battle::Battler

  def pbLexiconTransform(target)
    oldAbil = @ability_id
    @effects[PBEffects::Transform]        = true
    @effects[PBEffects::TransformSpecies] = target.species
    pbChangeTypes(target)
    self.ability = target.ability
    @attack  = target.attack
    @defense = target.defense
    @spatk   = target.spatk
    @spdef   = target.spdef
    @speed   = target.speed
    GameData::Stat.each_battle { |s| @stages[s.id] = target.stages[s.id] }
    if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
      @effects[PBEffects::FocusEnergy] = target.effects[PBEffects::FocusEnergy]
      @effects[PBEffects::LaserFocus]  = target.effects[PBEffects::LaserFocus]
    end
    #@moves.clear
    # Idk why the hell did I have to do all this. Im going to assume normal Transform is bugged too
    this_level = target.level
    moveset = target.pokemon.getMoveList
    knowable_moves = []
    moveset.each { |m| knowable_moves.push(m[1]) if (0..this_level).include?(m[0]) }
    knowable_moves = knowable_moves.reverse
    knowable_moves |= []
    knowable_moves = knowable_moves.reverse
    target.moves.clear
    first_move_index = knowable_moves.length - 4
    first_move_index = 0 if first_move_index < 0
    (first_move_index...knowable_moves.length).each do |i|
      target.moves.push(Pokemon::Move.new(knowable_moves[i]))
    end

    target.moves.each_with_index do |m, i|
      @moves[i] = Battle::Move.from_pokemon_move(@battle, Pokemon::Move.new(m.id))
      #@moves[i].pp       = 5
      #@moves[i].total_pp = 5
    end
    @effects[PBEffects::Disable]      = 0
    @effects[PBEffects::DisableMove]  = nil
    @effects[PBEffects::WeightChange] = target.effects[PBEffects::WeightChange]
    @battle.scene.pbRefreshOne(@index)
    pbOnLosingAbility(oldAbil)
  end
end
