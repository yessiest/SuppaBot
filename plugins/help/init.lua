local segment = {}
segment.name = "help"
math.randomseed(os.time()+os.clock())
local function randomize_stuff()
  if math.random(1,100) < 10 then
    segment.help = [[
This button here, builds Teleporters. This button, builds Dispensers.
And this little button makes them enemy sum-bitches wish they'd never been born!

--the inspiration behind this bot's design    ]]
  else
    segment.help = [[
This plugin provides the help command, which can view help messages for plugins and commands
    ]]
  end
end
local utils = require("bot_utils")
local function count(tab)
  local count = 0
  for k,v in pairs(tab) do
    count = count+1
  end
  return count
end

local function concatenate_keys(tab)
  local key_list = {}
  for k,v in pairs(tab) do
    table.insert(key_list,k)
  end
  return "``"..table.concat(key_list,"``,\n``").."``"
end

segment.commands = {
  ["help"] = {
    help = {embed={
      title = "View help embeds for commands and plugins",
      description = "To specify if it's a plugin or a command, simply add the option accordingly",
      fields = {
        {name = "Usage:",value = "help [<command> or --plugin <plugin>]"},
        {name = "Perms:",value = "any"},
        {name = "Options:",value = "--plugin"}
      }
    }},
    exec = function(msg,args,opts)
      randomize_stuff()
      local plugin_data = plugins.get()
      local embed = {
        color = discordia.Color.fromHex("32b3bc").value
      }
      if args[1] then
        if count(opts) < 1 then
          if plugin_data.commands[args[1]] then
            local command = plugin_data.commands[args[1]]
            if command.help then
              embed = command.help.embed
            else
              embed.title = "Help for command ``"..args[1].."``"
              embed.description = "This help message is generated automatically"
              embed.fields = {
                --this is perhaps the weirdest thing i've written yet, but it's kinda beautiful
                {name = "Perms:", value = command.perms and (
                  (command.perms.perms and
                    table.concat(command.perms.perms,", ")
                  ) or (command.perms.perms.special and "Special") or "Administrator"
                  ) or "any"},
                (command.args and {name = "Usage:",value =
                  args[1].." <"..table.concat(command.args,"> <")..">"
                })
              }
            end
          else
            embed.description = "No such command"
          end
        elseif (opts["plugin"]) then
          if plugin_data["plugins"][args[1]] then
            embed.title = "Plugin ``"..args[1].."``:"
            embed.description = plugin_data["plugins"][args[1]]["_help"]
            embed.fields = {{
              name = "Commands:",
              value ="``"..table.concat(plugin_data["plugins"][args[1]],"``,\n``").."``"
            }}
          else
            embed.description = "No such plugin"
          end
        end
      else
        embed.title = "SuppaBot commands:"
        embed.description = "use ``"..globals.prefix.."help <command>`` to view help messages. (type ``"..globals.prefix.."help help`` for more info)"
        embed.fields = {}
        for k,v in pairs(plugin_data["plugins"]) do
          table.insert(embed.fields,{
            name = k,
            value = "``"..table.concat(v,"``, ``").."``"
          })
        end
      end
      msg:reply({embed = embed})
    end,
   }
}
return segment
