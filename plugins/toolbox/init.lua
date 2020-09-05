local segment = {}
segment.help = [[
This plugin contains some miscellaneous features that didn't exactly fit on their own
]]
local utilities = require("bot_utils")
math.randomseed(os.time()+os.clock())
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
segment.commands = {
	["flip"] = {
		help = gen_help("flip","Flips a coin, obv.","flip"),
		exec = function(msg,args,opts)
			local coin = math.random(1,100)%2
			if coin > 0 then
				msg:reply("Heads")
			else
				msg:reply("Tails")
			end
		end,
	},
	["dice"] = {
		help = gen_help("dice","Simulates a dice throw, prints the value of each die","dice <2d6,d30,d20+4,etc>"),
		exec = function(msg,args,opts)
			local random = math.random
			local out = {embed = {
				fields = {},
				footer = {
					text = 0
				}
			}}
			local list = {}
			msg.content:gsub(globals.prefix.."dice","",1):gsub("[^ ]+",
				function(capt)
					table.insert(list,capt)
				end)
			for k,v in pairs(list) do
				if v:find("d%d+") then
					for I = 1,(tonumber(v:match("(%d+)d%d+")) or 1) do
						local value = math.random(1,tonumber(v:match("d(%d+)")))
						if v:find("d%d+%+%d+") then
							value = value + tonumber(v:match("d%d+%+(%d+)"))
						end
						out.embed.fields[#out.embed.fields+1] = {name = "d"..v:match("d(%d+)"),value = value,  inline = true}
						out.embed.footer.text = out.embed.footer.text+value
						if I > 25 then
							break
						end
					end
				end
			end
			out.embed.footer.text = "Total: "..out.embed.footer.text
			msg:reply(out)
		end,
	},
	["cards"] = {
		help = gen_help("cards","Draw a specific amount of playing cards and display them","cards <amount>"),
		args = {"number"},
		exec = function(msg,args,opts)
			local out = {embed = {
				fields = {}
			}}
			local random = math.random
			for I = 1,(args[1] < 25 and args[1]) or 25 do
				local suits = {"spades","clubs","diamonds","hearts"}
				local values = {
					"A","1","2","3","4","5",
					"6","7","8","9","J","Q","K"
				}
				out.embed.fields[I] = {name = "card", value = " :"..suits[random(1,4)]..":"..values[random(1,11)].." ",inline = true}
			end
			msg:reply(out)
		end,
	},
	["speak"] = {
		help = gen_help("speak","Repeats the message, but suppresses the pings","speak <things>","-u, --unescape: remove escape sequences"),
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			local text = table.concat(args," "):gsub("@","\\@"):gsub("#","\\#")
			if opts["unescape"] or opts["u"] then
				text = text:gsub("\\","")
			end
			msg:reply(text)
			msg:delete()
		end,
	},
	["adminSpeak"] = {
		help = gen_help("speak","Repeats the message without suppressing pings (requires permission to ping everyone)","speak <things>","-u, --unescape: remove escape sequences"),
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
			local text = table.concat(args," "):gsub("@","\\@"):gsub("#","\\#")
			if opts["unescape"] or opts["u"] then
				text = text:gsub("\\","")
			end
			msg:reply(text)
		end,
	},
	["calculate"] = {
		help = gen_help("calculate","Calculate maths using lua's interpeter. Math functions from C included, use ``sin(x)`` or ``cos(x)`` for example","calculate <expression>"),
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			if segment.calculation_coroutine then
				segment.calculation_coroutine = nil
			end
			segment.calculation_coroutine = coroutine.wrap(function()
				local sandbox = {}
				for k,v in pairs(math) do
					sandbox[k] = v
				end
				local state,answer = pcall(load("return "..(table.concat(args," ") or ""),"calc",nil,setmetatable(sandbox,{})))
				if state then
					msg:reply(tostring(answer))
				else
					msg:reply("Syntax error")
				end
			end)
			segment.calculation_coroutine()
		end,
	},
	["pfp"] = {
		help = gen_help("pfp","Show the profile picture of a user, or if none is specified, of yourself","pfp <user or none>"),
		exec = function(msg,args,opts)
			local user = client:getUser((args[1] or ""):match("%d+"))
			if user then
				msg:reply(user:getAvatarURL())
			else
				msg:reply(msg.author:getAvatarURL())
			end
		end,
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
	}
}

return segment
