const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

const { getCurrentUserId } = require('../../shared');

exports.handler = async (event) => {
  try {
    const userId = await getCurrentUserId(event);
    if (!userId) {
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized' }),
      };
    }

    const { alertId } = JSON.parse(event.body || '{}');
    if (!alertId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'alertId required' }),
      };
    }

    const s3 = new AWS.S3();
    const bucket = process.env.AUDIO_BUCKET;
    const key = `alerts/${alertId}/audio_${Date.now()}.m4a`;

    const uploadUrl = s3.getSignedUrl('putObject', {
      Bucket: bucket,
      Key: key,
      ContentType: 'audio/aac',
      Expires: 300,
    });

    await dynamodb.update({
      TableName: 'shadowtrace-alerts',
      Key: { alertId },
      UpdateExpression: 'SET audioKeys = list_append(audioKeys, :keys)',
      ExpressionAttributeValues: {
        ':keys': [key],
      },
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        uploadUrl,
        s3Key: key,
        expiresIn: 300,
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
