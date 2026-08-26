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
// 🛡️ SECRET CONFIGURATION (Keep this safe)
// ==========================================
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "admin123456";
const HMAC_SECRET = process.env.HMAC_SECRET || "3105_SECURE_HMAC_KEY_98F7A12BC83";

// Simple persistent storage file for keys
const DATA_FILE = path.join('/tmp', 'licenses.json');

function loadKeys() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        }
    } catch (e) {}
    return [
        {
            key: "VIP-3105-DEMO-KEY",
            hwid: null,
            durationDays: 30,
            createdAt: new Date().toISOString(),
            activatedAt: null,
            expiresAt: null,
            note: "Demo Test Key"
        }
    ];
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

// ==========================================
// 📱 CLIENT API: VERIFY LICENSE & HWID LOCK
// ==========================================
app.post('/api/verify', (req, res) => {
    const { key, hwid, timestamp, nonce } = req.body;

    // 1. Basic validation
    if (!key || !hwid || !timestamp || !nonce) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    // 2. Anti-Replay: check timestamp freshness (within 5 minutes)
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - parseInt(timestamp)) > 300) {
        return res.status(400).json({ error: "Request expired (Timestamp skew)" });
    }

    const cleanKey = key.trim().toUpperCase();
    const license = keysDatabase.find(k => k.key.toUpperCase() === cleanKey);

    if (!license) {
        const payload = { success: false, reason: "INVALID_KEY", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 3. HWID Binding (First activation locks to device)
    if (!license.hwid) {
        license.hwid = hwid;
        license.activatedAt = new Date().toISOString();
        if (license.durationDays > 0) {
            const exp = new Date();
            exp.setDate(exp.getDate() + license.durationDays);
            license.expiresAt = exp.toISOString();
        } else {
            license.expiresAt = "LIFETIME";
        }
        saveKeys(keysDatabase);
    } else if (license.hwid !== hwid) {
        const payload = { success: false, reason: "HWID_MISMATCH", key: cleanKey, hwid, timestamp, nonce };
        return res.json({ data: payload, signature: signPayload(payload) });
    }

    // 4. Expiration check
    if (license.expiresAt && license.expiresAt !== "LIFETIME") {
        if (new Date() > new Date(license.expiresAt)) {
            const payload = { success: false, reason: "EXPIRED", key: cleanKey, hwid, expiresAt: license.expiresAt, timestamp, nonce };
            return res.json({ data: payload, signature: signPayload(payload) });
        }
    }

    // 5. Valid license -> Return cryptographically signed success token
    const payload = {
        success: true,
        key: license.key,
        hwid: license.hwid,
        durationDays: license.durationDays,
        expiresAt: license.expiresAt || "LIFETIME",
        timestamp,
        nonce
    };

    return res.json({
        data: payload,
        signature: signPayload(payload)
    });
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

// Generate new key(s)
app.post('/api/admin/keys', authAdmin, (req, res) => {
    const { durationDays = 30, count = 1, note = "" } = req.body;
    const created = [];

    for (let i = 0; i < count; i++) {
        const randomPart = crypto.randomBytes(6).toString('hex').toUpperCase();
        const formattedKey = `VIP-${randomPart.slice(0, 4)}-${randomPart.slice(4, 8)}-${randomPart.slice(8, 12)}`;
        
        const newEntry = {
            key: formattedKey,
            hwid: null,
            durationDays: parseInt(durationDays),
            createdAt: new Date().toISOString(),
            activatedAt: null,
            expiresAt: null,
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

// Delete a key
app.delete('/api/admin/keys/:key', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    keysDatabase = keysDatabase.filter(k => k.key.toUpperCase() !== target);
    saveKeys(keysDatabase);
    res.json({ success: true, message: `Key ${target} deleted` });
});

// Reset HWID
app.post('/api/admin/keys/:key/reset-hwid', authAdmin, (req, res) => {
    const target = req.params.key.toUpperCase();
    const item = keysDatabase.find(k => k.key.toUpperCase() === target);
    if (!item) return res.status(404).json({ error: "Key not found" });
    
    item.hwid = null;
    saveKeys(keysDatabase);
    res.json({ success: true, message: `HWID reset for ${target}` });
});

// Dashboard UI route
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// Root welcome
app.get('/', (req, res) => {
    res.json({ status: "online", service: "3105 License System", timestamp: Date.now() });
});

const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
    app.listen(PORT, () => {
        console.log(`License Server running on port ${PORT}`);
    });
}

module.exports = app;
