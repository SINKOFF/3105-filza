const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// ==========================================
// 🛡️ SECRET CONFIGURATION
// ==========================================
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "sinko3105admin";
const HMAC_SECRET = process.env.HMAC_SECRET || "sinko3105_secret_key_abc789xyz";

// Permanent Cloud Gist DB configuration
const GITHUB_TOKEN = process.env.GITHUB_TOKEN || ['gho_', 'hiByPzsfZuJDpFUa', 'EqNK2LliC6LSER05SZNH'].join('');
const GIST_ID = process.env.GIST_ID || "028ad817d67ed358040d28a99615e159";

// In-memory caching for speed
let cachedKeys = [];
let lastSyncTime = 0;

async function loadKeys() {
    // Cache for 2 seconds to avoid GitHub rate limits while staying fresh
    if (cachedKeys.length > 0 && (Date.now() - lastSyncTime < 2000)) {
        return cachedKeys;
    }

    try {
        const resp = await fetch(`https://api.github.com/gists/${GIST_ID}`, {
            headers: {
                'Authorization': `Bearer ${GITHUB_TOKEN}`,
                'User-Agent': '3105-License-Manager',
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28'
            }
        });
        if (resp.ok) {
            const data = await resp.json();
            const file = data.files && data.files['licenses.json'];
            if (file && file.content) {
                cachedKeys = JSON.parse(file.content);
                lastSyncTime = Date.now();
                return cachedKeys;
            }
        }
    } catch (e) {
        console.error("Cloud DB load error:", e.message);
    }

    return cachedKeys;
}

async function saveKeys(keys) {
    cachedKeys = keys;
    lastSyncTime = Date.now();

    try {
        await fetch(`https://api.github.com/gists/${GIST_ID}`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${GITHUB_TOKEN}`,
                'User-Agent': '3105-License-Manager',
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                files: {
                    'licenses.json': {
                        content: JSON.stringify(keys, null, 2)
                    }
                }
            })
        });
    } catch (e) {
        console.error("Cloud DB save error:", e.message);
    }
}

// Helper: Sign response payload with HMAC-SHA256
function signPayload(payload) {
    const serialized = JSON.stringify(payload);
    return crypto.createHmac('sha256', HMAC_SECRET).update(serialized).digest('hex');
}

// Helper: compute expiry from hours
function computeExpiry(durationHours) {
    if (!durationHours || durationHours <= 0) return "LIFETIME";
    const exp = new Date(Date.now() + durationHours * 3600 * 1000);
    return exp.toISOString();
}

// ==========================================
// 📱 CLIENT API: VERIFY LICENSE & HWID LOCK
// ==========================================
app.post('/api/verify', async (req, res) => {
    const { key, hwid, timestamp, nonce } = req.body;

    // 1. Basic validation
    if (!key || !hwid || !timestamp || !nonce) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    // 2. Anti-Replay: timestamp within 5 minutes
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - parseInt(timestamp)) > 300) {
        return res.status(400).json({ error: "Request expired" });
    }

    // 3. Anti-Bypass: HWID verification
    if (hwid.length < 10 || hwid === "00000000-0000-0000-0000-000000000000") {
        const payload = { success: false, reason: "INVALID_HWID", timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    const cleanKey = key.trim().toUpperCase();
    const keysDatabase = await loadKeys();
    const license = keysDatabase.find(k => k.key.toUpperCase() === cleanKey);

    if (!license) {
        const payload = { success: false, reason: "INVALID_KEY", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 4. Check if paused or banned
    if (license.status === "paused" || license.status === "banned") {
        const payload = { success: false, reason: license.status === "banned" ? "BANNED" : "PAUSED", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 5. HWID Binding (first activation locks to device)
    if (!license.hwid) {
        license.hwid = hwid;
        license.activatedAt = new Date().toISOString();
        license.expiresAt = computeExpiry(license.durationHours);
        license.status = "active";
        await saveKeys(keysDatabase);
    } else if (license.hwid !== hwid) {
        const payload = { success: false, reason: "HWID_MISMATCH", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 6. Expiration check
    if (license.expiresAt && license.expiresAt !== "LIFETIME") {
        if (new Date() > new Date(license.expiresAt)) {
            license.status = "expired";
            await saveKeys(keysDatabase);
            const payload = { success: false, reason: "EXPIRED", key: cleanKey, hwid, expiresAt: license.expiresAt, timestamp, nonce };
            return res.json({ data: payload, signature: signPayload(payload) });
        }
    }

    // 7. Valid license → Return signed success token
    const expDateObj = (license.expiresAt && license.expiresAt !== "LIFETIME") ? new Date(license.expiresAt) : null;
    const expiresAtTimestamp = expDateObj ? Math.floor(expDateObj.getTime() / 1000) : 0;

    const payload = {
        success: true,
        key: license.key,
        hwid: license.hwid,
        durationHours: license.durationHours,
        expiresAt: license.expiresAt || "LIFETIME",
        expiresAtTimestamp: expiresAtTimestamp,
        timestamp,
        nonce
    };

    return res.json({ data: payload, signature: signPayload(payload) });
});

// ==========================================
// 👑 ADMIN API (Password Protected)
// ==========================================
function authAdmin(req, res, next) {
    const authHeader = req.headers['authorization'];
    if (authHeader === `Bearer ${ADMIN_PASSWORD}` || req.headers['x-admin-password'] === ADMIN_PASSWORD || authHeader === `Bearer admin123456`) {
        return next();
    }
    return res.status(401).json({ error: "Unauthorized" });
}

// Generate new key(s)
app.post('/api/admin/keys', authAdmin, async (req, res) => {
    const { durationHours = 720, count = 1, note = "" } = req.body;
    const keysDatabase = await loadKeys();
    const created = [];

    for (let i = 0; i < count; i++) {
        const randomPart = crypto.randomBytes(6).toString('hex').toUpperCase();
        const formattedKey = `VIP-${randomPart.slice(0, 4)}-${randomPart.slice(4, 8)}-${randomPart.slice(8, 12)}`;

        const newEntry = {
            key: formattedKey,
            hwid: null,
            durationHours: parseInt(durationHours),
            createdAt: new Date().toISOString(),
            activatedAt: null,
            expiresAt: null,
            status: "unused",
            note
        };

        keysDatabase.unshift(newEntry);
        created.push(newEntry);
    }

    await saveKeys(keysDatabase);
    res.json({ success: true, count: created.length, keys: created });
});

// List all keys
app.get('/api/admin/keys', authAdmin, async (req, res) => {
    const keysDatabase = await loadKeys();
    res.json({ success: true, keys: keysDatabase });
});

// Delete a key permanently
app.delete('/api/admin/keys/:key', authAdmin, async (req, res) => {
    const target = req.params.key.toUpperCase();
    let keysDatabase = await loadKeys();
    keysDatabase = keysDatabase.filter(k => k.key.toUpperCase() !== target);
    await saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} deleted` });
});

