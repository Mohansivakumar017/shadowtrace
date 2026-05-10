const { dynamo, sns, json } = require('../../shared');

exports.handler = async (event) => {
  try {
    const deviceId = event.detail?.DeviceId;
    const position = event.detail?.Position;

    if (!deviceId || !position) {
      return json(400, { error: 'DeviceId and Position required from geofence event' });
    }

    const tripsResult = await dynamo.query({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      IndexName: 'UserIdStatusIndex',
      KeyConditionExpression: 'userId = :userId AND #status = :status',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: { ':userId': deviceId, ':status': 'ACTIVE' },
      Limit: 1,
    }).promise();

    if (tripsResult.Items.length === 0) {
      return json(200, { message: 'No active trip found' });
    }

    const trip = tripsResult.Items[0];
    const userId = deviceId;

    const contactsResult = await dynamo.query({
      TableName: process.env.CONTACTS_TABLE || 'shadowtrace-contacts',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: { ':userId': userId },
    }).promise();

    const contacts = contactsResult.Items || [];

    if (contacts.length > 0) {
      const contactNames = contacts.map(c => c.name || 'Guardian').join(', ');
      const lat = position[1];
      const lng = position[0];

      await sns.publish({
        TopicArn: process.env.SNS_TOPIC_ARN,
        Subject: 'ShadowTrace Route Deviation Alert',
        Message: JSON.stringify({
          event: 'ROUTE_DEVIATION',
          userId,
          tripId: trip.tripId,
          contacts: contactNames,
          lastPosition: { lat, lng },
          message: `ROUTE DEVIATION: User has left their planned route. Last position: ${lat}, ${lng}`,
          timestamp: new Date().toISOString(),
        }),
      }).promise();
    }

    await dynamo.update({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId: trip.tripId },
      UpdateExpression: 'SET #status = :status, updatedAt = :timestamp',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: { ':status': 'DEVIATION', ':timestamp': new Date().toISOString() },
    }).promise();

    return json(200, { message: 'Route deviation alert dispatched' });
  } catch (error) {
    return json(500, { error: error.message || 'Alert dispatch failed' });
  }
};
