const { sns, json, parseBody } = require('../../shared');

exports.handler = async (event) => {
  const body = parseBody(event);

  if (!process.env.SNS_TOPIC_ARN) {
    return json(500, { error: 'SNS_TOPIC_ARN is not configured' });
  }

  try {
    const message = {
      title: body.title || 'ShadowTrace Alert',
      body: body.body || '',
      userId: body.userId || null,
      data: body.data || {},
    };

    const result = await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: message.title,
      Message: JSON.stringify(message),
    }).promise();

    return json(200, { message: 'Notification published', messageId: result.MessageId });
  } catch (error) {
    return json(500, { error: error.message || 'Unable to publish notification' });
  }
};
