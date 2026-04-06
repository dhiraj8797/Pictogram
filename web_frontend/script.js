// PictoGram Website JavaScript with Firebase Integration
class PictoGramApp {
    constructor() {
        this.currentUser = null;
        this.posts = [];
        this.messages = [];
        this.auth = null;
        this.firestore = null;
        
        // Login screen state (matching app)
        this.useEmailLogin = true;
        this.useEmailSignup = true;
        this.obscurePassword = true;
        this.obscureSignupPassword = true;
        this.isLoading = false;
        this.errorMessage = null;
        
        this.init();
    }

    // Setup smooth scrolling
    setupSmoothScrolling() {
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
    }

    init() {
        // Initialize Firebase
        this.initializeFirebase();
        
        // Wait for Firebase to initialize
        this.waitForFirebase().then(async () => {
            // Setup auth listener
            this.setupAuthListener();
            
            // Load sample data (will be replaced with real data)
            await this.loadSampleData();
            this.setupEventListeners();
            this.setupPostActions();
            this.renderPosts();
            this.renderMessages();
            this.setupSmoothScrolling();
        });
    }

    // Initialize Firebase with your app's configuration
    initializeFirebase() {
        // Real Firebase credentials from your Flutter app
        const firebaseConfig = {
            apiKey: "AIzaSyB72KxNCbgSNHMOm-zaLuCkT1e6GOsidJI",
            authDomain: "pictogram-af7c8.firebaseapp.com",
            projectId: "pictogram-af7c8",
            storageBucket: "pictogram-af7c8.firebasestorage.app",
            messagingSenderId: "793414644362",
            appId: "1:793414644362:web:a32b3dde636591a50c3373"
        };

        // Check if using placeholder config
        const isPlaceholderConfig = firebaseConfig.apiKey === "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ||
                                   firebaseConfig.apiKey.includes("XXXXXXXX") ||
                                   firebaseConfig.projectId === "your-project-id";
        
        if (isPlaceholderConfig) {
            console.log('Firebase not configured - using demo mode');
            console.log('To use real Firebase, update the firebaseConfig in script.js with your actual credentials');
            this.auth = null;
            this.firestore = null;
            return;
        }

        try {
            firebase.initializeApp(firebaseConfig);
            this.auth = firebase.auth();
            this.firestore = firebase.firestore();
            console.log('Firebase initialized successfully');
        } catch (error) {
            console.error('Firebase initialization error:', error);
            // Fall back to demo mode
            this.auth = null;
            this.firestore = null;
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

    // Login screen methods (matching app)
    switchToEmailLogin() {
        this.useEmailLogin = true;
        this.updateLoginUI();
    }

    switchToPhoneLogin() {
        this.useEmailLogin = false;
        this.updateLoginUI();
    }

    togglePassword() {
        this.obscurePassword = !this.obscurePassword;
        this.updatePasswordVisibility();
    }

    toggleSignupPassword() {
        this.obscureSignupPassword = !this.obscureSignupPassword;
        this.updateSignupPasswordVisibility();
    }

    switchToEmailSignup() {
        this.useEmailSignup = true;
        this.updateSignupUI();
    }

    switchToPhoneSignup() {
        this.useEmailSignup = false;
        this.updateSignupUI();
    }

    updateSignupUI() {
        // Update toggle buttons
        const emailToggle = document.getElementById('signupEmailToggle');
        const phoneToggle = document.getElementById('signupPhoneToggle');
        const emailText = document.getElementById('signupEmailToggleText');
        const phoneText = document.getElementById('signupPhoneToggleText');
        const fieldIcon = document.getElementById('signupFieldIcon');
        const emailField = document.getElementById('signupEmailField');
        const phoneField = document.getElementById('signupPhoneField');
        const passwordField = document.getElementById('signupPasswordField');
        const forgotPassword = document.getElementById('signupForgotPassword');

        if (this.useEmailSignup) {
            // Email selected
            emailToggle.style.background = 'rgba(255,255,255,0.1)';
            phoneToggle.style.background = 'transparent';
            emailText.style.color = 'white';
            emailText.style.fontWeight = '600';
            phoneText.style.color = 'rgba(255,255,255,0.5)';
            phoneText.style.fontWeight = 'normal';
            
            fieldIcon.className = 'fas fa-envelope';
            emailField.style.display = 'block';
            phoneField.style.display = 'none';
            emailField.required = true;
            phoneField.required = false;
            passwordField.style.display = 'block';
            forgotPassword.style.display = 'block';
        } else {
            // Phone selected
            emailToggle.style.background = 'transparent';
            phoneToggle.style.background = 'rgba(255,255,255,0.1)';
            emailText.style.color = 'rgba(255,255,255,0.5)';
            emailText.style.fontWeight = 'normal';
            phoneText.style.color = 'white';
            phoneText.style.fontWeight = '600';
            
            fieldIcon.className = 'fas fa-phone';
            emailField.style.display = 'none';
            phoneField.style.display = 'block';
            emailField.required = false;
            phoneField.required = true;
            passwordField.style.display = 'none';
            forgotPassword.style.display = 'none';
        }
    }

    updateLoginUI() {
        // Update toggle buttons
        const emailToggle = document.getElementById('emailToggle');
        const phoneToggle = document.getElementById('phoneToggle');
        const emailText = document.getElementById('emailToggleText');
        const phoneText = document.getElementById('phoneToggleText');
        const fieldIcon = document.getElementById('fieldIcon');
        const emailField = document.getElementById('emailField');
        const phoneField = document.getElementById('phoneField');
        const passwordField = document.getElementById('passwordField');
        const forgotPassword = document.getElementById('forgotPassword');

        if (this.useEmailLogin) {
            // Email selected
            emailToggle.style.background = 'rgba(255,255,255,0.1)';
            phoneToggle.style.background = 'transparent';
            emailText.style.color = 'white';
            emailText.style.fontWeight = '600';
            phoneText.style.color = 'rgba(255,255,255,0.5)';
            phoneText.style.fontWeight = 'normal';
            
            fieldIcon.className = 'fas fa-envelope';
            emailField.style.display = 'block';
            phoneField.style.display = 'none';
            emailField.required = true;
            phoneField.required = false;
            passwordField.style.display = 'block';
            forgotPassword.style.display = 'block';
        } else {
            // Phone selected
            emailToggle.style.background = 'transparent';
            phoneToggle.style.background = 'rgba(255,255,255,0.1)';
            emailText.style.color = 'rgba(255,255,255,0.5)';
            emailText.style.fontWeight = 'normal';
            phoneText.style.color = 'white';
            phoneText.style.fontWeight = '600';
            
            fieldIcon.className = 'fas fa-phone';
            emailField.style.display = 'none';
            phoneField.style.display = 'block';
            emailField.required = false;
            phoneField.required = true;
            passwordField.style.display = 'none';
            forgotPassword.style.display = 'none';
        }
    }

    updatePasswordVisibility() {
        const passwordIcon = document.getElementById('passwordIcon');
        const passwordInput = document.querySelector('#passwordField input[type="password"]');
        
        if (this.obscurePassword) {
            passwordIcon.className = 'fas fa-eye';
            passwordInput.type = 'password';
        } else {
            passwordIcon.className = 'fas fa-eye-slash';
            passwordInput.type = 'text';
        }
    }

    updateSignupPasswordVisibility() {
        const passwordIcon = document.getElementById('signupPasswordIcon');
        const passwordInput = document.getElementById('signupPassword');
        
        if (this.obscureSignupPassword) {
            passwordIcon.className = 'fas fa-eye';
            passwordInput.type = 'password';
        } else {
            passwordIcon.className = 'fas fa-eye-slash';
            passwordInput.type = 'text';
        }
    }

    showError(message, modalId) {
        const errorDiv = document.getElementById(modalId + 'Error');
        const errorText = document.getElementById(modalId + 'ErrorText');
        
        errorText.textContent = message;
        errorDiv.style.display = 'block';
        
        // Auto-hide after 3 seconds
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 3000);
    }

    hideError(modalId) {
        const errorDiv = document.getElementById(modalId + 'Error');
        errorDiv.style.display = 'none';
    }

    setLoading(loading, modalId) {
        const button = document.getElementById(modalId + 'Button');
        const buttonText = document.getElementById(modalId + 'ButtonText');
        
        this.isLoading = loading;
        
        if (loading) {
            button.disabled = true;
            buttonText.innerHTML = '<div class="loading-spinner"></div>';
        } else {
            button.disabled = false;
            buttonText.textContent = modalId === 'login' ? 'Login' : 'Sign Up';
        }
    }

    // Validation (matching app logic)
    validateLoginForm(email, phone, password) {
        console.log('DEBUG: validateLoginForm called', { useEmailLogin: this.useEmailLogin, email, phone, password: password.length > 0 });
        
        if (this.useEmailLogin) {
            if (!email) {
                console.log('DEBUG: Email validation failed - empty');
                this.showError('Please enter your email', 'login');
                return false;
            }
            if (!this.isValidEmail(email)) {
                console.log('DEBUG: Email validation failed - invalid format');
                this.showError('Please enter a valid email', 'login');
                return false;
            }
            if (!password) {
                console.log('DEBUG: Password validation failed - empty');
                this.showError('Please enter your password', 'login');
                return false;
            }
            if (password.length < 6) {
                console.log('DEBUG: Password validation failed - too short');
                this.showError('Password must be at least 6 characters', 'login');
                return false;
            }
        } else {
            if (!phone) {
                console.log('DEBUG: Phone validation failed - empty');
                this.showError('Please enter your phone number', 'login');
                return false;
            }
            if (!this.isValidPhone(phone)) {
                console.log('DEBUG: Phone validation failed - invalid format');
                this.showError('Please enter a valid 10-digit phone number', 'login');
                return false;
            }
        }
        
        console.log('DEBUG: Validation passed');
        return true;
    }

    validateSignupForm(displayName, email, phone, password) {
        console.log('DEBUG: validateSignupForm called', { 
            useEmailSignup: this.useEmailSignup, 
            displayName, 
            email, 
            phone, 
            password: password.length > 0 
        });
        
        if (!displayName) {
            console.log('DEBUG: Display name validation failed - empty');
            this.showError('Please choose a username', 'signup');
            return false;
        }
        
        if (this.useEmailSignup) {
            if (!email) {
                console.log('DEBUG: Email validation failed - empty');
                this.showError('Please enter your email', 'signup');
                return false;
            }
            if (!this.isValidEmail(email)) {
                console.log('DEBUG: Email validation failed - invalid format');
                this.showError('Please enter a valid email', 'signup');
                return false;
            }
            if (!password) {
                console.log('DEBUG: Password validation failed - empty');
                this.showError('Please create a password', 'signup');
                return false;
            }
            if (password.length < 6) {
                console.log('DEBUG: Password validation failed - too short');
                this.showError('Password must be at least 6 characters', 'signup');
                return false;
            }
        } else {
            if (!phone) {
                console.log('DEBUG: Phone validation failed - empty');
                this.showError('Please enter your phone number', 'signup');
                return false;
            }
            if (!this.isValidPhone(phone)) {
                console.log('DEBUG: Phone validation failed - invalid format');
                this.showError('Please enter a valid 10-digit phone number', 'signup');
                return false;
            }
        }
        
        console.log('DEBUG: Signup validation passed');
        return true;
    }

    isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    isValidPhone(phone) {
        return /^[0-9]{10}$/.test(phone);
    }
    // Firebase Login
    async handleLogin(event) {
        console.log('DEBUG: handleLogin called');
        event.preventDefault();
        
        if (this.isLoading) {
            console.log('DEBUG: Already loading, returning');
            return;
        }
        
        // Hide previous errors
        this.hideError('login');
        
        // Get form values
        const emailField = document.getElementById('emailField');
        const phoneField = document.getElementById('phoneField');
        const passwordField = document.querySelector('#passwordField input[type="password"]') || 
                              document.querySelector('#passwordField input');
        
        console.log('DEBUG: Fields found:', { emailField: !!emailField, phoneField: !!phoneField, passwordField: !!passwordField });
        
        if (!emailField || !passwordField) {
            console.error('Required fields not found');
            this.showError('Form fields not found. Please refresh the page.', 'login');
            return;
        }
        
        const email = emailField.value.trim();
        const phone = phoneField ? phoneField.value.trim() : '';
        const password = passwordField.value.trim();
        
        console.log('DEBUG: Form values:', { email: email.length > 0, phone: phone.length > 0, password: password.length > 0 });
        
        // Validate inputs (matching app logic)
        if (!this.validateLoginForm(email, phone, password)) {
            console.log('DEBUG: Validation failed');
            return;
        }
        
        console.log('DEBUG: Validation passed, setting loading state');
        // Set loading state
        this.setLoading(true, 'login');
        
        if (!this.auth) {
            // Demo mode
            this.showNotification('Firebase not configured - using demo mode', 'info');
            
            setTimeout(() => {
                this.currentUser = {
                    uid: 'demo-user',
                    email: this.useEmailLogin ? email : `phone-${phone}@demo.com`,
                    displayName: this.useEmailLogin ? email.split('@')[0] : `User${phone}`,
                    avatar: `https://picsum.photos/seed/${this.useEmailLogin ? email : phone}/120/120`
                };
                
                this.setLoading(false, 'login');
                closeModal('loginModal');
                this.showNotification('Demo login successful!', 'success');
                this.updateUIForLoggedInUser();
            }, 1500);
            
            return;
        }

        try {
            if (this.useEmailLogin) {
                // Email login
                const userCredential = await this.auth.signInWithEmailAndPassword(email, password);
                console.log('Email login successful');
            } else {
                // Phone login - navigate to OTP (for now, show message)
                this.showNotification('Phone login will redirect to OTP verification', 'info');
                this.setLoading(false, 'login');
                return;
            }
            
            this.setLoading(false, 'login');
            closeModal('loginModal');
            this.showNotification('Login successful! Welcome back!', 'success');
            
        } catch (error) {
            console.error('Login error:', error);
            this.setLoading(false, 'login');
            this.showError(this.getErrorMessage(error.code), 'login');
        }
    }

    // Firebase Signup
    async handleSignup(event) {
        event.preventDefault();
        
        if (this.isLoading) return;
        
        // Hide previous errors
        this.hideError('signup');
        
        // Get form values
        const displayNameField = event.target.querySelector('input[type="text"]');
        const emailField = document.getElementById('signupEmailField');
        const phoneField = document.getElementById('signupPhoneField');
        const passwordField = document.getElementById('signupPassword');
        
        if (!displayNameField || !emailField || !phoneField || !passwordField) {
            console.error('Signup fields not found');
            this.showError('Form fields not found. Please refresh the page.', 'signup');
            return;
        }
        
        const displayName = displayNameField.value.trim();
        const email = emailField.value.trim();
        const phone = phoneField.value.trim();
        const password = passwordField.value.trim();
        
        console.log('DEBUG: Signup form values:', { 
            displayName: displayName.length > 0, 
            email: email.length > 0, 
            phone: phone.length > 0, 
            password: password.length > 0,
            useEmailSignup: this.useEmailSignup
        });
        
        // Validate inputs
        if (!this.validateSignupForm(displayName, email, phone, password)) {
            console.log('DEBUG: Signup validation failed');
            return;
        }
        
        // Set loading state
        this.setLoading(true, 'signup');
        
        if (!this.auth) {
            // Demo mode
            this.showNotification('Firebase not configured - using demo mode', 'info');
            
            setTimeout(() => {
                this.currentUser = {
                    uid: 'demo-user',
                    email: this.useEmailSignup ? email : `phone-${phone}@demo.com`,
                    displayName: displayName,
                    avatar: `https://picsum.photos/seed/${this.useEmailSignup ? email : phone}/120/120`
                };
                
                this.setLoading(false, 'signup');
                closeModal('signupModal');
                this.showNotification('Demo account created successfully!', 'success');
                this.updateUIForLoggedInUser();
            }, 1500);
            
            return;
        }

        try {
            const userCredential = await this.auth.createUserWithEmailAndPassword(email, password);
            
            // Update display name
            await userCredential.user.updateProfile({
                displayName: displayName
            });

            this.setLoading(false, 'signup');
            closeModal('signupModal');
            this.showNotification('Account created successfully!', 'success');
            
        } catch (error) {
            console.error('Signup error:', error);
            this.setLoading(false, 'signup');
            this.showError(this.getErrorMessage(error.code), 'signup');
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
            // Show home page, hide landing page
            const homeSection = document.getElementById('home');
            const landingSection = document.getElementById('landing');
            const profileSection = document.getElementById('profile');
            
            if (homeSection) homeSection.style.display = 'block';
            if (landingSection) landingSection.style.display = 'none';
            if (profileSection) profileSection.style.display = 'none';
            
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
            const mobileAuthButtons = document.querySelector('.mobile-auth-buttons');
            if (mobileAuthButtons) {
                mobileAuthButtons.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 12px; padding: 16px; border-bottom: 1px solid rgba(255,255,255,0.1);">
                        <img src="${this.currentUser.avatar}" alt="Avatar" style="width: 32px; height: 32px; border-radius: 50%; border: 2px solid var(--primary-purple);">
                        <span style="color: white; font-weight: 500;">${this.currentUser.displayName}</span>
                    </div>
                    <button onclick="app.handleLogout()" class="btn-secondary" style="width: 100%; margin-top: 16px;">Logout</button>
                `;
            }
            
            // Load user data and render home page
            this.loadUserData();
            this.renderHomePage();
            this.renderProfile();
        }
    }

    // Update UI for logged out user
    updateUIForLoggedOutUser() {
        // Show landing page, hide home page
        const homeSection = document.getElementById('home');
        const landingSection = document.getElementById('landing');
        const profileSection = document.getElementById('profile');
        
        if (homeSection) homeSection.style.display = 'none';
        if (landingSection) landingSection.style.display = 'flex';
        if (profileSection) profileSection.style.display = 'none';
        
        // Reset navigation
        const authButtons = document.querySelector('.auth-buttons');
        if (authButtons) {
            authButtons.innerHTML = `
                <button onclick="showLoginModal()" class="btn-secondary">Login</button>
                <button onclick="showSignupModal()" class="btn-primary">Sign Up</button>
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
    async loadSampleData() {
        if (this.firestore) {
            // Load real data from Firebase only
            await this.loadAllPosts();
            await this.loadAllMessages();
        } else {
            // Show message that Firebase is not configured
            console.log('Firebase not configured - no data loaded');
            this.posts = [];
            this.messages = [];
        }
    }

    // Load all posts from Firebase
    async loadAllPosts() {
        if (!this.firestore) return;
        
        try {
            console.log('DEBUG: Loading all posts from Firebase');
            
            const postsSnapshot = await this.firestore
                .collection('posts')
                .limit(20) // Load latest 20 posts
                .get();
            
            console.log('DEBUG: Found total posts:', postsSnapshot.size);
            
            const postsData = postsSnapshot.docs.map(doc => {
                const postData = doc.data();
                return {
                    id: doc.id,
                    userId: postData.userId,
                    username: postData.username || postData.displayName || 'unknown_user',
                    avatar: postData.avatar || postData.userAvatar || `https://picsum.photos/seed/${postData.userId || doc.id}/40/40`,
                    image: postData.image || postData.imageUrl || `https://picsum.photos/seed/${doc.id}/400/400`,
                    caption: postData.caption || postData.description || '',
                    likes: postData.likes || 0,
                    comments: postData.comments || 0,
                    time: this.formatTime(postData.createdAt),
                    liked: postData.liked || false,
                    createdAt: postData.createdAt
                };
            });
            
            // Load user information for posts that don't have usernames
            const postsWithUserInfo = await this.loadUserInfoForPosts(postsData);
            
            this.posts = postsWithUserInfo;
            console.log('DEBUG: Processed all posts:', this.posts.length);
            
        } catch (error) {
            console.error('Error loading all posts:', error);
            this.posts = [];
        }
    }

    // Load user information for posts
    async loadUserInfoForPosts(posts) {
        const postsWithUserInfo = await Promise.all(posts.map(async (post) => {
            if (post.username === 'unknown_user' && post.userId) {
                try {
                    // Try to get user info from users collection
                    const userDoc = await this.firestore.collection('users').doc(post.userId).get();
                    if (userDoc.exists) {
                        const userData = userDoc.data();
                        post.username = userData.displayName || userData.username || 'User';
                        post.avatar = userData.avatar || post.avatar;
                    } else {
                        // Fallback: create username from email or UID
                        post.username = 'User_' + post.userId.substring(0, 6);
                    }
                } catch (error) {
                    console.log('Could not load user info for post:', post.id);
                    post.username = 'User_' + post.userId.substring(0, 6);
                }
            }
            return post;
        }));
        
        return postsWithUserInfo;
    }

    // Load all messages from Firebase
    async loadAllMessages() {
        if (!this.firestore) return;
        
        try {
            console.log('DEBUG: Loading messages from Firebase');
            
            // Simple query without ordering to avoid index requirement
            const messagesSnapshot = await this.firestore
                .collection('messages')
                .limit(50) // Limit to avoid index issues
                .get();
            
            this.messages = messagesSnapshot.docs.map(doc => {
                const messageData = doc.data();
                return {
                    id: doc.id,
                    username: messageData.otherUsername || messageData.username || 'unknown',
                    avatar: messageData.otherAvatar || messageData.avatar || `https://picsum.photos/seed/${messageData.otherUserId || doc.id}/48/48`,
                    lastMessage: messageData.lastMessage || messageData.message || '',
                    time: this.formatTime(messageData.lastMessageTime || messageData.createdAt),
                    unread: messageData.unreadCount || 0
                };
            });
            
            // Sort client-side by time (newest first)
            this.messages.sort((a, b) => {
                const timeA = new Date(a.time === 'Just now' ? Date.now() : a.time);
                const timeB = new Date(b.time === 'Just now' ? Date.now() : b.time);
                return timeB - timeA;
            });
            
            console.log('DEBUG: Loaded messages:', this.messages.length);
            
        } catch (error) {
            console.error('Error loading messages:', error);
            this.messages = [];
        }
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

        // Login screen functions (matching app)
        window.switchToEmailLogin = () => {
            app.switchToEmailLogin();
        };

        window.switchToPhoneLogin = () => {
            app.switchToPhoneLogin();
        };

        window.togglePassword = () => {
            app.togglePassword();
        };

        window.toggleSignupPassword = () => {
            app.toggleSignupPassword();
        };

        window.showForgotPassword = () => {
            app.showNotification('Password reset coming soon!', 'info');
        };

        // Signup screen functions (matching app)
        window.switchToEmailSignup = () => {
            app.switchToEmailSignup();
        };

        window.switchToPhoneSignup = () => {
            app.switchToPhoneSignup();
        };

        // Home page action functions
        window.createNewPost = () => {
            app.createNewPost();
        };

        window.viewMessages = () => {
            app.viewMessages();
        };

        window.editProfile = () => {
            app.editProfile();
        };

        // Navigation functions
        window.toggleMobileMenu = () => {
            const menu = document.getElementById('mobileMenu');
            if (menu) {
                menu.classList.toggle('hidden');
            }
        };

        // Post interaction functions
        window.likePost = (postId) => {
            app.likePost(postId);
        };

        window.commentPost = (postId) => {
            app.commentPost(postId);
        };

        window.sharePost = (postId) => {
            app.sharePost(postId);
        };

        window.savePost = (postId) => {
            app.savePost(postId);
        };

        window.showPostOptions = (postId) => {
            app.showPostOptions(postId);
        };

        window.viewComments = (postId) => {
            app.viewComments(postId);
        };

        window.followUser = (userId) => {
            app.followUser(userId);
        };

        // Story functions
        window.createStory = () => {
            app.createStory();
        };

        window.viewStory = (storyId) => {
            app.viewStory(storyId);
        };
    }

    // Load user data from Firebase
    async loadUserData() {
        if (!this.auth || !this.currentUser) return;
        
        try {
            // Load user profile from Firestore
            const userDoc = await this.firestore.collection('users').doc(this.currentUser.uid).get();
            
            if (userDoc.exists) {
                const userData = userDoc.data();
                this.currentUser = { ...this.currentUser, ...userData };
            } else {
                // Create user profile if it doesn't exist
                await this.firestore.collection('users').doc(this.currentUser.uid).set({
                    displayName: this.currentUser.displayName,
                    email: this.currentUser.email,
                    avatar: this.currentUser.avatar,
                    bio: '',
                    followers: 0,
                    following: 0,
                    posts: 0,
                    createdAt: new Date().toISOString()
                });
            }
            
            // Load user's posts
            await this.loadUserPosts();
            
        } catch (error) {
            console.error('Error loading user data:', error);
            // Use demo data if Firebase fails
            this.loadDemoUserData();
        }
    }

    // Load demo user data
    loadDemoUserData() {
        this.currentUser = {
            ...this.currentUser,
            bio: 'Welcome to my PictoGram profile!',
            followers: Math.floor(Math.random() * 1000) + 100,
            following: Math.floor(Math.random() * 500) + 50,
            posts: Math.floor(Math.random() * 50) + 5
        };
        this.loadDemoUserPosts();
    }

    // Load user's posts from Firebase
    async loadUserPosts() {
        if (!this.firestore || !this.currentUser) return;
        
        try {
            console.log('DEBUG: Loading posts for user:', this.currentUser.uid);
            
            // Simple query without ordering to avoid index requirement
            const postsSnapshot = await this.firestore
                .collection('posts')
                .where('userId', '==', this.currentUser.uid)
                .limit(20) // Limit to avoid index issues
                .get();
            
            console.log('DEBUG: Found posts:', postsSnapshot.size);
            
            this.userPosts = postsSnapshot.docs.map(doc => {
                const postData = doc.data();
                console.log('DEBUG: Post data:', postData);
                
                // Use current user's info for their posts
                const username = this.currentUser.displayName || 
                               postData.username || 
                               postData.displayName || 
                               'User';
                
                return {
                    id: doc.id,
                    userId: postData.userId || this.currentUser.uid,
                    username: username,
                    avatar: postData.avatar || this.currentUser.avatar,
                    image: postData.image || postData.imageUrl || `https://picsum.photos/seed/${doc.id}/400/400`,
                    caption: postData.caption || postData.description || '',
                    likes: postData.likes || 0,
                    comments: postData.comments || 0,
                    time: this.formatTime(postData.createdAt),
                    liked: postData.liked || false,
                    createdAt: postData.createdAt
                };
            });
            
            // Sort client-side by createdAt (newest first)
            this.userPosts.sort((a, b) => {
                const timeA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.createdAt || 0);
                const timeB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.createdAt || 0);
                return timeB - timeA;
            });
            
            console.log('DEBUG: Processed user posts:', this.userPosts.length);
            
        } catch (error) {
            console.error('Error loading user posts:', error);
            this.userPosts = [];
        }
    }

    // Format timestamp
    formatTime(timestamp) {
        if (!timestamp) return 'Just now';
        
        const now = new Date();
        const postTime = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
        const diffMs = now - postTime;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);
        
        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins} minutes ago`;
        if (diffHours < 24) return `${diffHours} hours ago`;
        if (diffDays < 7) return `${diffDays} days ago`;
        
        return postTime.toLocaleDateString();
    }

    // Load demo user posts
    loadDemoUserPosts() {
        this.userPosts = [
            {
                id: 'demo1',
                userId: this.currentUser.uid,
                username: this.currentUser.displayName.toLowerCase().replace(/\s+/g, '_'),
                avatar: this.currentUser.avatar,
                image: `https://picsum.photos/seed/${this.currentUser.uid}-post1/400/400`,
                caption: 'My first post on PictoGram! 🎉',
                likes: Math.floor(Math.random() * 100),
                comments: Math.floor(Math.random() * 20),
                time: 'Just now',
                liked: false
            },
            {
                id: 'demo2',
                userId: this.currentUser.uid,
                username: this.currentUser.displayName.toLowerCase().replace(/\s+/g, '_'),
                avatar: this.currentUser.avatar,
                image: `https://picsum.photos/seed/${this.currentUser.uid}-post2/400/400`,
                caption: 'Living my best life! 🌟',
                likes: Math.floor(Math.random() * 200),
                comments: Math.floor(Math.random() * 30),
                time: '2 hours ago',
                liked: false
            }
        ];
    }

    // Render home page
    renderHomePage() {
        if (!this.currentUser) return;
        
        // Update sidebar with user info
        this.updateSidebar();
        
        // Load real stories
        this.loadStories();
        
        // Render posts feed
        this.renderPostsFeed();
        
        // Load real suggestions
        this.loadSuggestions();
    }

    // Load real stories from Firebase
    async loadStories() {
        if (!this.firestore) return;
        
        try {
            console.log('DEBUG: Loading stories from Firebase');
            
            const storiesContainer = document.getElementById('storiesContainer');
            if (!storiesContainer) return;
            
            // Get stories from Firebase (last 24 hours)
            const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
            
            const storiesSnapshot = await this.firestore
                .collection('stories')
                .where('createdAt', '>=', twentyFourHoursAgo)
                .orderBy('createdAt', 'desc')
                .limit(10)
                .get();
            
            console.log('DEBUG: Found stories:', storiesSnapshot.size);
            
            // Add "Your Story" first
            let storiesHTML = `
                <div style="flex-shrink: 0; text-align: center; cursor: pointer;" onclick="createStory()">
                    <div style="width: 66px; height: 66px; border-radius: 50%; background: linear-gradient(45deg, #f09433 0%, #e6683c 25%, #dc2743 50%, #cc2366 75%, #bc1888 100%); padding: 2px; margin-bottom: 4px;">
                        <div style="width: 100%; height: 100%; border-radius: 50%; background: #262626; display: flex; align-items: center; justify-content: center;">
                            <i class="fas fa-plus" style="color: white; font-size: 20px;"></i>
                        </div>
                    </div>
                    <p style="color: white; font-size: 12px; margin: 0;">Your story</p>
                </div>
            `;
            
            // Add real stories
            storiesSnapshot.forEach(doc => {
                const storyData = doc.data();
                storiesHTML += `
                    <div style="flex-shrink: 0; text-align: center; cursor: pointer;" onclick="viewStory('${doc.id}')">
                        <div style="width: 66px; height: 66px; border-radius: 50%; background: linear-gradient(45deg, #f09433 0%, #e6683c 25%, #dc2743 50%, #cc2366 75%, #bc1888 100%); padding: 2px; margin-bottom: 4px;">
                            <img src="${storyData.image || storyData.imageUrl || `https://picsum.photos/seed/${doc.id}/66/66`}" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;">
                        </div>
                        <p style="color: white; font-size: 12px; margin: 0;">${storyData.username || 'User'}</p>
                    </div>
                `;
            });
            
            storiesContainer.innerHTML = storiesHTML;
            
        } catch (error) {
            console.error('Error loading stories:', error);
            // Hide stories section if no stories
            const storiesSection = document.getElementById('storiesSection');
            if (storiesSection) {
                storiesSection.style.display = 'none';
            }
        }
    }

    // Load real suggestions from Firebase
    async loadSuggestions() {
        if (!this.firestore) return;
        
        try {
            console.log('DEBUG: Loading suggestions from Firebase');
            
            const suggestionsList = document.getElementById('suggestionsList');
            if (!suggestionsList) return;
            
            // Get users you don't follow (exclude yourself)
            const usersSnapshot = await this.firestore
                .collection('users')
                .limit(10)
                .get();
            
            const suggestions = usersSnapshot.docs
                .map(doc => ({ id: doc.id, ...doc.data() }))
                .filter(user => user.id !== this.currentUser.uid)
                .slice(0, 5);
            
            if (suggestions.length === 0) {
                suggestionsList.innerHTML = '<p style="color: #8e8e8e; text-align: center; padding: 20px;">No suggestions available</p>';
                return;
            }
            
            suggestionsList.innerHTML = suggestions.map(suggestion => `
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <img src="${suggestion.avatar || `https://picsum.photos/seed/${suggestion.id}/32/32`}" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">
                        <div>
                            <p style="color: white; font-weight: 600; margin: 0; font-size: 14px;">${suggestion.displayName || 'User'}</p>
                            <p style="color: #8e8e8e; font-size: 12px; margin: 0;">Suggested for you</p>
                        </div>
                    </div>
                    <button onclick="followUser('${suggestion.id}')" style="background: none; border: none; color: #0095f6; font-size: 12px; font-weight: 600; cursor: pointer;">
                        Follow
                    </button>
                </div>
            `).join('');
            
        } catch (error) {
            console.error('Error loading suggestions:', error);
            const suggestionsList = document.getElementById('suggestionsList');
            if (suggestionsList) {
                suggestionsList.innerHTML = '<p style="color: #8e8e8e; text-align: center; padding: 20px;">Unable to load suggestions</p>';
            }
        }
    }

    // Update sidebar with user info
    updateSidebar() {
        const sidebarAvatar = document.getElementById('sidebarAvatar');
        const sidebarUsername = document.getElementById('sidebarUsername');
        const sidebarFullname = document.getElementById('sidebarFullname');
        
        if (sidebarAvatar) sidebarAvatar.src = this.currentUser.avatar;
        if (sidebarUsername) sidebarUsername.textContent = this.currentUser.displayName.toLowerCase().replace(/\s+/g, '_');
        if (sidebarFullname) sidebarFullname.textContent = this.currentUser.displayName;
    }

    // Render posts feed in Instagram style
    renderPostsFeed() {
        const postsFeed = document.getElementById('postsFeed');
        if (!postsFeed) return;
        
        // Combine all posts (user's posts + other posts) and sort by time
        const allPosts = [...(this.userPosts || []), ...(this.posts || [])];
        
        // Sort by newest first
        allPosts.sort((a, b) => {
            const timeA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.createdAt || 0);
            const timeB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.createdAt || 0);
            return timeB - timeA;
        });
        
        if (allPosts.length === 0) {
            postsFeed.innerHTML = `
                <div style="background: #262626; border: 1px solid #2c2c2c; border-radius: 8px; padding: 60px 20px; text-align: center;">
                    <i class="fas fa-camera" style="font-size: 48px; color: #8e8e8e; margin-bottom: 16px; display: block;"></i>
                    <h3 style="color: white; margin-bottom: 8px;">Start sharing your moments</h3>
                    <p style="color: #8e8e8e; margin-bottom: 20px;">When you share photos, they will appear on your profile.</p>
                    <button onclick="createNewPost()" style="background: #0095f6; color: white; border: none; padding: 8px 16px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                        Share your first photo
                    </button>
                </div>
            `;
            return;
        }
        
        postsFeed.innerHTML = allPosts.map(post => this.renderInstagramPost(post)).join('');
    }

    // Render individual Instagram-style post
    renderInstagramPost(post) {
        return `
            <div style="background: #262626; border: 1px solid #2c2c2c; border-radius: 8px; margin-bottom: 24px;">
                <!-- Post Header -->
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 14px 16px;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <img src="${post.avatar}" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">
                        <div>
                            <p style="color: white; font-weight: 600; margin: 0; font-size: 14px;">${post.username}</p>
                            <p style="color: white; margin: 0; font-size: 14px;">•</p>
                        </div>
                    </div>
                    <button onclick="showPostOptions('${post.id}')" style="background: none; border: none; color: white; cursor: pointer;">
                        <i class="fas fa-ellipsis-h"></i>
                    </button>
                </div>
                
                <!-- Post Image -->
                <div style="width: 100%; max-height: 600px; overflow: hidden;">
                    <img src="${post.image}" style="width: 100%; height: 100%; object-fit: cover;">
                </div>
                
                <!-- Post Actions -->
                <div style="padding: 8px 16px;">
                    <div style="display: flex; gap: 16px; margin-bottom: 8px;">
                        <button onclick="likePost('${post.id}')" style="background: none; border: none; color: white; cursor: pointer;">
                            <i class="${post.liked ? 'fas' : 'far'} fa-heart" style="font-size: 24px;"></i>
                        </button>
                        <button onclick="commentPost('${post.id}')" style="background: none; border: none; color: white; cursor: pointer;">
                            <i class="far fa-comment" style="font-size: 24px;"></i>
                        </button>
                        <button onclick="sharePost('${post.id}')" style="background: none; border: none; color: white; cursor: pointer;">
                            <i class="far fa-paper-plane" style="font-size: 24px;"></i>
                        </button>
                        <button onclick="savePost('${post.id}')" style="background: none; border: none; color: white; cursor: pointer; margin-left: auto;">
                            <i class="far fa-bookmark" style="font-size: 24px;"></i>
                        </button>
                    </div>
                    
                    <!-- Likes -->
                    <p style="color: white; font-weight: 600; margin-bottom: 8px;">${post.likes.toLocaleString()} likes</p>
                    
                    <!-- Caption -->
                    <div style="margin-bottom: 8px;">
                        <span style="color: white; font-weight: 600; margin-right: 8px;">${post.username}</span>
                        <span style="color: white;">${post.caption}</span>
                    </div>
                    
                    <!-- Comments -->
                    ${post.comments > 0 ? `<button onclick="viewComments('${post.id}')" style="background: none; border: none; color: #8e8e8e; cursor: pointer; font-size: 14px; padding: 0; margin-bottom: 8px;">View all ${post.comments} comments</button>` : ''}
                    
                    <!-- Time -->
                    <p style="color: #8e8e8e; font-size: 10px; margin: 0;">${post.time}</p>
                </div>
                
                <!-- Add Comment -->
                <div style="padding: 0 16px 16px; border-top: 1px solid #2c2c2c; margin-top: 4px;">
                    <input type="text" placeholder="Add a comment..." style="background: none; border: none; color: white; width: 100%; padding: 8px 0; outline: none;">
                </div>
            </div>
        `;
    }

    // Post interaction functions
    likePost(postId) {
        const post = this.posts.find(p => p.id === postId) || this.userPosts?.find(p => p.id === postId);
        if (post) {
            post.liked = !post.liked;
            post.likes += post.liked ? 1 : -1;
            this.renderPostsFeed();
        }
    }

    commentPost(postId) {
        this.showNotification('Comments feature coming soon!', 'info');
    }

    sharePost(postId) {
        this.showNotification('Share feature coming soon!', 'info');
    }

    savePost(postId) {
        this.showNotification('Save feature coming soon!', 'info');
    }

    showPostOptions(postId) {
        this.showNotification('Post options coming soon!', 'info');
    }

    viewComments(postId) {
        this.showNotification('Comments view coming soon!', 'info');
    }

    followUser(userId) {
        this.showNotification(`Following user!`, 'success');
    }

    // Story functions
    createStory() {
        this.showNotification('Story creation coming soon!', 'info');
    }

    viewStory(storyId) {
        this.showNotification('Story viewer coming soon!', 'info');
    }

    // Calculate total likes received
    calculateTotalLikes() {
        if (!this.userPosts) return 0;
        return this.userPosts.reduce((total, post) => total + (post.likes || 0), 0);
    }

    // Render recent posts preview
    renderRecentPostsPreview() {
        const previewContainer = document.getElementById('recentPostsPreview');
        if (!previewContainer) return;
        
        const recentPosts = this.userPosts?.slice(0, 3) || [];
        
        if (recentPosts.length === 0) {
            previewContainer.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 48px; background: rgba(255,255,255,0.05); border-radius: 16px;">
                    <i class="fas fa-camera" style="font-size: 48px; color: rgba(255,255,255,0.3); margin-bottom: 16px; display: block;"></i>
                    <p style="color: rgba(255,255,255,0.7); margin-bottom: 24px;">You haven't posted anything yet</p>
                    <button onclick="createNewPost()" class="btn-primary">Create Your First Post</button>
                </div>
            `;
            return;
        }
        
        previewContainer.innerHTML = recentPosts.map(post => this.renderPostCard(post)).join('');
    }

    // Home page action functions
    createNewPost() {
        this.showNotification('Post creation coming soon!', 'info');
    }

    viewMessages() {
        // Navigate to messages section
        const messagesSection = document.getElementById('messages');
        if (messagesSection) {
            messagesSection.scrollIntoView({ behavior: 'smooth' });
        }
    }

    editProfile() {
        this.showNotification('Profile editing coming soon!', 'info');
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
    try {
        console.log('DEBUG: DOM loaded, initializing app...');
        window.app = new PictoGramApp();
        console.log('DEBUG: App initialized successfully');
    } catch (error) {
        console.error('ERROR: Failed to initialize app:', error);
        document.body.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: center; height: 100vh; background: #0A0010; color: white; font-family: Arial, sans-serif;">
                <div style="text-align: center; padding: 40px; background: rgba(224, 56, 154, 0.1); border-radius: 16px; border: 1px solid rgba(224, 56, 154, 0.3);">
                    <h2 style="color: #E0389A; margin-bottom: 20px;">Application Error</h2>
                    <p style="margin-bottom: 20px;">Failed to initialize the application.</p>
                    <details style="text-align: left; margin-bottom: 20px;">
                        <summary style="cursor: pointer; color: #E0389A;">Error Details</summary>
                        <pre style="background: rgba(0,0,0,0.3); padding: 10px; border-radius: 8px; margin-top: 10px; font-size: 12px; overflow-x: auto;">${error.stack || error.message}</pre>
                    </details>
                    <button onclick="location.reload()" style="background: #E0389A; color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer;">
                        Reload Page
                    </button>
                </div>
            </div>
        `;
    }
});

// Add smooth scroll behavior for navigation links
document.addEventListener('DOMContentLoaded', () => {
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

// Observe elements for animations (run after app initialization)
document.addEventListener('DOMContentLoaded', () => {
    setTimeout(() => {
        const elementsToAnimate = document.querySelectorAll('.post-card, .message-item');
        elementsToAnimate.forEach(el => observer.observe(el));
    }, 100);
});
