--TODO: fix this mess of useless code
local match_bracket = function(position,text,mode,match_left,match_right)
  assert(type(position) == "number" and type(text) == "table" and (type(mode) == "boolean" or type(mode) == "nil"),"Expected number,table[,bool], got "..type(position)..type(text)..type(mode))
  local matching,level,last_matching,scroll = nil,1,nil,nil
  if not mode then
    matchables = {match_left,match_right}
    scroll = 1
  else
    matchables = {match_right,match_left}
    scroll = -1
  end
  --enter "matching" mode - no tokens executed
  while not matching do
      position = position + scroll
    --find last matching token in case the code tape has ended
    if text[position] == nil then
      matching = last_matching
      if not matching then
        return nil,"No matching brackets."
      end
    end
    if text[position] == matchables[1] then
      level = level + 1
    elseif text[position] == matchables[2] then
      --store in case of asymmetric topology
      last_matching = position
      if level == 1 then
        matching = position
      end
      level = level - 1
    end
  end
  return matching
end
local file = require("file")
local bf = {}
--create interpreter object. created for each code chunk as tape reinitialization is required to run new code.
bf.new = function(input,options)
  --assert input
  assert(type(options) == "table" or type(options) == "nil","Expected argument #2 of type table, got "..type(options))
  assert(type(input) == "string","Expected argument #1 of type string, got "..type(input))

  --generate the prototype and attach functions to it
  local self = {file_buffer = {}, tape = {}, pointer = 1, counter = 1, program = {}, stack = {}, file_pointer = 0}
  input:gsub(".",function(capt) self.program[#self.program + 1] = capt end)
  setmetatable(self, {__index = bf})

  --options and default values for them start here
  if not options then options = {} end
  self.options = {}
  self.options.tapesize = options.tapesize or 30000
  self.options.cellsize = options.cellsize or 1
  self.options.dump_char = options.dump_char or "$" --extension lv3 goes against debug conventions.
  self.options.debug_char = options.debug_char or "%"
  self.options.dump_capacity = options.dump_capacity or 30
  self.options.debug = options.debug or false
  self.options.path = options.path or "."
  self.oplimit = options.limit or math.huge
  if err then error(err) end
  --store tokens for use during the main loop.
  self.tokens = {}
  self.tokens[">"] = function()
    self.pointer = self.pointer + 1
    --wrap around
    if self.tape[self.pointer] == nil then
      self.pointer = 1
    end
  end
  self.tokens["<"] = function()
    self.pointer = self.pointer - 1
    --wrap around
    if self.tape[self.pointer] == nil then
      self.pointer = #self.tape
    end
  end
  self.tokens["+"] = function()
    self.tape[self.pointer] = self.tape[self.pointer] + 1
    if self.tape[self.pointer] > (256^self.options.cellsize)-1 then
      self.tape[self.pointer] = 0
    end
  end
  self.tokens["-"] = function()
    self.tape[self.pointer] = self.tape[self.pointer] - 1
    if self.tape[self.pointer] < 0 then
      self.tape[self.pointer] = (256^self.options.cellsize)-1
    end
  end
  self.tokens["."] = function()
    self.output = self.output..string.char(self.tape[self.pointer])
  end
  self.tokens[","] = function()
    if self.input[1] then
      self.tape[self.pointer] = self.input[1]:byte()
      table.remove(self.input,1)
    else
      self.tape[self.pointer] = 0
    end
  end
  self.tokens["["] = function()
    if self.tape[self.pointer] == 0 then
    local count,err = match_bracket(self.counter,self.program,false,"[","]")
      if err then self.tokens["@"](); self.errmsg = "structure error at "..self.pointer else
        self.counter = count
      end
    end
  end
  self.tokens["]"] = function()
    if self.tape[self.pointer] ~= 0 then
      local count,err = match_bracket(self.counter,self.program,true,"[","]")
      if err then self.tokens["@"](); self.errmsg = "structure error at "..self.pointer else
        self.counter = count
      end
    end
  end

  --start debug tokens
  if self.options.debug then

    --enable debugging flag
    self.tokens[self.options.debug_char] = function()
      self.debug = (not self.debug)
    end

    --dump current stack and a short range of memory around the pointer to the console.
    self.tokens[self.options.dump_char] = function()
      local pointer = self.pointer - self.options.dump_capacity
      if pointer < 0 then pointer = 0 end
      local dump = "cell #"..pointer..": "
      for I = 1,self.options.dump_capacity*2 do
        local cell = self.tape[I+pointer]
        if cell/100 < 1 then
          if cell/10 < 1 then
            cell = "00"..cell
          else
            cell = "0"..cell
          end
        end
        dump = dump.." "..cell
      end
      dump = dump.."\nStack:\n"
      for k,v in pairs(self.stack) do
        local cell = v
        if cell/100 < 1 then
          if cell/10 < 1 then
            cell = "00"..cell
          else
            cell = "0"..cell
          end
        end
        dump = dump.." "..cell
      end
     self.output =self.output.."\n"..dump.."\n"
    end
  end

  --generate tape
  for I = 1,self.options.tapesize do
    self.tape[I] = 0
  end
  --set reinitialization flags to false (no reinitialization before running)
  self.init = false
  self.default_program = self.program
  return self
end


--execute the main loop.
bf.run = function(self,input)
   --reinitialize tape, program, pointers and storages.
  if self.init then
    for I = 1,self.options.tapesize do
      self.tape[I] = 0
    end
    self.storage = 0
    self.stack = {}
    --reset the EXT3/EXT2 self-modifications.
    self.program = self.default_program
    self.counter = 1
    self.pointer = 1
    self.file_pointer = 1
    self.file_buffer = {}
  end


  --assert that self is an object.
  assert(type(self) == "table")
  --we can use tables of tokens instead of strings.
  assert(type(input) == "string" or type(input) == "table", "Expected argument of type table or string, got "..type(input))
  if type(input) == "string" then
    local temp_table = {}
    input:gsub(".",function(capt) temp_table[#temp_table + 1] = capt end)
    self.input = temp_table
  end
  local prgcount = 0
  self.output = ""
  --[2]


  while self.program[self.counter] ~= nil do
    if self.tokens[self.program[self.counter]] then
      self.tokens[self.program[self.counter]]()
      prgcount = prgcount+1 --counts the total amount of operations. useful during debugging.
      if self.debug then
       self.output =self.output.."\n".."cycle: "..prgcount.."; token: "..self.program[self.counter]..", "..self.counter.."; memory: #"..self.pointer..", "..self.tape[self.pointer]
        if self.options.ext1 then
         self.output =self.output.."; storage: "..self.storage
        end
       self.output =self.output.."\n"
      end
      if self.oplimit and prgcount > self.oplimit then
	self.errmsg = "operation limit reached"
	break
      end
    end
    self.counter = self.counter + 1 --[1]
  end


  for k,v in pairs(self.file_buffer) do
    local temporary_file = io.open(tostring(k),"w")
    temporary_file:write(v)
    temporary_file:close()
  end

  self.init = true
  return self.output,prgcount,self.errmsg
end

return bf
