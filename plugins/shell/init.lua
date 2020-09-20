local segment = {}
local utils = require("bot_utils")
local emulate = require("emulate")({
  client = client,
  discordia = discordia
})
local json = require("json")
local file = require("file")
file.activate_json(json)
segment.help = "Metashell is a plugin designed to let you handle commands in batches, like a shell would"
--these will store things to be carried over sessions and objects that we'll output
local variables = file.readJSON("./servers/"..id.."/variables.json",{})
local scripts = file.readJSON("./servers/"..id.."/scripts.json",{})
local delay = discordia.Stopwatch()
--these will be used to store our new command environment and our shell
local env
local shell
--this stores the shell generator
function create_shell(msg)
  if (not shell) and env then
    events:on("print",function(thing)
      if delay:getTime():toSeconds() > 2 then
        msg:reply(thing)
        delay:reset()
      end
    end)
    local emulate_function = function(text) return env.sendAwait(msg,text) end
    local emulate_function_no_output = function(text) env.sendAwaitNoOutput(msg,text) end
    shell = require("shell")({
      emulate = emulate_function,
      emulateNoOutput = emulate_function_no_output,
      json = json
    })
  else
    if not env then
      error("Attempted to create a shell without an environment")
    end
  end
end

--this will load additional commands from the shell-addons directory
segment.plugins_path = "./plugins/shell/shell-addons/"
local internalCommands = {}
local plugin_list = {}
local ls = io.popen("ls -1 "..segment.plugins_path,"r")
ls:read("*a"):gsub("[^\n]+",function(capt) table.insert(plugin_list,capt) end)
ls:close()
for k,v in pairs(plugin_list) do
  local new_plugin_source = require("file").read(segment.plugins_path..v,"*a")
  local new_plugin,err = load(new_plugin_source,"Metashell Plugin",nil,setmetatable({
    client = client,
    discordia = discordia,
    utils = utils,
    require = require,
    embed = embed,
    output = output,
    events = events,
    globals = globals,
  },{__index = _G}))
  if new_plugin then
    local status,thing = pcall(new_plugin)
    if status then
      for k2,v2 in pairs(new_plugin()) do
        internalCommands[k2] = v2
      end
      log("DEBUG","Loaded metashell submodule "..v)
    else
      log("ERROR","Failed to load metashell submodule "..v..": "..thing)
    end
  else
    log("ERROR","Failed to load metashell submodule "..v..": "..err)
  end
end
--this function will reload the environment when commands are added
local function loadEnvironment()
  if env then
    env.destroy()
  end
  local command_pool = utils.overwrite(plugins.get()["commands"],internalCommands)
  env = emulate.generateEnv(command_pool,{
    id = id,
    config = globals
  })

end
--hook our environment loader to the events
events:on("serverLoaded",loadEnvironment)
events:on("commandPoolUpdate",loadEnvironment)
loadEnvironment()
segment.commands = {
  ["script"] = {
    help = {embed={
      title = "Add sh-like scripts",
      description = "For more information, see <link here> (ALLAN PLEASE ADD DETAILS)",
      fields = {
        {name = "Usage: ",value = "script ```<script>```"},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    args = {
      "string"
    },
    perms = {
      perms = {
        "Administrator"
      }
    },
    exec = function(msg,args,opts)
      create_shell(msg)
      local script = msg.content:match("```(.+)```")
      local meta = shell.parse_meta_properties(script)
      if not meta.name then
        msg:reply("You have to provide a name for the script with ``@name = `` metaproperty")
        return
      end
      scripts[meta.name] = {
        description = meta.description,
        author = msg.author.username,
        source = script
      }
      msg:reply("Script "..meta.name.." added successfully")
    end
  },
  ["script-remove"] = {
    help = {embed={
      title = "Remove a script",
      description = "For more information, see <link here> (ALLAN PLEASE ADD DETAILS)",
      fields = {
        {name = "Usage: ",value = "script-delete <name>"},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    perms = {
      perms = {
        "Administrator"
      }
    },
    args = {
      "string"
    },
    exec = function(msg,args,opts)
      if scripts[args[1]] then
        scripts[args[1]] = nil
        msg:reply("Script "..args[1].." deleted")
      else
        msg:reply("Script not found")
      end
    end
  },
  ["scripts"] = {
    help = {embed={
      title = "List all scripts",
      description = "For more information, see <link here> (ALLAN PLEASE ADD DETAILS)",
      fields = {
        {name = "Usage: ",value = "scripts"},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    perms = {
      perms = {
        "Administrator"
      }
    },
    exec = function(msg,args,opts)
      msg:reply({embed={
        title = "All scripts:",
        fields = (function()
          local output = {}
          for k,v in pairs(scripts) do
            table.insert(output,{
              name = k,
              value = "Source:```"..v.source.."```\nAuthor:"..v.author,
              inline = true
            })
          end
          return output
        end)()
      }})
    end
  }
}

events:on("messageCreate",function(msg)
  create_shell(msg)
  for k,v in pairs(scripts) do
    if (msg.content:find(k) == 1) and (msg.author.id ~= client.user.id) then
      local str = msg.content:gsub(k.." ","")
      local status,args = require("air").parse(str)
      local variables_and_arguments = utils.deepcopy(variables)
      for k,v in pairs(args) do
        variables_and_arguments[tostring(k)] = v
      end
      variables = shell.run(v.source,variables_and_arguments)
    end
  end
end)

events:on("serverSaveConfig",function()
  file.writeJSON("./servers/"..id.."/variables.json",variables)
  file.writeJSON("./servers/"..id.."/scripts.json",scripts)
end)

segment.unload = function()
  if env then
    env.destroy()
  end
end
return segment
