local segment = {}
segment.help = [[
This plugin contains some miscellaneous features that didn't exactly fit on their own
]]
local markov = require("markov")
local markov_instance = markov.new()
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
	["markov"] = {
		help = gen_help("markov","Generate some text using markov chains","markov <text to start with>","--preset=<preset> - Select a text preset. Currently available: ``default``"),
		exec = function(msg,args,opts)
			local word = args[1]:match("%w+$")
			local preset,code,err = require("file").readJSON("./resources/"..(opts["preset"] or "default")..".json",{system_failed = true})
			if preset.system_failed then
				msg:reply("No such preset")
				return
			end
			markov_instance:load_state(preset)
			local output = markov_instance:run(word)
			msg:reply(args[1]:gsub(word.."$","",1)..output)
		end
	}
}

return segment
