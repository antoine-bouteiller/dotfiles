# Useful tests

Choose assertions that would fail for a plausible wrong implementation of the required behavior.
A stable public or module interface is usually the best boundary; "public" means a contract relevant
to this test, not necessarily a user-facing endpoint.

```typescript
test("created user can be retrieved", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

Keep each test focused on one behavior. Multiple assertions are useful when they establish one
outcome, such as both a response and the absence of a duplicate charge.

## Choose evidence for the contract

- Prefer returned values or observable state for ordinary behavior.
- Inspect persisted rows when the contract is storage layout, a migration, or transaction behavior.
  A read API can hide a persistence bug through caching or normalization.
- Assert calls, counts, or ordering when the interaction is the contract, such as charging once or
  committing before emitting an event. Avoid asserting incidental helper calls.
- Test a private algorithm through its owning interface where practical. If a stable module boundary
  is the actual unit of behavior, test there without exposing internals solely for a test.

A test is coupled to implementation when a behavior-preserving refactor breaks its assertions.
Inspect whether mocks or fixtures bypass the path whose correctness the test is meant to establish.

## Keep expected results independent

Duplicating production logic in an assertion can reproduce the same mistake:

```typescript
// Weak oracle: the implementation may contain this same reduction bug.
const expected = items.reduce((sum, item) => sum + item.price, 0);
expect(calculateTotal(items)).toBe(expected);

// Independent example with a known result.
expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
```

A duplicated calculation is not necessarily guaranteed to pass, but it adds less independent
evidence. Worked examples, trusted reference implementations, and meaningful properties are all
valid oracles. Do not replace useful property-based tests with literals merely to match this example.
