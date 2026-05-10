const AWS = require('aws-sdk');
const { dynamo, sns, json } = require('../../shared');

const location = new AWS.Location();

exports.handler = async (event) => {
  try {
    const tripId = event.tripId || event.detail?.tripId;
    const userId = event.userId || event.detail?.userId;

    if (!tripId || !userId) {
      return json(400, { error: 'tripId and userId required' });
    }

    const tripParams = {
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId },
    };

    const tripResult = await dynamo.get(tripParams).promise();
    if (!tripResult.Item) {
      return json(404, { error: 'Trip not found' });
    }

    const trip = tripResult.Item;

    try {
      const position = await location.getDevicePosition({
        TrackerName: 'shadowtrace-tracker',
        DeviceId: userId,
      }).promise();

      const lastLat = position.Position[1];
      const lastLng = position.Position[0];

      await sns.publish({
        TopicArn: process.env.SNS_TOPIC_ARN,
        Subject: 'ShadowTrace Dead Zone Alert',
        Message: JSON.stringify({
          event: 'DEAD_ZONE_TIMEOUT',
          userId,
          tripId,
          lastKnownLocation: { lat: lastLat, lng: lastLng },
          timestamp: new Date().toISOString(),
        }),
      }).promise();

      await dynamo.update({
        TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
        Key: { userId, tripId },
        UpdateExpression: 'SET #status = :status, updatedAt = :timestamp',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: { ':status': 'DEAD_ZONE_ALERT', ':timestamp': new Date().toISOString() },
      }).promise();

      return json(200, { message: 'Dead zone alert triggered' });
    } catch (locError) {
      if (locError.code === 'ResourceNotFoundException') {
        await sns.publish({
          TopicArn: process.env.SNS_TOPIC_ARN,
          Subject: 'ShadowTrace Dead Zone Alert - Device Not Found',
          Message: JSON.stringify({
            event: 'DEAD_ZONE_TIMEOUT',
            userId,
            tripId,
            message: 'Device position unavailable - user may be in dead zone',
            timestamp: new Date().toISOString(),
          }),
        }).promise();

        await dynamo.update({
          TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
          Key: { userId, tripId },
          UpdateExpression: 'SET #status = :status, updatedAt = :timestamp',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: { ':status': 'DEAD_ZONE_ALERT', ':timestamp': new Date().toISOString() },
        }).promise();

        return json(200, { message: 'Dead zone alert triggered (device not found)' });
      }
      throw locError;
    }
  } catch (error) {
    return json(500, { error: error.message || 'Dead zone timer failed' });
  }
};
