markov = require("markov")
json = require("json")
text = [[
A Markov chain is a mathematical system that experiences transitions from one state to another according to certain probabilistic rules. The defining characteristic of a Markov chain is that no matter how the process arrived at its present state, the possible future states are fixed. In other words, the probability of transitioning to any particular state is dependent solely on the current state and time elapsed. The state space, or set of all possible states, can be anything: letters, numbers, weather conditions, baseball scores, or stock performances.

Markov chains may be modeled by finite state machines, and random walks provide a prolific example of their usefulness in mathematics. They arise broadly in statistical and information-theoretical contexts and are widely employed in economics, game theory, queueing (communication) theory, genetics, and finance. While it is possible to discuss Markov chains with any size of state space, the initial theory and most applications are focused on cases with a finite (or countably infinite) number of states.

Many uses of Markov chains require proficiency with common matrix methods.
A Markov chain is a stochastic process, but it differs from a general stochastic process in that a Markov chain must be "memory-less." That is, (the probability of) future actions are not dependent upon the steps that led up to the present state. This is called the Markov property. While the theory of Markov chains is important precisely because so many "everyday" processes satisfy the Markov property, there are many common examples of stochastic properties that do not satisfy the Markov property.
A common probability question asks what the probability of getting a certain color ball is when selecting uniformly at random from a bag of multi-colored balls. It could also ask what the probability of the next ball is, and so on. In such a way, a stochastic process begins to exist with color for the random variable, and it does not satisfy the Markov property. Depending upon which balls are removed, the probability of getting a certain color ball later may be drastically different.
A variant of the same question asks once again for ball color, but it allows replacement each time a ball is drawn. Once again, this creates a stochastic process with color for the random variable. This process, however, does satisfy the Markov property. Can you figure out why?
In probability theory, the most immediate example is that of a time-homogeneous Markov chain, in which the probability of any state transition is independent of time. Such a process may be visualized with a labeled directed graph, for which the sum of the labels of any vertex's outgoing edges is 1.
In the language of conditional probability and random variables, a Markov chain is a sequence X0, X1, X2, …X_0, \, X_1, \, X_2, \, \dotsX0​,X1​,X2​,… of random variables satisfying the rule of conditional independence.
In other words, knowledge of the previous state is all that is necessary to determine the probability distribution of the current state. This definition is broader than the one explored above, as it allows for non-stationary transition probabilities and therefore time-inhomogeneous Markov chains; that is, as time goes on (steps increase), the probability of moving from one state to another may change.

]]
markov_instance = markov.new(text)
preset = io.open("new_preset.json","w")
a = markov_instance:save_state()
print(a)
preset:write(json.encode(a))
preset:close()
