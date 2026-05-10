const AWS = require('aws-sdk');
const { dynamo, stepFunctions, json, parseBody, getCurrentUserId, validateInput, nowIso } = require('../../shared');

const location = new AWS.Location();

exports.handler = async (event) => {
  try {
    const body = parseBody(event);
    const userId = await getCurrentUserId(event);

    validateInput(body, ['lat', 'lng', 'tripId', 'timestamp']);

    const lat = parseFloat(body.lat);
    const lng = parseFloat(body.lng);
    const tripId = body.tripId;
    const timestamp = body.timestamp;

    await location.batchUpdateDevicePosition({
      TrackerName: 'shadowtrace-tracker',
      Updates: [
        {
          DeviceId: userId,
          Position: [lng, lat],
          Timestamp: new Date(timestamp),
        },
      ],
    }).promise();

    const locationRecord = {
      tripId,
      timestamp,
      userId,
      lat,
      lng,
      speed: body.speed ? parseFloat(body.speed) : null,
      heading: body.heading ? parseFloat(body.heading) : null,
    };

    await dynamo.put({
      TableName: process.env.LOCATIONS_TABLE || 'shadowtrace-locations',
      Item: locationRecord,
    }).promise();

    const tripParams = {
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId },
    };

    const tripResult = await dynamo.get(tripParams).promise();

    if (tripResult.Item && tripResult.Item.taskToken) {
      await stepFunctions.sendTaskHeartbeat({
        taskToken: tripResult.Item.taskToken,
      }).promise();
    }

    return json(200, { message: 'Location updated', tripId });
  } catch (error) {
    if (error.message.startsWith('401|')) {
      return json(401, { error: error.message.replace('401|', '') });
    }
    if (error.message.startsWith('400|')) {
      return json(400, { error: error.message.replace('400|', '') });
    }
    return json(500, { error: error.message || 'Unable to update location' });
  }
};

