module Transitions
  class VSUnown < Transition_Base
    DURATION           = 4.0
    BAR_Y              = 80
    BAR_SCROLL_SPEED   = 1800
    BAR_MASK           = [8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7]
    FOE_SPRITE_X_LIMIT = 384
    FOE_SPRITE_X       = 428

    def initialize_bitmaps
      @bar_bitmap   = RPG::Cache.transition("unown_vsBar")
      @vs_1_bitmap  = RPG::Cache.transition("hgss_vs1")
      @vs_2_bitmap  = RPG::Cache.transition("hgss_vs2")

      # Use variable 33 for the Pokémon's species ID
      species_id = $game_variables[33]
      @foe_bitmap = RPG::Cache.load_bitmap("Graphics/Pokemon/Front/", species_id.to_s)

      @black_bitmap = RPG::Cache.transition("black_half")
      dispose if !@bar_bitmap || !@vs_1_bitmap || !@vs_2_bitmap || !@foe_bitmap || !@black_bitmap
    end

    def initialize_sprites
      @flash_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @flash_viewport.z     = 99999
      @flash_viewport.color = Color.new(255, 255, 255, 0)
      # Background black
      @rear_black_sprite = new_sprite(0, 0, @black_bitmap)
      @rear_black_sprite.z       = 1
      @rear_black_sprite.zoom_y  = 2.0
      @rear_black_sprite.opacity = 224
      @rear_black_sprite.visible = false
      # Bar sprites (need 2 of them to make them loop around)
      ((Graphics.width.to_f / @bar_bitmap.width).ceil + 1).times do |i|
        spr = new_sprite(@bar_bitmap.width * i, BAR_Y, @bar_bitmap)
        spr.z = 2
        @sprites.push(spr)
      end
      # Overworld sprite
      @bar_mask_sprite = new_sprite(0, 0, @overworld_bitmap.clone)
      @bar_mask_sprite.z = 3
      # VS logo
      @vs_x = 144
      @vs_y = @sprites[0].y + (@sprites[0].height / 2)
      @vs_main_sprite = new_sprite(@vs_x, @vs_y, @vs_1_bitmap, @vs_1_bitmap.width / 2, @vs_1_bitmap.height / 2)
      @vs_main_sprite.z       = 4
      @vs_main_sprite.visible = false
      @vs_1_sprite = new_sprite(@vs_x, @vs_y, @vs_2_bitmap, @vs_2_bitmap.width / 2, @vs_2_bitmap.height / 2)
      @vs_1_sprite.z       = 10
      @vs_1_sprite.zoom_x  = 2.0
      @vs_1_sprite.zoom_y  = @vs_1_sprite.zoom_x
      @vs_1_sprite.visible = false
      @vs_2_sprite = new_sprite(@vs_x, @vs_y, @vs_2_bitmap, @vs_2_bitmap.width / 2, @vs_2_bitmap.height / 2)
      @vs_2_sprite.z       = 11
      @vs_2_sprite.zoom_x  = 2.0
      @vs_2_sprite.zoom_y  = @vs_2_sprite.zoom_x
      @vs_2_sprite.visible = false
      # Foe sprite



      @foe_sprite = new_sprite(Graphics.width + @foe_bitmap.width, @sprites[0].y + @sprites[0].height+12,
                               @foe_bitmap, @foe_bitmap.width / 2, @foe_bitmap.height)


      pokemon_data = $game_variables[33]
      @foe_sprite = new_sprite(Graphics.width + @foe_bitmap.width, @sprites[0].y + @sprites[0].height+12,
                                 @foe_bitmap, @foe_bitmap.width / 2, @foe_bitmap.height)

        # Create a Pokémon object from the species ID in variable 33
        species_id = $game_variables[33]
        pokemon_data = Pokemon.new(species_id, 50) # Level 50

        @foe_sprite = AutoMosaicPokemonSprite.new(@foe_sprite.viewport)
        @foe_sprite.setPokemonBitmap(pokemon_data)
        @foe_sprite.tone = Tone.new(-255, -255, -255)
        @foe_sprite.x = Graphics.width + @foe_sprite.bitmap.width
        @foe_sprite.y = @sprites[0].height + 96 + 16
        @foe_sprite.ox = @foe_sprite.bitmap.width / 2
        @foe_sprite.oy = @foe_sprite.bitmap.height
        @foe_sprite.z = 7
        @foe_sprite.update
      # Sprite with foe's name written in it
      @text_sprite = BitmapSprite.new(Graphics.width, @bar_bitmap.height, @viewport)
      @text_sprite.y       = BAR_Y
      @text_sprite.z       = 8
      @text_sprite.visible = false
      pbSetSystemFont(@text_sprite.bitmap)
      pbDrawTextPositions(@text_sprite.bitmap,
                          [[$game_variables[28].to_s.downcase.capitalize, 244, 86, :left,
                            Color.new(248, 248, 248), Color.new(72, 80, 80)]])
      # Foreground black
      @black_sprite = new_sprite(0, 0, @black_bitmap)
      @black_sprite.z       = 10
      @black_sprite.zoom_y  = 2.0
      @black_sprite.visible = false

      unownbitmap = RPG::Cache.load_bitmap("Graphics/Transitions/", "unown_char_outline")
      if unownbitmap

      random_words = ["angry", "bear", "chase", "direct", "engage", "find",
                     "give", "help", "increase", "join", "keep", "laugh", "make",
                     "nuzzle", "observe", "perform", "quicken", "reassure", "search",
                     "tell", "undo", "vanish", "want", "xxxxx", "yield", "zoom", "amongus",
                     "beast", "draco", "dread", "earth", "fist", "flame", "icicle", "insect",
                     "iron", "meadow", "mind", "pixie", "sky", "splash", "spooky", "stone",
                     "toxic", "zap"]

      # Filter out non-string data and remove spaces
      valid_strings = random_words.select { |word| word.is_a?(String) && !word.empty? }
      valid_strings.map! { |word| word.gsub(/\s+/, '').to_s.downcase }

      # Pick a random subset of 8 words from the valid_strings array
      random_subset = valid_strings.sample(20)
      index = 0
      y_position = 0  # Initial y position
      while index < random_subset.length
        random_string = random_subset[index]
        characters = random_string.chars
        combined_bitmap = Bitmap.new(characters.length * 32, 32)
        characters.each_with_index do |char, char_index|
          if ('a'..'z').include?(char)
            char_number = char.ord - 'a'.ord
            rect = Rect.new(char_number * 32, 0, 32, 32)
            combined_bitmap.blt(char_index * 32, 0, unownbitmap, rect)
          end
        end
        random_start_x = @foe_sprite.x
        random_offset_x = 0
        random_offset_y = 0
        if index.odd?
          random_offset_x = rand(64..128)
          random_offset_y = rand(-16..16)
        end
        if index % 3 == 0
          random_offset_x = rand(-32..96)
          random_offset_y = rand(-16..16)
        end
        random_x = random_start_x + random_offset_x
        random_y = @foe_sprite.y / 2 + y_position - 64 + random_offset_y # Adjust y position
        random_y = [[random_y, 0].max, Graphics.height].min
        unown = new_sprite(random_x, random_y, combined_bitmap)
        unown.z = 7
        unown.visible = true
        unown.viewport = @foe_sprite.viewport
        @unown.push(unown)

        if index.odd?
          y_position += 16
        elsif index % 3 == 0
          y_position -= 16
        else
          y_position += 32  # Increase y position for the next sprite
        end
        index += 1
      end
      # Add individual letter sprites
      y_position = 0
      num_letter_sprites = rand(9..15)
      y_position += 32
      (1..num_letter_sprites).each_with_index do |_, index|
        random_letter = ('a'..'z').to_a.sample  # Generate a random letter
        combined_bitmap = Bitmap.new(32, 32)
        char_number = random_letter.ord - 'a'.ord
        rect = Rect.new(char_number * 32, 0, 32, 32)
        combined_bitmap.blt(0, 0, unownbitmap, rect)
        random_start_x = @foe_sprite.x
        random_offset_x = 0
        random_offset_y = 0
        if index.odd?
          random_offset_x = rand(64..128)
          random_offset_y = rand(-16..16)
        end
        if index % 3 == 0
          random_offset_x = rand(-32..96)
          random_offset_y = rand(-16..16)
        end
        random_x = random_start_x + random_offset_x
        random_y = @foe_sprite.y / 2 + y_position - 64 + random_offset_y # Adjust y position
        random_y = [[random_y, 0].max, Graphics.height].min
        unown = new_sprite(random_x, random_y, combined_bitmap)
        # TODO? Probably order the Z so the lower they are they always show on top
        unown.z = 7
        unown.visible = true
        unown.viewport = @foe_sprite.viewport
        @unown.push(unown)
      end

      @sprite_speeds = Array.new(random_subset.length) { rand(2..4) }



