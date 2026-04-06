// PictoGram Website JavaScript with Firebase Integration
class PictoGramApp {
    constructor() {
        this.currentUser = null;
        this.posts = [];
        this.messages = [];
        this.auth = null;
        this.firestore = null;
        this.init();
    }

    async init() {
        // Initialize Firebase
        this.initializeFirebase();
        
        // Wait for Firebase to initialize
        await this.waitForFirebase();
        
        // Setup auth listener
        this.setupAuthListener();
        
        // Load sample data (will be replaced with real data)
        this.loadSampleData();
        this.setupEventListeners();
        this.setupPostActions();
        this.renderPosts();
        this.renderMessages();
        this.setupSmoothScrolling();
    }

    // Initialize Firebase with your app's configuration
    initializeFirebase() {
        // TODO: Replace with your actual Firebase config from your Flutter app
        const firebaseConfig = {
            apiKey: "your-api-key-here",
            authDomain: "your-project-id.firebaseapp.com",
            projectId: "your-project-id",
            storageBucket: "your-project-id.appspot.com",
            messagingSenderId: "your-sender-id",
            appId: "your-app-id"
        };

        try {
            firebase.initializeApp(firebaseConfig);
            this.auth = firebase.auth();
            this.firestore = firebase.firestore();
            console.log('Firebase initialized successfully');
        } catch (error) {
            console.error('Firebase initialization error:', error);
            // For demo purposes, continue without Firebase
            this.showNotification('Firebase not configured - using demo mode', 'info');
        }
    }

