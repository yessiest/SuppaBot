--haha yes time to make cron in lua
local segment = {}
segment.help = "Add tasks to be executed later"
local file = require("file")
file.activate_json(require("json"))
local utils = require("bot_utils")
local emulate = require("emulate")({
  client = client,
  discordia = discordia
})
segment.name = "task"
local preload_tab = file.readJSON("./servers/"..id.."/crontab.json",{})
segment.tab = {}
globals.utc = globals.utc or 0
globals.utc_minutes = globals.utc_minutes or 0
segment.coroutines = {}

local function cronTime(time)
  if type(time) ~= "string" then
    return false
  end
  local mask = {60,24,32,13}
  local tokens = {}
  time:gsub("[%d%*]+",function(c) table.insert(tokens,c) end,4)
  for I = 1,4 do --check if date/time format matches
    if not ((tokens[I]:match("%d+") and tonumber(tokens[I]) < mask[I]) or ((tokens[I] == "*") and (I > 1)))  then
      err = true
    end
  end
  if not err then
    return tokens
  else
    return nil
  end
end

local function getLastMessageOf(channel,member)
  for k,v in pairs(client:getGuild(id):getChannel(channel).messages) do
    if v.member and v.member.id == member then
      return v
    else
      if not v.member then
        log("DEBUG","Picked an uncached message as a dupe candidate "..tostring(v.id))
        log("DEBUG",[[Here are some of its properties
id = ]]..tostring(v.id)..[[
member = ]]..tostring(v.member)..[[
content = ]]..tostring(v.content)..[[
        ]])
      end
    end
  end
end

local function addEventTask(task)
  if task.event and task.channel and task.member then
    task.coroutineID = math.random(1000000000,9999999999)
    while segment.coroutines[task.coroutineID] do
      task.coroutineID = math.random(1000000000,9999999999)
    end
    local taskID = #segment.tab+1
    segment.coroutines[task.coroutineID] = function(check,args)
      local check_func = ((type(check) == "function") and check) or (function() return true end)
      if (not task.args) or (type(task.args) == "table" and check_func(task.args)) then
        local content = task.task
        for k,v in pairs(args or {}) do
          content = content:gsub("%$"..k,tostring(v))
        end
        local dupeable = getLastMessageOf(task.channel,task.member)
        if not dupeable then
          log("ERROR","Failed to dupe a message properly")
          return nil
        end
        emulate.send(dupeable,{
          content = content,
          delete = function() end
        })
        if task.once then
          signals:removeListener(task.event,segment.coroutines[task.coroutineID])
          table.remove(segment.tab,taskID)
          segment.coroutines[task.coroutineID] = nil
        end
      end
    end
    signals:on(task.event,segment.coroutines[task.coroutineID])
    table.insert(segment.tab,task)
    return true
  else
    return false
  end
end

local function addTimeTask(task)
  if type(task.time) == "table" then
    table.insert(segment.tab,task)
    return true
  else
    return false
  end
end

for k,v in pairs(preload_tab) do
  if v.type == "event" then
    addEventTask(v)
  else
    addTimeTask(v)
  end
end

