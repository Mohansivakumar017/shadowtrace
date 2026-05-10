const https = require('https');
const { json, parseBody } = require('../../shared');

function callOpenAI(apiKey, messages) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages,
      temperature: 0.3,
    });

    const req = https.request({
      hostname: 'api.openai.com',
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

exports.handler = async (event) => {
  const body = parseBody(event);
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    return json(500, { error: 'OPENAI_API_KEY is not configured' });
  }

  try {
    const messageList = Array.isArray(body.messages) && body.messages.length > 0
      ? body.messages
      : body.prompt
        ? [{ role: 'user', content: body.prompt }]
        : [];

    const response = await callOpenAI(apiKey, [
      {
        role: 'system',
        content: 'You are ShadowTrace AI. Provide concise, safety-focused advice and emergency guidance.',
      },
      ...messageList,
    ]);

    const content = response?.choices?.[0]?.message?.content || '';
    return json(200, { reply: content, raw: response });
  } catch (error) {
    return json(500, { error: error.message || 'AI request failed' });
  }
};
