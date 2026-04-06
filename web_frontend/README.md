# PictoGram Website

A modern, responsive web version of PictoGram social media platform built with HTML, CSS, and JavaScript.

## Features

### 🎨 Core Features
- **Responsive Design** - Works perfectly on desktop, tablet, and mobile
- **Modern UI** - Glassmorphism effects with purple/pink gradient theme
- **User Authentication** - Login and signup functionality
- **Post Feed** - Browse and interact with posts
- **Messaging System** - Real-time chat interface
- **Profile Management** - User profiles with statistics
- **Smooth Animations** - Engaging micro-interactions

### 🚀 Technical Features
- **No Framework Dependencies** - Pure HTML/CSS/JavaScript
- **Tailwind CSS** - Utility-first CSS framework
- **Font Awesome Icons** - Beautiful icon library
- **LocalStorage** - Client-side data persistence
- **Responsive Images** - Optimized for all devices
- **SEO Optimized** - Meta tags and semantic HTML

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/dhiraj8797/Pictogram.git
cd Pictogram/web_frontend
```

### 2. Open in Browser
Simply open `index.html` in your web browser:
```bash
# Option 1: Double-click index.html
# Option 2: Use live server
npx serve .
# Option 3: Python server
python -m http.server 8000
```

### 3. Deploy to pictogram.online
The website is ready to deploy to your domain `pictogram.online`.

## Deployment Options

### Option 1: Static Hosting (Recommended)
Deploy to any static hosting service:
- **Netlify** - Drag and drop deployment
- **Vercel** - Zero-config deployment
- **GitHub Pages** - Free hosting from your repo
- **Firebase Hosting** - Google's hosting solution

### Option 2: Traditional Hosting
Upload the files to your web server:
- Upload all files to `public_html` or `www` directory
- Ensure `index.html` is the default document
- Configure domain DNS to point to your server

### Option 3: CDN Deployment
Use a CDN for global performance:
- **Cloudflare** - Free CDN with SSL
- **AWS CloudFront** - Amazon's CDN
- **Fastly** - Enterprise CDN solution

## Configuration

### Domain Setup
1. **DNS Configuration**: Point `pictogram.online` to your hosting
2. **SSL Certificate**: Enable HTTPS (free with Let's Encrypt)
3. **Domain Verification**: Add domain to hosting provider

### Firebase Integration (Optional)
```javascript
// Add your Firebase config in script.js
const firebaseConfig = {
    apiKey: "your-api-key",
    authDomain: "pictogram-online.firebaseapp.com",
    projectId: "pictogram-online",
    // ... other config
};
```

## Features Breakdown

### 🏠 Home Section
- Hero section with call-to-action
- Gradient text effects
- Smooth animations
- Mobile-responsive design

### 📱 Features Section
- Three-column feature showcase
- Icon-based feature highlights
- Hover effects and animations
- Glassmorphism card design

### 📸 Explore Section
- Dynamic post grid layout
- Post interaction (like, comment, share)
- User avatars and metadata
- Responsive image handling

### 💬 Messages Section
- Message list with unread indicators
- User avatars and last messages
- Hover effects for interaction
- Mobile-optimized layout

### 👤 Profile Section
- User profile display
- Statistics dashboard
- Edit profile functionality
- Settings integration

## Customization

### 🎨 Theme Colors
Edit `styles.css` to customize colors:
```css
:root {
    --primary-purple: #9333ea;
    --primary-pink: #ec4899;
    --dark-bg: #111827;
    --card-bg: #1f2937;
}
```

### 🖼️ Images
Replace placeholder images:
- Update avatar URLs in `script.js`
- Replace post images with your content
- Add your own logo and branding

### 📝 Content
Edit text content in `index.html`:
- Update headings and descriptions
- Modify feature descriptions
- Customize footer links

## Performance Optimization

### 🚀 Image Optimization
- Use WebP format for better compression
- Implement lazy loading for images
- Add responsive image sources

### ⚡ Code Optimization
- Minify CSS and JavaScript
- Enable Gzip compression
- Use CDN for assets

### 🔍 SEO Best Practices
- Meta tags for search engines
- Semantic HTML structure
- Alt tags for images
- Structured data markup

## Browser Support

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile Safari (iOS 14+)
- ✅ Chrome Mobile (Android 10+)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple devices
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- 📧 Email: support@pictogram.online
- 🐛 Issues: GitHub Issues
- 💬 Discord: [Community Server]

---

**Built with ❤️ for the PictoGram community**
