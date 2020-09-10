segment = {}
segment.help = "This is a set of commands that add some features specific to this bot"
local emulate = require("emulate")({
  client = client,
  discordia = discordia,
})
local last_message_arrived = discordia.Stopwatch()
client:on("messageCreate",function(msg)
  last_message_arrived:reset()
  last_message_arrived:start()
end)
local utils = require("bot_utils")
local map = require("file").readJSON("./servers/"..id.."/aliasmap.json",{})
segment.commands = {
  ["prefix"] = {
    help = {embed={
      title = "Set or view current prefix for this bot",
      description = "If you're not sure what's the current prefix, just ping the bot",
      fields = {
        {name = "Usage:",value = "prefix [<new prefix> or \"<new prefix>\"]"},
        {name = "Perms:",value = "Administrator"},
      }
    }},
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if args[1] then
        globals.prefix = args[1]
        msg:reply("Prefix set to ``"..args[1].."``")
      else
        msg:reply("Current prefix: ``"..globals.prefix.."``")
      end
    end,
  },
  ["alias"] = {
    help = {embed={
      title = "Creates aliases",
      description = "Add an alias for a command. (https://en.wikipedia.org/wiki/Alias_(command))",
      fields = {
        {name = "Usage: ",value = "alias \"<alias name>\" \"<command>\""},
        {name = "Examples: ",value = [[
``alias !hi "]]..globals.prefix..[[speak Hello!"`` - reply to !hi with "Hello!" using speak command
``alias !say "]]..globals.prefix..[[speak ..."`` - reply to !hi with everything typed after !hi
``alias !say "]]..globals.prefix..[[speak $1"`` - reply to !hi with the first argument sent along with !hi]]
        },
        {name = "Perms: ",value = "Administrator (doesn't apply to created aliases)"}
      }
    }},
    args = {
      "string","string"
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if not map[args[1]] then
        map[args[1]] = args[2]
        msg:reply("Bound ``"..args[1].."`` as an alias to ``"..args[2].."``")
      end
    end
  },
  ["unalias"] = {
    help = {embed = {
      title = "Removes aliases",
      description = "Remove a previously created alias",
      fields = {
        {name = "Usage: ",value = "unalias \"<alias name>\""},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    args = {
      "string"
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if map[args[1]] then
        map[args[1]] = nil
        msg:reply("Removed the ``"..args[1].."`` alias")
      end
    end
  },
  ["aliases"] = {
    help = {embed = {
      title = "Lists aliases",
      description = "List all previously created aliases",
      fields = {
        {name = "Usage: ",value = "aliases"},
        {name = "Perms: ",value = "all"}
      }
    }},
    exec = function(msg,args,opts)
      msg:reply({embed = {
        title = "Aliases for this server",
        fields = (function()
          local fields = {}
          for k,v in pairs(map) do
            table.insert(fields,{name = k,value = v})
          end
          return fields
        end)()
      }})
    end
  },
  ["ping"] = {
    help = {embed = {
      title = "View response latency",
      description = "This command shows some latency stats",
      fields = {
        {name = "Usage: ",value = "ping"},
        {name = "Perms: ",value = "all"}
      }
    }},
    exec = function(msg,args,opts)
      local before = msg:getDate()
      local reply = msg:reply("Pong!")
      if not reply then
        log("ERROR","Couldn't send the ping reply for some reason")
        return
      end
      local after = reply:getDate()
      local latency = (after:toMilliseconds() - before:toMilliseconds())
      last_message_arrived:stop()
      local uptime = discordia.Date():toSeconds() - discordia.uptime:toSeconds()
      local processing = (last_message_arrived:getTime():toMilliseconds())
      msg:reply({embed = {
        title = "Stats:",
        fields = {
          {name = "Latency",value = tostring(math.floor(latency)).."ms"},
          {name = "Processing time",value = tostring(math.floor(processing)).."ms"},
          {name = "Uptime",value = tostring(utils.unixToString(uptime))}
        }
      }})
    end
  }
}
events:on("messageCreate",function(msg)
  for k,v in pairs(map) do
    if (msg.content:find(k) == 1) and (msg.author.id ~= client.user.id) then
      local str = msg.content:gsub(k.." ","")
      aftersub = v:gsub("%.%.%.",str)
      local status,args = require("air").parse(str)
      for k,v in pairs(args) do
        aftersub = aftersub:gsub("([^\\])%$"..k,"%1"..v)
      end
      emulate.send(msg,{
        content = aftersub
      })
    end
  end
end)

events:on("serverSaveConfig",function()
  require("file").writeJSON("./servers/"..id.."/aliasmap.json",map)
end)

return segment
