const AWS = require('aws-sdk');
const { dynamo, json, parseBody, getCurrentUserId, validateInput } = require('../../shared');

const location = new AWS.Location();

exports.handler = async (event) => {
  try {
    const body = parseBody(event);
    const userId = await getCurrentUserId(event);

    validateInput(body, ['routePolyline']);

    const polyline = body.routePolyline;
    if (!Array.isArray(polyline) || polyline.length === 0) {
      return json(400, { error: 'routePolyline must be a non-empty array' });
    }

    let safetyScore = 100;
    const riskFactors = [];

    const locationsResult = await dynamo.query({
      TableName: process.env.LOCATIONS_TABLE || 'shadowtrace-locations',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: { ':userId': userId },
    }).promise();

    const deviations = locationsResult.Items.filter(loc => {
      const lat = loc.lat;
      const lng = loc.lng;
      return !isPointNearPolyline(lat, lng, polyline, 100);
    });

    safetyScore -= deviations.length * 10;
    if (deviations.length > 0) {
      riskFactors.push(`${deviations.length} past deviation events`);
    }

    const trips = await dynamo.query({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: { ':userId': userId },
    }).promise();

    const hazardTrips = trips.Items.filter(t => t.hazardFlag === true);
    if (hazardTrips.length > 0) {
      safetyScore -= 15;
      riskFactors.push('Weather hazard detected on this route');
    }

    const waypointNames = [];
    for (const waypoint of polyline) {
      try {
        const placeResult = await location.searchPlaceIndexForPosition({
          IndexName: 'shadowtrace-place-index',
          Position: waypoint,
        }).promise();

        if (placeResult.Results && placeResult.Results.length > 0) {
          waypointNames.push(placeResult.Results[0].Place.Label || 'Unknown');
        }
      } catch {
        waypointNames.push('Unknown');
      }
    }

    safetyScore = Math.max(0, Math.min(100, safetyScore));

    return json(200, {
      safetyScore,
      riskFactors,
      waypointNames,
      deviationCount: deviations.length,
    });
  } catch (error) {
    if (error.message.startsWith('401|')) {
      return json(401, { error: error.message.replace('401|', '') });
    }
    if (error.message.startsWith('400|')) {
      return json(400, { error: error.message.replace('400|', '') });
    }
    return json(500, { error: error.message || 'Safety score calculation failed' });
  }
};

function isPointNearPolyline(lat, lng, polyline, toleranceMeters) {
  const toleranceDegrees = toleranceMeters / 111000;

  for (const point of polyline) {
    const pointLat = point[1];
    const pointLng = point[0];
    const distance = Math.sqrt(
      Math.pow(lat - pointLat, 2) + Math.pow(lng - pointLng, 2)
    );
    if (distance < toleranceDegrees) {
      return true;
    }
  }
  return false;
}
