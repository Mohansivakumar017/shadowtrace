const request = require("supertest");
const app = require("../../app");

describe("Reroute API", () => {

  test("returns alternate route", async () => {

    const response = await request(app)
      .post("/reroute")
      .send({
        source: "A",
        destination: "B",
        risk: "HIGH"
      });

    expect(response.statusCode).toBe(200);

    expect(
      response.body.alternateRoute
    ).toBeDefined();

  });

});
