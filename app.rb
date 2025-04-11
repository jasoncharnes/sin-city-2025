require 'gosu'

# Define Reel class before SlotMachine
class Reel
  attr_accessor :spinning
  attr_reader :visible_symbols
  
  def initialize(window)
    @window = window
    @symbols = ['RUBY', 'DHH', 'MATZ', 'ANDREW'] # Default symbols
    @position = 0
    @spinning = false
    @visible_symbols = get_visible_symbols
  end
  
  def update_symbols(symbols)
    @symbols = symbols.shuffle
    @visible_symbols = get_visible_symbols
  end
  
  def update
    if @spinning
      @position += SlotMachine::SPIN_SPEED
      @position %= (@symbols.length * SlotMachine::SYMBOL_HEIGHT)
      @visible_symbols = get_visible_symbols
    end
  end
  
  def draw(x, y)
    # Draw visible symbols
    SlotMachine::VISIBLE_SYMBOLS.times do |i|
      y_pos = y + (i * SlotMachine::SYMBOL_HEIGHT)
      
      # Symbol background
      Gosu.draw_rect(x, y_pos, SlotMachine::REEL_WIDTH, SlotMachine::SYMBOL_HEIGHT, Gosu::Color::WHITE)
      
      # Symbol border
      border_width = 2
      Gosu.draw_rect(x, y_pos, SlotMachine::REEL_WIDTH, border_width, Gosu::Color::BLACK, 3)
      Gosu.draw_rect(x, y_pos + SlotMachine::SYMBOL_HEIGHT - border_width, SlotMachine::REEL_WIDTH, border_width, Gosu::Color::BLACK, 3)
      
      # Draw the symbol image
      symbol = @visible_symbols[i]
      symbol_img = @window.get_symbol_image(symbol)
      if symbol_img
        scale_factor = [SlotMachine::REEL_WIDTH / symbol_img.width.to_f, SlotMachine::SYMBOL_HEIGHT / symbol_img.height.to_f].min * 0.8
        center_x = x + SlotMachine::REEL_WIDTH / 2 - (symbol_img.width * scale_factor) / 2
        center_y = y_pos + SlotMachine::SYMBOL_HEIGHT / 2 - (symbol_img.height * scale_factor) / 2
        symbol_img.draw(center_x, center_y, 4, scale_factor, scale_factor)
      end
    end
  end
  
  def get_visible_symbols
    # Calculate which symbols are visible based on current position
    result = []
    
    # Show only the required number of symbols
    SlotMachine::VISIBLE_SYMBOLS.times do |i|
      index = (@position / SlotMachine::SYMBOL_HEIGHT + i) % @symbols.length
      result << @symbols[index]
    end
    
    result
  end
end

# Coin class for the coin rain animation
class Coin
  attr_reader :x, :y
  
  def initialize(x, y, speed, size)
    @x = x
    @y = y
    @speed = speed
    @size = size
    @rotation = rand * 360
    @rotation_speed = rand(-10..10)
  end
  
  def update
    @y += @speed
    @rotation = (@rotation + @rotation_speed) % 360
  end
  
  def draw
    # Draw a gold coin
    Gosu.draw_circle(@x, @y, @size, 16, Gosu::Color::BLACK, 10)
    Gosu.draw_circle(@x, @y, @size - 1, 16, SlotMachine::GOLD, 11)
    
    # Draw a "$" symbol inside the coin - fix the Font initialization
    coin_font = Gosu::Font.new((@size * 1.2).to_i)
    text_width = coin_font.text_width("$") / 2
    coin_font.draw_text("$", @x - text_width, @y - @size/2, 12, 1, 1, Gosu::Color::BLACK)
  end
end

