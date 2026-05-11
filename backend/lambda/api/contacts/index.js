const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const sns = new AWS.SNS();

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

    if (event.httpMethod === 'GET') {
      const contacts = await dynamodb.query({
        TableName: 'shadowtrace-contacts',
        KeyConditionExpression: 'userId = :userId',
        ExpressionAttributeValues: {
          ':userId': userId,
        },
      });

      return {
        statusCode: 200,
        body: JSON.stringify(contacts.Items || []),
      };
    }

    if (event.httpMethod === 'POST') {
      const { name, phone, email } = JSON.parse(event.body || '{}');
      if (!name || !phone) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'name and phone required' }),
        };
      }

      const contactId = `contact_${Date.now()}`;

      await dynamodb.put({
        TableName: 'shadowtrace-contacts',
        Item: {
          userId,
          contactId,
          name,
          phone,
          email,
          addedAt: new Date().toISOString(),
        },
      });

      if (phone) {
        try {
          const topicArn = process.env.SNS_ALERTS_TOPIC;
          await sns
            .subscribe({
              TopicArn: topicArn,
              Protocol: 'sms',
              Endpoint: phone,
            })
            .promise();
        } catch (e) {
          console.error('SNS subscribe error:', e.message);
        }
      }

      return {
        statusCode: 201,
        body: JSON.stringify({
          contactId,
          success: true,
        }),
      };
    }

    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
