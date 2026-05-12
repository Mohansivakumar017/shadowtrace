const calculateRouteRisk = require(
  "../../src/route_calc"
);

describe("Route Risk Calculation", () => {

  test("returns HIGH risk for dangerous conditions", () => {

    const result = calculateRouteRisk({
      crimeRate: 9,
      weather: "storm",
      traffic: "low"
    });

    expect(result.level).toBe("HIGH");
  });

  test("returns LOW risk for safe route", () => {

    const result = calculateRouteRisk({
      crimeRate: 1,
      weather: "clear",
      traffic: "moderate"
    });

    expect(result.level).toBe("LOW");
  });

});
