# Final Project: Operation Transformation

The goal is to emulate the REDUCE (REal-time Distributed Unconstrained Cooperative Editing) and GOT (Generic Operational Transformation) approach proposed by C. Sun et al. [1] and C. Sun et al. [2] in Elixir.

Use Elixir to implement isolated processes, with the Emulation package provided in Distributed Systems course. The Emulation package is a wrapper around Erlang’s distributed Erlang, which provides a simple interface for sending and receiving messages.

## Goal

- create isolated document editors that support insert and delete characters at specified index
- to provide reasonable user experience, we require that any local operation must be executed immediately to be reflected in the document (so the raft approach is not possible)
- CCI model should be used: we need convergence, causality-preservation, and international-preservation
- [Bonus]: enable range editing (such as highlighting, underlining, etc.)

## Assumption

- synchronous network; no messages is lost, but they might not be receive in order
- for simplicity, the scale of the system is small, and we use O(N) methods to insert and delete characters. (this could be improved using rope, but we are not doing this here)

## Design

The codes for the mock editor are in the `apps/ot` directory.

### The State Vector and the concept of time

Every site maintains an initially zero state vector. The i-th index of the state vector of site d represents the number of operations originated at site i that have been executed by site d.

We associate every operation O with (1) the site of its generation and (2) the site’s current state vector.

Using the state vector at operations’ generation (timestamp), we are able to determine the causal order of them.

A site d is causally ready to execute an operation O originated at site s only if (1) the SV of d is at least up-to-date as site s when O is generated (element-wise >= in SV) and (2) site d haven’t executed O before. Notice that this definition allows an operation to be executed at its local site immediately.

Furthermore, to ensure convergence in the presence of allowing different execution orders of independent operations, we have to define a total order. We can compare two operations by the sum of the timestamp, and then the identifier of the site.

### History Buffer

The history buffer is used to store the operations that have been executed at the local site. It is used to ensure that an operation is not executed twice. The history buffer is a list of operations ordered by the total order.

### The operation transformation

The operation transformation is the core of the algorithm. It is used to transform the operations so that they can be executed in the same order at different sites.

## Testing

The test package is provided in the `apps/ot/tests` directory. To run the test, use the following command:

```bash
mix test
```

## References

[1] Sun, C., Jia, X., Zhang, Y., Yang, Y., & Chen, D. (1998). Achieving convergence, causality preservation, and intention preservation in real-time cooperative editing systems. ACM Transactions on Computer-Human Interaction (TOCHI), 5(1), 63-108.

[2] Sun, C., & Ellis, C. (1998, November). Operational transformation in real-time group editors: issues, algorithms, and achievements. In Proceedings of the 1998 ACM conference on Computer supported cooperative work (pp. 59-68).

[3] Laddad, S., Power, C., Milano, M., Cheung, A., & Hellerstein, J. M. (2022). Katara: synthesizing CRDTs with verified lifting. Proceedings of the ACM on Programming Languages, 6(OOPSLA2), 1349-1377.

[4] Zagorskii, A. (2022, June 25). Operational transformations as an algorithm for automatic conflict resolution. Medium. Retrieved December 14, 2022, from https://medium.com/coinmonks/operational-transformations-as-an-algorithm-for-automatic-conflict-resolution-3bf8920ea447
