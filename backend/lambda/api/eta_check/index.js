const { getCurrentUserId, validateInput } = require('../../shared');
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const location = new AWS.Location();
const sns = new AWS.SNS();

exports.handler = async (event) => {
  try {
    // Supports both HTTP trigger and Step Functions scheduled trigger
    const tripId = event.pathParameters?.tripId || event.tripId;
    const userId = event.userId || await getCurrentUserId(event);

    if (!tripId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'tripId required' })
      };
    }

    // Fetch trip data
    const trip = await dynamodb.get({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId }
    }).promise();

    if (!trip.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Trip not found' })
      };
    }

    const { destLat, destLng, startedAt, originalEtaSeconds, snsTopicArn, travelMode } = trip.Item;

    // Get current device position from ALS tracker
    const posResp = await location.getDevicePosition({
      TrackerName: process.env.TRACKER_NAME || 'shadowtrace-tracker',
      DeviceId: userId
    }).promise();

    const [currentLng, currentLat] = posResp.Position;

    // Calculate remaining route
    const routeResp = await location.calculateRoute({
      CalculatorName: process.env.ROUTE_CALC || 'shadowtrace-route-calc',
      DeparturePosition: [currentLng, currentLat],
      DestinationPosition: [destLng, destLat],
      TravelMode: travelMode || 'Walking'
    }).promise();

    const remainingSeconds = routeResp.Summary.DurationSeconds;
    const elapsedSeconds = (Date.now() - new Date(startedAt).getTime()) / 1000;
    const projectedTotalSeconds = elapsedSeconds + remainingSeconds;
    const delaySeconds = projectedTotalSeconds - originalEtaSeconds;
    const delayMinutes = Math.round(delaySeconds / 60);
    const isSignificantDelay = delaySeconds > 600;

    let anomalyType = 'on_time';
    if (isSignificantDelay) anomalyType = 'significant_delay';
    if (remainingSeconds < 60) anomalyType = 'arriving_soon';

    // Update DynamoDB
    await dynamodb.update({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId },
      UpdateExpression: 'SET currentEtaSeconds = :e, anomalyType = :a, lastEtaCheck = :l',
      ExpressionAttributeValues: {
        ':e': remainingSeconds,
        ':a': anomalyType,
        ':l': new Date().toISOString()
      }
    }).promise();

    // Alert guardians on significant delay
    if (isSignificantDelay && snsTopicArn) {
      await sns.publish({
        TopicArn: snsTopicArn,
        Message:
          `ShadowTrace ETA Alert: Your traveler is running ${delayMinutes} minutes late. ` +
          `Current position: ${currentLat.toFixed(4)}, ${currentLng.toFixed(4)}. ` +
          `Estimated arrival in ${Math.round(remainingSeconds / 60)} minutes.`,
        Subject: 'ShadowTrace — Travel Delay Alert'
      }).promise();
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        tripId,
        anomalyType,
        remainingMinutes: Math.round(remainingSeconds / 60),
        delayMinutes: Math.max(0, delayMinutes),
        isSignificantDelay,
        currentPosition: { lat: currentLat, lng: currentLng }
      })
    };
  } catch (err) {
    console.error('ETA check error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  }
};
