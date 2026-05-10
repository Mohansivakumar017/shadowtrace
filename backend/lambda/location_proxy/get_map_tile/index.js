const AWS = require('aws-sdk');

const location = new AWS.LocationService({ apiVersion: '2020-11-19' });

exports.handler = async (event) => {
  // Expected query string parameters: mapName, z, x, y
  const params = event.queryStringParameters || {};
  const mapName = params.mapName;
  const z = params.z;
  const x = params.x;
  const y = params.y;

  if (!mapName || z === undefined || x === undefined || y === undefined) {
    return { statusCode: 400, body: 'Missing params' };
  }

  // Amazon Location can provide Tile URLs via the Maps service GetMapTile API
  // For raster tiles, you would normally call the GetMapTile API or generate
  // signed URL. Here we use the data API to request a tile. This is example pseudocode.
  try {
    const tileData = await location.getMapTile({ MapName: mapName, Z: parseInt(z, 10), X: parseInt(x, 10), Y: parseInt(y, 10) }).promise();
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'image/png' },
      body: tileData.Body.toString('base64'),
      isBase64Encoded: true,
    };
  } catch (err) {
    console.error('GetMapTile error', err);
    return { statusCode: 500, body: 'Error fetching tile' };
  }
};
