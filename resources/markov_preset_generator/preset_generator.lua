markov = require("markov")
json = require("json")
text = [[

]]
markov_instance = markov.new(text)
preset = io.open("new_preset.json","w")
a = markov_instance:save_state()
print(a)
preset:write(json.encode(a))
preset:close()
