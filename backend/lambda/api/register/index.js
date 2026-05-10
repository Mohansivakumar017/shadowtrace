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

  const attrs = [];
  if (body.email) attrs.push({ Name: 'email', Value: body.email });
  if (body.phone) attrs.push({ Name: 'phone_number', Value: body.phone });

  try {
    const signUpResult = await cognito.signUp({
      ClientId: clientId,
      Username: username,
      Password: password,
      UserAttributes: attrs,
    }).promise();

    return json(200, {
      message: 'Registration successful',
      userSub: signUpResult.UserSub,
      userConfirmed: signUpResult.UserConfirmed,
    });
  } catch (error) {
    return json(400, { error: error.message || 'Registration failed' });
  }
};
