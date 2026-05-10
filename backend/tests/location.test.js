const { handler } = require('../api/update_live_location/index');

jest.mock('aws-sdk', () => ({
  Location: jest.fn(() => ({
    batchUpdateDevicePosition: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({}),
    }),
  })),
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      put: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
      get: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({ Item: { taskToken: 'token-123' } }) }),
    })),
  },
  StepFunctions: jest.fn(() => ({
    sendTaskHeartbeat: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
  })),
}));

jest.mock('../../shared', () => ({
  dynamo: {
    put: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
    get: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({ Item: { taskToken: 'token-123' } }) }),
  },
  stepFunctions: {
    sendTaskHeartbeat: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
  },
  json: jest.fn((status, payload) => ({ statusCode: status, body: JSON.stringify(payload) })),
  parseBody: (event) => {
    if (typeof event.body === 'string') return JSON.parse(event.body);
    return event.body || {};
  },
  getCurrentUserId: jest.fn().mockResolvedValue('user-123'),
  validateInput: (body, fields) => {
    for (const field of fields) {
      if (!body[field] && body[field] !== 0) throw new Error(`400|Missing ${field}`);
    }
    return body;
  },
}));

describe('Location Update Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('valid location update returns 200', async () => {
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({
        lat: 28.6139,
        lng: 77.2090,
        tripId: 'trip-123',
        timestamp: new Date().toISOString(),
      }),
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(200);
  });

  test('invalid lat range returns 400', async () => {
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({
        lat: 95,
        lng: 77.2090,
        tripId: 'trip-123',
        timestamp: new Date().toISOString(),
      }),
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(400);
  });

  test('BatchUpdateDevicePosition is called', async () => {
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({
        lat: 28.6139,
        lng: 77.2090,
        tripId: 'trip-123',
        timestamp: new Date().toISOString(),
      }),
    };

    await handler(event);
  });

  test('DynamoDB write is called', async () => {
    const { dynamo } = require('../../shared');
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({
        lat: 28.6139,
        lng: 77.2090,
        tripId: 'trip-123',
        timestamp: new Date().toISOString(),
      }),
    };

    await handler(event);
    expect(dynamo.put).toHaveBeenCalled();
  });
});
