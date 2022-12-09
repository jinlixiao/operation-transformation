# Final Project: Operation Transformation
The goal is to emulate the REDUCE approach proposed by C. Sun et al. 

Use Elixir to implement isolated processes, with the Emulation package provided in class. 

Goal: 
* create isolated document editors that support insert and delete characters at specified index
* to provide reasonable user experience, we require that any local operation must be executed immediately to be reflected in the document (so the raft approach is not possible)
* CCI model should be used: we need convergence, causality-preservation, and international-preservation
* [Bonus]: enable range editing (such as highlighting, underlining, etc.)

Assumption: 
* synchronous network; no messages is lost, but they might not be receive in order
* for simplicity, the scale of the system is small, and we use O(N) methods to insert and delete characters. (this could be improved using rope, but we are not doing this here)
