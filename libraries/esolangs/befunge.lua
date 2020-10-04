local seq = function(start,endt)
  local new_table = {}
  for I = start,endt do
    table.insert(new_table,I)
  end
  return new_table
end

math.randomseed(os.clock()+os.time())

local function longest(tab)
  local a = 0
  for k,v in pairs(tab) do
    if type(v) == "table" and #v > a then
      a = v
    end
  end
  return a
end

local function to_befunge_unit(char)
  local unit
  if (char > 0) and (char < 256) then
    unit = string.char(char)
  else
    unit = "%"..char
  end
  return unit
end

local function from_befunge_unit(char)
  if char:match("%%(%d+)") then
    return tonumber(char:match("%%(%d+)"))
  else
    return string.byte(char)
  end
end

local field = function(source)
  local new_field = {}
  local lines = {}
  source:gsub("[^\n]+",function(capt) table.insert(lines,capt) end)
  new_field.max_field_width = 150
  new_field.max_field_height = 100
  local field_width = 0
  local field_height = 0
  for k,v in pairs(lines) do
    new_field[k] = {}
    v:gsub(".",function(capt)
      if #new_field[k] < new_field.max_field_width then
        table.insert(new_field[k],capt)
      end
    end)
    if #new_field[k] > field_width then
      field_width = #new_field[k]
    end
  end
  field_height = #new_field
  function new_field:expand(height,width)
    if (height > new_field.max_field_height) or (width > new_field.max_field_width) then
      return nil
    end
    for I = 1,height do
      local row = self[I]
      if not row then
        table.insert(self,{})
        row = self[I]
      end
      while #row > width do
        table.remove(row,#row)
      end
      while #row < width do
        table.insert(row," ")
      end
    end
    return true
  end
  new_field:expand(field_height,field_width)
  new_field.height = field_height
  new_field.width = field_width
  --return the field itself, the width of the field and its height
  return new_field
end

local rw_head = function(field,commands)
  local RW_head = {}
  RW_head.read_mode = false
  RW_head.coords = {
    x = 1,
    y = 1
  }
  RW_head.stack = {}
  function RW_head:push(value)
    table.insert(self.stack,value)

  end
  function RW_head:pop(value)
    local value = self.stack[#self.stack]
    table.remove(self.stack,#self.stack)
    return value
  end
  function RW_head:walk()
    self.coords = {
      x = self.coords.x+self.direction.x,
      y = self.coords.y+self.direction.y
    }
    if self.coords.y > field.height then
      self.coords.y = 1
    elseif self.coords.y < 1 then
      self.coords.y = field.height
    end
    if self.coords.x > field.width then
      self.coords.x = 1
    elseif self.coords.x < 1 then
      self.coords.x = field.width
    end
  end
  function RW_head:execute()
    if not self.read_mode then
      if commands[field[self.coords.y][self.coords.x]] then
        commands[field[self.coords.y][self.coords.x]](field,self)
      end
    else
      if field[self.coords.y][self.coords.x] ~= "\"" then
        self:push(string.byte(field[self.coords.y][self.coords.x]))
      else
        self.read_mode = false
      end
    end
  end
  RW_head.direction = {
    x = 1,
    y = 0
  }
  return RW_head
end
interpreter_state = true
local befunge = {}
function befunge:init(source,args)
  local required = {
    handle_int_input = true,
    handle_output = true,
    handle_input = true,
  }
  args.handle_warning = args.handle_warning or function() end
  args.handle_error = args.handle_error or function() end
  for k,v in pairs(required) do
    if not args[k] then
      error("Unable to initialize module: "..k.." not specified")
    end
  end
  befunge.interpreter_state = true
  local opcount = 0
  local new_field = field(source)
  local warn_args = function(field,head)
    local instruction = field[head.coords.y][head.coords.x]
    local pos = head.coords.x..":"..head.coords.y
    args.handle_warning("One or more arguments not present on "..instruction.." at "..pos)
  end
  local commands = {
    ["@"] = function()
      befunge.interpreter_state = false
    end,
    ["v"] = function(field,head)
      head.direction = {
        x = 0,
        y = 1
      }
    end,
    [">"] = function(field,head)
      head.direction = {
        x = 1,
        y = 0
      }
    end,
    ["<"] = function(field,head)
      head.direction = {
        x = -1,
        y = 0
      }
    end,
    ["^"] = function(field,head)
      head.direction = {
        x = 0,
        y = -1
      }
    end,
    ["+"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      head:push(a+b)
    end,
    ["-"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      head:push(b-a)
    end,
    ["*"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      head:push(a*b)
    end,
    ["/"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      if a == 0 then
        (args.handle_division_by_zero or function()
        end)()
        return
      end
      local result = b/a
      head:push(math.floor(result))
    end,
    ["%"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      if a == 0 then
        (args.handle_division_by_zero or function()
        end)()
        return
      end
      local result = math.fmod(b,a)
      head:push(result)
    end,
    ["\""] = function(field,head)
      head.read_mode = true
    end,
    [","] = function(field,head)
      local v = head:pop()
      if not v then
        args.handle_error("Attempted to append to output on stack underflow")
        return
      end
      if (v > 0) and (v < 256) then
        v = string.char(v)
      else
        v = ""
      end
      args.handle_output(v)
    end,
    ["."] = function(field,head)
      local v = head:pop()
      if not v then
        args.handle_error("Attempted to append to output on stack underflow")
        return
      end
      args.handle_output(v)
    end,
    ["?"] = function(field,head)
      local ranInt = math.random(0,200)
      local direction
      if ranInt > 99 then
        direction = -1
      else
        direction = 1
      end
      if math.fmod(ranInt,2) == 0 then
        head.direction = {
          x = direction,
          y = 0
        }
      else
        head.direction = {
          x = 0,
          y = direction
        }
      end
    end,
    ["!"] = function(field,head)
      local v = head:pop()
      if not v then
        warn_args(field,head)
        return
      end
      if v == 0 then
        head:push(1)
      else
        head:push(0)
      end
    end,
    ["`"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        return
      end
      if a < b then
        head:push(1)
      else
        head:push(0)
      end
    end,
    ["|"] = function(field,head)
      local v = head:pop()
      if not v then
        warn_args(field,head)
        return
      end
      if v == 0 then
        head.direction = {
          x = 0,
          y = 1
        }
      else
        head.direction = {
          x = 0,
          y = -1
        }
      end
    end,
    ["_"] = function(field,head)
      local v = head:pop()
      if not v then
        warn_args(field,head)
        return
      end
      if v == 0 then
        head.direction = {
          x = 1,
          y = 0
        }
      else
        head.direction = {
          x = -1,
          y = 0
        }
      end
    end,
    [":"] = function(field,head)
      local value = head:pop()
      if not value then
        warn_args(field,head)
        value = 0
      end
      head:push(value)
      head:push(value)
    end,
    ["\\"] = function(field,head)
      local a,b = head:pop(),head:pop()
      if not (a or b) then
        warn_args(field,head)
        a = 0
        b = 0
      end
      head:push(a)
      head:push(b)
    end,
    ["#"] = function(field,head)
      head:walk()
    end,
    ["&"] = function(field,head)
      local v = args.handle_int_input()
      if not v then
        v = -1
      end
      head:push(v)
    end,
    ["~"] = function(field,head)
      local v = args.handle_input()
      if not v then
        v = -1
      end
      head:push(v)
    end,
    ["p"] = function(field,head)
      local y,x = head:pop(),head:pop()
      local value = head:pop()
      if not (y or x or value) then
        args.handle_error("Attempted to call \"put\" operator with less than 3 arguments")
        return
      end
      y,x = y+1,x+1
      if (not field[y]) or (not field[y][x]) then
        if (y < field.max_field_height) and (x < field.max_field_width) and (x >= 0) and (y >= 0) then
          field:expand(y,x)
        else
          args.handle_error("Attempted to get a value out of bounds")
          return
        end
      end
      field[y][x] = to_befunge_unit(value)
    end,
    ["g"] = function(field,head)
      local y,x = head:pop(),head:pop()
      if not (y or x) then
        args.handle_error("Attempted to call \"get\" operator with less than 3 arguments")
        return
      end
      y,x = y+1,x+1
      if (not field[y]) or (not field[y][x]) then
        head:push(0)
        args.handle_error("Attempted to put a value out of bounds")
        return
      end
      head:push(from_befunge_unit(field[y][x]))
    end,
    ["$"] = function(field,head)
      head:pop()
    end
  }
  for I = 0,9 do
    commands[tostring(I)] = function(field,head)
      head:push(I)
    end
  end
  local walker = rw_head(new_field,commands)
  function befunge:run()
    while befunge.interpreter_state do
      walker:execute()
      walker:walk()
      if args.opcount and opcount > args.opcount then
        args.handle_error("Instruction limit reached (>"..opcount..")")
        break
      end
      opcount = opcount + 1
    end
    return opcount
  end
end

return befunge
