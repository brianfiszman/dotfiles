import { expect, test } from "vitest";

test("passes a real Vitest assertion", () => {
  expect(2 + 2).toBe(4);
});

test("reports a real Vitest failure", () => {
  expect(2 + 2).toBe(5);
});
