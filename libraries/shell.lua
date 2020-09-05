local bm = function(text,left_bracket,right_bracket,func)
  local output = " "..text
  local perform_magic = function(capture) return func(capture:sub(2,-2)) end
  while output:find("[^\\]"..right_bracket) and output:find("[^\\]"..left_bracket) do
    local pos = output:match(".*[^\\]"..left_bracket):len()
    output = output:sub(1,pos-1)..output:match(".*[^\\]("..left_bracket..".+)"):gsub(".-[^\\]"..right_bracket,perform_magic,1)
  end
  return output:sub(2,-1)
end


return function(args)
  assert(type(args) == "table", "No environment provided")
  local requesites = {
    emulate = true,
    emulateNoOutput = true,
    json = true,
  }
  for k,v in pairs(requesites) do
    if not args[k] then
      error("Module "..k.." not found, aborting")
    end
  end
  local preProcess = function(comm,vars,noemu)
    --replace %$%d (not escaped by a \\) with it's variable equivalent
    local comm = comm:gsub("([^\\]%$%w+)",function(pattern)
      local trail = pattern:match("([^\\])%$%w+")
      local value = vars[pattern:match("[^\\]%$(%w+)")]
      return trail..(value or "")
    end)
    --parse the { } as a command, result of which will substitute the brackets
    comm = bm(comm,"%(","%)",function(text)
      local output = args.emulate({content = text})
      if type(output) == "table" then
        output = json.encode(output)
      end
      return output or ""
    end)
    return comm or ""
  end
  return {
    parse_meta_properties = function(script)
      local output = {}
      --parse the metaproperties (eveything that looks like #<word> <everything until ;>)
      script:gsub("@(%w+) ?= ?(.-[^\\]);",function(k,v) output[k] = v end)
      return output
    end,
    run = function(script,variables)
      local variables = variables or {}
      local output = ""
      local complexoutput
      local commands = {}
      --remove meta properties
      script = script:gsub("@%w+ ? = ?.-[^\\];","")
      --split the rest into commands
      script = script:gsub("(.-[^\\];)",function(capt) table.insert(commands,capt); return "" end)
      for k,v in pairs(commands) do
        local currentCommand = v
        --match <word> = <whatever until>; as assignment of an execution result to a variable
        currentCommand = currentCommand:gsub("^[\n ]*(%w+) ?= ? (.-[^\\]);",function(var,comm)
          if var and comm then
            local comm = preProcess(comm,variables)
            variables[var] = comm
          end
          --we return nothing for the latter gsub not to run the command again
          return ""
        end)
        --match everything else as a standalone command
        currentCommand:gsub("^[\n ]*(.-[^\\]);",function(comm)
          if comm:match("^%s$") then
            return ""
          end
          local comm = preProcess(comm,variables)
          local out = args.emulate({content = comm})
          if type(out) == "table" then
            variables["?"] = json.encode(out)
          else
            variables["?"] = out
          end
        end)
      end
      return variables
    end
  }
end