# Add circle drawing capability to Gosu
module Gosu
  def self.draw_circle(x, y, radius, segments, color, z = 0, mode = :default)
    segment_angle = 360.0 / segments
    segments.times do |i|
      angle1 = i * segment_angle
      angle2 = (i + 1) * segment_angle
      
      rad1 = angle1 * Math::PI / 180
      rad2 = angle2 * Math::PI / 180
      
      x1 = x + radius * Math.cos(rad1)
      y1 = y + radius * Math.sin(rad1)
      x2 = x + radius * Math.cos(rad2)
      y2 = y + radius * Math.sin(rad2)
      
      draw_triangle(
        x, y, color,
        x1, y1, color,
        x2, y2, color,
        z, mode
      )
    end
  end
  
  # No Window class modification needed
end

class SlotMachine < Gosu::Window
  WIDTH = 1200
  HEIGHT = 800
  REEL_WIDTH = 200
  REEL_HEIGHT = 375  # Reduced height to prevent overflow
  SYMBOL_HEIGHT = 125
  SPIN_SPEED = 30
  VISIBLE_SYMBOLS = 3  # Only show 3 symbols per reel
  
  # Number of paylines
  PAYLINE_COUNT = 3
  
  # Colors
  GOLD = Gosu::Color.new(255, 212, 175, 55)
  DARK_RED = Gosu::Color.new(255, 120, 20, 20)
  CREAM = Gosu::Color.new(255, 252, 240, 202)
  MAROON = Gosu::Color.new(255, 128, 0, 32)
  DARK_WOOD = Gosu::Color.new(255, 60, 30, 15)
  
  # Payline colors - brighter, more vibrant colors
  PAYLINE_COLORS = [
    Gosu::Color.new(255, 255, 50, 50),   # Bright red
    Gosu::Color.new(255, 50, 255, 50),   # Bright green
    Gosu::Color.new(255, 50, 100, 255)   # Bright blue
  ]
  
  # Cheat code
  CHEAT_CODE = "abc123"

  def initialize
    super WIDTH, HEIGHT
    self.caption = 'Ruby Slots - High Roller Edition'
    
    @font = Gosu::Font.new(36, bold: true)
    @title_font = Gosu::Font.new(72, bold: true)
    @big_font = Gosu::Font.new(120, bold: true)
    @balance = 1000
    @bet = 10
    @lines_bet = 1  # Start with 1 payline
    @message = "PRESS SPACE TO SPIN THE REELS!"
    
    # Load images
    @ruby_img = Gosu::Image.new(File.join(Dir.pwd, 'assets', 'images', 'ruby.png'))
    @dhh_img = Gosu::Image.new(File.join(Dir.pwd, 'assets', 'images', 'dhh.png'))
    @matz_img = Gosu::Image.new(File.join(Dir.pwd, 'assets', 'images', 'matz.png'))
    @andrew_img = Gosu::Image.new(File.join(Dir.pwd, 'assets', 'images', 'andrew.png'))
    
    # Symbol definitions
    @symbols = ['RUBY', 'DHH', 'MATZ', 'ANDREW']
    
    # Initialize reels
    @reels = Array.new(3) { Reel.new(self) }
    
    # Update reels with symbols after initialization
    @reels.each { |reel| reel.update_symbols(@symbols) }
    
    @spinning = false
    @spin_start_time = 0
    @results = nil
    @last_win_paylines = []
    
    # Define paylines (row index for each reel)
    # Each payline is [reel1_row, reel2_row, reel3_row]
    @paylines = [
      [1, 1, 1],  # Middle horizontal
      [0, 0, 0],  # Top horizontal
      [2, 2, 2],  # Bottom horizontal
    ]
    
    # For flashing effects
    @flash_timer = 0
    @flash_state = true
    
    # Sound effects
    @coin_sound = Gosu::Sample.new(File.join(Dir.pwd, 'assets', 'sounds', 'coin.wav')) rescue nil
    @win_sound = Gosu::Sample.new(File.join(Dir.pwd, 'assets', 'sounds', 'win.wav')) rescue nil
    @spin_sound = Gosu::Sample.new(File.join(Dir.pwd, 'assets', 'sounds', 'spin.wav')) rescue nil
    
    # Background gradients
    @background = create_gradient(WIDTH, HEIGHT, Gosu::Color.new(255, 30, 15, 5), Gosu::Color.new(255, 60, 30, 15))
    @reel_background = create_gradient(REEL_WIDTH * 3 + 40, REEL_HEIGHT + 40, DARK_RED, MAROON)
    
    # Cheat code variables
    @input_buffer = ""
    @coin_rain_active = false
    @coin_rain_start_time = 0
    @coins = []
    @input_backspace_timer = 0
  end
  
  def create_gradient(width, height, color1, color2)
    img = Gosu.record(width, height) do
      Gosu.draw_quad(
        0, 0, color1,
        width, 0, color1,
        0, height, color2,
        width, height, color2
      )
    end
    img
  end
  
  def get_symbol_image(symbol)
    case symbol
    when 'RUBY' then @ruby_img
    when 'DHH' then @dhh_img
    when 'MATZ' then @matz_img
    when 'ANDREW' then @andrew_img
    end
  end

  def update
    if @spinning
      elapsed = Gosu.milliseconds - @spin_start_time
      
      # Stop reels at different times for effect
      @reels[0].spinning = elapsed < 1500
      @reels[1].spinning = elapsed < 2200
      @reels[2].spinning = elapsed < 3000
      
      # Update spinning reels
      @reels.each(&:update)
      
      # Check if all reels have stopped
      unless @reels.any?(&:spinning)
        @spinning = false
        check_win
      end
    end
    
    # Update flashing effect for winning lines
    if !@last_win_paylines.empty?
      @flash_timer += 1
      if @flash_timer >= 15  # Adjust speed of flashing here
        @flash_timer = 0
        @flash_state = !@flash_state
      end
    end
    
    # Check and update coin rain state
    if @coin_rain_active
      elapsed = Gosu.milliseconds - @coin_rain_start_time
      
      # Add new coins randomly
      if rand < 0.3 # Adjust density of coins
        @coins << Coin.new(rand(WIDTH), -50, rand(3..8), rand(2..6))
      end
      
      # Update existing coins
      @coins.each(&:update)
      
      # Remove coins that have fallen off screen
      @coins.reject! { |coin| coin.y > HEIGHT + 50 }
      
      # Check if coin rain should end (30 seconds)
      if elapsed > 30000
        @coin_rain_active = false
        @coins.clear
      end
      
      # Play coin sound occasionally during rain
      if rand < 0.05 && @coin_sound
        @coin_sound.play(0.2, 0.8 + rand * 0.4) # Random pitch
      end
    end
    
    # Auto-clear input buffer after delay (for cheat code)
    if !@input_buffer.empty?
      @input_backspace_timer += 1
      if @input_backspace_timer > 90 # ~1.5 seconds
        @input_buffer = ""
        @input_backspace_timer = 0
      end
    end
  end

  def draw
    # Draw casino background
    @background.draw(0, 0, 0)
    
    # Draw title
    title_width = @title_font.text_width("RUBY SLOTS")
    @title_font.draw_text("RUBY SLOTS", WIDTH/2 - title_width/2, 30, 10, 1, 1, GOLD)
    
    # Draw casino machine cabinet
    draw_casino_cabinet
    
    # Draw reels background
    reel_bg_x = (WIDTH - (REEL_WIDTH * 3 + 40)) / 2
    @reel_background.draw(reel_bg_x - 20, 100 - 20, 1)
    
    # Draw reels
    @reels.each_with_index do |reel, i|
      x = reel_bg_x + (i * REEL_WIDTH) + 10*i
      reel.draw(x, 100)
    end
    
    # Highlight winning symbol positions with glow effect
    if !@last_win_paylines.empty? && @flash_state
      highlight_winning_symbols(reel_bg_x)
    end
    
    # Draw paylines
    draw_paylines(reel_bg_x)
    
    # Draw UI text with shadows
    draw_text_with_shadow("BALANCE: $#{@balance}", 40, HEIGHT - 200, GOLD)
    draw_text_with_shadow("BET: $#{@bet}", 40, HEIGHT - 150, GOLD)
    draw_text_with_shadow("LINES: #{@lines_bet}/#{PAYLINE_COUNT}", 40, HEIGHT - 100, GOLD)
    
    # Draw spin button
    draw_spin_button
    
    # Message display
    msg_width = @font.text_width(@message)
    draw_text_with_shadow(@message, WIDTH/2 - msg_width/2, HEIGHT - 50, GOLD)
    
    # Draw text-only payout table
    draw_payout_table(WIDTH - 300, HEIGHT - 350)
    
    # Draw coin rain if active
    if @coin_rain_active
      # Add tons of coins when active
      3.times { @coins << Coin.new(rand(WIDTH), -50, rand(3..8), rand(2..6)) } if rand < 0.5
      
      # Draw all the coins
      @coins.each(&:draw)
      
      # Draw big "JACKPOT" text that pulses
      elapsed = Gosu.milliseconds - @coin_rain_start_time
      scale = 1.0 + 0.2 * Math.sin(elapsed / 200.0)
      jackpot_text = "JACKPOT!!!"
      text_width = @big_font.text_width(jackpot_text) * scale
      
      # Make text color cycle through rainbow
      hue = (elapsed / 50) % 360
      r, g, b = hsv_to_rgb(hue, 1.0, 1.0)
      color = Gosu::Color.new(255, r, g, b)
      
      # Draw the jackpot text with shadow
      shadow_color = Gosu::Color.new(180, 0, 0, 0)
      @big_font.draw_text(jackpot_text, WIDTH/2 - text_width/2 + 6, HEIGHT/2 - 60 + 6, 20, scale, scale, shadow_color)
      @big_font.draw_text(jackpot_text, WIDTH/2 - text_width/2, HEIGHT/2 - 60, 21, scale, scale, color)
      
      # Also draw the cheat code text below
      cheat_text = "CHEAT CODE ACTIVATED!"
      cheat_width = @font.text_width(cheat_text)
      draw_text_with_shadow(cheat_text, WIDTH/2 - cheat_width/2, HEIGHT/2 + 60, Gosu::Color::YELLOW)
    end
    
    # Draw cheat code input indicator (always visible to help users)
    if !@input_buffer.empty?
      buffer_display = @input_buffer.gsub(/[a-z0-9]/, '*')
      draw_text_with_shadow("Code: #{buffer_display}", 40, 40, Gosu::Color::YELLOW)
    end
  end
  
  # Convert HSV to RGB (for rainbow text color)
  def hsv_to_rgb(h, s, v)
    h_i = (h/60).floor % 6
    f = h/60 - h_i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    
    case h_i
    when 0 then [v * 255, t * 255, p * 255]
    when 1 then [q * 255, v * 255, p * 255]
    when 2 then [p * 255, v * 255, t * 255]
    when 3 then [p * 255, q * 255, v * 255]
    when 4 then [t * 255, p * 255, v * 255]
    when 5 then [v * 255, p * 255, q * 255]
    end
  end
  
  def highlight_winning_symbols(reel_bg_x)
    @last_win_paylines.each do |payline_idx|
      payline = @paylines[payline_idx]
      color = PAYLINE_COLORS[payline_idx % PAYLINE_COLORS.length]
      
      # Draw a glowing highlight behind each winning symbol
      payline.each_with_index do |row, reel_idx|
        x = reel_bg_x + (reel_idx * REEL_WIDTH) + (10 * reel_idx)
        y = 100 + row * SYMBOL_HEIGHT
        
        # Draw glow effect (larger rectangle with semi-transparent color)
        glow_padding = 10
        Gosu.draw_rect(
          x - glow_padding, 
          y - glow_padding, 
          REEL_WIDTH + glow_padding*2, 
          SYMBOL_HEIGHT + glow_padding*2, 
          Gosu::Color.new(150, color.red, color.green, color.blue), 
          3
        )
      end
    end
  end
  
  def draw_paylines(reel_bg_x)
    # Draw all paylines
    @paylines.each_with_index do |payline, i|
      # Only draw active paylines or winning paylines
      next unless i < @lines_bet || @last_win_paylines.include?(i)
      
      color = PAYLINE_COLORS[i % PAYLINE_COLORS.length]
      
      # Skip drawing winning lines if they should be hidden in flash state
      next if @last_win_paylines.include?(i) && !@flash_state
      
      # Set opacity based on whether this was a winning line
      alpha = @last_win_paylines.include?(i) ? 255 : 120
      line_color = Gosu::Color.new(alpha, color.red, color.green, color.blue)
      
      # Calculate payline positions - centered in each symbol
      points = []
      payline.each_with_index do |row, reel_idx|
        x = reel_bg_x + (reel_idx * REEL_WIDTH) + (10 * reel_idx) + REEL_WIDTH / 2
        y = 100 + row * SYMBOL_HEIGHT + SYMBOL_HEIGHT / 2  # Center of symbol
        points << [x, y]
      end
      
      # Draw thicker lines for better visibility
      line_width = @last_win_paylines.include?(i) ? 3 : 2
      
      # Draw lines connecting the points with thicker width
      (0...points.length-1).each do |j|
        x1, y1 = points[j]
        x2, y2 = points[j+1]
        
        # Draw line with multiple passes for thickness
        (-line_width..line_width).each do |offset|
          Gosu.draw_line(
            x1, y1 + offset, line_color, 
            x2, y2 + offset, line_color, 
            5
          )
        end
      end
      
      # Draw markers at payline positions
      points.each do |x, y|
        marker_size = @last_win_paylines.include?(i) ? 20 : 12
        # Draw diamond-shaped marker
        Gosu.draw_quad(
          x, y - marker_size/2, line_color,
          x + marker_size/2, y, line_color,
          x, y + marker_size/2, line_color,
          x - marker_size/2, y, line_color,
          6
        )
      end
      
      # Draw payline number in a circle on the left side
      if i < @lines_bet || @last_win_paylines.include?(i)
        circle_x = reel_bg_x - 40
        circle_y = points.first[1]
        circle_radius = 20
        
        # Draw circle background
        Gosu.draw_circle(circle_x, circle_y, circle_radius, 16, Gosu::Color::BLACK, 6)
        Gosu.draw_circle(circle_x, circle_y, circle_radius - 2, 16, line_color, 7)
        
        # Draw number
        number_text = (i+1).to_s
        text_width = @font.text_width(number_text) / 2
        @font.draw_text(number_text, circle_x - text_width, circle_y - 15, 8, 0.8, 0.8, Gosu::Color::WHITE)
      end
    end
  end
  
  def draw_payout_table(x, y)
    # Background for payout table
    Gosu.draw_rect(x - 20, y - 20, 260, 220, Gosu::Color::BLACK, 3)
    Gosu.draw_rect(x - 15, y - 15, 250, 210, DARK_RED, 4)
    
    # Title
    @font.draw_text("PAYOUTS", x + 50, y - 5, 5, 0.8, 0.8, GOLD)
    
    # Draw text-only payouts
    spacing = 40
    
    @font.draw_text("RUBY x3 = 15x", x + 20, y + spacing, 5, 0.6, 0.6, GOLD)
    @font.draw_text("MATZ x3 = 5x", x + 20, y + spacing*2, 5, 0.6, 0.6, GOLD)
    @font.draw_text("DHH x3 = 2x", x + 20, y + spacing*3, 5, 0.6, 0.6, GOLD)
    @font.draw_text("ANDREW = WILD!", x + 20, y + spacing*4, 5, 0.6, 0.6, GOLD)
  end
  
  def draw_text_with_shadow(text, x, y, color)
    @font.draw_text(text, x+2, y+2, 1, 1, 1, Gosu::Color::BLACK) # Shadow
    @font.draw_text(text, x, y, 2, 1, 1, color) # Text
  end
  
  def draw_casino_cabinet
    # Machine body
    Gosu.draw_rect(30, 20, WIDTH - 60, HEIGHT - 40, DARK_WOOD, 0)
    
    # Machine border
    border_width = 15
    Gosu.draw_rect(30, 20, WIDTH - 60, border_width, GOLD, 1) # Top
    Gosu.draw_rect(30, HEIGHT - 20 - border_width, WIDTH - 60, border_width, GOLD, 1) # Bottom
    Gosu.draw_rect(30, 20, border_width, HEIGHT - 40, GOLD, 1) # Left
    Gosu.draw_rect(WIDTH - 30 - border_width, 20, border_width, HEIGHT - 40, GOLD, 1) # Right
    
    # Decorative corner pieces
    corner_size = 30
    # Top left
    Gosu.draw_rect(30, 20, corner_size, corner_size, GOLD, 2)
    # Top right
    Gosu.draw_rect(WIDTH - 30 - corner_size, 20, corner_size, corner_size, GOLD, 2)
    # Bottom left
    Gosu.draw_rect(30, HEIGHT - 20 - corner_size, corner_size, corner_size, GOLD, 2)
    # Bottom right
    Gosu.draw_rect(WIDTH - 30 - corner_size, HEIGHT - 20 - corner_size, corner_size, corner_size, GOLD, 2)
  end
  
  def draw_spin_button
    # Spin button
    button_radius = 60
    button_x = WIDTH - 150
    button_y = HEIGHT - 150
    
    # Button base (darker red)
    Gosu.draw_circle(button_x, button_y, button_radius, 32, MAROON, 3)
    
    # Button top (lighter when not spinning)
    button_color = @spinning ? MAROON : DARK_RED
    Gosu.draw_circle(button_x, button_y, button_radius - 5, 32, button_color, 4)
    
    # Button text
    spin_text = "SPIN"
    text_width = @font.text_width(spin_text)
    @font.draw_text(spin_text, button_x - text_width/2, button_y - 15, 5, 1, 1, GOLD)
  end
  
  def button_down(id)
    case id
    when Gosu::KB_ESCAPE
      close
    when Gosu::KB_SPACE
      spin if !@spinning && @balance >= total_bet
    when Gosu::KB_UP
      @bet += 10 if !@spinning && @bet < @balance
    when Gosu::KB_DOWN
      @bet -= 10 if !@spinning && @bet > 10
    when Gosu::KB_LEFT
      @lines_bet = [@lines_bet - 1, 1].max if !@spinning
    when Gosu::KB_RIGHT
      @lines_bet = [@lines_bet + 1, PAYLINE_COUNT].min if !@spinning
    when Gosu::MS_LEFT
      # Check if click is on spin button
      if mouse_x.between?(WIDTH - 210, WIDTH - 90) && mouse_y.between?(HEIGHT - 210, HEIGHT - 90)
        spin if !@spinning && @balance >= total_bet
      end
    # DIRECT KEY HANDLING FOR CHEAT CODE - 100% reliable
    when Gosu::KB_A
      handle_cheat_key('a')
    when Gosu::KB_B
      handle_cheat_key('b')
    when Gosu::KB_C
      handle_cheat_key('c')
    when Gosu::KB_1
      handle_cheat_key('1')
    when Gosu::KB_2
      handle_cheat_key('2')
    when Gosu::KB_3
      handle_cheat_key('3')
    end
  end
  
  # Handle text input for cheat code
  def handle_cheat_key(key)
    return if @spinning
    
    # Add the key to our buffer
    @input_buffer += key
    @input_backspace_timer = 0
    
    # Show input for debugging
    puts "Input buffer: #{@input_buffer}" 
    
    # Check for cheat code
    if @input_buffer.include?(CHEAT_CODE)
      activate_coin_rain
      @input_buffer = ""
    end
    
    # Keep buffer manageable
    @input_buffer = @input_buffer[-10..-1] if @input_buffer.length > 10
  end
  
  def activate_coin_rain
    return if @coin_rain_active # Don't activate if already active
    
    puts "CHEAT CODE ACTIVATED! JACKPOT!"
    
    @coin_rain_active = true
    @coin_rain_start_time = Gosu.milliseconds
    @coins = []
    
    # Give player a MASSIVE jackpot
    @balance += 100000
    
    # Show message
    @message = "CHEAT CODE ACTIVATED - $100,000 BONUS!"
    
    # Play win sound at max volume
    if @win_sound
      @win_sound.play(1.0)
    end
  end
  
  def total_bet
    @bet * @lines_bet
  end

  def spin
    @balance -= total_bet
    @spinning = true
    @spin_start_time = Gosu.milliseconds
    @message = "SPINNING..."
    @reels.each { |reel| reel.spinning = true }
    @last_win_paylines = []
    @flash_state = true
    @flash_timer = 0
    @spin_sound.play(0.5) if @spin_sound
  end

  def check_win
    # Reset total winnings and winning lines
    total_win = 0
    winning_paylines = {}  # Map payline index to win amount
    @last_win_paylines = []
    
    # Check each active payline
    @paylines.each_with_index do |payline, payline_idx|
      # Skip paylines not bet on
      next if payline_idx >= @lines_bet
      
      # Get symbols on this payline
      symbols = []
      payline.each_with_index do |row, reel_idx|
        symbols << @reels[reel_idx].visible_symbols[row]
      end
      
      # Check for wins on this payline
      win_amount = calculate_win(symbols)
      
      if win_amount > 0
        total_win += win_amount
        winning_paylines[payline_idx] = win_amount
        @last_win_paylines << payline_idx
      end
    end
    
    # Update balance and display message
    if total_win > 0
      @balance += total_win
      
      if winning_paylines.length == 1
        line_num = @last_win_paylines.first + 1
        win_amount = winning_paylines[@last_win_paylines.first]
        @message = "YOU WON $#{win_amount} ON LINE #{line_num}!"
      else
        # Format message for multiple winning lines
        win_msg = winning_paylines.map { |line_idx, amount| "LINE #{line_idx + 1}: $#{amount}" }.join(", ")
        @message = "WINS! #{win_msg} - TOTAL: $#{total_win}"
      end
      
      @win_sound.play(0.8) if @win_sound
    else
      @message = "TRY AGAIN, HIGH ROLLER!"
    end
    
    # Game over check
    if @balance <= 0
      @message = "GAME OVER! PLEASE EXIT OR INSERT MORE COINS."
    end
  end
  
  def calculate_win(symbols)
    # First check for Andrews (wilds) and possible combinations
    if contains_wild?(symbols)
      # Check each possible wild combination
      return check_wild_combinations(symbols)
    elsif all_same?(symbols)
      # All three symbols match
      return @bet * symbol_multiplier(symbols[0])
    end
    
    # No win on this payline
    return 0
  end
  
  def contains_wild?(results)
    results.include?('ANDREW')
  end
  
  def all_same?(results)
    results.uniq.length == 1
  end
  
  def check_wild_combinations(results)
    # Get indices of wilds and non-wilds
    wild_indices = results.each_index.select { |i| results[i] == 'ANDREW' }
    non_wild_indices = results.each_index.select { |i| results[i] != 'ANDREW' }
    
    # If all wilds, big jackpot!
    if wild_indices.length == 3
      return @bet * 50 # Special all-wild jackpot
    end
    
    # If some non-wilds, check if they're all the same
    if non_wild_indices.length > 0
      # Get the first non-wild symbol
      base_symbol = results[non_wild_indices.first]
      
      # Check if all non-wild symbols are the same
      if non_wild_indices.all? { |i| results[i] == base_symbol }
        # This means we have a winning combination with wilds
        return @bet * symbol_multiplier(base_symbol)
      end
    end
    
    return 0
  end
  
  def symbol_multiplier(symbol)
    case symbol
    when 'RUBY' then 15
    when 'MATZ' then 5
    when 'DHH' then 2
    when 'ANDREW' then 50 # Wild symbol has its own multiplier for 3 of a kind
    else 1
    end
  end
  
  def needs_cursor?
    true  # Show cursor for clicking the spin button
  end
end

# Start the game
SlotMachine.new.show