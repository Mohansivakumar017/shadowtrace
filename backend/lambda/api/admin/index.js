const { getCurrentUserId, json } = require('../../shared');
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    const userId = await getCurrentUserId(event);
    const path = event.pathParameters?.['proxy'] || '';

    if (path === 'admin/stats' && event.httpMethod === 'GET') {
      return await getStats();
    } else if (path === 'admin/alerts' && event.httpMethod === 'GET') {
      return await getAlerts();
    }

    return json(404, { error: 'Not found' });
  } catch (err) {
    console.error('Admin error:', err);
    return json(500, { error: err.message });
  }
};

async function getStats() {
  try {
    const trips = await dynamodb.scan({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      FilterExpression: 'attribute_exists(tripId) AND #status = :active',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: { ':active': 'ACTIVE' },
      ProjectionExpression: 'tripId',
    }).promise();

    const alerts = await dynamodb.scan({
      TableName: process.env.ALERTS_TABLE || 'shadowtrace-alerts',
      FilterExpression:
        'attribute_exists(alertId) AND begins_with(#ts, :today)',
      ExpressionAttributeNames: { '#ts': 'timestamp' },
      ExpressionAttributeValues: {
        ':today': new Date().toISOString().split('T')[0],
      },
      ProjectionExpression: 'alertId',
    }).promise();

    const sosAlerts = await dynamodb.scan({
      TableName: process.env.ALERTS_TABLE || 'shadowtrace-alerts',
      FilterExpression: 'attribute_exists(alertId) AND #type = :sos AND #status = :active',
      ExpressionAttributeNames: { '#type': 'type', '#status': 'status' },
      ExpressionAttributeValues: { ':sos': 'SOS', ':active': 'ACTIVE' },
      ProjectionExpression: 'alertId',
    }).promise();

    const users = await dynamodb.scan({
      TableName: process.env.USERS_TABLE || 'shadowtrace-users',
      FilterExpression: 'attribute_exists(userId) AND lastSeen > :fiveMinAgo',
      ExpressionAttributeValues: {
        ':fiveMinAgo': new Date(Date.now() - 5 * 60 * 1000).toISOString(),
      },
      ProjectionExpression: 'userId',
    }).promise();

    return json(200, {
      activeTrips: trips.Items?.length || 0,
      alertsToday: alerts.Items?.length || 0,
      activeSOS: sosAlerts.Items?.length || 0,
      usersOnline: users.Items?.length || 0,
    });
  } catch (err) {
    console.error('Get stats error:', err);
    return json(500, { error: 'Failed to fetch stats' });
  }
}

async function getAlerts() {
  try {
    const result = await dynamodb.scan({
      TableName: process.env.ALERTS_TABLE || 'shadowtrace-alerts',
      ProjectionExpression:
        'alertId, userId, #type, lat, lng, #ts, #status',
      ExpressionAttributeNames: {
        '#type': 'type',
        '#ts': 'timestamp',
        '#status': 'status',
      },
      Limit: 50,
    }).promise();

    const alerts = (result.Items || [])
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, 50);

    return json(200, { alerts });
  } catch (err) {
    console.error('Get alerts error:', err);
    return json(500, { error: 'Failed to fetch alerts' });
  }
}
