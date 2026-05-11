const { dynamo, json, parseBody, getCurrentUserId, nowIso, randomId } = require('../../shared');

exports.handler = async (event) => {
  const body = parseBody(event);
  const userId = getCurrentUserId(event);
  const incidentId = body.incidentId || randomId('incident');

  const incident = {
    incidentId,
    userId,
    type: body.type || 'GENERAL',
    status: body.status || 'OPEN',
    location: body.location || null,
    details: body.details || body.description || null,
    attachments: body.attachments || [],
    createdAt: body.createdAt || nowIso(),
    updatedAt: nowIso(),
  };

  try {
    await dynamo.put({ TableName: process.env.INCIDENTS_TABLE || 'Incidents', Item: incident }).promise();
    return json(200, { message: 'Incident saved', incident });
  } catch (error) {
    return json(500, { error: error.message || 'Unable to save incident' });
  }
};
