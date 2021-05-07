-- transmit
-- emergent feedback sequencer
-- by: @cfd90
-- originally by: @tehn

local musicutil = require "musicutil"

engine.name = "Thebangs"

local cells = {}
local range = 50
local mutate_chance = 15

local notes = musicutil.generate_scale_of_length(48, "minor pentatonic", 24)
local times = {2, 4, 4, 8}

function table_contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

function init()
  engine.algoIndex(4)
  
  params:add_separator()
  
  params:add_taper("io_range", "io_range", 1, 100, 50, 1, "")
  params:add_taper("mutate_chance", "mutate_chance", 1, 100, 15, 1, "%")
  
  params:add_separator()
  
  params:add_taper("attack", "attack", 0, 2, 0, 0.1, "")
  params:set_action("attack", function(x) engine.attack(x) end)
  
  params:add_taper("release", "release", 0, 2, 0.5, 0.1, "")
  params:set_action("release", function(x) engine.release(x) end)

  params:bang()
  
  g = grid.connect()
  
  for y=1,g.rows do
    cells[y] = {}
    
    for x=1,g.cols do
      local trig = false
      local delay = times[math.random(1, #times)]
      local input = math.random(1, range)
      local output = math.random(1, range)
      local note = notes[math.random(1, #notes)]
      
      cells[y][x] = { trig = trig, input = input, output = output, note = note, delay = delay, counter = delay }
    end
  end
  
  grid_redraw()
  
  g.key = function(x, y, z)
    if z == 1 then
      cells[y][x].trig = true
      grid_redraw()
    end
  end
  
  clk = clock.run(tick)
end

function grid_redraw()
  g:all(0)
  
  for y=1,g.rows do
    for x=1,g.cols do
      local cell = cells[y][x]
      
      if cell.trig then
        g:led(x, y, 15)
      end
    end
  end
  
  g:refresh()
end

function tick()
  while true do
    clock.sync(1/8)
    
    local play = {}
    
    for y=1,g.rows do
      for x=1,g.cols do
        local cell = cells[y][x]
        
        cell.counter = util.clamp(cell.counter - 1, 1, 8)
        
        if cell.trig and cell.counter == 1 then
          if not table_contains(play, cell.note) then
            table.insert(play, cell.note)
          end
          
          cell.trig = false
          
          for _y=1,g.rows do
            for _x=1,g.cols do
              local _cell = cells[_y][_x]
              
              if _y ~= y and _x ~= x and cell.output == _cell.input then
                _cell.trig = true
                _cell.counter = _cell.delay
              end
            end
          end
        end
      end
    end
    
    for i=1,#play do
      local note = play[i]
      engine.hz(musicutil.note_num_to_freq(note))
    end
    
    grid_redraw()
  end
end

local function chance(p)
  if p == 1 then
    return true
  else
    return math.random() <= p
  end
end

local function mutate(p)
  for y=1,g.rows do
    local notes = musicutil.generate_scale_of_length(48, "minor pentatonic", 24)
    local times = {2, 4, 4, 8}
    
    for x=1,g.cols do
      if chance(p) then
        local input = math.random(1, range)
        cells[y][x].input = input
      end
      
      if chance(p) then
        local output = math.random(1, range)
        cells[y][x].output = output
      end
      
      if chance(p) then
        local note = notes[math.random(1, #notes)]
        cells[y][x].note = note
      end
      
      if chance(p) then
        local delay = times[math.random(1, #times)]
        cells[y][x].delay = delay
        cells[y][x].counter = delay
      end
    end
  end
end

function key(n, z)
  if n == 1 and z == 1 then
    for y=1,g.rows do
      for x=1,g.cols do
        -- Reset both trig state and countdown.
        cells[y][x].trig = false
        cells[y][x].counter = cells[y][x].delay
      end
    end
  elseif n == 2 and z == 1 then
    mutate(1)
  elseif n == 3 and z == 1 then
    mutate(mutate_chance)
  end
end

function enc(n, d)
  if n == 1 then
    params:delta("release", d)
  elseif n == 2 then
    range = util.clamp(range + d, 1, 100)
  elseif n == 3 then
    mutate_chance = util.clamp(mutate_chance + d, 1, 100)
  end
  
  redraw()
end

function redraw()
  screen.clear()
  screen.move(0, 60)
  screen.level(15)
  screen.text("range: ")
  screen.level(5)
  screen.text(range)
  screen.move(60, 60)
  screen.level(15)
  screen.text("mutate: ")
  screen.level(5)
  screen.text(mutate_chance .. "%")
  screen.update()
end