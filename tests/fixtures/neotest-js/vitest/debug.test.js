import { expect, test } from "vitest";

test("runs through the real JavaScript debugger", () => {
  const debugTestMarker = "neotest-vitest-breakpoint-reached";
  expect(debugTestMarker).toBe("neotest-vitest-breakpoint-reached");
});
