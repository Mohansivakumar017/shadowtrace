const checkEtaAnomaly = require(
  "../../src/eta_check"
);

describe("ETA Monitoring", () => {

  test("detects abnormal delay", () => {

    const result = checkEtaAnomaly({
      expectedMinutes: 10,
      currentMinutes: 35
    });

    expect(result.alert).toBe(true);
  });

  test("accepts normal delay", () => {

    const result = checkEtaAnomaly({
      expectedMinutes: 10,
      currentMinutes: 12
    });

    expect(result.alert).toBe(false);
  });

});
