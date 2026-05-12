const classifyThreat = require(
  "../../src/ai_threat_classifier"
);

describe("Threat Classifier", () => {

  test("detects unsafe zone", () => {

    const result = classifyThreat({
      lighting: 1,
      crimeDensity: 10
    });

    expect(result.threat).toBe("HIGH");
  });

  test("detects safe environment", () => {

    const result = classifyThreat({
      lighting: 9,
      crimeDensity: 1
    });

    expect(result.threat).toBe("LOW");
  });

});