end







    end

    def set_up_timings
      @bar_x = 0
      @bar_appear_end      = 0.2   # Starts appearing at 0.0
      @vs_appear_start     = 0.7
      @vs_appear_start_2   = 0.9
      @vs_shrink_time      = @vs_appear_start_2 - @vs_appear_start
      @vs_appear_final     = @vs_appear_start_2 + @vs_shrink_time
      @foe_appear_start    = 1.2
      @foe_appear_end      = 1.4
      @flash_start         = 1.9
      @flash_duration      = 0.25
      @fade_to_white_start = 3.0
      @fade_to_white_end   = 3.5
      @fade_to_black_start = 3.8
    end

    def dispose_all
      # Dispose sprites
      @rear_black_sprite&.dispose
      @bar_mask_sprite&.dispose
      @vs_main_sprite&.dispose
      @vs_1_sprite&.dispose
      @vs_2_sprite&.dispose
      @foe_sprite&.dispose
      @text_sprite&.dispose
      @black_sprite&.dispose
      # Dispose bitmaps
      @bar_bitmap&.dispose
      @vs_1_bitmap&.dispose
      @vs_2_bitmap&.dispose
      @foe_bitmap&.dispose
      @black_bitmap&.dispose
      # Dispose viewport
      @flash_viewport&.dispose
    end


    def update_anim

          #@pokemon_sprite.update
          #@foe_bitmap   = @pokemon_sprite.bitmap

      @bar_x = -timer * BAR_SCROLL_SPEED
      while @bar_x <= -@bar_bitmap.width
        @bar_x += @bar_bitmap.width
      end



      @sprites.each_with_index { |spr, i| spr.x = @bar_x + (i * @bar_bitmap.width) }

      vs_phase = (timer * 30).to_i % 3
      @vs_main_sprite.x = @vs_x + [0, 4, 0][vs_phase]
      @vs_main_sprite.y = @vs_y + [0, 0, -4][vs_phase]
      @foe_sprite.update if @foe_sprite.x==FOE_SPRITE_X


      if @foe_sprite.x >= FOE_SPRITE_X
        # Once @foe_sprite reaches FOE_SPRITE_X, make @unown sprites follow it
        @unown.each_with_index do |sprite, index|
          @sprite_speed = @sprite_speeds[index % @sprite_speeds.length]
          sprite.x -= @sprite_speed*2  # Move left indefinitely
          #sprite.opacity -= 1 if sprite.x <= Graphics.width / 2
          # puts "Unown sprite x: #{sprite.x}, y: #{sprite.y}"
        end
      end

      if timer >= @fade_to_black_start

        @black_sprite.visible = true
        proportion = (timer - @fade_to_black_start) / (@duration - @fade_to_black_start)
        @flash_viewport.color.alpha = 255 * (1 - proportion)
      elsif timer >= @fade_to_white_start
        proportion = (timer - @fade_to_white_start) / (@fade_to_white_end - @fade_to_white_start)
        @flash_viewport.color.alpha = 255 * proportion
      elsif timer >= @flash_start + @flash_duration
        @flash_viewport.color.alpha = 0
      elsif timer >= @flash_start
        proportion = (timer - @flash_start) / @flash_duration
        if proportion >= 0.5
          @flash_viewport.color.alpha = 320 * 2 * (1 - proportion)
          @rear_black_sprite.visible = true
          @foe_sprite.color.alpha = 0
          @text_sprite.visible = false
        else
          @flash_viewport.color.alpha = 320 * 2 * proportion
        end
      elsif timer >= @foe_appear_end
        @foe_sprite.x = FOE_SPRITE_X
      elsif timer >= @foe_appear_start
        proportion = (timer - @foe_appear_start) / (@foe_appear_end - @foe_appear_start)
        start_x = Graphics.width + (@foe_bitmap.width / 2)
        @foe_sprite.x = start_x + ((FOE_SPRITE_X_LIMIT - start_x) * proportion)
         #@unown.each do |sprite|
         #   sprite.x -= rand(2..4)  # Move left indefinitely
         #   puts "Unown sprite x: #{sprite.x}, y: #{sprite.y}"
         # end

      elsif timer >= @vs_appear_final
        @vs_1_sprite.visible = false
      elsif timer >= @vs_appear_start_2
        if @vs_2_sprite.visible
          @vs_2_sprite.zoom_x = 1.6 - (0.8 * (timer - @vs_appear_start_2) / @vs_shrink_time)
          @vs_2_sprite.zoom_y = @vs_2_sprite.zoom_x
          if @vs_2_sprite.zoom_x <= 1.2
            @vs_2_sprite.visible = false
            @vs_main_sprite.visible = true
          end
        end
        @vs_1_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start_2) / @vs_shrink_time)
        @vs_1_sprite.zoom_y = @vs_1_sprite.zoom_x
      elsif timer >= @vs_appear_start

        @vs_2_sprite.visible = true
        @vs_2_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start) / @vs_shrink_time)
        @vs_2_sprite.zoom_y = @vs_2_sprite.zoom_x
        if @vs_1_sprite.visible || @vs_2_sprite.zoom_x <= 1.6
          @vs_1_sprite.visible = true
          @vs_1_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start - (@vs_shrink_time / 2)) / @vs_shrink_time)
          @vs_1_sprite.zoom_y = @vs_1_sprite.zoom_x
        end
      elsif timer >= @bar_appear_end
        @bar_mask_sprite.visible = false
      else
        start_x = Graphics.width * (1 - (timer / @bar_appear_end))
        color = Color.new(0, 0, 0, 0)
        (@sprites[0].height / 2).times do |i|
          x = start_x - (BAR_MASK[i % BAR_MASK.length] * 4)
          @bar_mask_sprite.bitmap.fill_rect(x, BAR_Y + (i * 2), @bar_mask_sprite.width - x, 2, color)
        end
      end
    end


  end
end
