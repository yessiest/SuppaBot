local segment = {}
segment.name = "blahblahtestplugin"
segment.help = "This is a test plugin. All it does is show off some of the features of the new command system."
segment.commands = {
  ["test"] = {
      help = {embed = {
          title = "Test command",
          description = "Blah Blah Test Command. Adds two numbers together",
          fields = {
            {name = "Usage:",value = "test <number> <number>"},
            {name = "Perms:",value = "any"}
          }
      }},
      perms = {
        any = true
      },
      args = {
        "number",
        "number"
      },
      exec = function(msg)
        local n1,n2 = msg.content:match("(%d+) (%d+)")
        if n1 and n2 then
          msg:reply(n1+n2)
        end
      end,
  },
  ["testPerms"] = {
    help = {embed={
      title = "Test Admin Permissions",
      description = "Blah blah test admin descripton.",
      fields = {
        {name = "Usage:",value = "testPerms"},
        {name = "Perms:",value = "administrator"}
      }
    }},
    perms = {
      any = false,
      users = {
        ["245973168257368076"] = true
      },
      roles = {
        ["738377452262522881"] = true
      },
      perms = {
        "administrator"
      }
    },
    exec = function(msg)
      msg:reply("Yes, you are an admin or the Owner of this bot. Congrats")
    end,
  },
  ["shortForm"] = {
    exec = function(msg)
      msg:reply("yeeeeeeeeeeeeeeeeeeeeeeeeeeeee haw")
      --this is the shortest possible form of a command.
      --help is by default generated from args
      --args by default is set to none
      --perms is by default set to all
    end,
  }
}
segment.unload = function()
  print("Unloading package blahblahtestplugin")
end
return segment
