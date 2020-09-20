local json = require("json")
return {
  ["help"] = {
    help = "oh hai mark",
    exec = function(msg,args,opts)
      msg:reply("hi")
    end
  },
  ["random"] = {
    help = "Return a random number. Usage: random <min> <max>",
    args = {
      "number",
      "number"
    },
    exec = function(msg,args,opts)
      msg:reply(math.random(tonumber(args[1]),tonumber(args[2])))
    end
  },
  ["print"] = {
    help = "Append the message to the output. (During script runtime, all message replies are ignored.) Usage: message [--unsecape] [-u] <text> ",
    exec = function(msg,args,opts)
      local str = table.concat(args," ")
      if opts["unescape"] or opts["u"] then
        str = str:gsub("\\","")
      end
      events:emit("print",str)
      msg:reply(str)
    end,
  },
  ["embed"] = {
    help = "Set the embed to be output after execution (During script runtime, embeds replies are ignored.) Usage: embed <embed in json format>",
    exec = function(msg,args,opts)
      local embed_text = msg.content:gsub(globals.prefix.."embed","",1):gsub("\\([%{%}])","%1")
      local status,json_out,code,err = pcall(json.decode,embed_text)
      if status and json_out then
        events:emit("print",json_out)
      else
        events:emit("print","JSON decode error: "..err)
      end
      msg:reply(msg.content:gsub(globals.prefix.."embed","",1))
    end,
  },
}