    async waitForFirebase() {
        // Wait a bit for Firebase to initialize
        await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Setup Firebase auth listener
    setupAuthListener() {
        if (this.auth) {
            this.auth.onAuthStateChanged((user) => {
                if (user) {
                    this.currentUser = {
                        uid: user.uid,
                        email: user.email,
                        displayName: user.displayName || user.email.split('@')[0],
                        avatar: user.photoURL || `https://picsum.photos/seed/${user.uid}/120/120`
                    };
                    this.showNotification(`Welcome back, ${this.currentUser.displayName}!`, 'success');
                    this.updateUIForLoggedInUser();
                } else {
                    this.currentUser = null;
                    this.updateUIForLoggedOutUser();
                }
            });
        }
    }

    // Firebase Login
    async handleLogin(event) {
        event.preventDefault();
        
        if (!this.auth) {
            this.showNotification('Firebase not configured - using demo mode', 'info');
            // Demo login
            const email = event.target.querySelector('input[type="email"]').value;
            this.currentUser = {
                uid: 'demo-user',
                email: email,
                displayName: email.split('@')[0],
                avatar: `https://picsum.photos/seed/${email}/120/120`
            };
            closeModal('loginModal');
            this.showNotification('Demo login successful!', 'success');
            this.updateUIForLoggedInUser();
            return;
        }

        const email = event.target.querySelector('input[type="email"]').value;
        const password = event.target.querySelector('input[type="password"]').value;

        try {
            const userCredential = await this.auth.signInWithEmailAndPassword(email, password);
            closeModal('loginModal');
            this.showNotification('Login successful! Welcome back!', 'success');
        } catch (error) {
            console.error('Login error:', error);
            this.showNotification(this.getErrorMessage(error.code), 'error');
        }
    }

    // Firebase Signup
    async handleSignup(event) {
        event.preventDefault();
        
        if (!this.auth) {
            this.showNotification('Firebase not configured - using demo mode', 'info');
            // Demo signup
            const displayName = event.target.querySelector('input[type="text"]').value;
            const email = event.target.querySelector('input[type="email"]').value;
            this.currentUser = {
                uid: 'demo-user',
                email: email,
                displayName: displayName,
                avatar: `https://picsum.photos/seed/${email}/120/120`
            };
            closeModal('signupModal');
            this.showNotification('Demo account created successfully!', 'success');
            this.updateUIForLoggedInUser();
            return;
        }

        const displayName = event.target.querySelector('input[type="text"]').value;
        const email = event.target.querySelector('input[type="email"]').value;
        const password = event.target.querySelector('input[type="password"]').value;

        try {
            const userCredential = await this.auth.createUserWithEmailAndPassword(email, password);
            
            // Update display name
            await userCredential.user.updateProfile({
                displayName: displayName
            });

            closeModal('signupModal');
            this.showNotification('Account created successfully!', 'success');
        } catch (error) {
            console.error('Signup error:', error);
            this.showNotification(this.getErrorMessage(error.code), 'error');
        }
    }

    // Get user-friendly error messages
    getErrorMessage(errorCode) {
        const errorMessages = {
            'auth/user-not-found': 'No account found with this email',
            'auth/wrong-password': 'Incorrect password',
            'auth/email-already-in-use': 'An account with this email already exists',
            'auth/weak-password': 'Password should be at least 6 characters',
            'auth/invalid-email': 'Please enter a valid email address',
            'auth/user-disabled': 'This account has been disabled',
            'auth/too-many-requests': 'Too many failed attempts. Please try again later'
        };
        
        return errorMessages[errorCode] || 'An error occurred. Please try again.';
    }

    // Firebase Logout
    async handleLogout() {
        if (this.auth) {
            try {
                await this.auth.signOut();
                this.showNotification('Logged out successfully', 'success');
            } catch (error) {
                console.error('Logout error:', error);
                this.showNotification('Error logging out', 'error');
            }
        } else {
            // Demo logout
            this.currentUser = null;
            this.showNotification('Demo logout successful', 'success');
            this.updateUIForLoggedOutUser();
        }
    }

    // Update UI for logged in user
    updateUIForLoggedInUser() {
        if (this.currentUser) {
            // Update navigation
            const authButtons = document.querySelector('.auth-buttons');
            if (authButtons) {
                authButtons.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <img src="${this.currentUser.avatar}" alt="Avatar" style="width: 32px; height: 32px; border-radius: 50%; border: 2px solid var(--primary-purple);">
                        <span style="color: white; font-weight: 500;">${this.currentUser.displayName}</span>
                        <button onclick="app.handleLogout()" class="btn-secondary">Logout</button>
                    </div>
                `;
            }

            // Update mobile menu
            const mobileMenuButtons = document.querySelector('#mobileMenu button:last-of-type');
            if (mobileMenuButtons) {
                mobileMenuButtons.outerHTML = `
                    <button onclick="app.handleLogout(); toggleMobileMenu();" class="btn-secondary" style="width: 100%; margin-top: 12px;">Logout</button>
                `;
            }

            // Update profile section
            this.renderProfile();
        }
    }

    // Update UI for logged out user
    updateUIForLoggedOutUser() {
        // Update navigation
        const authButtons = document.querySelector('.auth-buttons');
        if (authButtons) {
            authButtons.innerHTML = `
                <button onclick="showLoginModal()" class="btn-secondary" style="margin-right: 12px;">
                    Login
                </button>
                <button onclick="showSignupModal()" class="btn-primary">
                    Sign Up
                </button>
            `;
        }

        // Update mobile menu
        const mobileMenuButtons = document.querySelector('#mobileMenu button:last-of-type');
        if (mobileMenuButtons) {
            mobileMenuButtons.outerHTML = `
                <button onclick="showLoginModal(); toggleMobileMenu();" class="btn-secondary" style="width: 100%; margin-top: 16px;">Login</button>
                <button onclick="showSignupModal(); toggleMobileMenu();" class="btn-primary" style="width: 100%; margin-top: 12px;">Sign Up</button>
            `;
        }

        // Update profile section
        this.renderProfile();
    }

    // Load sample data
    loadSampleData() {
        this.posts = [
            {
                id: 1,
                username: 'alex_dreamer',
                avatar: 'https://picsum.photos/seed/alex/40/40',
                image: 'https://picsum.photos/seed/post1/400/400',
                caption: 'Beautiful sunset at the beach 🌅',
                likes: 234,
                comments: 18,
                time: '2 hours ago',
                liked: false
            },
            {
                id: 2,
                username: 'sarah_creative',
                avatar: 'https://picsum.photos/seed/sarah/40/40',
                image: 'https://picsum.photos/seed/post2/400/400',
                caption: 'Coffee and creativity ☕✨',
                likes: 189,
                comments: 12,
                time: '4 hours ago',
                liked: true
            },
            {
                id: 3,
                username: 'mike_adventures',
                avatar: 'https://picsum.photos/seed/mike/40/40',
                image: 'https://picsum.photos/seed/post3/400/400',
                caption: 'Mountain climbing adventure 🏔️',
                likes: 456,
                comments: 34,
                time: '6 hours ago',
                liked: false
            },
            {
                id: 4,
                username: 'emma_artist',
                avatar: 'https://picsum.photos/seed/emma/40/40',
                image: 'https://picsum.photos/seed/post4/400/400',
                caption: 'Digital art creation 🎨',
                likes: 678,
                comments: 56,
                time: '8 hours ago',
                liked: true
            },
            {
                id: 5,
                username: 'john_photographer',
                avatar: 'https://picsum.photos/seed/john/40/40',
                image: 'https://picsum.photos/seed/post5/400/400',
                caption: 'Street photography 📸',
                likes: 345,
                comments: 28,
                time: '1 day ago',
                liked: false
            },
            {
                id: 6,
                username: 'lisa_foodie',
                avatar: 'https://picsum.photos/seed/lisa/40/40',
                image: 'https://picsum.photos/seed/post6/400/400',
                caption: 'Homemade pasta 🍝️',
                likes: 567,
                comments: 45,
                time: '1 day ago',
                liked: true
            }
        ];

        this.messages = [
            {
                id: 1,
                username: 'alex_dreamer',
                avatar: 'https://picsum.photos/seed/alex/48/48',
                lastMessage: 'Hey! How are you doing?',
                time: '5 min ago',
                unread: 2
            },
            {
                id: 2,
                username: 'sarah_creative',
                avatar: 'https://picsum.photos/seed/sarah/48/48',
                lastMessage: 'Thanks for the like!',
                time: '1 hour ago',
                unread: 0
            },
            {
                id: 3,
                username: 'mike_adventures',
                avatar: 'https://picsum.photos/seed/mike/48/48',
                lastMessage: 'Check out my new photos',
                time: '3 hours ago',
                unread: 1
            },
            {
                id: 4,
                username: 'emma_artist',
                avatar: 'https://picsum.photos/seed/emma/48/48',
                lastMessage: 'Love your work!',
                time: '1 day ago',
                unread: 0
            }
        ];
    }

    // Setup event listeners
    setupEventListeners() {
        // Mobile menu toggle
        window.toggleMobileMenu = () => {
            const menu = document.getElementById('mobileMenu');
            menu.classList.toggle('hidden');
        };

        // Modal functions
        window.showLoginModal = () => {
            document.getElementById('loginModal').classList.remove('hidden');
        };

        window.showSignupModal = () => {
            document.getElementById('signupModal').classList.remove('hidden');
        };

        window.closeModal = (modalId) => {
            document.getElementById(modalId).classList.add('hidden');
        };

        window.switchToSignup = () => {
            closeModal('loginModal');
            showSignupModal();
        };

        window.switchToLogin = () => {
            closeModal('signupModal');
            showLoginModal();
        };

        // Form handlers
        window.handleLogin = (event) => {
            app.handleLogin(event);
        };

        window.handleSignup = (event) => {
            app.handleSignup(event);
        };
    }

    // Update UI for logged in user
    updateUIForLoggedInUser() {
        if (this.currentUser) {
            // Update navigation
            const authButtons = document.querySelector('nav .hidden.md\\:block:last-child');
            if (authButtons) {
                authButtons.innerHTML = `
                    <div class="flex items-center space-x-4">
                        <span class="text-gray-300">Welcome, ${this.currentUser.username}!</span>
                        <button onclick="logout()" class="bg-gray-700 hover:bg-gray-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                            Logout
                        </button>
                    </div>
                `;
            }
        }
    }

    // Render posts
    renderPosts() {
        const postsGrid = document.getElementById('postsGrid');
        if (!postsGrid) return;

        postsGrid.innerHTML = this.posts.map(post => `
            <div class="post-card card-enter">
                <div class="post-header">
                    <img src="${post.avatar}" alt="${post.username}" class="post-avatar">
                    <div class="post-info">
                        <div class="post-username">${post.username}</div>
                        <div class="post-time">${post.time}</div>
                    </div>
                </div>
                <img src="${post.image}" alt="Post image" class="post-image">
                <div class="post-content">
                    <p class="text-gray-300 mb-3">${post.caption}</p>
                    <div class="post-actions">
                        <button class="post-action-btn ${post.liked ? 'liked' : ''}" onclick="toggleLike(${post.id})">
                            <i class="${post.liked ? 'fas' : 'far'} fa-heart"></i>
                            <span class="ml-1">${post.likes}</span>
                        </button>
                        <button class="post-action-btn" onclick="openComments(${post.id})">
                            <i class="far fa-comment"></i>
                            <span class="ml-1">${post.comments}</span>
                        </button>
                        <button class="post-action-btn" onclick="sharePost(${post.id})">
                            <i class="fas fa-share"></i>
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    }

    // Render messages
    renderMessages() {
        const messagesList = document.getElementById('messagesList');
        if (!messagesList) return;

        messagesList.innerHTML = `
            <div class="bg-gray-800 rounded-xl p-6 border border-purple-500/20">
                <h3 class="text-xl font-semibold mb-4">Recent Messages</h3>
                <div class="space-y-2">
                    ${this.messages.map(message => `
                        <div class="message-item" onclick="openChat(${message.id})">
                            <div class="flex items-center">
                                <img src="${message.avatar}" alt="${message.username}" class="message-avatar">
                                <div class="message-content">
                                    <div class="message-username">${message.username}</div>
                                    <div class="message-preview">${message.lastMessage}</div>
                                </div>
                                <div class="text-right">
                                    <div class="message-time">${message.time}</div>
                                    ${message.unread > 0 ? `<div class="unread-badge ml-auto">${message.unread}</div>` : ''}
                                </div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    // Render profile
    renderProfile() {
        const profileContent = document.getElementById('profileContent');
        if (!profileContent) return;

        if (this.currentUser) {
            profileContent.innerHTML = `
                <div class="bg-gray-800 rounded-xl p-8 border border-purple-500/20">
                    <div class="profile-header">
                        <img src="${this.currentUser.avatar}" alt="${this.currentUser.username}" class="profile-avatar">
                        <div class="profile-username">${this.currentUser.username}</div>
                        <div class="profile-bio">${this.currentUser.email}</div>
                        <div class="profile-stats">
                            <div class="profile-stat">
                                <div class="profile-stat-value">42</div>
                                <div class="profile-stat-label">Posts</div>
                            </div>
                            <div class="profile-stat">
                                <div class="profile-stat-value">1.2K</div>
                                <div class="profile-stat-label">Followers</div>
                            </div>
                            <div class="profile-stat">
                                <div class="profile-stat-value">856</div>
                                <div class="profile-stat-label">Following</div>
                            </div>
                        </div>
                        <div class="profile-actions">
                            <button class="btn btn-primary">Edit Profile</button>
                            <button class="btn btn-secondary">Settings</button>
                        </div>
                    </div>
                </div>
            `;
        } else {
            profileContent.innerHTML = `
                <div class="glass-card text-center">
                    <div style="color: rgba(255,255,255,0.7); margin-bottom: 24px;">Please login to view your profile</div>
                    <button onclick="showLoginModal()" class="btn-primary">Login</button>
                </div>
            `;
        }
    }

    // Post actions
    setupPostActions() {
        window.toggleLike = (postId) => {
            const post = this.posts.find(p => p.id === postId);
            if (post) {
                post.liked = !post.liked;
                post.likes += post.liked ? 1 : -1;
                this.renderPosts();
            }
        };

        window.openComments = (postId) => {
            this.showNotification('Comments feature coming soon!', 'info');
        };

        window.sharePost = (postId) => {
            const post = this.posts.find(p => p.id === postId);
            if (post) {
                const shareUrl = `https://pictogram.online/post/${postId}`;
                navigator.clipboard.writeText(shareUrl);
                this.showNotification('Post link copied to clipboard!', 'success');
            }
        };
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 80px;
            right: 20px;
            z-index: 10000;
            padding: 16px;
            border-radius: 12px;
            color: white;
            max-width: 320px;
            background: ${type === 'success' ? 'linear-gradient(135deg, #E0389A, #CC2299)' : 
                         type === 'error' ? 'linear-gradient(135deg, #dc2626, #b91c1c)' : 
                         'linear-gradient(135deg, #2563eb, #1d4ed8)'};
            border: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            animation: slideIn 0.3s ease;
        `;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => {
                notification.remove();
            }, 300);
        }, 3000);
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new PictoGramApp();
    
    // Add smooth scroll behavior for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
    
    // Add scroll effect to navigation
    window.addEventListener('scroll', () => {
        const nav = document.querySelector('nav');
        if (window.scrollY > 100) {
            nav.style.background = 'rgba(10, 0, 16, 0.98)';
        } else {
            nav.style.background = 'rgba(10, 0, 16, 0.95)';
        }
    });
});

// Add intersection observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
        }
    });
}, observerOptions);

// Observe elements for animations
document.addEventListener('DOMContentLoaded', () => {
    const elementsToAnimate = document.querySelectorAll('.post-card, .message-item');
    elementsToAnimate.forEach(el => observer.observe(el));
});
