const { dynamo, sns, json, parseBody, getCurrentUserId, nowIso, randomId } = require('../shared');

exports.handler = async (event) => {
  const body = parseBody(event);
  const userId = await getCurrentUserId(event);
  const incidentId = body.incidentId || randomId('incident');

  const incident = {
    incidentId,
    userId,
    type: body.type || 'SOS',
    status: 'OPEN',
    location: body.location || body.position || null,
    evidence: body.evidence || null,
    createdAt: nowIso(),
    updatedAt: nowIso(),
  };

  try {
    await dynamo.put({ TableName: process.env.INCIDENTS_TABLE || 'Incidents', Item: incident }).promise();

    if (process.env.SNS_TOPIC_ARN) {
      await sns.publish({
        TopicArn: process.env.SNS_TOPIC_ARN,
        Subject: 'ShadowTrace SOS',
        Message: JSON.stringify({ event: 'SOS_TRIGGERED', incident }),
      }).promise();
    }

    return json(200, { message: 'SOS processed', incident });
  } catch (error) {
    return json(500, { error: error.message || 'SOS processing failed' });
  }
};
