segment = {}
local check_perms = require("check_perms")
local fake_server = {
  id = id
}
local file = require("file")
file.activate_json(require("json"))
local overlay = file.readJSON("./servers/"..id.."/overlay.json",{})
local cached_commands = {}
events:on("commandPoolUpdate",function()
  local commands = plugins.get()["commands"]
  for k,v in pairs(commands) do
    if not cached_commands[k] then
      if overlay[k] then
        if not v.perms then
          v.perms = {}
        end
        v.perms.users = overlay[k].users or v.perms.users
        v.perms.roles = overlay[k].roles or v.perms.roles
      end
      cached_commands[k] = true
    end
  end
  for k,v in pairs(cached_commands) do
    if not commands[k] then
      cached_commands[k] = nil
    end
  end
end)

events:on("serverSaveConfig",function()
  file.writeJSON("./servers/"..id.."/overlay.json",overlay)
end)

segment.commands = {
  ["rules"] = {
    args = {
      "string",
      "string",
    },
    perms = {
      perms = {
        "administrator"
      }
    }
    exec = function(msg,args,opts)
      local target,command = args[1],args[2]
      local commands = plugins.get()["commands"]
      if not commands[target] then
        msg:reply("Target command not found")
        return
      end
      local name = target
      target = commands[target]
      if command == "list" then
        local roles = "```"
        for k,v in pairs(target.perms.roles or {}) do
          roles = roles..((v > 0 and "allow ") or (v < 0 and "disallow "))..k.."\n"
        end
        roles = roles.." ```"
        local users = "```"
        for k,v in pairs(target.perms.users or {}) do
          users = users..((v > 0 and "allow ") or (v < 0 and "disallow "))..k.."\n"
        end
        users = users.." ```"
        msg:reply({embed={
          title = "Custom permissions for command ``"..name.."``",
          fields = {
            {name = "Roles",value = roles},
            {name = "Users",value = users}
          }
        }})
      else
        if not check_perms(fake_server,target,msg,require("discordia")) then
          msg:reply("You don't have a high enough permission to change rules for this command")
          return
        end
        local type,id = args[3],args[4]
        if not id then
          msg:reply("Type and ID are needed to create a proper rule")
        end
        if (type ~= "user") and (type ~= "role") then
          msg:reply("Type can only be ``user`` or ``role``")
        end
        id = id:match("%d+")
        local state = 0
        if command == "allow" then
          state = 1
        elseif command == "disallow" then
          state = -1
        elseif command == "reset" then
          state = nil
        end
        if not overlay[name] then
          overlay[name] = {}
          overlay[name].users = {}
          overlay[name].roles = {}
        end
        if not target.perms then
          target.perms = {}
        end
        if type == "user" then
          if not target.perms.users then
            target.perms.users = {}
          end
          target.perms.users[id] = state
          overlay[name].users[id] = state
        elseif type == "role" then
          if not target.perms.roles then
            target.perms.roles = {}
          end
          target.perms.roles[id] = state
          overlay[name].roles[id] = state
        end
        msg:reply("Changes applied.")
      end
    end
  }
}
return segment
