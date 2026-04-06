// PictoGram Website JavaScript
class PictoGramApp {
    constructor() {
        this.currentUser = null;
        this.posts = [];
        this.messages = [];
        this.init();
    }

    init() {
        this.loadSampleData();
        this.setupEventListeners();
        this.renderPosts();
        this.renderMessages();
        this.setupSmoothScrolling();
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
            event.preventDefault();
            const email = event.target.querySelector('input[type="email"]').value;
            const password = event.target.querySelector('input[type="password"]').value;
            
            // Simulate login
            this.currentUser = {
                username: email.split('@')[0],
                email: email,
                avatar: `https://picsum.photos/seed/${email}/120/120`
            };
            
            closeModal('loginModal');
            this.showNotification('Login successful! Welcome back!', 'success');
            this.updateUIForLoggedInUser();
        };

        window.handleSignup = (event) => {
            event.preventDefault();
            const displayName = event.target.querySelector('input[type="text"]').value;
            const email = event.target.querySelector('input[type="email"]').value;
            const password = event.target.querySelector('input[type="password"]').value;
            
            // Simulate signup
            this.currentUser = {
                username: displayName,
                email: email,
                avatar: `https://picsum.photos/seed/${email}/120/120`
            };
            
            closeModal('signupModal');
            this.showNotification('Account created successfully!', 'success');
            this.updateUIForLoggedInUser();
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
                <div class="bg-gray-800 rounded-xl p-8 border border-purple-500/20 text-center">
                    <div class="text-gray-400 mb-4">Please login to view your profile</div>
                    <button onclick="showLoginModal()" class="btn btn-primary">Login</button>
                </div>
            `;
        }
    }

    // Post actions
    window.toggleLike = (postId) => {
        const post = app.posts.find(p => p.id === postId);
        if (post) {
            post.liked = !post.liked;
            post.likes += post.liked ? 1 : -1;
            app.renderPosts();
        }
    };

    window.openComments = (postId) => {
        app.showNotification('Comments feature coming soon!', 'info');
    };

    window.sharePost = (postId) => {
        const post = app.posts.find(p => p.id === postId);
        if (post) {
            // Simulate share
            if (navigator.share) {
                navigator.share({
                    title: 'Post by ' + post.username,
                    text: post.caption,
                    url: `https://pictogram.online/post/${postId}`
                });
            } else {
                app.showNotification('Post link copied to clipboard!', 'success');
            }
        }
    };

    window.openChat = (messageId) => {
        const message = app.messages.find(m => m.id === messageId);
        if (message) {
            app.showNotification(`Opening chat with ${message.username}...`, 'info');
        }
    };

    window.logout = () => {
        this.currentUser = null;
        location.reload();
    };

    // Utility functions
    setupSmoothScrolling() {
        window.scrollToSection = (sectionId) => {
            const section = document.getElementById(sectionId);
            if (section) {
                section.scrollIntoView({ behavior: 'smooth' });
            }
        };
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `fixed top-20 right-4 z-50 p-4 rounded-lg text-white max-w-sm fade-in ${
            type === 'success' ? 'bg-green-600' : 
            type === 'error' ? 'bg-red-600' : 
            'bg-blue-600'
        }`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
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
            nav.classList.add('bg-gray-900/98');
            nav.classList.remove('bg-gray-900/95');
        } else {
            nav.classList.add('bg-gray-900/95');
            nav.classList.remove('bg-gray-900/98');
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
