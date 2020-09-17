filelib = require("libraries.file")
local colors = require("tty-colors")
_G.logging = {}
_G.logging.theme = {
  WARNING = "yellow",
  ERROR = "light red",
  INFO = "green",
  DEBUG = "light cyan"
}
_G.logging.print = function(type,data,prefix)
  local type = type:upper()
  if _G.logging.enable then
    print(prefix.." ["..colors(type,_G.logging.theme[type] or "white").."] "..os.date("!%c")..":  "..data)
  end
end
_G.logging.enable = true
return function(file,prefix)
  local logger = {}
  if filelib.exists(file) then
    logger.file_handler = io.open(file,"a")
  else
    logger.file_handler = io.open(file,"w")
  end
  function logger:log(type,data)
    local type = tostring(type):upper()
    local data = tostring(data)
    self.file_handler:write("["..type.."] "..os.date("!%c")..":  "..data.."\n")
    _G.logging.print(type,data,prefix)
  end
  function logger:close()
    self.file_handler:close()
  end
  logger = setmetatable(logger,{__call = function(self,type,data) logger:log(type,data) end})
  return logger
end
