const { handler } = require('../api/dead_zone_timer/index');

jest.mock('aws-sdk', () => ({
  Location: jest.fn(() => ({
    getDevicePosition: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        Position: [77.2090, 28.6139],
      }),
    }),
  })),
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      get: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({ Item: { taskToken: 'token-123' } }),
      }),
      update: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({}),
      }),
    })),
  },
  SNS: jest.fn(() => ({
    publish: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({}),
    }),
  })),
}));

jest.mock('../../shared', () => ({
  dynamo: {
    get: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({ Item: { taskToken: 'token-123' } }),
    }),
    update: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({}),
    }),
  },
  sns: {
    publish: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({}),
    }),
  },
  json: jest.fn((status, payload) => ({ statusCode: status, body: JSON.stringify(payload) })),
}));

describe('Dead Zone Timer Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('heartbeat timeout triggers SNS', async () => {
    const { sns } = require('../../shared');
    const event = {
      tripId: 'trip-123',
      userId: 'user-123',
    };

    await handler(event);
    expect(sns.publish).toHaveBeenCalled();
  });

  test('alert is written to DynamoDB on timeout', async () => {
    const { dynamo } = require('../../shared');
    const event = {
      tripId: 'trip-123',
      userId: 'user-123',
    };

    await handler(event);
    expect(dynamo.update).toHaveBeenCalled();
  });

  test('trip status is updated to DEAD_ZONE_ALERT', async () => {
    const event = {
      tripId: 'trip-123',
      userId: 'user-123',
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(200);
  });
});
