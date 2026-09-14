# Choose test doubles

Prefer real collaborators when they are fast, deterministic, and easy to isolate. Use fakes or mocks
when a dependency would introduce external side effects, nondeterminism, excessive cost, or a failure
that is difficult to reproduce.

Common boundaries are external APIs, clocks, randomness, filesystem access, and databases. A test
database is valuable when SQL, constraints, or transactions are part of the behavior being verified;
a database mock cannot establish those guarantees.

Internal collaborators can also be doubled when they expose a stable contract and the test targets
a different responsibility. Avoid mocks that recreate private implementation structure or bypass
the very behavior under test.

## Design for controllable dependencies

Reuse the repository's injection or adapter conventions. Pass an external dependency explicitly
when that makes behavior controllable without adding an unnecessary abstraction:

```typescript
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}
```

Operation-specific adapters can make tests clearer than a generic fetch mock with many branches.
Use an existing SDK or adapter first. Keep a generic transport when HTTP behavior is the contract;
do not introduce a new SDK solely to satisfy a testing style rule.

Configure doubles for the scenario and assert the observable result. Verify an interaction only
when it is part of the requirement, such as sending one payment request despite repeated clicks.
