const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const locationService = new AWS.LocationService();

exports.handler = async (event) => {
  try {
    console.log('IoT message received:', JSON.stringify(event, null, 2));

    const location = JSON.parse(event.body || '{}');
    const { deviceId, lat, lng, timestamp } = location;

    if (!deviceId || !lat || !lng) {
      console.error('Missing required fields');
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'deviceId, lat, lng required' }),
      };
    }

    await dynamodb.put({
      TableName: 'shadowtrace-locations',
      Item: {
        userId: `device_${deviceId}`,
        timestamp: timestamp || new Date().toISOString(),
        lat,
        lng,
        source: 'iot-core',
        deviceId,
      },
    });

    try {
      await locationService
        .batchUpdateDevicePosition({
          TrackerName: 'shadowtrace-tracker',
          Updates: [
            {
              DeviceId: deviceId,
              Position: [lng, lat],
              Timestamp: new Date(timestamp).getTime(),
            },
          ],
        })
        .promise();
    } catch (e) {
      console.error('ALS update error:', e.message);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true }),
    };
  } catch (error) {
    console.error('Handler error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
