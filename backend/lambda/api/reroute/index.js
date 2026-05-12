const { getCurrentUserId, validateInput } = require('../../shared');
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const location = new AWS.Location();

exports.handler = async (event) => {
  try {
    const userId = await getCurrentUserId(event);
    const body = JSON.parse(event.body || '{}');
    validateInput(body, ['tripId', 'currentLat', 'currentLng', 'reason']);
    const { tripId, currentLat, currentLng, reason } = body;

    // Fetch original destination from DynamoDB
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

    const { destLat, destLng, travelMode } = trip.Item;

    // Calculate new route from CURRENT position to destination
    const routeResp = await location.calculateRoute({
      CalculatorName: process.env.ROUTE_CALC || 'shadowtrace-route-calc',
      DeparturePosition: [currentLng, currentLat],
      DestinationPosition: [destLng, destLat],
      TravelMode: travelMode || 'Walking',
      IncludeLegGeometry: true,
      OptimizeFor: 'FastestRoute'
    }).promise();

    const newPolyline = routeResp.Legs[0].Geometry.LineString.map(
      ([lng, lat]) => ({ lat, lng })
    );
    const newEta = routeResp.Summary.DurationSeconds;
    const newDistance = routeResp.Summary.Distance;

    // Create geofence corridor around new route (200m buffer)
    const bufferPolygon = createBufferPolygon(newPolyline, 200);
    await location.putGeofence({
      CollectionName: process.env.GEOFENCE_COLLECTION || 'shadowtrace-routes',
      GeofenceId: `trip-${tripId}-rerouted`,
      Geometry: { Polygon: [bufferPolygon] }
    }).promise();

    // Update trip in DynamoDB
    await dynamodb.update({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId },
      UpdateExpression: 'SET polyline = :p, eta = :e, rerouteReason = :r, reroutedAt = :ra',
      ExpressionAttributeValues: {
        ':p': newPolyline,
        ':e': newEta,
        ':r': reason,
        ':ra': new Date().toISOString()
      }
    }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({
        tripId,
        newPolyline,
        newEta,
        newDistance,
        rerouteReason: reason,
        message: `Route updated due to: ${reason}`
      })
    };
  } catch (err) {
    console.error('Reroute error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  }
};

function createBufferPolygon(polyline, radiusMeters) {
  const R = 6371000;
  const coords = [];

  for (const point of polyline) {
    const dLat = (radiusMeters / R) * (180 / Math.PI);
    const dLng = dLat / Math.cos((point.lat * Math.PI) / 180);
    coords.push([point.lng + dLng, point.lat + dLat]);
    coords.push([point.lng - dLng, point.lat - dLat]);
  }
  coords.push(coords[0]);
  return coords;
}
