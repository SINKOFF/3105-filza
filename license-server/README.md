# 🔐 3105 iOS License & HWID Authentication Server

A high-performance, standalone license key generation, validation, and HWID management system built for iOS (IPA) applications and web management.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2FSINKOFF%2F3105-license-server&env=ADMIN_PASSWORD,HMAC_SECRET)
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/SINKOFF/3105-license-server)

---

## 🚀 Features

- **📱 Mobile & Desktop Web Dashboard**: Generate, manage, and revoke keys directly from your iPhone (Safari/Chrome) or PC.
- **🔒 HWID Lock**: Automatically locks keys to the specific iOS device on first activation to prevent key sharing.
- **🔄 HWID Reset**: 1-click HWID reset from the admin dashboard when a user changes their device.
- **🛡️ Cryptographic Security**: HMAC-SHA256 signatures on all API responses prevent memory injection or response manipulation.
- **⏱️ Anti-Replay Protection**: Timestamps and nonce verification prevent packet replay attacks.
- **☁️ 24/7 Cloud Ready**: Deploy instantly on **Vercel** or **Render** for 100% uptime with zero server maintenance.

---

## 🛠️ Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `ADMIN_PASSWORD` | `admin123456` | Password required to access `/admin` dashboard |
| `HMAC_SECRET` | `3105_SECURE_HMAC_KEY_98F7A12BC83` | Secret key used to cryptographically sign API verification responses |

---

## 📱 iOS Swift Client Integration

In your iOS project (`LicenseService.swift`), point `serverURL` to your deployed URL:

```swift
private let serverURL = "https://your-license-api.vercel.app"
private let hmacSecret = "3105_SECURE_HMAC_KEY_98F7A12BC83"
```
