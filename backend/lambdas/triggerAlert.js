const AWS = require('aws-sdk');
const stepfunctions = new AWS.StepFunctions();
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const { userId, location, type } = JSON.parse(event.body);
    const alertId = `alert_${Date.now()}`;

    // 1. Store Alert in DynamoDB
    const params = {
        TableName: 'ShadowTraceAlerts',
        Item: {
            alertId,
            userId,
            location,
            status: 'PENDING',
            timestamp: new Date().toISOString(),
            retryCount: 0
        }
    };

    try {
        await dynamodb.put(params).promise();

        // 2. Start Step Function Workflow
        const stateMachineParams = {
            stateMachineArn: process.env.STATE_MACHINE_ARN,
            input: JSON.stringify({ alertId, userId, retryCount: 0 })
        };

        await stepfunctions.startExecution(stateMachineParams).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Alert triggered', alertId })
        };
    } catch (error) {
        console.error(error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Internal Server Error' })
        };
    }
};
