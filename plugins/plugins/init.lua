local segment = {}
segment.help = "This plugin manages all other plugins, believe it or not."
local utilities = require("bot_utils")

local generic_admin_template = {
  args = {"string"},
  perms = {
    perms = {
      "administrator"
    },
    users = {
      ["245973168257368076"] = true
    }
  },
}

local function get_plugin_folder()
  local ls = io.popen("ls -1 ./plugins/","r")
  local pluginlist = {}
  ls:read("*a"):gsub("[^\n]+",function(c) table.insert(pluginlist,c) end)
  ls:close()
  return pluginlist
end

local function concatenate_keys(tab)
  local key_list = {}
  for k,v in pairs(tab) do
    table.insert(key_list,k)
  end
  return "``"..table.concat(key_list,"``,\n``").."``"
end

segment.commands = {
  ["enable"] = utilities.overwrite(generic_admin_template,{
    help = {embed = {
      title = "Enable plugin",
      description = [[This command loads a plugin,
adding its commands to the command pool]],
      fields = {
        {name = "Usage:",value = "load <plugin-name>"},
        {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
      },
      color = discordia.Color.fromHex("ff5100").value
    }},
    exec = function(msg,args,opts)
      local status,message = plugins.load("./plugins/"..args[1]:match("%w+").."/init.lua")
      local plugin_data = plugins.get()
      local embed = {
        description = message,
        color = discordia.Color.fromHex("ff5100").value,
      }
      if status then
        embed.fields = {
          {name = "New commands:",value =
            table.concat(plugin_data["plugins"][args[1]] or {},", ").." "
          }
        }
      end
      msg:reply({embed = embed})
    end
  }),
  ["disable"] = utilities.overwrite(generic_admin_template,{
    help = {embed = {
      title = "Disable a loaded plugin",
      description = [[This commands unloads a previously loaded plugin,
removing its commands from the command pool]],
      fields = {
        {name = "Usage:",value = "unload <plugin-name>"},
        {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
      },
      color = discordia.Color.fromHex("ff5100").value
    }},
    exec = function(msg,args,opts)
      local plugin_data = plugins.get()
      if not (args[1] == "plugins") then
        local status,message = plugins.unload("./plugins/"..args[1]:match("%w+").."/init.lua")
        local embed = {
          description = message,
          color = discordia.Color.fromHex("ff5100").value,
        }
        if status then
          embed.fields = {
            {name = "Removed commands:",value =
              table.concat(plugin_data["plugins"][args[1]] or {},", ").." "
            }
          }
        end
        msg:reply({embed = embed})
      else
        msg:reply("TIME PARADOX")
      end
    end
  }),
  ["plugins"] = utilities.overwrite(generic_admin_template,{
    help = {embed = {
      title = "View all known plugins",
      description = [[This commmand prints info on loaded and unloaded plugins]],
      fields = {
        {name = "Usage:",value = "plugins"},
        {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
      }
    }},
    args = {},
    exec = function(msg,args,opts)
      local loaded_plugins = plugins.get()["plugins"]
      local all_plugins = get_plugin_folder()
      local unloaded_plugins = {}
      for k,v in pairs(all_plugins) do
        if not loaded_plugins[v] then
          table.insert(unloaded_plugins,v)
        end
      end
      if #unloaded_plugins == 0 then
        table.insert(unloaded_plugins," ")
      end
      msg:reply({embed={
        color = discordia.Color.fromHex("ff5100").value,
        fields = {
          {name = "Loaded plugins",value = concatenate_keys(loaded_plugins)},
          {name = "Unloaded plugins",value = "``"..table.concat(unloaded_plugins,"``,\n``").."``"}
        }
      }})
    end
  })
}
return segment
