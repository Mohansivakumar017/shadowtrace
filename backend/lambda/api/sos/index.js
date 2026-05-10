const { dynamo, sns, stepFunctions, json, parseBody, getCurrentUserId, validateInput, nowIso, randomId } = require('../../shared');

exports.handler = async (event) => {
  try {
    const body = parseBody(event);
    const userId = await getCurrentUserId(event);

    validateInput(body, ['lat', 'lng']);

    const alertId = randomId('alert');
    const timestamp = nowIso();

    const alert = {
      alertId,
      userId,
      lat: parseFloat(body.lat),
      lng: parseFloat(body.lng),
      timestamp,
      status: 'ACTIVE',
    };

    await dynamo.put({
      TableName: process.env.ALERTS_TABLE || 'shadowtrace-alerts',
      Item: alert,
    }).promise();

    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: 'ShadowTrace SOS Alert',
      Message: JSON.stringify({
        event: 'SOS_TRIGGERED',
        userId,
        alertId,
        lastKnownLocation: { lat: alert.lat, lng: alert.lng },
        timestamp,
      }),
    }).promise();

    const workflowInput = JSON.stringify({
      userId,
      alertId,
      lat: alert.lat,
      lng: alert.lng,
    });

    const execution = await stepFunctions.startExecution({
      stateMachineArn: process.env.EMERGENCY_WORKFLOW_ARN,
      input: workflowInput,
    }).promise();

    return json(200, { alertId, executionArn: execution.executionArn });
  } catch (error) {
    if (error.message.startsWith('401|')) {
      return json(401, { error: error.message.replace('401|', '') });
    }
    if (error.message.startsWith('400|')) {
      return json(400, { error: error.message.replace('400|', '') });
    }
    return json(500, { error: error.message || 'SOS processing failed' });
  }
};

