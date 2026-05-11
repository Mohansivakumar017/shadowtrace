const AWS = require('aws-sdk');
const crypto = require('crypto');
const { CognitoJwtVerifier } = require('aws-jwt-verify');

const dynamo = new AWS.DynamoDB.DocumentClient({ convertEmptyValues: true });
const sns = new AWS.SNS();
const stepFunctions = new AWS.StepFunctions();
const cognito = new AWS.CognitoIdentityServiceProvider();

const COGNITO_USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const COGNITO_CLIENT_ID = process.env.COGNITO_CLIENT_ID;

let verifier;

async function initVerifier() {
  if (!verifier) {
    verifier = CognitoJwtVerifier.create({
      userPoolId: COGNITO_USER_POOL_ID,
      tokenUse: 'id',
      clientId: COGNITO_CLIENT_ID,
    });
  }
  return verifier;
}

function headers() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-User-Id',
    'Access-Control-Allow-Methods': 'OPTIONS,GET,POST,PUT',
  };
}

function json(statusCode, payload) {
  return { statusCode, headers: headers(), body: JSON.stringify(payload) };
}

function parseBody(event) {
  if (!event) return {};
  if (typeof event.body === 'string' && event.body.trim().length > 0) {
    try {
      return JSON.parse(event.body);
    } catch (error) {
      return {};
    }
  }
  return event.body || {};
}

async function getCurrentUserId(event) {
  const authHeader = event.headers?.authorization || event.headers?.Authorization;

  if (!authHeader) {
    throw new Error('401|Missing authorization header');
  }

  const token = authHeader.replace('Bearer ', '');
  const ver = await initVerifier();

  try {
    const payload = await ver.verify(token);
    return payload.sub;
  } catch (error) {
    throw new Error('401|Invalid or expired token');
  }
}

function validateInput(body, requiredFields = []) {
  if (!body || typeof body !== 'object') {
    throw new Error('400|Request body is required');
  }

  for (const field of requiredFields) {
    if (body[field] === undefined || body[field] === null || body[field] === '') {
      throw new Error(`400|Missing required field: ${field}`);
    }
  }

  if (body.lat !== undefined && body.lat !== null) {
    const lat = parseFloat(body.lat);
    if (isNaN(lat) || lat < -90 || lat > 90) {
      throw new Error('400|Invalid latitude: must be between -90 and 90');
    }
  }

  if (body.lng !== undefined && body.lng !== null) {
    const lng = parseFloat(body.lng);
    if (isNaN(lng) || lng < -180 || lng > 180) {
      throw new Error('400|Invalid longitude: must be between -180 and 180');
    }
  }

  const sanitized = {};
  for (const [key, value] of Object.entries(body)) {
    if (typeof value === 'string') {
      sanitized[key] = value.trim().replace(/[<>\"'`]/g, '');
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}

function nowIso() {
  return new Date().toISOString();
}

function randomId(prefix) {
  return `${prefix}-${crypto.randomUUID()}`;
}

module.exports = {
  dynamo,
  sns,
  stepFunctions,
  cognito,
  json,
  parseBody,
  getCurrentUserId,
  validateInput,
  nowIso,
  randomId,
};
