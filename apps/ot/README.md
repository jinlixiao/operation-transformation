# OT

Processes running `OT.loop()` represents the real-time editors. To use them, create a `OT.client` associated with the respective editor. The client will be responsible for sending and receiving operations to and from the server. See `ot_test.exs` for examples.

## Files

### Codes

`lib/ot.ex` contains the main loop code for the realt-time editor, and also its client. It is responsible for sending and receiving operations to and from the server. It also handles the local state of the editor.

`lib/clock.ex` contains the code for the logical clock used by the real-time editor. It is responsible for generating timestamps for operations, and for merging timestamps from other editors.

`lib/op.ex` contains the code for operations. Operations are used to represent changes to the editor's state. They are sent to the server, and then applied to the local state of the editor.

`lib/transform.ex` contains the logic for transforming operations. Operations are transformed when they are received from the server, and when they are received from other editors.

### Test

`test/ot_test.exs` contains tests for the real-time editor. It uses the `OT.client` to simulate multiple editors, and tests that the operations are correctly sent and received.

`test/transform_test.exs` contains tests for the operation transformation logic. It checks whether several invariant properties hold for the transformation logic.

To run the test suite, run `mix test`.