segment.commands = {
  ["task"] = {
    help = {embed = {
      title = "Add tasks",
      description = "Tasks are like cron tasks, in a sense that you specify when to execute them and what command to execute",
      fields = {
        {name = "Usage: ",value = "task (\"minute hour day month\" or @<event name> \"argument1\" \"argument2\") \"command\""},
        {name = "Perms: ",value = "Administrator"},
        {name = "Opts: ",value = [[
--description=\"description here\" - self-descriptive
--once - remove the task after completion
        ]]},
        {name = "Examples: ",value = [[
``task "5 10 * *" "]]..globals.prefix..[[speak hi"`` -- sends "hi" to the current channel at 10:05 every day every month
``task "5 10 15 *" "]]..globals.prefix..[[speak hi"`` -- sends "hi" to the current channel at 10:05 every 15th day of the month
``task --once  "5 10 15 *" "]]..globals.prefix..[[speak hi"`` -- same as before, except the task gets removed after sending the message
additional examples can be found at https://github.com/yessiest/SuppaBot/wiki/Tasks
        ]]}
      }
    }},
    perms = {
      perms = {
        "administrator"
      }
    },
    args = {
      "string",
      "string"
    },
    exec = function(msg,args,opts)
      local command = args[#args]
      if args[1]:match("^@%w+") then
        local event = args[1]:match("^@(%w+)")
        local conditions = utils.slice(args,2,#args-1)
        local status = addEventTask({
          type = "event",
          channel = tostring(msg.channel.id),
          member = tostring(msg.member.id),
          event = event,
          args = conditions,
          task = command,
          description = opts["description"] or "",
          once = opts["once"]
        })
        if status then
          msg:reply("Task "..(#segment.tab).." added")
        else
          msg:reply("Failed to add task")
        end
      elseif args[1]:match("^ ?%d+ [%d*]+ [%d*]+ [%d*]+ ?$") then
        local status = addTimeTask({
          type = "time",
          time = cronTime(args[1]:match("^ ?%d+ [%d*]+ [%d*]+ [%d*]+ ?$")),
          channel = tostring(msg.channel.id),
          member = tostring(msg.member.id),
          task = command,
          description = opts["description"] or "",
          once = opts["once"]
        })
        if status then
          msg:reply("Task "..(#segment.tab).." added")
        else
          msg:reply("Failed to add task")
        end
      else
        msg:reply("Syntax error")
      end
    end
  },
  ["tasks"] = {
    help = {embed = {
      title = "List all tasks",
      description = "Bold white text is conditions for the task, code block is the command to be executed",
      fields = {
        {name = "Usage: ",value = "tasks"},
        {name = "Perms: ",value = "Administrator"},
      }
    }},
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      msg:reply({embed = {
        title = "Tasks: ",
        fields = (function()
          local output = {}
          for k,v in pairs(segment.tab) do
            if v.type == "event" then
              table.insert(output,{
                name = tostring(k)..": @"..v.event.." "..table.concat(v.args," "),
                value = "```"..v.task.."```\n"..tostring(v.description),
                inline = true
              })
            elseif v.type == "time" then
              table.insert(output,{
                name = tostring(k)..": "..table.concat(v.time," "),
                value = "```"..v.task.."```\n"..tostring(v.description),
                inline = true
              })
            end
          end
          return output
        end)()
      }})
    end
  },
  ["task-remove"] = {
    help = {embed = {
      title = "Remove a task",
      description = "That one is self-descriptive",
      fields = {
        {name = "Usage: ",value = "remove-task <task id>"},
        {name = "Perms: ",value = "Administrator"},
      }
    }},
    perms = {
      perms = {
        "administrator"
      }
    },
    args = {
      "number"
    },
    exec = function(msg,args,opts)
      if segment.tab[args[1]] then
        local task = segment.tab[args[1]]
        if task.type == "event" then
          signals:removeListener(task.event,segment.coroutines[task.coroutineID])
          segment.coroutines[task.coroutineID] = nil
        end
        table.remove(segment.tab,args[2])
        msg:reply("Task "..args[1].." removed")
      else
        msg:reply("Task "..args[1].." not found")
      end
    end
  },
  ["utc"] = {
    help = {embed = {
      title = "Set the UTC time offset",
      description = "If your UTC time offset is x:45 or x:30 simply add \":30\" or \"45\" to the number accordingly",
      fields = {
        {name = "Usage: ",value = "utc <hour>[:<minute>]"},
        {name = "Perms: ",value = "Administrator"},
      }
    }},
    perms = {
      perms = {
        "administrator"
      }
    },
    args = {
      "string"
    },
    exec = function(msg,args,opts)
      if args[1]:match("^%d+$") then
        globals.utc = tonumber(args[1]:match("^(%d+)$"))
        msg:reply("UTC offset set")
      elseif args[1]:match("^%d+:%d+$") then
        globals.utc = tonumber(args[1]:match("^(%d+):%d+$"))
        globals.utc_minutes = tonumber(args[1]:match("^%d+:(%d+)$"))
        msg:reply("UTC offset set")
      else
        msg:reply("Invalid syntax")
      end
    end
  },
  ["time"] = {
    help = {embed = {
      title = "View the internal bot time",
      description = "If you've set a time offset previously, it will get accounted",
      fields = {
        {name = "Usage: ",value = "time"},
        {name = "Perms: ",value = "all"},
      }
    }},
    exec = function(msg,args,opts)
      local utc_time = os.date("%c",os.time()+(3600)*(globals.utc-4)+(60)*(globals.utc_minutes))
      msg:reply(utc_time)
    end
  }
}

segment.unload = function()
  for k,v in pairs(segment.tab) do
    if v.type == "event" then
      signals:removeListener(v.event,segment.coroutines[v.coroutineID])
      segment.coroutines[v.coroutineID] = nil
      segment.tab[k] = nil
    end
  end
end

local function check_time(date,crondate)
  local mask = {"min","hour","day","month"}
  local output = true
  for I = 1,4 do
    if not (tonumber(crondate[I]) == tonumber(date[mask[I]]) or crondate[I] == "*") then
      output = false
    end
  end
  return output
end

events:on("messageCreate",function(msg)
  signals:emit("message",function(args)
    local output = true
    if not args[1] then
      output = true
    elseif msg.content:find(args[1],1,true) then
      output = true
    else
      output = false
    end
    if output and (tostring(msg.author.id) == tostring(client.user.id)) then
      output = false
    end
    if output and (msg.emulated) then
      output = false
    end
    if output and (not args[2]) then
      output = true
    elseif output and (msg.author.name:find(args[2],1,true)) then
      output = true
    else
      output = false
    end
    return output
  end,{
    user = msg.author.id,
    content = msg.content,
    name = msg.author.name,
    ctxid = msg.id
  })
  return
end)

events:on("serverSaveConfig",function()
  file.writeJSON("./servers/"..id.."/crontab.json",segment.tab)
end)

events:on("clock",function()
  if tonumber(os.time())%60 == 30 then
      local utc_time = os.date("*t",os.time()+(3600)*(globals.utc-4)+(60)*(globals.utc_minutes))
      for k,v in pairs(segment.tab) do
        if (v.type == "time") and check_time(utc_time,v.time) then
          emulate_message = getLastMessageOf(v.channel,v.member)
          if emulate_message then
            emulate.send(emulate_message,{
              content = v.task,
              delete = function() end
            })
          else
            log("ERROR","There are no messages to dupe a new one from")
          end
          if v.once then
            table.remove(segment.tab,k)
          end
        end
      end
    end
end)

return segment
