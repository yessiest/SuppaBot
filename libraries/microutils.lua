local microutils = {}
--used in brainfuck
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

microutils.match_bracket = match_bracket
local sleep = function(s)
  local ntime = os.clock() + s/1000
  repeat until os.clock() > ntime
end

microutils.sleep = sleep
return microutils
