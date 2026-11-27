const assert = require("node:assert/strict");

describe("Mocha adapter", () => {
  it("passes a real Mocha assertion", () => {
    assert.equal(2 + 2, 4);
  });

  it("reports a real Mocha failure", () => {
    assert.equal(2 + 2, 5);
  });
});
