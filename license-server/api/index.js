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
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "admin123456";
const HMAC_SECRET = process.env.HMAC_SECRET || "sinko3105_secret_key_abc789xyz";

// Persistent storage (Vercel /tmp — resets on cold start, use a DB for permanent storage)
const DATA_FILE = path.join('/tmp', 'licenses_v2.json');

function loadKeys() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        }
    } catch (e) {}
    return [];
}

function saveKeys(keys) {
    try {
        fs.writeFileSync(DATA_FILE, JSON.stringify(keys, null, 2), 'utf8');
    } catch (e) {}
}

let keysDatabase = loadKeys();

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
app.post('/api/verify', (req, res) => {
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

    // 3. Anti-Bypass: HWID must be a plausible UUID, reject obvious fakes
    const uuidRegex = /^[0-9A-F-]{32,}$/i;
    if (hwid.length < 10 || hwid === "00000000-0000-0000-0000-000000000000") {
        const payload = { success: false, reason: "INVALID_HWID", timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    const cleanKey = key.trim().toUpperCase();
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
        saveKeys(keysDatabase);
    } else if (license.hwid !== hwid) {
        const payload = { success: false, reason: "HWID_MISMATCH", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 6. Expiration check
    if (license.expiresAt && license.expiresAt !== "LIFETIME") {
        if (new Date() > new Date(license.expiresAt)) {
            license.status = "expired";
            saveKeys(keysDatabase);
            const payload = { success: false, reason: "EXPIRED", key: cleanKey, hwid, expiresAt: license.expiresAt, timestamp, nonce };
            return res.json({ data: payload, signature: signPayload(payload) });
        }
    }

    // 7. Valid license → Return signed success token
    const payload = {
        success: true,
        key: license.key,
        hwid: license.hwid,
        durationHours: license.durationHours,
        expiresAt: license.expiresAt || "LIFETIME",
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
    if (authHeader === `Bearer ${ADMIN_PASSWORD}` || req.headers['x-admin-password'] === ADMIN_PASSWORD) {
        return next();
    }
    return res.status(401).json({ error: "Unauthorized" });
}

// Generate new key(s) — supports custom hours
app.post('/api/admin/keys', authAdmin, (req, res) => {
    const { durationHours = 720, count = 1, note = "" } = req.body;
    // durationHours: 0 = Lifetime, 1 = 1 hour, 24 = 1 day, 720 = 30 days, etc.
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

    saveKeys(keysDatabase);
    res.json({ success: true, count: created.length, keys: created });
});

// List all keys
app.get('/api/admin/keys', authAdmin, (req, res) => {
    res.json({ success: true, keys: keysDatabase });
});

// Delete a key permanently
app.delete('/api/admin/keys/:key', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    keysDatabase = keysDatabase.filter(k => k.key.toUpperCase() !== target);
    saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} deleted` });
});

// Pause a key (blocks login but keeps HWID and data)
app.post('/api/admin/keys/:key/pause', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = "paused";
    saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} paused` });
});

// Resume (un-pause) a key
app.post('/api/admin/keys/:key/resume', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = item.hwid ? "active" : "unused";
    saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} resumed` });
});

// Ban a key permanently (harder than pause — shows BANNED error)
app.post('/api/admin/keys/:key/ban', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.status = "banned";
    saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} banned` });
});

// Reset HWID (allows key to activate on a new device)
app.post('/api/admin/keys/:key/reset-hwid', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    item.hwid = null;
    item.activatedAt = null;
    item.expiresAt = null;
    item.status = "unused";
    saveKeys(keysDatabase);
    res.json({ success: true, message: `HWID reset for ${target}` });
});

// Stats endpoint
app.get('/api/admin/stats', authAdmin, (req, res) => {
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
        console.log(`License Server v2 running on port ${PORT}`);
    });
}

module.exports = app;
