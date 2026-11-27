test("passes a real Jest assertion", () => {
  expect(2 + 2).toBe(4);
});

test("reports a real Jest failure", () => {
  expect(2 + 2).toBe(5);
});
