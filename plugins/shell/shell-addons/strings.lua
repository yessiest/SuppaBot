return {
  ["gsub"] = {
    help = "Works like lua gsub",
    args = {
      "string",
      "string",
      "string"
    },
    exec = function(msg,args,opts)
      local status,output = pcall(string.gsub,args[1],args[2],args[3],tonumber(args[4]))
      if status then
        msg:reply(output)
      else
        events:emit("print","Error on gsub: "..tostring(output))
      end
    end
  },
  ["match"] = {
    args = {
      "string",
      "string"
    },
    exec = function(msg,args,opts)
      local status,output = pcall(string.match,args[1],args[2])
      if status then
        msg:reply(output)
      else
        events:emit("print","Error on match: "..tostring(output))
      end
    end
  }
}
