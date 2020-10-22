segment = {}
local check_perms = require("check_perms")
local fake_server = {
  id = id
}
segment.commands = {
  ["rules"] = {
    args = {
      "string",
      "string",
    }
    exec = function(msg,args,opts)
      local target,command = args[1],args[2]
      local commands = plugins.get()["commands"]
      if not commands[target] then
        msg:reply("Target command not found")
        return
      end
      target = commands[target]
      if not check_perms(fake_server,target,msg,require("discordia")) then
        msg:reply("You don't have a high enough permission to change rules for this command")
        return
      end
    end
  }
}
return segment
