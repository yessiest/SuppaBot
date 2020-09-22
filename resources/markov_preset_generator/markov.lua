local markov = {}

local function node(relations)
   local node = {}
   local total = 0
   for k,v in pairs(relations) do
     total = total + v.occurences
   end
   for k,v in pairs(relations) do
     node[k] = {probability = v.occurences/total,occurences = v.occurences}
   end
   return node
end

local function escape(str)
  return str:gsub("([%%%*%(%)%^%.%[%]%+%-%$%?])","%%%1")
end

local function register_words(str,word_list)
   local word_list = word_list or {}
   str:gsub("%S+",function(word)
      if not word_list[word] then
         word_list[word] = {}
      end
      local current_word = word_list[word]
      str:gsub(escape(word) .. "%s+(%S+)",function(word2)
        if not current_word[word2] then
          current_word[word2] = {}
        end
        if not current_word[word2].occurences then
          current_word[word2].occurences = 1
        else
          current_word[word2].occurences = current_word[word2].occurences + 1
        end
      end)
   end)
   for k,v in pairs(word_list) do
     word_list[k] = node(v)
   end
   return word_list
end

local table_length = function(tab)
  local len = 0
  for k,v in pairs(tab) do
    len = len + 1
  end
  return len
end

function markov.walk(self,start)
  if not self.init then
    error("Attempted to use an instance method on an uninitialized instance")
  end
  local random = math.random(0,1e7)/1e7
  local words = {}
  words.count = 0
  local word = nil
  if self.net[start] then
    while (words.count < 1) and (table_length(self.net[start]) > 0) do
      for k,v in pairs(self.net[start]) do
        if (random <= v.probability) then
          words.count = words.count + 1
          table.insert(words,k)
        end
      end
      random = math.random(0,1e7)/1e7
    end
  end
  if words.count > 0 then
    word = words[math.random(1,#words)]
  end
  return word
end

function markov.expand_vocabulary(self,source)
  if not self.init then
    error("Attempted to use an instance method on an uninitialized instance")
  end
  self.net = register_words(source,self.net)
end

function markov.save_state(self)
  return self.net
end

function markov.load_state(self,new_state)
  self.net = new_state
end

function markov.run(self,start,count)
  if not self.init then
    error("Attempted to use an instance method on an uninitialized instance")
  end
  if not start then
    for k,v in pairs(self.net) do
      start = k
      break
    end
  end
  local sequence = ""
  local current_word = start
  while current_word do
    sequence = sequence..current_word.." "
    local _,counter = sequence:gsub("(%S+)","%1")
    current_word = self:walk(current_word)
    if counter > (count or 200) then
      sequence = sequence:sub(1,-2).."..."
      break
    end
  end
  return sequence
end

function markov.new(str)
   local self = setmetatable({},{__index = markov})
   self.net = register_words(str or "")
   self.init = true
   return self
end

return markov
