const AWS = require('aws-sdk');
const https = require('https');
const { dynamo, json, parseBody, getCurrentUserId, validateInput, randomId } = require('../../shared');

const location = new AWS.Location();

function makeHttpsRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(body) });
        } catch {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function getWeather(lat, lng) {
  const owmKey = process.env.OWM_KEY;
  if (!owmKey) return { main: 'Clear', hazard: false };

  try {
    const response = await makeHttpsRequest({
      hostname: 'api.openweathermap.org',
      path: `/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${owmKey}`,
      method: 'GET',
    });

    if (response.body.list && response.body.list[0]) {
      const weather = response.body.list[0].weather[0].main;
      const hazardous = ['Thunderstorm', 'Snow', 'Tornado', 'Squall'].includes(weather);
      return { main: weather, hazard: hazardous };
    }

    if (response.body.weather && response.body.weather[0]) {
      const weather = response.body.weather[0].main;
      const hazardous = ['Thunderstorm', 'Snow', 'Tornado', 'Squall'].includes(weather);
      return { main: weather, hazard: hazardous };
    }

    return { main: 'Clear', hazard: false };
  } catch {
    return { main: 'Clear', hazard: false };
  }
}

function createBufferPolygon(linestring, bufferMeters) {
  if (!linestring || linestring.length < 2) return [];

  const coordinates = linestring;
  const bufferDegrees = bufferMeters / 111000;
  const buffered = [];

  for (const coord of coordinates) {
    const [lng, lat] = coord;
    buffered.push([
      [lng - bufferDegrees, lat - bufferDegrees],
      [lng + bufferDegrees, lat - bufferDegrees],
      [lng + bufferDegrees, lat + bufferDegrees],
      [lng - bufferDegrees, lat + bufferDegrees],
      [lng - bufferDegrees, lat - bufferDegrees],
    ]);
  }

  const polygon = [];
  if (buffered.length > 0) {
    polygon.push(buffered[0]);
  }
  return [polygon];
}

exports.handler = async (event) => {
  try {
    const body = parseBody(event);
    const userId = await getCurrentUserId(event);

    validateInput(body, ['originLat', 'originLng', 'destLat', 'destLng']);

    const originLat = parseFloat(body.originLat);
    const originLng = parseFloat(body.originLng);
    const destLat = parseFloat(body.destLat);
    const destLng = parseFloat(body.destLng);

    const routeResult = await location.calculateRoute({
      CalculatorName: 'shadowtrace-route-calc',
      DeparturePosition: [originLng, originLat],
      DestinationPosition: [destLng, destLat],
      TravelMode: 'Walking',
      IncludeLegGeometry: true,
    }).promise();

    const leg = routeResult.Legs[0];
    const linestring = leg.Geometry.LineString;
    const eta = leg.Duration || 0;

    const midIndex = Math.floor(linestring.length / 2);
    const midpoint = linestring[midIndex];
    const weather = await getWeather(midpoint[1], midpoint[0]);

    const bufferPolygon = createBufferPolygon(linestring, 200);

    const geofenceId = randomId('geofence');
    await location.putGeofence({
      CollectionName: 'shadowtrace-routes',
      GeofenceId: geofenceId,
      Geometry: {
        Polygon: bufferPolygon,
      },
    }).promise();

    await location.associateTrackerConsumer({
      TrackerName: 'shadowtrace-tracker',
      ConsumerArn: `arn:aws:geo:${process.env.AWS_REGION}:${process.env.AWS_ACCOUNT_ID}:geofence-collection/shadowtrace-routes`,
    }).promise();

    const tripId = randomId('trip');

    const trip = {
      userId,
      tripId,
      originLat,
      originLng,
      destLat,
      destLng,
      polyline: linestring,
      eta,
      hazardFlag: weather.hazard,
      weather: weather.main,
      geofenceId,
      status: 'ACTIVE',
      createdAt: new Date().toISOString(),
    };

    await dynamo.put({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Item: trip,
    }).promise();

    return json(200, {
      tripId,
      polyline: linestring,
      eta,
      hazardFlag: weather.hazard,
      weather: weather.main,
    });
  } catch (error) {
    if (error.message.startsWith('401|')) {
      return json(401, { error: error.message.replace('401|', '') });
    }
    if (error.message.startsWith('400|')) {
      return json(400, { error: error.message.replace('400|', '') });
    }
    return json(500, { error: error.message || 'Route calculation failed' });
  }
};
