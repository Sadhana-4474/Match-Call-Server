require('dotenv').config();
const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
const PORT = process.env.PORT || 3000;

const APP_ID = process.env.APP_ID;
const APP_CERTIFICATE = process.env.APP_CERTIFICATE;
const API_KEY = process.env.API_KEY || ''; // optional — recommended
const DEFAULT_EXPIRE_SECONDS = process.env.EXPIRE_SECONDS ? parseInt(process.env.EXPIRE_SECONDS, 10) : 3600 * 24 * 365;

if (!APP_ID || !APP_CERTIFICATE) {
  console.error('Missing APP_ID or APP_CERTIFICATE in environment variables');
  process.exit(1);
}

app.get('/generateToken', (req, res) => {
  const channelName = req.query.channelName;
  if (!channelName) return res.status(400).json({ error: 'channelName is required' });

  // Simple API key check if configured
  if (API_KEY) {
    const provided = req.query.apiKey || req.header('x-api-key');
    if (!provided || provided !== API_KEY) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
  }

  const uid = Number(req.query.uid || 0);
  const role = req.query.role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
  const expireSeconds = Number(req.query.expireSeconds || DEFAULT_EXPIRE_SECONDS);

  const currentTs = Math.floor(Date.now() / 1000);
  const privilegeExpireTs = currentTs + expireSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpireTs
    );
    return res.json({ token, expiresAt: privilegeExpireTs });
  } catch (err) {
    console.error('Token generation error:', err);
    return res.status(500).json({ error: 'Token generation failed' });
  }
});

app.get('/', (_, res) => res.send('Agora token server running'));

app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
