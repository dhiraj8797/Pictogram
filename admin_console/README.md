# PictoGram Admin Console

A standalone web admin dashboard — **no build step, no app, just open in a browser.**

---

## How to Access

### Option 1 — Open directly (simplest)
1. Open `admin_console/index.html` directly in **Chrome** or **Edge**
2. Log in with your admin email & password

> ⚠️ Some browsers block Firebase when opening `file://` URLs.  
> If login fails, use Option 2.

### Option 2 — Serve locally (recommended)
```bash
# If you have Python installed:
cd admin_console
python -m http.server 8080

# Then open: http://localhost:8080
```

Or with Node.js:
```bash
npx serve admin_console
```

---

## First-Time Setup: Grant Admin Access

You must manually set `isAdmin: true` on your account in Firestore.

### Via Firebase Console:
1. Go to → https://console.firebase.google.com/project/pictogram-af7c8/firestore
2. Open the **`users`** collection
3. Find your user document (match by email)
4. Add field: **`isAdmin`** → **`boolean`** → **`true`**
5. Save

Now log in to the admin console with that email and password.

---

## Features

| Section | What you can do |
|---------|----------------|
| **Dashboard** | Total users, posts, open reports, verified users, recent activity |
| **Users** | Search, filter, ban/unban, grant/remove verification badge, delete |
| **Posts** | Browse all posts, preview images, delete content |
| **Reports** | View open reports, dismiss, delete content, or ban reported user |

---

## Security Notes

- Only accounts with `isAdmin: true` in Firestore can log in
- The admin console is **completely separate** from the mobile app
- No admin UI is exposed inside the PictoGram app
- Never share or deploy this file publicly without adding Firestore security rules

### Recommended Firestore Rule (add to Firebase Console):
```javascript
match /users/{uid} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```