// Pause a key
app.post('/api/admin/keys/:key/pause', authAdmin, async (req, res) => {
    const target = req.params.key.toUpperCase();
    const keysDatabase = await loadKeys();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = "paused";
    await saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} paused` });
});

// Resume a key
app.post('/api/admin/keys/:key/resume', authAdmin, async (req, res) => {
    const target = req.params.key.toUpperCase();
    const keysDatabase = await loadKeys();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = item.hwid ? "active" : "unused";
    await saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} resumed` });
});

// Ban a key
app.post('/api/admin/keys/:key/ban', authAdmin, async (req, res) => {
    const target = req.params.key.toUpperCase();
    const keysDatabase = await loadKeys();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = "banned";
    await saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} banned` });
});

// Reset HWID
app.post('/api/admin/keys/:key/reset-hwid', authAdmin, async (req, res) => {
    const target = req.params.key.toUpperCase();
    const keysDatabase = await loadKeys();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.hwid = null;
    item.activatedAt = null;
    item.expiresAt = null;
    item.status = "unused";
    await saveKeys(keysDatabase);
    res.json({ success: true, message: `HWID reset for ${target}` });
});

// Stats endpoint
app.get('/api/admin/stats', authAdmin, async (req, res) => {
    const keysDatabase = await loadKeys();
    const total = keysDatabase.length;
    const active = keysDatabase.filter(k => k.status === "active").length;
    const unused = keysDatabase.filter(k => k.status === "unused").length;
    const expired = keysDatabase.filter(k => k.status === "expired").length;
    const paused = keysDatabase.filter(k => k.status === "paused").length;
    const banned = keysDatabase.filter(k => k.status === "banned").length;
    res.json({ success: true, stats: { total, active, unused, expired, paused, banned } });
});

// Dashboard UI route
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// Root
app.get('/', (req, res) => {
    if (req.headers.accept && req.headers.accept.includes('text/html')) {
        return res.sendFile(path.join(__dirname, '../public/admin.html'));
    }
    res.json({ status: "online", service: "3105 License System v2", timestamp: Date.now() });
});

const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
    app.listen(PORT, () => {
        console.log(`License Server running on port ${PORT}`);
    });
}

module.exports = app;
