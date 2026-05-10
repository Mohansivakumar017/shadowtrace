const AWS = require('aws-sdk');
const sns = new AWS.SNS();
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const { userId, alertId } = event;

    try {
        // 1. Get Guardians for User
        const userParams = {
            TableName: 'ShadowTraceUsers',
            Key: { userId }
        };
        const userResult = await dynamodb.get(userParams).promise();
        const guardians = userResult.Item.guardians; // Array of phone numbers

        // 2. Send SMS via SNS
        const message = `SHADOWTRACE: EMERGENCY DETECTED for User ${userId}. Live tracking started. Check app.`;

        for (const phone of guardians) {
            await sns.publish({
                Message: message,
                PhoneNumber: phone
            }).promise();
        }

        // 3. Update Alert Status
        await dynamodb.update({
            TableName: 'ShadowTraceAlerts',
            Key: { alertId },
            UpdateExpression: 'set #s = :status',
            ExpressionAttributeNames: { '#s': 'status' },
            ExpressionAttributeValues: { ':status': 'ESCALATED' }
        }).promise();

        return { status: 'ESCALATED' };
    } catch (error) {
        console.error(error);
        throw error;
    }
};
