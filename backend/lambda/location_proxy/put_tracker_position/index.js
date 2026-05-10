const AWS = require('aws-sdk');
const location = new AWS.LocationService({ apiVersion: '2020-11-19' });

exports.handler = async (event) => {
  // Expected body: { trackerName, deviceId, position: { lat, lon }, sampleTime }
  const body = (typeof event.body === 'string') ? JSON.parse(event.body) : event.body;
  const trackerName = body?.trackerName;
  const deviceId = body?.deviceId;
  const pos = body?.position;

  if (!trackerName || !deviceId || !pos) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Missing parameters' }) };
  }

  try {
    // Use BatchPutGeofence or BatchUpdateDevicePosition depending on API. Example uses BatchPutGeofence
    const resp = await location.batchUpdateDevicePosition({ TrackerName: trackerName, Updates: [{ DeviceId: deviceId, Position: [pos.lon, pos.lat], SampleTime: body.sampleTime || new Date().toISOString() }] }).promise();
    return { statusCode: 200, body: JSON.stringify({ message: 'Position updated', resp }) };
  } catch (err) {
    console.error('PutTrackerPosition error', err);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal' }) };
  }
};
