const { handler } = require('../api/sos/index');

jest.mock('../../shared', () => ({
  dynamo: {
    put: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
  },
  sns: {
    publish: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({}) }),
  },
  stepFunctions: {
    startExecution: jest.fn().mockReturnValue({ promise: jest.fn().mockResolvedValue({ executionArn: 'arn:aws:states:...' }) }),
  },
  json: jest.fn((status, payload) => ({ statusCode: status, body: JSON.stringify(payload) })),
  parseBody: (event) => {
    if (typeof event.body === 'string') return JSON.parse(event.body);
    return event.body || {};
  },
  getCurrentUserId: jest.fn().mockResolvedValue('user-123'),
  validateInput: (body, fields) => {
    for (const field of fields) {
      if (!body[field]) throw new Error(`400|Missing ${field}`);
    }
    return body;
  },
  nowIso: () => new Date().toISOString(),
  randomId: (prefix) => `${prefix}-test-id`,
}));

describe('SOS Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('valid SOS returns 200 and alertId', async () => {
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({ lat: 28.6139, lng: 77.2090 }),
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toHaveProperty('alertId');
  });

  test('missing lat returns 400', async () => {
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({ lng: 77.2090 }),
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(400);
  });

  test('missing JWT returns 401', async () => {
    const { getCurrentUserId } = require('../../shared');
    getCurrentUserId.mockRejectedValueOnce(new Error('401|Missing authorization header'));

    const event = {
      headers: {},
      body: JSON.stringify({ lat: 28.6139, lng: 77.2090 }),
    };

    const response = await handler(event);
    expect(response.statusCode).toBe(401);
  });

  test('SNS publish is called', async () => {
    const { sns } = require('../../shared');
    const event = {
      headers: { authorization: 'Bearer token' },
      body: JSON.stringify({ lat: 28.6139, lng: 77.2090 }),
    };

    await handler(event);
    expect(sns.publish).toHaveBeenCalled();
  });
});
