const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const stepFunctions = new AWS.StepFunctions();

const authUtils = require('../../shared/auth-utils');

exports.handler = async (event) => {
  try {
    const userId = await authUtils.getCurrentUserId(event);
    if (!userId) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized' }),
      };
    }

    const { tripId } = JSON.parse(event.body || '{}');
    if (!tripId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'tripId required' }),
      };
    }

    const trip = await dynamodb.get({
      TableName: 'shadowtrace-trips',
      Key: { tripId },
    });

    if (!trip.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Trip not found' }),
      };
    }

    const taskToken = trip.Item.taskToken;
    if (taskToken) {
      try {
        await stepFunctions
          .sendTaskHeartbeat({ taskToken })
          .promise();
      } catch (e) {
        console.error('Heartbeat send error:', e.message);
      }
    }

    await dynamodb.update({
      TableName: 'shadowtrace-trips',
      Key: { tripId },
      UpdateExpression: 'SET lastHeartbeat = :now',
      ExpressionAttributeValues: {
        ':now': new Date().toISOString(),
      },
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        nextDeadlineSeconds: 300,
      }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
