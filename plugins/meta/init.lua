segment = {}
segment.help = "This is a set of commands that add some features specific to this bot"

local emulate = require("emulate")({
  client = client,
  discordia = discordia,
})
local map = {}
local last_message_arrived = discordia.Stopwatch()
local utils = require("bot_utils")

client:on("messageCreate",function(msg)
  last_message_arrived:reset()
  last_message_arrived:start()
end)

local function add_alias(name,command,preix)
  if (not map[name]) then
    if type(prefix) == "nil" then
      prefix = true
    end
    map[name] = {comm = command,prefix = prefix}
    plugins.add_command(name,{
      help  = {embed = {
        title = "hmmmm"
      }},
      exec = function(msg,args2,opts)
        local str = msg.content:gsub(name.." ","")
        aftersub = command:gsub("%.%.%.",str)
        aftersub = aftersub:gsub("%$prefix",globals.prefix)
        local status,args = require("air").parse(str)
        for k,v in pairs(args) do
          aftersub = aftersub:gsub("([^\\])%$"..k,"%1"..v)
        end
        emulate.send(msg,{
          content = aftersub
        })
      end,
      noprefix = prefix,
    })
    return true
  else
    return false
  end
end

local function remove_alias(name)
  if map[name] then
    map[name] = nil
    plugins.remove_command(name)
    return true
  else
    return false
  end
end

local function gen_help(title,description,usage,opts)
	return {embed = {
		title = title,
		description = description,
		fields = {
			{name = "Usage:",value=globals.prefix..usage},
			{name = "Perms:",value="all"},
			(opts and {name = "Opts:",value = opts})
		}
	}}
end

local function purify_strings(msg,input)
  local text = input
  while text:match("<@(%D*)(%d*)>") do
    local obj,id = text:match("<@(%D*)(%d*)>")
    local substitution = ""
    if obj:match("!") then
      local member = msg.guild:getMember(id)
      if member then
        substitution = "@"..member.name
      end
    elseif obj:match("&") then
      local role = msg.guild:getRole(id)
      if role then
        substitution = "@"..role.name
      end
    end
    if substitution == "" then
      substitution = "<\\@"..obj..id..">"
    end
    text = text:gsub("<@(%D*)"..id..">",substitution)
  end
  return text
end

for k,v in pairs(require("file").readJSON("./servers/"..id.."/aliasmap.json",{})) do
  commdata = v
  if type(v) == "string" then --legacy format conversion
    commdata = {comm = v, prefix = false}
  end
  add_alias(k,commdata.comm,commdata.prefix)
end

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
``alias !say "]]..globals.prefix..[[speak $1"`` - reply to !hi with the first argument sent along with !hi
More at https://github.com/yessiest/SuppaBot/wiki/Tasks]]
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
      if add_command(args[1],args[2],(opts["prefix"] or opts["p"])) then
        msg:reply("Bound ``"..args[1].."`` as an alias to ``"..args[2].."``")
      else
        msg:reply("``"..args[1].."`` is already bound")
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
      if remove_alias(args[1]) then
        msg:reply("Removed the ``"..args[1].."`` alias")
      else
        msg:reply("No such alias")
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
  },
  ["about"] = {
    help = {embed = {
      title = "View bot info",
      description = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "about"},
        {name = "Perms: ",value = "all"}
      }
    }},
    exec = function(msg,args,opts)
      local rand = math.random
      local author = client:getUser("245973168257368076")
      msg:reply({embed = {
        title = "About Suppa-Bot",
        thumbnail = {
          url = client.user:getAvatarURL()
        },
        color = discordia.Color.fromRGB(rand(50,200),rand(50,200),rand(50,200)).value,
        description = "Suppa-Bot is an open-source bot written in Lua.",
        fields = {
          {name = "Source Code: ",value = "https://github.com/yessiest/SuppaBot"},
          {name = "Author: ",value = author.tag},
          {name = "Invite: ",value = "Not available yet"}
        }
      }})
    end
  },
  ["server"] = {
    help = gen_help("server","Show server stats in a form of embed","server"),
    exec = function(msg,args,opts)
      msg:reply({embed = {
        thumbnail = {
          url = msg.guild.iconURL
        },
        title = msg.guild.name,
        description = msg.guild.description,
        fields = {
          {name = "Members",value = msg.guild.totalMemberCount,inline = true},
          {name = "Owner",value = (msg.guild.owner and msg.guild.owner.user.tag..":"..msg.guild.owner.user.id),inline = true},
          {name = "Created At",value = os.date("!%c",msg.guild.createdAt).." (UTC+0)",inline = true},
          {name = "Text Channels",value = msg.guild.textChannels:count(),inline = true},
          {name = "Voice Channels",value = msg.guild.voiceChannels:count(),inline = true}
        }
      }})
    end,
  },
  ["user"] = {
    help = gen_help("user","View user stats","user <user or none>"),
    exec = function(msg,args,opts)
      local member = msg.guild:getMember((args[1] or ""):match("%d+")) or msg.guild:getMember(msg.author.id)
      local roles = ""
      for k,v in pairs(member.roles) do
        roles = roles..v.mentionString.."\n"
      end
      msg:reply({embed = {
        title = member.user.tag..":"..member.user.id,
        thumbnail = {
          url = member.user:getAvatarURL()
        },
        fields = {
          {name = "Profile Created At",value = os.date("!%c",member.user.createdAt).." (UTC+0)"},
          {name = "Joined At",value = os.date("!%c",discordia.Date.fromISO(member.joinedAt):toSeconds()).." (UTC+0)",inline = true},
          {name = "Boosting",value = ((member.premiumSince and "Since "..member.premiumSince) or "No"),inline = true},
          {name = "Highest Role",value = member.highestRole.mentionString,inline = true},
          {name = "Roles",value = roles,inline = true}
        }
      }})
    end,
  },
	["speak"] = {
		help = gen_help("speak","Repeats the message, but suppresses the pings","speak <things>","-u, --unescape: remove escape sequences"),
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			local text = purify_strings(msg, table.concat(args," "))
			if opts["unescape"] or opts["u"] then
				text = text:gsub("\\","")
			end
			msg:reply(text)
			msg:delete()
		end,
	},
	["adminSpeak"] = {
		help = gen_help("adminSpeak","Repeats the message without suppressing pings (requires permission to ping everyone)","speak <things>","-u, --unescape: remove escape sequences"),
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			local text = table.concat(args," ")
			if opts["unescape"] or opts["u"] then
				text = text:gsub("\\","")
			end
			msg:reply(text)
			msg:delete()
		end,
		perms = {
			perms = {
				"mentionEveryone"
			}
		}
  },
  ["echo"] = {
    help = gen_help("echo","Repeats the message, but suppresses the pings","speak <things>","-u, --unescape: remove escape sequences"),
    args = {
      "string"
    },
    exec = function(msg,args,opts)
      local text = purify_strings(msg, table.concat(args," "))
      if opts["unescape"] or opts["u"] then
        text = text:gsub("\\","")
      end
      msg:reply(text)
    end,
  },
}

segment.unload = function()
  for k,v in pairs(map) do
    remove_alias(k)
  end
end

events:on("serverSaveConfig",function()
  require("file").writeJSON("./servers/"..id.."/aliasmap.json",map)
end)

return segment
