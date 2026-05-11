const { dynamo, json, parseBody, getCurrentUserId, nowIso } = require('../shared');

exports.handler = async (event) => {
  const body = parseBody(event);
  const token = body.token;
  const userId = await getCurrentUserId(event);

  if (!token) {
    return json(400, { error: 'Missing token' });
  }

  const params = {
    TableName: process.env.DEVICE_TOKENS_TABLE || 'DeviceTokens',
    Item: {
      token: token,
      userId: userId,
      createdAt: nowIso(),
    },
  };

  try {
    await dynamo.put(params).promise();
    return json(200, { message: 'Token registered' });
  } catch (err) {
    console.error('Dynamo error', err);
    return json(500, { error: 'Internal error' });
  }
};
