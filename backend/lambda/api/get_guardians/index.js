const { dynamo, json, currentUserId } = require('../../shared');

exports.handler = async (event) => {
  const userId = currentUserId(event);

  try {
    const result = await dynamo.query({
      TableName: process.env.GUARDIANS_TABLE || 'Guardians',
      IndexName: 'userId-index',
      KeyConditionExpression: 'userId = :uid',
      ExpressionAttributeValues: {
        ':uid': userId,
      },
    }).promise();

    return json(200, { guardians: result.Items || [] });
  } catch (error) {
    return json(500, { error: error.message || 'Unable to load guardians' });
  }
};
