const { getCurrentUserId, validateInput } = require('../../shared');
const AWS = require('aws-sdk');
const https = require('https');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const lambda = new AWS.Lambda();

exports.handler = async (event) => {
  try {
    const userId = await getCurrentUserId(event);
    const body = JSON.parse(event.body || '{}');
    validateInput(body, ['tripId', 'locationHistory']);
    const { tripId, locationHistory } = body;

    // Step 1: Extract 8 movement features
    const features = extractMovementFeatures(locationHistory);

    // Step 2: Rule-based fast classification
    const ruleResult = applyRules(features);

    // Step 3: If uncertain (confidence < 0.75), use OpenAI
    let result = ruleResult;
    if (ruleResult.confidence < 0.75 && process.env.OPENAI_API_KEY) {
      result = await classifyWithOpenAI(features, locationHistory.slice(-5));
    }

    // Step 4: Store in DynamoDB
    await dynamodb.update({
      TableName: process.env.TRIPS_TABLE || 'shadowtrace-trips',
      Key: { userId, tripId },
      UpdateExpression: 'SET threatLevel = :tl, threatType = :tt, confidence = :c, classifiedAt = :ca',
      ExpressionAttributeValues: {
        ':tl': result.threatLevel,
        ':tt': result.threatType,
        ':c': result.confidence,
        ':ca': new Date().toISOString()
      }
    }).promise();

    // Step 5: Auto-trigger SOS if HIGH confidence threat
    if (result.threatLevel === 'HIGH' && result.confidence >= 0.80) {
      const last = locationHistory[locationHistory.length - 1];
      await lambda.invoke({
        FunctionName: process.env.SOS_FUNCTION_NAME || 'shadowtrace-sos',
        InvocationType: 'Event',
        Payload: JSON.stringify({
          body: JSON.stringify({
            userId, tripId,
            lat: last.lat, lng: last.lng,
            triggerType: 'ai_detected',
            reason: result.threatType,
            confidence: result.confidence
          })
        })
      }).promise();
    }

    return {
      statusCode: 200,
      body: JSON.stringify(result)
    };
  } catch (err) {
    console.error('Classifier error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  }
};

function extractMovementFeatures(history) {
  if (!history || history.length < 2) {
    return {
      avgSpeed: 0,
      maxSpeed: 0,
      speedVariance: 0,
      directionChanges: 0,
      stallDuration: 0,
      totalDistance: 0,
      backtrackRatio: 0,
      pointCount: history?.length || 0
    };
  }

  const speeds = [];
  const distances = [];
  const bearings = [];

  for (let i = 1; i < history.length; i++) {
    const prev = history[i - 1];
    const curr = history[i];
    const dt = Math.max(1, (new Date(curr.timestamp) - new Date(prev.timestamp)) / 1000);
    const dist = haversine(prev.lat, prev.lng, curr.lat, curr.lng);
    distances.push(dist);
    speeds.push(dist / dt);
    bearings.push(calcBearing(prev.lat, prev.lng, curr.lat, curr.lng));
  }

  const avgSpeed = mean(speeds);
  const maxSpeed = Math.max(...speeds);
  const speedVar = variance(speeds, avgSpeed);
  const dirChanges = bearings.filter((b, i) =>
    i > 0 && Math.abs(normalizeAngle(b - bearings[i - 1])) > 60
  ).length;
  const totalDist = distances.reduce((a, b) => a + b, 0);
  const stallDuration = history[history.length - 1].stallSeconds || 0;

  const netDisplacement = haversine(
    history[0].lat, history[0].lng,
    history[history.length - 1].lat, history[history.length - 1].lng
  );
  const backtrackRatio = totalDist > 0 ? 1 - (netDisplacement / totalDist) : 0;

  return {
    avgSpeed,
    maxSpeed,
    speedVariance: speedVar,
    directionChanges: dirChanges,
    stallDuration,
    totalDistance: totalDist,
    backtrackRatio,
    pointCount: history.length
  };
}

function applyRules(f) {
  if (f.stallDuration > 300) {
    return {
      threatLevel: 'HIGH',
      threatType: 'prolonged_inactivity',
      confidence: 0.92,
      reason: `No movement for ${Math.round(f.stallDuration / 60)} minutes`
    };
  }
  if (f.stallDuration > 120 && f.avgSpeed < 0.3) {
    return {
      threatLevel: 'MEDIUM',
      threatType: 'extended_stall',
      confidence: 0.80,
      reason: 'Extended period of very slow movement'
    };
  }
  if (f.backtrackRatio > 0.6 && f.directionChanges > 4) {
    return {
      threatLevel: 'HIGH',
      threatType: 'possible_abduction_route',
      confidence: 0.78,
      reason: 'Erratic backtracking pattern detected'
    };
  }
  if (f.directionChanges > 6 && f.speedVariance > 2) {
    return {
      threatLevel: 'MEDIUM',
      threatType: 'erratic_movement',
      confidence: 0.70,
      reason: 'High speed variance with frequent direction changes'
    };
  }
  if (f.maxSpeed > 30 && f.avgSpeed > 15 && f.speedVariance < 1) {
    return {
      threatLevel: 'LOW',
      threatType: 'vehicle_travel',
      confidence: 0.88,
      reason: 'Consistent vehicle speed detected'
    };
  }
  return {
    threatLevel: 'LOW',
    threatType: 'normal_movement',
    confidence: 0.85,
    reason: 'Movement patterns appear normal'
  };
}

async function classifyWithOpenAI(features, recentPoints) {
  const prompt = `You are a personal safety AI analyst. Classify this movement pattern for threat level.
Features: ${JSON.stringify(features, null, 2)}
Last points: ${JSON.stringify(recentPoints.map(p => ({lat: p.lat, lng: p.lng, t: p.timestamp})))}
Respond ONLY with JSON (no markdown): {"threatLevel":"LOW"|"MEDIUM"|"HIGH","threatType":"string","confidence":0.0-1.0,"reason":"explanation"}`;

  return new Promise((resolve) => {
    const payload = JSON.stringify({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 120,
      temperature: 0.1
    });

    const options = {
      hostname: 'api.openai.com',
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => (data += chunk));
      res.on('end', () => {
        try {
          const resp = JSON.parse(data);
          const content = resp.choices[0].message.content.trim();
          resolve(JSON.parse(content));
        } catch {
          resolve({
            threatLevel: 'LOW',
            threatType: 'normal_movement',
            confidence: 0.5,
            reason: 'Classification unavailable'
          });
        }
      });
    });

    req.on('error', () =>
      resolve({
        threatLevel: 'LOW',
        threatType: 'normal_movement',
        confidence: 0.5,
        reason: 'Network error'
      })
    );

    req.write(payload);
    req.end();
  });
}

function haversine(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function calcBearing(lat1, lon1, lat2, lon2) {
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const y = Math.sin(dLon) * Math.cos((lat2 * Math.PI) / 180);
  const x =
    Math.cos((lat1 * Math.PI) / 180) * Math.sin((lat2 * Math.PI) / 180) -
    Math.sin((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.cos(dLon);
  return (Math.atan2(y, x) * 180) / Math.PI;
}

function normalizeAngle(a) {
  return ((a % 360) + 540) % 360 - 180;
}

function mean(arr) {
  return arr.reduce((a, b) => a + b, 0) / arr.length;
}

function variance(arr, m) {
  return arr.reduce((a, b) => a + (b - m) ** 2, 0) / arr.length;
}
