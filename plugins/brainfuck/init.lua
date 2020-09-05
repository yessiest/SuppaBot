local exbin = require("exbin")
local segment = {}
segment.help = "Runs brainfuck code and some of the extensions for it"
local settings = {
  tapesize = 30000,
  cellsize = 1,
  debug = true,
  limit = 500000
}
local lastExec
segment.commands = {
  ["brainfuck"] = {
    help = {embed = {
      title = "Run brainfuck code",
      description = "self-descriptive",
      color = discordia.Color.fromHex("#32cd32").value,
      fields = {
         {name = "Usage: ",value = "brainfuck <brainfuck code> [<input>]"},
         {name = "Perms: ",value = "all"},
      }
    }},
    args = {
      "string"
    },
    exec = function(msg,args,opts)
      settings.load_extensions = {}
      settings.path = "./lib/exbin/"
      lastExec = coroutine.wrap(function()
        local instance = exbin.new(args[1],settings)
        local result,opcount,err = instance:run(args[2] or "")
        if result == "" then
          result = ""
        end
        if not err then
          msg:reply({ embed = {
            title = "Result:",
            color = discordia.Color.fromHex("#32cd32").value,
            description = "```"..tostring(result).."```",
            footer = {
              text = "Finished in "..opcount.." operations"
            }
          }})
        else
          msg:reply({
            embed = {
              title = "Error:",
              description = "```"..tostring(err).."```",
              color = discordia.Color.fromHex("#32cd32").value,
            }
          })
        end
      end)
      lastExec()
    end
  }
}
return segment
