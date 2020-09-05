return {
  ["select"] = {
    help = "Select an item out of a list of arguments. Usage: <number> <argument1> <argument2> ... <argument N>",
    exec = function(msg,args,opts)
      local err,out = nil,""
      if (#args > 1) and tonumber(args[1]) then
        if not args[args[1]+1] then
          err = "Argument "..args[1].." doesnt exist"
        else
          out = args[args[1]+1]
        end
      else
        if tonumber(args[1]) == nil then
          err = "Argument 1 is not a number"
        elseif tonumber(args[1]) < 1 then
          err = "Argument 1 is less than 1"
        else
          err = "Not enough arguments"
        end
      end
      if err then
        events:emit("print","Select error: "..err)
      end
      msg:reply(out)
    end
  },
  ["count"] = {
    help = "Count all arguments passed to this command. Usage: <arg1>, <arg2> ... <arg N>",
    exec = function(msg,args,opts)
      msg:reply(#args)
    end
  },
  ["seq"] = {
    help = "Create a list of arguments with numbers, from X to Y",
    args = {
      "number",
      "number"
    },
    exec = function(msg,args,opts)
      out = args[1]
      for I = args[1]+1,args[2] do
        out = out.." "..I
      end
      msg:reply(out)
    end
  }
}
