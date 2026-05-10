const { cognito, json, parseBody } = require('../../shared');

exports.handler = async (event) => {
  const body = parseBody(event);
  const username = body.email || body.phone || body.username;
  const password = body.password;

  if (!username || !password) {
    return json(400, { error: 'username and password are required' });
  }

  const clientId = process.env.COGNITO_CLIENT_ID;
  if (!clientId) {
    return json(500, { error: 'COGNITO_CLIENT_ID is not configured' });
  }

  try {
    const authResult = await cognito.initiateAuth({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: clientId,
      AuthParameters: {
        USERNAME: username,
        PASSWORD: password,
      },
    }).promise();

    return json(200, {
      message: 'Login successful',
      tokens: authResult.AuthenticationResult || null,
    });
  } catch (error) {
    return json(401, { error: error.message || 'Authentication failed' });
  }
};
