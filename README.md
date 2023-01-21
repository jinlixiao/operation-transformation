# Operation Transformation

This project emulates the REDUCE (REal-time Distributed Unconstrained Cooperative Editing) and GOT (Generic Operational Transformation) approach proposed by C. Sun et al. [1] and C. Sun et al. [2] in Elixir.

In short, we simulates isolated document editors that support insert and delete characters at specified index. The code is able to handle concurrent insert and delete operations, and to resolve conflicts between them.

We used Elixir to implement isolated processes, with the Emulation package provided in [Distributed Systems course](https://cs.nyu.edu/~apanda/classes/fa22/). The Emulation package is a wrapper around Erlang’s distributed Erlang, which provides a simple interface for sending and receiving messages.

## Assumption

For the purpose of this project, we assume a synchronous network where no messages would be lost, and the messages sent from the same source to the same destination are received in the order they are sent.

Moreover, for simplicity, the scale of the system should be small. So we mostly use the O(N) algorithms to actually commit (insert, delete) transactions into the document. We also do not use rope, an efficient data structure for implementing text editing features, while our implementation can be easily extended into such a method.

Our goal is to simulate a distributed editor consisting of several isolated processes. The document supports the following operations:

- `insert(c, i)`: insert the character `c` at index `i`
- `delete(i)`: delete the character at index `i`

## Correctness Criteria

The method chosen is also based on one very important requirement: high availability of the local system. When a user wants to do some operation locally, it must be executed immediately instead of waiting for a prerequisite to be met from other processes. This is mainly concerning that the document itself could be very distributed across a wide range of regions, so each process is similar to a local leader participating in the multi-leader system.

We also want to guarantee the three following consistency criterias:

- _Eventual Consistency_: the document is eventually consistent, i.e., all the editors will eventually have the same document.
- _Causality Preservation_: the order of operations is preserved, i.e., if an operation O1 is executed before an operation O2, then O1 will be executed before O2 at all sites.
- _Intention Preservation_: for any operation, the effect of executing it at all sites is the same as the intention of the operation; and the effect of executing it does not change the effects of independent operation. More specific definition can be seen below.

## Intention Preservation Verification Criteria

The effect of an operation is a subject term that depends on the application. The specific transformation functions are usually dependent on the specification. For our purposes, the exact verification criteria for intention-preservation for `insert` and `delete` operations can be specified as below.

For insertions, denote the original operation by `o = insert(c, i)` and the transformed operation by `o’ = insert(c’, i’)`. Then it must satisfy that

- `c = c’`, which means that the character inserted should appear in (1) the document after the execution of `o’` and (2) the document state after all independent operations of o.
- For any character `s` exists both in the document state when o is generated and when o’ is about to be executed, if `s` is at the left/right side of the index `i` when o is generated, then `s` must be at the left/right side of the index `i’` when `o’` is about to be executed.

For deletions, denote the original operation by `o = delete(i)` and the transformed operation by `o’ = delete(i’)` or identity. Then it must satisfy that

- The character at index `i` in the document state when o is generated must disappear in (1) the document after the execution of o’ and (2) the document state after all independent operations of o.
- If o’ is not identity, then for any character `s` exists both in the document state when o is generated and when o’ is about to be executed, if `s` is at the left/right side of the index `i` when o is generated, then `s` must be at the left/right side of the index `i’` when `o’` is about to be executed.

These criteria ensure that effects of independent operations would not interfere with each other. Specifically

- A delete operation would not delete any characters inserted by independent operations.
- If multiple delete operations specify the intention to delete the same character, then the combined effect would only delete that character once.
- If multiple independent insert operations insert characters at the same index, then all characters would appear in the document state as if they were inserted according to some (undefined) total order.

## Implementation for Reaching Consistency

The codes for the mock editor are in the `apps/ot` directory.

Notice that the three consistency criteria that we have stated in the previous section can be satisfied in order.

### Causal Consistency

Every site maintains an initially zero state vector. The i-th index of the state vector of site d represents the number of operations originated at site i that have been executed by site d.

We associate every operation O with (1) the site of its generation and (2) the site’s current state vector. Using the state vector at operations’ generation (timestamp), we are able to determine their causal order.

A site d is causally ready to execute an operation O originated at site s only if (1) the SV of d is at least up-to-date as site s when O is generated (element-wise $\geq$ in SV) and (2) site d hasn’t executed O before. Notice that this definition allows an operation to be executed at its local site immediately. In our code, we defer a causally not-ready operation by redirecting the message to itself.

### Eventually Consistency

To ensure convergence in the presence of allowing different execution orders of independent operations, we define a total order. We can compare two causally independent operations by the sum of the timestamp, and then the identifier of the site.

Then we make sure that each site executes the operation in the same total order. Because we specified that we immediately execute a causally ready operation, we can undo-redo operations. Whenever we receive an operation from another site that is causally ready but is out of total order, we undo all operations in the history that are totally before this operation, do this operation, and redo the undo operations.

### Intention Preservation

In order to satisfy the intention verification criteria that we stated above, we need to use operational transformation to make sure that every operation is executed in its appropriate context. Notice that the intention-preservation problem cannot be solved by a serialization protocol.

We defined operational transformation functions ([`transform.ex`](https://github.com/jinlixiao/operation-transformation/blob/main/apps/ot/lib/transform.ex)) according to our criteria. Notice that the paper we referenced used a different editor grammar than outs, so our transformation functions are different.

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
