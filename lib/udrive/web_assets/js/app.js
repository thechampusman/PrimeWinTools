// UDrive Web Application
class UDriveApp {
    constructor() {
        this.currentPath = '';  // Start with empty path (root of storage folder)
        this.currentView = 'files';
        this.files = [];
        this.selectedFiles = [];
        this.viewMode = 'grid';
        this.sortBy = 'name';
        this.sortOrder = 'asc';
        
        // Media player state
        this.currentMediaFile = null;
        this.currentMediaPlaylist = [];
        this.currentMediaIndex = -1;
        
        // Image viewer state
        this.currentImageFiles = [];
        this.currentImageIndex = -1;
        this.imageViewerEvents = null;
        
        // History management
        this.navigationHistory = [];
        this.isNavigatingBack = false;
        
        this.init();
    }
    
    init() {
        console.log('🚀 Initializing UDrive App...');
        this.initBanner();
        this.bindEvents();
        console.log('📂 Loading initial files...');
        this.loadFiles();
        this.loadStoragePath();
        
        // Initialize browser history management
        this.initHistoryManagement();
        
        // Initialize uploader
        window.uploader = new UDriveUploader();
        console.log('✅ UDrive App initialized successfully');
    }
    
    initBanner() {
        // Handle banner close functionality
        const bannerClose = document.querySelector('.banner-close');
        const banner = document.querySelector('.version-banner');
        const body = document.body;
        
        if (bannerClose && banner) {
            bannerClose.addEventListener('click', () => {
                banner.classList.add('hidden');
                body.style.paddingTop = '0';
                // Save preference in localStorage
                localStorage.setItem('udrive-banner-hidden', 'true');
            });
        }
        
        // Check if banner was previously hidden
        if (localStorage.getItem('udrive-banner-hidden') === 'true') {
            banner?.classList.add('hidden');
            body.style.paddingTop = '0';
        }
        
        // Mobile menu functionality
        this.initMobileMenu();
    }
    
    initMobileMenu() {
        const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
        const sidebar = document.querySelector('.modern-sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        if (mobileMenuBtn && sidebar && overlay) {
            mobileMenuBtn.addEventListener('click', () => {
                sidebar.classList.toggle('open');
                overlay.classList.toggle('show');
            });
            
            // Close sidebar when clicking overlay
            overlay.addEventListener('click', () => {
                sidebar.classList.remove('open');
                overlay.classList.remove('show');
            });
            
            // Close sidebar when clicking nav items on mobile
            document.querySelectorAll('.nav-item').forEach(item => {
                item.addEventListener('click', () => {
                    if (window.innerWidth <= 768) {
                        sidebar.classList.remove('open');
                        overlay.classList.remove('show');
                    }
                });
            });
        }
    }
    
    initHistoryManagement() {
        // Initialize with current state
        const initialState = {
            path: this.currentPath,
            view: this.currentView,
            modalOpen: false
        };
        
        // Replace current state to set up initial history entry
        history.replaceState(initialState, '', window.location.href);
        
        // Handle browser back/forward buttons
        window.addEventListener('popstate', (e) => {
            this.handleHistoryNavigation(e.state);
        });
        
        // Prevent leaving the page accidentally
        window.addEventListener('beforeunload', (e) => {
            // Only show warning if user is trying to leave completely
            const currentUrl = window.location.href;
            if (!currentUrl.includes('#') && !this.isNavigatingBack) {
                e.preventDefault();
                e.returnValue = '';
            }
        });
    }
    
    handleHistoryNavigation(state) {
        console.log('🔙 Browser back button pressed, state:', state);
        console.log('🔙 Current modal open:', this.isModalOpen());
        
        if (!state) {
            // If no state, go back to root and close any modals
            console.log('🔙 No state found, going to root and closing modals');
            this.hideModals();
            this.navigateToPath('', false);
            return;
        }
        
        this.isNavigatingBack = true;
        
        // Handle modal state - if target state doesn't have modal open, close it
        if (!state.modalOpen && this.isModalOpen()) {
            console.log('🔙 Target state has no modal, closing current modal');
            this.hideModals();
        }
        
        // Handle path navigation
        if (state.path !== this.currentPath) {
            console.log('🔙 Path changed from', this.currentPath, 'to', state.path);
            this.navigateToPath(state.path, false);
        }
        
        // Handle view changes
        if (state.view !== this.currentView) {
            console.log('🔙 View changed from', this.currentView, 'to', state.view);
            this.switchView(state.view, false);
        }
        
        this.isNavigatingBack = false;
    }
    
    pushHistoryState(path, view = this.currentView, modalOpen = false) {
        if (this.isNavigatingBack) return;
        
        const state = {
            path: path,
            view: view,
            modalOpen: modalOpen
        };
        
        console.log('📌 Pushing history state:', state);
        
        // Create a URL with hash to represent the current state
        let url = window.location.pathname;
        if (path) {
            url += '#' + encodeURIComponent(path);
        }
        if (modalOpen) {
            url += (path ? '&' : '#') + 'modal=open';
        }
        
        console.log('📌 New URL:', url);
        history.pushState(state, '', url);
    }
    
    isModalOpen() {
        const mediaModal = document.getElementById('mediaPlayerModal');
        const imageModal = document.getElementById('imageViewerModal');
        return (mediaModal && mediaModal.style.display === 'flex') ||
               (imageModal && imageModal.style.display === 'flex');
    }
    
    navigateToPath(path, pushHistory = true) {
        this.currentPath = path;
        this.loadFiles(path);
        if (pushHistory) {
            this.pushHistoryState(path);
        }
    }

    initSortControls() {
        // Sort dropdown toggle
        const sortTrigger = document.querySelector('.sort-trigger');
        const sortMenu = document.querySelector('.sort-menu');
        
        if (sortTrigger && sortMenu) {
            sortTrigger.addEventListener('click', (e) => {
                e.stopPropagation();
                const isVisible = sortMenu.classList.contains('show');
                
                // Close all other dropdowns first
                document.querySelectorAll('.sort-menu').forEach(menu => {
                    menu.classList.remove('show');
                });
                
                if (!isVisible) {
                    // Simple approach: just show the dropdown and let CSS handle initial positioning
                    sortMenu.classList.add('show');
                    
                    // Then immediately position it correctly using getBoundingClientRect
                    setTimeout(() => {
                        const rect = sortTrigger.getBoundingClientRect();
                        const viewportWidth = window.innerWidth;
                        
                        if (viewportWidth <= 768) {
                            // Mobile bottom sheet
                            sortMenu.style.position = 'fixed';
                            sortMenu.style.bottom = '20px';
                            sortMenu.style.left = '20px';
                            sortMenu.style.right = '20px';
                            sortMenu.style.top = 'auto';
                            sortMenu.style.zIndex = '999999';
                        } else {
                            // Desktop positioning
                            sortMenu.style.position = 'fixed';
                            sortMenu.style.top = (rect.bottom + 8) + 'px';
                            sortMenu.style.left = (rect.right - 200) + 'px';
                            sortMenu.style.right = 'auto';
                            sortMenu.style.bottom = 'auto';
                            sortMenu.style.zIndex = '999999';
                        }
                    }, 0);
                }
            });
            
            // Close dropdown when clicking outside
            document.addEventListener('click', () => {
                sortMenu.classList.remove('show');
            });
            
            // Handle sort option clicks
            document.querySelectorAll('.sort-option').forEach(option => {
                option.addEventListener('click', (e) => {
                    e.stopPropagation();
                    
                    // Remove active class from all options
                    document.querySelectorAll('.sort-option').forEach(opt => opt.classList.remove('active'));
                    
                    // Add active class to clicked option
                    option.classList.add('active');
                    
                    // Update sort criteria
                    const sortType = option.dataset.sort;
                    this.sortBy = sortType;
                    
                    // Update trigger text
                    const triggerText = sortTrigger.querySelector('span');
                    if (triggerText) {
                        triggerText.textContent = option.textContent.trim();
                    }
                    
                    // Close dropdown
                    sortMenu.classList.remove('show');
                    
                    // Apply sort
                    this.sortFiles();
                });
            });
        }
    }
    
    sortFiles() {
        if (!this.files || this.files.length === 0) return;
        
        this.files.sort((a, b) => {
            let aVal, bVal;
            
            switch (this.sortBy) {
                case 'name':
                    aVal = a.name.toLowerCase();
                    bVal = b.name.toLowerCase();
                    break;
                case 'size':
                    aVal = a.size || 0;
                    bVal = b.size || 0;
                    break;
                case 'modified':
                    aVal = new Date(a.lastModified || 0);
                    bVal = new Date(b.lastModified || 0);
                    break;
                case 'type':
                    aVal = a.type || '';
                    bVal = b.type || '';
                    break;
                default:
                    aVal = a.name.toLowerCase();
                    bVal = b.name.toLowerCase();
            }
            
            // Folders first
            if (a.type === 'folder' && b.type !== 'folder') return -1;
            if (b.type === 'folder' && a.type !== 'folder') return 1;
            
            // Then sort by criteria
            if (aVal < bVal) return this.sortOrder === 'asc' ? -1 : 1;
            if (aVal > bVal) return this.sortOrder === 'asc' ? 1 : -1;
            return 0;
        });
        
        this.renderFiles();
    }
    
    bindEvents() {
        // Navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', async (e) => {
                e.preventDefault();
                const view = item.dataset.view;
                await this.switchView(view);
            });
        });
        
        // View controls
        document.getElementById('gridViewBtn')?.addEventListener('click', () => {
            this.setViewMode('grid');
        });
        
        document.getElementById('listViewBtn')?.addEventListener('click', () => {
            this.setViewMode('list');
        });
        
        // Actions        
        document.getElementById('refreshBtn')?.addEventListener('click', () => {
            this.loadFiles();
        });
        
        // Sort functionality
        this.initSortControls();
        
        // Search
        document.getElementById('searchBtn').addEventListener('click', () => {
            this.performSearch();
        });
        
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.performSearch();
                }
            });
        }

        // Sort controls
        const sortBy = document.getElementById('sortBy');
        if (sortBy) {
            sortBy.addEventListener('change', (e) => {
                this.sortBy = e.target.value;
                this.sortFiles();
            });
        }

        const sortOrder = document.getElementById('sortOrder');
        if (sortOrder) {
            sortOrder.addEventListener('click', (e) => {
                const btn = e.target.closest('button');
                this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
                btn.dataset.order = this.sortOrder;
                btn.innerHTML = this.sortOrder === 'asc'
                    ? '<i class="fas fa-sort-alpha-down"></i>'
                    : '<i class="fas fa-sort-alpha-up"></i>';
                this.sortFiles();
            });
        }
        
        // Context menu
        document.addEventListener('contextmenu', (e) => {
            const fileItem = e.target.closest('.file-item');
            if (fileItem) {
                e.preventDefault();
                this.showContextMenu(e, fileItem);
            }
        });
        
        document.addEventListener('click', () => {
            this.hideContextMenu();
        });
        
        // Close modals
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                this.hideModals();
            }
        });
        
        document.querySelectorAll('.close-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.hideModals();
            });
        });
        
        // Search functionality
        document.getElementById('searchBtn')?.addEventListener('click', () => {
            this.performSearch();
        });
        
        document.getElementById('searchInput')?.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.performSearch();
            }
        });
        
        // Clear search when input is empty
        document.getElementById('searchInput')?.addEventListener('input', (e) => {
            if (e.target.value.trim() === '') {
                this.loadFiles(); // Reset to current folder
            }
        });
        
        // Network link functionality
        this.initNetworkLink();
    }
    
    initNetworkLink() {
        const networkLinkBtn = document.getElementById('networkLinkBtn');
        const networkDropdown = document.getElementById('networkDropdown');
        
        if (networkLinkBtn && networkDropdown) {
            // Add pulse animation on load to draw attention
            setTimeout(() => {
                networkLinkBtn.classList.add('pulse');
                setTimeout(() => {
                    networkLinkBtn.classList.remove('pulse');
                }, 6000); // Remove after 6 seconds
            }, 2000); // Start after 2 seconds
            
            // Toggle dropdown on button click
            networkLinkBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                const isVisible = networkDropdown.classList.contains('show');
                
                if (isVisible) {
                    networkDropdown.classList.remove('show');
                } else {
                    this.loadNetworkLinks();
                    networkDropdown.classList.add('show');
                }
                
                // Remove pulse animation when clicked
                networkLinkBtn.classList.remove('pulse');
            });
            
            // Close dropdown when clicking outside
            document.addEventListener('click', (e) => {
                if (!networkLinkBtn.contains(e.target) && !networkDropdown.contains(e.target)) {
                    networkDropdown.classList.remove('show');
                }
            });
        }
        
        // Load network links on initialization
        this.loadNetworkLinks();
    }
    
    async loadNetworkLinks() {
        try {
            // Get server network info directly from the enhanced API
            const response = await fetch('/api/info');
            const data = await response.json();
            
            let serverPort = '8080'; // Default port
            let primaryNetworkUrl = null;
            let allNetworkUrls = [];
            let autoDetected = false;
            
            if (data.success && data.server) {
                serverPort = data.server.port || '8080';
            }
            
            // Use server-side network detection
            if (data.success && data.network) {
                autoDetected = data.network.autoDetected || false;
                primaryNetworkUrl = data.network.primaryUrl;
                
                if (data.network.interfaces && Array.isArray(data.network.interfaces)) {
                    allNetworkUrls = data.network.interfaces.map(iface => ({
                        ip: iface.ip,
                        url: iface.url,
                        interface: iface.interface,
                        isPrivate: iface.isPrivate || false,
                        isPrimary: iface.isPrimary || false
                    }));
                }
            }
            
            // Fallback to current connection if server detection failed
            if (!primaryNetworkUrl) {
                const currentHost = window.location.hostname;
                if (currentHost !== 'localhost' && currentHost !== '127.0.0.1') {
                    primaryNetworkUrl = `http://${currentHost}:${serverPort}`;
                    autoDetected = true;
                }
            }
            
            // Set the network links
            const localNetworkLink = document.getElementById('localNetworkLink');
            const currentNetworkLink = document.getElementById('currentNetworkLink');
            const localNetworkHint = document.getElementById('localNetworkHint');
            
            if (localNetworkLink) {
                // Use server-provided network URL if available
                let networkUrl = data.network?.networkUrl || primaryNetworkUrl;
                
                if (networkUrl && data.network?.networkAccessEnabled) {
                    localNetworkLink.value = networkUrl;
                    if (localNetworkHint) {
                        const networkIp = networkUrl.split('://')[1].split(':')[0];
                        localNetworkHint.textContent = `✅ Network access enabled! IP: ${networkIp}`;
                        localNetworkHint.style.color = '#10b981';
                    }
                } else if (primaryNetworkUrl && autoDetected) {
                    localNetworkLink.value = primaryNetworkUrl;
                    if (localNetworkHint) {
                        const primaryIp = primaryNetworkUrl.split('://')[1].split(':')[0];
                        localNetworkHint.textContent = `✅ Auto-detected network IP: ${primaryIp}`;
                        localNetworkHint.style.color = '#10b981';
                    }
                } else {
                    localNetworkLink.value = `http://[Your-Local-IP]:${serverPort}`;
                    localNetworkLink.placeholder = 'Replace [Your-Local-IP] with your actual IP';
                    if (localNetworkHint) {
                        if (data.network?.networkAccessEnabled === false) {
                            localNetworkHint.textContent = '⚠️ Network access is disabled. Only local access available.';
                        } else {
                            localNetworkHint.textContent = '⚠️ Could not auto-detect IP. Please replace [Your-Local-IP] with your computer\'s network IP address.';
                        }
                        localNetworkHint.style.color = '#f59e0b';
                    }
                }
            }
            
            if (currentNetworkLink) {
                currentNetworkLink.value = window.location.href;
            }
            
            console.log('📡 Network links loaded:', {
                primary: primaryNetworkUrl,
                serverNetworkUrl: data.network?.networkUrl,
                networkAccessEnabled: data.network?.networkAccessEnabled,
                autoDetected: autoDetected,
                allInterfaces: allNetworkUrls,
                current: window.location.href
            });
            
        } catch (error) {
            console.error('❌ Failed to load network links:', error);
            
            // Fallback to basic links with instructions
            const localNetworkLink = document.getElementById('localNetworkLink');
            const currentNetworkLink = document.getElementById('currentNetworkLink');
            const localNetworkHint = document.getElementById('localNetworkHint');
            
            if (localNetworkLink) {
                localNetworkLink.value = 'http://[Your-Local-IP]:8080';
                localNetworkLink.placeholder = 'Replace [Your-Local-IP] with your computer\'s IP address';
            }
            
            if (localNetworkHint) {
                localNetworkHint.textContent = '❌ Network detection failed. Please manually replace [Your-Local-IP] with your computer\'s IP address.';
                localNetworkHint.style.color = '#ef4444';
            }
            
            if (currentNetworkLink) {
                currentNetworkLink.value = window.location.href;
            }
        }
    }
    
    copyNetworkLink(type) {
        const inputId = type === 'local' ? 'localNetworkLink' : 'currentNetworkLink';
        const input = document.getElementById(inputId);
        
        if (input) {
            input.select();
            input.setSelectionRange(0, 99999); // For mobile devices
            
            navigator.clipboard.writeText(input.value).then(() => {
                this.showToast('Network link copied to clipboard!', 'success');
                
                // Visual feedback
                const copyBtn = input.parentElement.querySelector('.copy-btn');
                if (copyBtn) {
                    const originalHTML = copyBtn.innerHTML;
                    copyBtn.innerHTML = '<i class="fas fa-check"></i>';
                    copyBtn.style.background = '#10b981';
                    copyBtn.style.color = 'white';
                    
                    setTimeout(() => {
                        copyBtn.innerHTML = originalHTML;
                        copyBtn.style.background = '';
                        copyBtn.style.color = '';
                    }, 2000);
                }
            }).catch(() => {
                // Fallback for older browsers
                try {
                    document.execCommand('copy');
                    this.showToast('Network link copied to clipboard!', 'success');
                } catch (error) {
                    this.showToast('Could not copy link. Please copy manually.', 'error');
                }
            });
        }
    }
    
    initMediaControls() {
        // Video-specific controls
        this.initVideoControls();
        
        // Audio-specific controls  
        this.initAudioControls();
        
        // Listen for media events
        this.initMediaEventListeners();
    }
    
    initVideoControls() {
        const videoPlayer = document.getElementById('videoPlayer');
        
        if (videoPlayer) {
            // Basic video player event listeners
            videoPlayer.addEventListener('play', () => {
                this.isVideoPlaying = true;
            });
            
            videoPlayer.addEventListener('pause', () => {
                this.isVideoPlaying = false;
            });
            
            videoPlayer.addEventListener('ended', () => {
                this.isVideoPlaying = false;
                this.playNext(); // Auto-play next video if available
            });
        }
        
        // Navigation buttons
        document.getElementById('videoPrevBtn')?.addEventListener('click', (e) => {
            e.stopPropagation();
            this.playPrevious();
        });
        
        document.getElementById('videoNextBtn')?.addEventListener('click', (e) => {
            e.stopPropagation();
            this.playNext();
        });
        
        // Fullscreen button
        document.getElementById('videoFullscreenBtn')?.addEventListener('click', (e) => {
            e.stopPropagation();
            this.toggleFullscreen();
        });
    }
        
    }
    
    initAudioControls() {
        // Audio Play/Pause button
        document.getElementById('audioPlayPauseBtn')?.addEventListener('click', () => {
            this.toggleAudioPlayPause();
        });
        
        // Audio Previous/Next buttons
        document.getElementById('audioPrevBtn')?.addEventListener('click', () => {
            this.playPrevious();
        });
        
        document.getElementById('audioNextBtn')?.addEventListener('click', () => {
            this.playNext();
        });
        
        // Audio Volume controls
        const audioVolumeSlider = document.getElementById('audioVolumeSlider');
        const audioMuteBtn = document.getElementById('audioMuteBtn');
        
        if (audioVolumeSlider) {
            audioVolumeSlider.addEventListener('input', (e) => {
                this.setAudioVolume(e.target.value / 100);
            });
        }
        
        if (audioMuteBtn) {
            audioMuteBtn.addEventListener('click', () => {
                this.toggleAudioMute();
            });
        }
        
        // Audio Progress slider
        const audioProgressSlider = document.getElementById('audioProgressSlider');
        if (audioProgressSlider) {
            audioProgressSlider.addEventListener('input', (e) => {
                this.seekAudioTo(e.target.value / 100);
            });
        }
    }
    
    initMediaEventListeners() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        // Video player events
        if (videoPlayer) {
            videoPlayer.addEventListener('loadedmetadata', () => {
                this.updateVideoDuration();
            });
            
            videoPlayer.addEventListener('timeupdate', () => {
                this.updateVideoProgress();
            });
            
            videoPlayer.addEventListener('play', () => {
                this.updateVideoPlayPauseButtons(true);
            });
            
            videoPlayer.addEventListener('pause', () => {
                this.updateVideoPlayPauseButtons(false);
            });
            
            videoPlayer.addEventListener('ended', () => {
                this.playNext();
            });
        }
        
        // Audio player events
        if (audioPlayer) {
            audioPlayer.addEventListener('loadedmetadata', () => {
                this.updateAudioDuration();
            });
            
            audioPlayer.addEventListener('timeupdate', () => {
                this.updateAudioProgress();
            });
            
            audioPlayer.addEventListener('play', () => {
                this.updateAudioPlayPauseButtons(true);
            });
            
            audioPlayer.addEventListener('pause', () => {
                this.updateAudioPlayPauseButtons(false);
            });
            
            audioPlayer.addEventListener('ended', () => {
                this.playNext();
            });
        }
        
        // Fullscreen change events
        document.addEventListener('fullscreenchange', () => {
            this.handleFullscreenChange();
        });
        
        document.addEventListener('webkitfullscreenchange', () => {
            this.handleFullscreenChange();
        });
        
        document.addEventListener('msfullscreenchange', () => {
            this.handleFullscreenChange();
        });
    }
    
    updateVideoDuration() {
        const videoPlayer = document.getElementById('videoPlayer');
        const totalTimeElement = document.getElementById('videoTotalTime');
        
        if (videoPlayer && totalTimeElement && videoPlayer.duration) {
            totalTimeElement.textContent = this.formatTime(videoPlayer.duration);
        }
    }
    
    updateAudioDuration() {
        const audioPlayer = document.getElementById('audioPlayer');
        const totalTimeElement = document.getElementById('audioTotalTime');
        
        if (audioPlayer && totalTimeElement && audioPlayer.duration) {
            totalTimeElement.textContent = this.formatTime(audioPlayer.duration);
        }
    }
    
    updateVideoProgress() {
        const videoPlayer = document.getElementById('videoPlayer');
        const currentTimeElement = document.getElementById('videoCurrentTime');
        const progressFill = document.getElementById('videoProgressFill');
        const progressSlider = document.getElementById('videoProgressSlider');
        
        if (videoPlayer && videoPlayer.duration) {
            const percentage = (videoPlayer.currentTime / videoPlayer.duration) * 100;
            
            if (currentTimeElement) {
                currentTimeElement.textContent = this.formatTime(videoPlayer.currentTime);
            }
            
            if (progressFill) {
                progressFill.style.width = percentage + '%';
            }
            
            if (progressSlider) {
                progressSlider.value = percentage;
            }
        }
    }
    
    updateAudioProgress() {
        const audioPlayer = document.getElementById('audioPlayer');
        const currentTimeElement = document.getElementById('audioCurrentTime');
        const progressFill = document.getElementById('audioProgressFill');
        const progressSlider = document.getElementById('audioProgressSlider');
        
        if (audioPlayer && audioPlayer.duration) {
            const percentage = (audioPlayer.currentTime / audioPlayer.duration) * 100;
            
            if (currentTimeElement) {
                currentTimeElement.textContent = this.formatTime(audioPlayer.currentTime);
            }
            
            if (progressFill) {
                progressFill.style.width = percentage + '%';
            }
            
            if (progressSlider) {
                progressSlider.value = percentage;
            }
        }
    }
    
    updateVideoPlayPauseButtons(isPlaying) {
        const videoPlayPauseBtn = document.getElementById('videoPlayPauseBtn');
        const centerPlayBtn = document.getElementById('centerPlayBtn');
        
        // Update play/pause button icon
        if (videoPlayPauseBtn) {
            const icon = videoPlayPauseBtn.querySelector('i');
            if (icon) {
                icon.className = isPlaying ? 'fas fa-pause' : 'fas fa-play';
            }
        }
        
        // Show/hide center play button like YouTube
        if (centerPlayBtn) {
            centerPlayBtn.style.display = isPlaying ? 'none' : 'flex';
        }
        
        // Update player state
        this.isVideoPlaying = isPlaying;
        
        // Show controls when paused
        if (!isPlaying) {
            const controlsOverlay = document.getElementById('videoControlsOverlay');
            if (controlsOverlay) {
                controlsOverlay.classList.add('show');
            }
        }
    }
    
    updateAudioPlayPauseButtons(isPlaying) {
        const audioPlayPauseBtn = document.getElementById('audioPlayPauseBtn');
        if (audioPlayPauseBtn) {
            const icon = audioPlayPauseBtn.querySelector('i');
            if (icon) {
                icon.className = isPlaying ? 'fas fa-pause' : 'fas fa-play';
            }
        }
    }
    
    handleFullscreenChange() {
        const playerWrapper = document.querySelector('.player-wrapper');
        const fullscreenBtns = document.querySelectorAll('#videoFullscreenBtn i, #fullscreenBtn i');
        
        if (!document.fullscreenElement) {
            // Exited fullscreen
            if (playerWrapper) {
                playerWrapper.classList.remove('video-player-fullscreen');
            }
            fullscreenBtns.forEach(icon => {
                icon.className = 'fas fa-expand';
            });
        }
    }
    
    togglePlayPause() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        const currentPlayer = videoPlayer.style.display !== 'none' ? videoPlayer : audioPlayer;
        
        if (currentPlayer && !currentPlayer.paused) {
            currentPlayer.pause();
        } else if (currentPlayer) {
            currentPlayer.play().catch(e => console.log('Play failed:', e));
        }
    }
    
    playPrevious() {
        if (this.currentMediaIndex > 0) {
            const playlist = document.querySelectorAll('.modern-playlist-item');
            const prevItem = playlist[this.currentMediaIndex - 1];
            if (prevItem) {
                prevItem.click();
            }
        }
    }
    
    playNext() {
        if (this.currentMediaIndex < this.mediaFiles.length - 1) {
            const nextFile = this.mediaFiles[this.currentMediaIndex + 1];
            this.playMediaFile(nextFile, this.currentMediaIndex + 1);
        }
    }
    
    playPrevious() {
        if (this.currentMediaIndex > 0) {
            const prevFile = this.mediaFiles[this.currentMediaIndex - 1];
            this.playMediaFile(prevFile, this.currentMediaIndex - 1);
        }
    }
    
    setVolume(volume) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        [videoPlayer, audioPlayer].forEach(player => {
            if (player) player.volume = volume;
        });
        
        // Update mute button icon
        const muteBtn = document.getElementById('muteBtn');
        if (muteBtn) {
            const icon = muteBtn.querySelector('i');
            if (icon) {
                if (volume === 0) {
                    icon.className = 'fas fa-volume-mute';
                } else if (volume < 0.5) {
                    icon.className = 'fas fa-volume-down';
                } else {
                    icon.className = 'fas fa-volume-up';
                }
            }
        }
    }
    
    toggleMute() {
        const volumeSlider = document.getElementById('volumeSlider');
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        const currentPlayer = videoPlayer.style.display !== 'none' ? videoPlayer : audioPlayer;
        
        if (currentPlayer) {
            if (currentPlayer.muted) {
                currentPlayer.muted = false;
                this.setVolume(volumeSlider.value / 100);
            } else {
                currentPlayer.muted = true;
                this.setVolume(0);
            }
        }
    }
    
    seekTo(percentage) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        const currentPlayer = videoPlayer.style.display !== 'none' ? videoPlayer : audioPlayer;
        
        if (currentPlayer && currentPlayer.duration) {
            currentPlayer.currentTime = currentPlayer.duration * percentage;
        }
    }
    
    updateDuration() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const totalTimeElement = document.getElementById('totalTime');
        
        const currentPlayer = videoPlayer.style.display !== 'none' ? videoPlayer : audioPlayer;
        
        if (currentPlayer && totalTimeElement && currentPlayer.duration) {
            totalTimeElement.textContent = this.formatTime(currentPlayer.duration);
        }
    }
    
    updateProgress() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const currentTimeElement = document.getElementById('currentTime');
        const progressFill = document.getElementById('progressFill');
        const progressSlider = document.getElementById('progressSlider');
        
        const currentPlayer = videoPlayer.style.display !== 'none' ? videoPlayer : audioPlayer;
        
        if (currentPlayer && currentPlayer.duration) {
            const percentage = (currentPlayer.currentTime / currentPlayer.duration) * 100;
            
            if (currentTimeElement) {
                currentTimeElement.textContent = this.formatTime(currentPlayer.currentTime);
            }
            
            if (progressFill) {
                progressFill.style.width = percentage + '%';
            }
            
            if (progressSlider) {
                progressSlider.value = percentage;
            }
        }
    }
    
    formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = Math.floor(seconds % 60);
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    
    // Video-specific controls
    toggleVideoPlayPause() {
        const videoPlayer = document.getElementById('videoPlayer');
        if (videoPlayer && videoPlayer.style.display !== 'none') {
            if (videoPlayer.paused) {
                videoPlayer.play().catch(e => console.log('Video play failed:', e));
            } else {
                videoPlayer.pause();
            }
        }
    }
    
    toggleAudioPlayPause() {
        const audioPlayer = document.getElementById('audioPlayer');
        if (audioPlayer && audioPlayer.style.display !== 'none') {
            if (audioPlayer.paused) {
                audioPlayer.play().catch(e => console.log('Audio play failed:', e));
            } else {
                audioPlayer.pause();
            }
        }
    }
    
    setVideoVolume(volume) {
        const videoPlayer = document.getElementById('videoPlayer');
        if (videoPlayer) {
            videoPlayer.volume = volume;
            this.updateVideoVolumeIcon(volume);
        }
    }
    
    setAudioVolume(volume) {
        const audioPlayer = document.getElementById('audioPlayer');
        if (audioPlayer) {
            audioPlayer.volume = volume;
            this.updateAudioVolumeIcon(volume);
        }
    }
    
    updateVideoVolumeIcon(volume) {
        const muteBtn = document.getElementById('videoMuteBtn');
        if (muteBtn) {
            const icon = muteBtn.querySelector('i');
            if (icon) {
                if (volume === 0) {
                    icon.className = 'fas fa-volume-mute';
                } else if (volume < 0.5) {
                    icon.className = 'fas fa-volume-down';
                } else {
                    icon.className = 'fas fa-volume-up';
                }
            }
        }
    }
    
    updateAudioVolumeIcon(volume) {
        const muteBtn = document.getElementById('audioMuteBtn');
        if (muteBtn) {
            const icon = muteBtn.querySelector('i');
            if (icon) {
                if (volume === 0) {
                    icon.className = 'fas fa-volume-mute';
                } else if (volume < 0.5) {
                    icon.className = 'fas fa-volume-down';
                } else {
                    icon.className = 'fas fa-volume-up';
                }
            }
        }
    }
    
    toggleVideoMute() {
        const videoPlayer = document.getElementById('videoPlayer');
        const volumeSlider = document.getElementById('videoVolumeSlider');
        
        if (videoPlayer) {
            if (videoPlayer.muted) {
                videoPlayer.muted = false;
                this.setVideoVolume(volumeSlider ? volumeSlider.value / 100 : 0.5);
            } else {
                videoPlayer.muted = true;
                this.updateVideoVolumeIcon(0);
            }
        }
    }
    
    toggleAudioMute() {
        const audioPlayer = document.getElementById('audioPlayer');
        const volumeSlider = document.getElementById('audioVolumeSlider');
        
        if (audioPlayer) {
            if (audioPlayer.muted) {
                audioPlayer.muted = false;
                this.setAudioVolume(volumeSlider ? volumeSlider.value / 100 : 0.5);
            } else {
                audioPlayer.muted = true;
                this.updateAudioVolumeIcon(0);
            }
        }
    }
    
    seekVideoTo(percentage) {
        const videoPlayer = document.getElementById('videoPlayer');
        if (videoPlayer && videoPlayer.duration) {
            videoPlayer.currentTime = videoPlayer.duration * percentage;
        }
    }
    
    seekAudioTo(percentage) {
        const audioPlayer = document.getElementById('audioPlayer');
        if (audioPlayer && audioPlayer.duration) {
            audioPlayer.currentTime = audioPlayer.duration * percentage;
        }
    }
    
    seekVideoBy(seconds) {
        const videoPlayer = document.getElementById('videoPlayer');
        if (videoPlayer) {
            videoPlayer.currentTime = Math.max(0, Math.min(videoPlayer.duration, videoPlayer.currentTime + seconds));
        }
    }
    
    toggleFullscreen() {
        const playerWrapper = document.querySelector('.player-wrapper');
        const videoPlayer = document.getElementById('videoPlayer');
        
        if (!playerWrapper || !videoPlayer) return;
        
        if (!document.fullscreenElement) {
            // Enter fullscreen
            playerWrapper.classList.add('video-player-fullscreen');
            if (playerWrapper.requestFullscreen) {
                playerWrapper.requestFullscreen();
            } else if (playerWrapper.webkitRequestFullscreen) {
                playerWrapper.webkitRequestFullscreen();
            } else if (playerWrapper.msRequestFullscreen) {
                playerWrapper.msRequestFullscreen();
            }
            
            // Update fullscreen button icon
            const fullscreenBtns = document.querySelectorAll('#videoFullscreenBtn i, #fullscreenBtn i');
            fullscreenBtns.forEach(icon => {
                icon.className = 'fas fa-compress';
            });
        } else {
            // Exit fullscreen
            if (document.exitFullscreen) {
                document.exitFullscreen();
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen();
            } else if (document.msExitFullscreen) {
                document.msExitFullscreen();
            }
        }
    }
    
    toggleTheaterMode() {
        const playerWrapper = document.querySelector('.player-wrapper');
        const mediaLayout = document.querySelector('.modern-media-layout');
        
        if (!playerWrapper) return;
        
        if (playerWrapper.classList.contains('video-player-theater')) {
            // Exit theater mode
            playerWrapper.classList.remove('video-player-theater');
            mediaLayout?.classList.remove('theater-mode');
            
            // Update theater button icon
            const theaterBtn = document.getElementById('videoTheaterBtn');
            if (theaterBtn) {
                const icon = theaterBtn.querySelector('i');
                if (icon) icon.className = 'fas fa-expand-arrows-alt';
            }
        } else {
            // Enter theater mode
            playerWrapper.classList.add('video-player-theater');
            mediaLayout?.classList.add('theater-mode');
            
            // Update theater button icon
            const theaterBtn = document.getElementById('videoTheaterBtn');
            if (theaterBtn) {
                const icon = theaterBtn.querySelector('i');
                if (icon) icon.className = 'fas fa-compress-arrows-alt';
            }
        }
    }
    
    async loadFiles(path = this.currentPath) {
        try {
            console.log('📂 Loading files for path:', path);
            console.log('📂 Current path before loading:', this.currentPath);
            this.showLoading();
            
            const apiUrl = `/api/files?path=${encodeURIComponent(path)}`;
            console.log('📡 Making API call to:', apiUrl);
            
            // Add timeout to fetch request
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
            
            const response = await fetch(apiUrl, {
                signal: controller.signal,
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                }
            });
            
            clearTimeout(timeoutId);
            console.log('📡 API response received! Status:', response.status);
            console.log('📡 API response headers:', Object.fromEntries(response.headers.entries()));
            
            if (!response.ok) {
                console.error('❌ HTTP error:', response.status, response.statusText);
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const responseText = await response.text();
            console.log('📡 Raw response text length:', responseText.length);
            console.log('📡 Raw response preview:', responseText.substring(0, 500) + '...');
            
            let data;
            try {
                data = JSON.parse(responseText);
                console.log('✅ JSON parsed successfully!');
            } catch (parseError) {
                console.error('❌ JSON parse error:', parseError);
                console.error('❌ Response text that failed to parse:', responseText);
                throw new Error('Invalid JSON response from server');
            }
            
            console.log('📦 API response data structure:', {
                success: data.success,
                filesCount: data.files ? data.files.length : 0,
                hasFiles: !!data.files
            });
            
            if (data.success) {
                this.files = data.files;
                console.log('✅ Files loaded successfully:', this.files.length, 'files');
                console.log('📁 First few files:', this.files.slice(0, 3));
                this.currentPath = path;
                this.updateBreadcrumb();
                this.sortFiles();
                this.renderFiles();
            } else {
                console.error('❌ API returned error:', data.message || 'Unknown error');
                this.showToast('Error loading files: ' + (data.message || 'Unknown error'), 'error');
            }
        } catch (error) {
            console.error('❌ Error in loadFiles:', error);
            if (error.name === 'AbortError') {
                console.error('❌ Request timed out after 10 seconds');
                this.showToast('Request timed out. Please try again.', 'error');
            } else {
                this.showToast('Network error: ' + error.message, 'error');
            }
        } finally {
            this.hideLoading();
        }
    }

    async performSearch() {
        const searchInput = document.getElementById('searchInput');
        const query = searchInput.value.trim();
        
        if (query === '') {
            this.showToast('Please enter a search term', 'error');
            return;
        }
        
        try {
            console.log('🔍 Searching for:', query);
            this.showLoading();
            const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
            const data = await response.json();
            
            if (data.success) {
                this.files = data.results;
                console.log('✅ Search completed:', this.files.length, 'results');
                this.currentPath = `Search: "${query}"`;
                this.updateBreadcrumb();
                this.sortFiles();
                this.renderFiles();
                
                if (this.files.length === 0) {
                    this.showToast('No files found', 'info');
                }
            } else {
                console.error('❌ Search error:', data.error);
                this.showToast('Search failed: ' + data.error, 'error');
            }
        } catch (error) {
            console.error('❌ Search network error:', error);
            this.showToast('Search error: ' + error.message, 'error');
        } finally {
            this.hideLoading();
        }
    }
    
    sortFiles() {
        this.files.sort((a, b) => {
            // Directories first
            if (a.type === 'folder' && b.type !== 'folder') return -1;
            if (a.type !== 'folder' && b.type === 'folder') return 1;
            
            let aVal, bVal;
            
            switch (this.sortBy) {
                case 'name':
                    aVal = a.name.toLowerCase();
                    bVal = b.name.toLowerCase();
                    break;
                case 'modified':
                    aVal = new Date(a.modified);
                    bVal = new Date(b.modified);
                    break;
                case 'size':
                    aVal = a.size;
                    bVal = b.size;
                    break;
                case 'type':
                    aVal = a.type;
                    bVal = b.type;
                    break;
                default:
                    aVal = a.name.toLowerCase();
                    bVal = b.name.toLowerCase();
            }
            
            if (this.sortOrder === 'desc') {
                [aVal, bVal] = [bVal, aVal];
            }
            
            if (aVal < bVal) return -1;
            if (aVal > bVal) return 1;
            return 0;
        });
        
        this.renderFiles();
    }
    
    renderFiles() {
        console.log('🎨 Rendering files:', this.files.length, 'files');
        console.log('🎨 Files array:', this.files);
        
        const fileList = document.getElementById('fileList');
        if (!fileList) {
            console.error('❌ File list element not found!');
            return;
        }
        
        console.log('🎨 File list element found:', fileList);
        
        fileList.innerHTML = '';
        fileList.className = this.viewMode === 'grid' ? 'file-grid' : 'file-list';
        
        if (this.files.length === 0) {
            fileList.innerHTML = '<div class="empty-state">No files found in this directory</div>';
            console.log('📭 No files to display');
            return;
        }
        
        this.files.forEach((file, index) => {
            console.log(`📁 Rendering file ${index + 1}:`, file.name, file.type);
            const fileElement = this.createFileElement(file);
            fileList.appendChild(fileElement);
        });
        
        console.log('✅ Files rendered successfully');
        
        console.log('✅ Files rendered successfully');
    }
    
    createFileElement(file) {
        const div = document.createElement('div');
        div.className = this.viewMode === 'grid' ? 'file-item' : 'file-list-item';
        div.dataset.path = file.path;
        div.dataset.type = file.type;
        div.dataset.isDirectory = file.type === 'folder';
        
        const icon = this.getFileIcon(file);
        const size = file.type === 'folder' 
            ? (file.itemCount !== undefined ? `${file.itemCount} items` : '') 
            : this.formatFileSize(file.size);
        const modified = this.formatDate(file.modified);
        
        if (this.viewMode === 'grid') {
            div.innerHTML = `
                <div class="file-icon ${file.type}">${icon}</div>
                <div class="file-name">${file.name}</div>
                <div class="file-meta">${size}</div>
                <div class="file-meta">${modified}</div>
            `;
        } else {
            div.innerHTML = `
                <div class="file-list-icon ${file.type}">${icon}</div>
                <div class="file-name">${file.name}</div>
                <div class="file-size">${size}</div>
                <div class="file-modified">${modified}</div>
                <div class="file-actions">
                    <button class="action-btn small" onclick="app.downloadFile('${file.path}')">
                        <i class="fas fa-download"></i>
                    </button>
                </div>
            `;
        }
        
        div.addEventListener('dblclick', () => {
            if (file.type === 'folder') {
                console.log('📂 Opening folder:', file.path);
                this.navigateToPath(file.path);
            } else {
                this.openFile(file);
            }
        });

        // Right-click context menu
        div.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.showContextMenu(e, file);
        });
        
        return div;
    }
    
    getFileIcon(file) {
        if (file.type === 'folder') return '<i class="fas fa-folder"></i>';
        
        switch (file.type) {
            case 'video': return '<i class="fas fa-film"></i>';
            case 'audio': return '<i class="fas fa-music"></i>';
            case 'image': return '<i class="fas fa-image"></i>';
            case 'document': return '<i class="fas fa-file-alt"></i>';
            case 'archive': return '<i class="fas fa-file-archive"></i>';
            case 'code': return '<i class="fas fa-code"></i>';
            default: return '<i class="fas fa-file"></i>';
        }
    }
    
    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
    }
    
    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    }
    
    async switchView(view, pushHistory = true) {
        this.currentView = view;
        
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.view === view);
        });
        
        // Add to history if not navigating back
        if (pushHistory && !this.isNavigatingBack) {
            this.pushHistoryState(this.currentPath, view);
        }
        
        // Hide all content views first
        document.querySelectorAll('.content-view').forEach(content => {
            content.style.display = 'none';
            content.classList.remove('active');
        });
        
        // Show the selected view
        const targetView = document.getElementById(view + 'View');
        if (targetView) {
            targetView.style.display = 'block';
            targetView.classList.add('active');
        }
        
        // Load appropriate content
        switch (view) {
            case 'files':
                this.loadFiles();
                break;
            case 'media':
                try {
                    // Ensure files are loaded first, then filter for media
                    if (this.files.length === 0) {
                        console.log('🎬 Loading files before showing media view...');
                        await this.loadFiles();
                    }
                    console.log('🎬 Switching to media view with', this.files.length, 'files loaded');
                    await this.loadMediaFiles();
                } catch (error) {
                    console.error('❌ Error switching to media view:', error);
                    this.hideLoading();
                    this.showToast('Error loading media view: ' + error.message, 'error');
                }
                break;
            case 'images':
                try {
                    // Ensure files are loaded first, then filter for images
                    if (this.files.length === 0) {
                        console.log('🖼️ Loading files before showing images view...');
                        await this.loadFiles();
                    }
                    console.log('🖼️ Switching to images view with', this.files.length, 'files loaded');
                    await this.loadImageFiles();
                } catch (error) {
                    console.error('❌ Error switching to images view:', error);
                    this.hideLoading();
                    this.showToast('Error loading images view: ' + error.message, 'error');
                }
                break;
        }
    }
    
    setViewMode(mode) {
        this.viewMode = mode;
        
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        
        document.getElementById(mode + 'ViewBtn').classList.add('active');
        this.renderFiles();
    }
    
    updateBreadcrumb() {
        const breadcrumb = document.getElementById('currentPath');
        const displayPath = this.currentPath === '' ? 'Home' : this.currentPath;
        breadcrumb.textContent = displayPath;
        
        // Add click handlers for breadcrumb navigation
        if (this.currentPath !== '') {
            breadcrumb.style.cursor = 'pointer';
            breadcrumb.onclick = () => {
                const pathParts = this.currentPath.split('/').filter(p => p);
                pathParts.pop();
                const parentPath = pathParts.length === 0 ? '' : pathParts.join('/');
                this.navigateToPath(parentPath);
            };
        } else {
            breadcrumb.style.cursor = 'default';
            breadcrumb.onclick = null;
        }
    }
    
    async openFile(file) {
        if (file.type === 'video' || file.type === 'audio') {
            this.openMediaPlayer(file);
        } else if (file.type === 'image') {
            await this.switchView('images');
            this.viewImage(file);
        } else {
            // Download or open in new tab
            window.open(`/download/${encodeURIComponent(file.path)}`, '_blank');
        }
    }
    
    openMediaPlayer(file) {
        // Find all media files in current directory for playlist
        const mediaFiles = this.files.filter(f => f.type === 'video' || f.type === 'audio');
        const currentIndex = mediaFiles.findIndex(f => f.path === file.path);
        
        // Create media player modal if it doesn't exist
        let mediaModal = document.getElementById('mediaPlayerModal');
        if (!mediaModal) {
            console.error('Media player modal not found in DOM');
            return;
        }
        
        // Show the media player modal
        mediaModal.style.display = 'flex';
        
        // Add to browser history
        this.pushHistoryState(this.currentPath, this.currentView, true);
        
        // Initialize the media player with the file and playlist
        this.initializeMediaPlayer(file, mediaFiles, currentIndex);
    }
    
    initializeMediaPlayer(file, playlist, currentIndex) {
        // Set current file info
        this.currentMediaFile = file;
        this.currentMediaPlaylist = playlist;
        this.currentMediaIndex = currentIndex;
        
        // Update modal header with file info
        const fileIcon = document.querySelector('.media-file-icon');
        const fileName = document.querySelector('.media-file-name');
        const fileSize = document.querySelector('.media-file-size');
        
        if (fileIcon) {
            fileIcon.innerHTML = file.type === 'video' ? '🎬' : '🎵';
        }
        if (fileName) {
            fileName.textContent = file.name;
        }
        if (fileSize) {
            fileSize.textContent = this.formatFileSize(file.size);
        }
        
        // Initialize player based on file type
        if (file.type === 'video') {
            this.initializeVideoPlayer(file);
        } else if (file.type === 'audio') {
            this.initializeAudioPlayer(file);
        }
        
        // Update playlist
        this.updateMediaPlaylist(playlist, currentIndex);
        
        // Set up event listeners for this media session
        this.setupMediaEventListeners();
    }
    
    initializeVideoPlayer(file) {
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        const unsupportedContainer = document.getElementById('unsupportedMediaContainer');
        
        // Hide other containers
        if (audioContainer) audioContainer.style.display = 'none';
        if (unsupportedContainer) unsupportedContainer.style.display = 'none';
        
        // Show video container
        if (videoContainer) {
            videoContainer.style.display = 'block';
            
            const videoPlayer = document.getElementById('videoPlayer');
            if (videoPlayer) {
                const streamUrl = `/stream/${encodeURIComponent(file.path)}`;
                videoPlayer.src = streamUrl;
                videoPlayer.load();
                
                // Auto-play after a short delay to ensure proper loading
                setTimeout(() => {
                    videoPlayer.play().catch(e => {
                        console.log('Auto-play prevented, user interaction required');
                    });
                }, 100);
            }
        }
    }
    
    initializeAudioPlayer(file) {
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        const unsupportedContainer = document.getElementById('unsupportedMediaContainer');
        
        // Hide other containers
        if (videoContainer) videoContainer.style.display = 'none';
        if (unsupportedContainer) unsupportedContainer.style.display = 'none';
        
        // Show audio container
        if (audioContainer) {
            audioContainer.style.display = 'block';
            
            const audioPlayer = document.getElementById('audioPlayer');
            if (audioPlayer) {
                const streamUrl = `/stream/${encodeURIComponent(file.path)}`;
                audioPlayer.src = streamUrl;
                audioPlayer.load();
                
                // Auto-play after a short delay
                setTimeout(() => {
                    audioPlayer.play().catch(e => {
                        console.log('Auto-play prevented, user interaction required');
                    });
                }, 100);
            }
        }
    }
    
    updateMediaPlaylist(playlist, currentIndex) {
        const playlistItems = document.querySelector('.playlist-items');
        if (!playlistItems) return;
        
        playlistItems.innerHTML = '';
        
        playlist.forEach((file, index) => {
            const item = document.createElement('div');
            item.className = `playlist-item ${index === currentIndex ? 'active' : ''}`;
            item.innerHTML = `
                <div class="playlist-item-icon">${file.type === 'video' ? '🎬' : '🎵'}</div>
                <div class="playlist-item-info">
                    <div class="playlist-item-name">${file.name}</div>
                    <div class="playlist-item-duration">${this.formatFileSize(file.size)}</div>
                </div>
            `;
            
            item.addEventListener('click', () => {
                this.playMediaFile(file, index);
            });
            
            playlistItems.appendChild(item);
        });
    }
    
    setupMediaEventListeners() {
        // Close modal events
        const closeBtn = document.getElementById('mediaCloseBtn');
        const overlay = document.querySelector('.media-modal-overlay');
        
        if (closeBtn) {
            closeBtn.onclick = () => this.closeMediaPlayer();
        }
        
        if (overlay) {
            overlay.onclick = (e) => {
                if (e.target === overlay) {
                    this.closeMediaPlayer();
                }
            };
        }
        
        // Header controls
        const fullscreenBtn = document.getElementById('mediaFullscreenBtn');
        const downloadBtn = document.getElementById('mediaDownloadBtn');
        
        if (fullscreenBtn) {
            fullscreenBtn.onclick = () => toggleFullscreen();
        }
        
        if (downloadBtn) {
            downloadBtn.onclick = () => downloadCurrentMedia();
        }
        
        // Media controls
        const playPauseBtn = document.getElementById('mediaPlayPauseBtn');
        const prevBtn = document.getElementById('mediaPrevBtn');
        const nextBtn = document.getElementById('mediaNextBtn');
        
        if (playPauseBtn) {
            playPauseBtn.onclick = () => this.togglePlayPause();
        }
        
        if (prevBtn) {
            prevBtn.onclick = () => this.playPreviousTrack();
        }
        
        if (nextBtn) {
            nextBtn.onclick = () => this.playNextTrack();
        }
        
        // Volume control
        const volumeSlider = document.getElementById('volumeSlider');
        if (volumeSlider) {
            volumeSlider.oninput = (e) => this.setVolume(e.target.value / 100);
        }
        
        // Progress control
        const progressSlider = document.getElementById('progressSlider');
        if (progressSlider) {
            progressSlider.oninput = (e) => this.setCurrentTime(e.target.value);
            progressSlider.onchange = (e) => this.setCurrentTime(e.target.value);
        }
        
        // Set up media element event listeners
        this.setupMediaElementListeners();
    }
    
    setupMediaElementListeners() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        [videoPlayer, audioPlayer].forEach(player => {
            if (!player) return;
            
            player.ontimeupdate = () => this.updateProgress();
            player.onloadedmetadata = () => this.updateDuration();
            player.onplay = () => this.onMediaPlay();
            player.onpause = () => this.onMediaPause();
            player.onended = () => this.onMediaEnded();
            player.onvolumechange = () => this.updateVolumeDisplay();
        });
    }
    
    closeMediaPlayer() {
        const mediaModal = document.getElementById('mediaPlayerModal');
        if (mediaModal) {
            mediaModal.style.display = 'none';
        }
        
        // Pause and reset players
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        if (videoPlayer) {
            videoPlayer.pause();
            videoPlayer.src = '';
        }
        
        if (audioPlayer) {
            audioPlayer.pause();
            audioPlayer.src = '';
        }
        
        // Reset state
        this.currentMediaFile = null;
        this.currentMediaPlaylist = [];
        this.currentMediaIndex = -1;
    }
    
    togglePlayPause() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        
        let currentPlayer = null;
        
        // Determine which player is currently active
        if (videoContainer && videoContainer.style.display !== 'none') {
            currentPlayer = videoPlayer;
        } else if (audioContainer && audioContainer.style.display !== 'none') {
            currentPlayer = audioPlayer;
        }
        
        if (currentPlayer) {
            if (currentPlayer.paused) {
                currentPlayer.play();
            } else {
                currentPlayer.pause();
            }
        }
    }
    
    playNextTrack() {
        if (this.currentMediaIndex < this.currentMediaPlaylist.length - 1) {
            const nextFile = this.currentMediaPlaylist[this.currentMediaIndex + 1];
            this.playMediaFile(nextFile, this.currentMediaIndex + 1);
        }
    }
    
    playPreviousTrack() {
        if (this.currentMediaIndex > 0) {
            const prevFile = this.currentMediaPlaylist[this.currentMediaIndex - 1];
            this.playMediaFile(prevFile, this.currentMediaIndex - 1);
        }
    }
    
    playMediaFile(file, index) {
        this.currentMediaFile = file;
        this.currentMediaIndex = index;
        
        // Update active playlist item
        document.querySelectorAll('.playlist-item').forEach((item, i) => {
            item.classList.toggle('active', i === index);
        });
        
        // Update file info in header
        const fileName = document.querySelector('.media-file-name');
        const fileSize = document.querySelector('.media-file-size');
        const fileIcon = document.querySelector('.media-file-icon');
        
        if (fileName) fileName.textContent = file.name;
        if (fileSize) fileSize.textContent = this.formatFileSize(file.size);
        if (fileIcon) fileIcon.innerHTML = file.type === 'video' ? '🎬' : '🎵';
        
        // Initialize the appropriate player
        if (file.type === 'video') {
            this.initializeVideoPlayer(file);
        } else if (file.type === 'audio') {
            this.initializeAudioPlayer(file);
        }
    }
    
    setVolume(volume) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        if (videoPlayer) videoPlayer.volume = volume;
        if (audioPlayer) audioPlayer.volume = volume;
    }
    
    setCurrentTime(time) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        
        let currentPlayer = null;
        
        // Determine which player is currently active
        if (videoContainer && videoContainer.style.display !== 'none') {
            currentPlayer = videoPlayer;
        } else if (audioContainer && audioContainer.style.display !== 'none') {
            currentPlayer = audioPlayer;
        }
        
        if (currentPlayer && !isNaN(currentPlayer.duration)) {
            currentPlayer.currentTime = (time / 100) * currentPlayer.duration;
        }
    }
    
    updateProgress() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        
        let currentPlayer = null;
        
        // Determine which player is currently active
        if (videoContainer && videoContainer.style.display !== 'none') {
            currentPlayer = videoPlayer;
        } else if (audioContainer && audioContainer.style.display !== 'none') {
            currentPlayer = audioPlayer;
        }
        
        if (!currentPlayer || isNaN(currentPlayer.duration)) return;
        
        const progress = (currentPlayer.currentTime / currentPlayer.duration) * 100;
        const progressFill = document.getElementById('mediaProgressFill');
        const progressSlider = document.getElementById('progressSlider');
        const currentTimeDisplay = document.getElementById('currentTime');
        
        if (progressFill) progressFill.style.width = progress + '%';
        if (progressSlider) progressSlider.value = progress;
        if (currentTimeDisplay) currentTimeDisplay.textContent = this.formatTime(currentPlayer.currentTime);
    }
    
    updateDuration() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        
        let currentPlayer = null;
        
        // Determine which player is currently active
        if (videoContainer && videoContainer.style.display !== 'none') {
            currentPlayer = videoPlayer;
        } else if (audioContainer && audioContainer.style.display !== 'none') {
            currentPlayer = audioPlayer;
        }
        
        if (!currentPlayer || isNaN(currentPlayer.duration)) return;
        
        const durationDisplay = document.getElementById('totalTime');
        if (durationDisplay) durationDisplay.textContent = this.formatTime(currentPlayer.duration);
    }
    
    onMediaPlay() {
        const playPauseBtn = document.getElementById('mediaPlayPauseBtn');
        if (playPauseBtn) playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>';
    }
    
    onMediaPause() {
        const playPauseBtn = document.getElementById('mediaPlayPauseBtn');
        if (playPauseBtn) playPauseBtn.innerHTML = '<i class="fas fa-play"></i>';
    }
    
    onMediaEnded() {
        // Auto-play next track if available
        this.playNextTrack();
    }
    
    updateVolumeDisplay() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const videoContainer = document.getElementById('videoPlayerContainer');
        const audioContainer = document.getElementById('audioPlayerContainer');
        const volumeSlider = document.getElementById('volumeSlider');
        
        let currentPlayer = null;
        
        // Determine which player is currently active
        if (videoContainer && videoContainer.style.display !== 'none') {
            currentPlayer = videoPlayer;
        } else if (audioContainer && audioContainer.style.display !== 'none') {
            currentPlayer = audioPlayer;
        }
        
        if (currentPlayer && volumeSlider) {
            volumeSlider.value = currentPlayer.volume * 100;
        }
    }
    
    formatTime(seconds) {
        if (isNaN(seconds)) return '0:00';
        
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = Math.floor(seconds % 60);
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    
    async viewImage(file) {
        // Find all image files in current directory for gallery
        const imageFiles = this.files.filter(f => f.type === 'image');
        const currentIndex = imageFiles.findIndex(f => f.path === file.path);
        
        if (currentIndex === -1) {
            this.showToast('Image not found in current directory', 'error');
            return;
        }
        
        // Initialize image viewer
        this.openImageViewer(imageFiles, currentIndex);
    }
    
    openImageViewer(imageFiles, startIndex = 0) {
        // Set up image viewer state
        this.currentImageFiles = imageFiles;
        this.currentImageIndex = startIndex;
        
        const imageModal = document.getElementById('imageViewerModal');
        if (!imageModal) {
            console.error('Image viewer modal not found');
            return;
        }
        
        // Show the modal
        imageModal.style.display = 'flex';
        
        // Add to browser history
        this.pushHistoryState(this.currentPath, this.currentView, true);
        
        // Initialize the image viewer
        this.initializeImageViewer();
        
        // Set up event listeners
        this.setupImageViewerEvents();
        
        // Load the initial image
        this.loadImageAtIndex(startIndex);
    }
    
    initializeImageViewer() {
        // Update counter
        const currentIndexEl = document.getElementById('currentImageIndex');
        const totalImagesEl = document.getElementById('totalImages');
        
        if (currentIndexEl) currentIndexEl.textContent = this.currentImageIndex + 1;
        if (totalImagesEl) totalImagesEl.textContent = this.currentImageFiles.length;
        
        // Enable/disable navigation buttons
        this.updateImageNavButtons();
        
        // Generate thumbnails
        this.generateImageThumbnails();
    }
    
    setupImageViewerEvents() {
        // Remove existing listeners first
        this.removeImageViewerEvents();
        
        // Navigation buttons
        const prevBtn = document.getElementById('prevImageBtn');
        const nextBtn = document.getElementById('nextImageBtn');
        const closeBtn = document.getElementById('closeImageViewer');
        const downloadBtn = document.getElementById('downloadImageBtn');
        
        this.imageViewerEvents = {
            prevImage: () => this.navigateImage(-1),
            nextImage: () => this.navigateImage(1),
            closeViewer: () => this.closeImageViewer(),
            downloadImage: () => this.downloadCurrentImage(),
            keyHandler: (e) => this.handleImageViewerKeys(e),
            swipeHandler: (e) => this.handleImageSwipe(e)
        };
        
        if (prevBtn) prevBtn.addEventListener('click', this.imageViewerEvents.prevImage);
        if (nextBtn) nextBtn.addEventListener('click', this.imageViewerEvents.nextImage);
        if (closeBtn) closeBtn.addEventListener('click', this.imageViewerEvents.closeViewer);
        if (downloadBtn) downloadBtn.addEventListener('click', this.imageViewerEvents.downloadImage);
        
        // Keyboard navigation
        document.addEventListener('keydown', this.imageViewerEvents.keyHandler);
        
        // Touch/swipe support
        const imageContent = document.querySelector('.image-viewer-content');
        if (imageContent) {
            this.setupImageSwipeGestures(imageContent);
        }
        
        // Click to toggle UI
        const imageModal = document.getElementById('imageViewerModal');
        if (imageModal) {
            imageModal.addEventListener('click', (e) => {
                if (e.target === imageModal || e.target.classList.contains('current-image')) {
                    this.toggleImageViewerUI();
                }
            });
        }
    }
    
    removeImageViewerEvents() {
        if (this.imageViewerEvents) {
            const prevBtn = document.getElementById('prevImageBtn');
            const nextBtn = document.getElementById('nextImageBtn');
            const closeBtn = document.getElementById('closeImageViewer');
            const downloadBtn = document.getElementById('downloadImageBtn');
            
            if (prevBtn) prevBtn.removeEventListener('click', this.imageViewerEvents.prevImage);
            if (nextBtn) nextBtn.removeEventListener('click', this.imageViewerEvents.nextImage);
            if (closeBtn) closeBtn.removeEventListener('click', this.imageViewerEvents.closeViewer);
            if (downloadBtn) downloadBtn.removeEventListener('click', this.imageViewerEvents.downloadImage);
            
            document.removeEventListener('keydown', this.imageViewerEvents.keyHandler);
        }
    }
    
    setupImageSwipeGestures(element) {
        let startX = 0;
        let startY = 0;
        let distX = 0;
        let distY = 0;
        let threshold = 100; // Minimum distance for swipe
        let restraint = 150; // Maximum distance perpendicular to swipe direction
        
        element.addEventListener('touchstart', (e) => {
            const touch = e.touches[0];
            startX = touch.clientX;
            startY = touch.clientY;
        }, { passive: true });
        
        element.addEventListener('touchend', (e) => {
            const touch = e.changedTouches[0];
            distX = touch.clientX - startX;
            distY = touch.clientY - startY;
            
            // Check if it's a horizontal swipe
            if (Math.abs(distX) >= threshold && Math.abs(distY) <= restraint) {
                if (distX > 0) {
                    // Swipe right - previous image
                    this.navigateImage(-1);
                } else {
                    // Swipe left - next image
                    this.navigateImage(1);
                }
            }
        }, { passive: true });
    }
    
    handleImageViewerKeys(e) {
        const imageModal = document.getElementById('imageViewerModal');
        if (!imageModal || imageModal.style.display === 'none') return;
        
        switch (e.key) {
            case 'ArrowLeft':
                e.preventDefault();
                this.navigateImage(-1);
                break;
            case 'ArrowRight':
                e.preventDefault();
                this.navigateImage(1);
                break;
            case 'Escape':
                e.preventDefault();
                this.closeImageViewer();
                break;
            case ' ':
                e.preventDefault();
                this.toggleImageViewerUI();
                break;
        }
    }
    
    navigateImage(direction) {
        const newIndex = this.currentImageIndex + direction;
        
        if (newIndex >= 0 && newIndex < this.currentImageFiles.length) {
            this.currentImageIndex = newIndex;
            this.loadImageAtIndex(newIndex);
        }
    }
    
    loadImageAtIndex(index) {
        const file = this.currentImageFiles[index];
        if (!file) return;
        
        const currentImage = document.getElementById('currentImage');
        const imageLoader = document.getElementById('imageLoader');
        
        // Show loader
        if (imageLoader) imageLoader.style.display = 'block';
        if (currentImage) currentImage.style.opacity = '0.5';
        
        // Update file info
        this.updateImageFileInfo(file);
        
        // Load image
        const img = new Image();
        img.onload = () => {
            if (currentImage) {
                currentImage.src = img.src;
                currentImage.style.opacity = '1';
                
                // Update resolution info
                const resolutionEl = document.querySelector('.image-file-resolution');
                if (resolutionEl) {
                    resolutionEl.textContent = `${img.naturalWidth} x ${img.naturalHeight}`;
                }
            }
            if (imageLoader) imageLoader.style.display = 'none';
        };
        
        img.onerror = () => {
            if (imageLoader) imageLoader.style.display = 'none';
            if (currentImage) currentImage.style.opacity = '1';
            this.showToast('Failed to load image', 'error');
        };
        
        img.src = `/stream/${encodeURIComponent(file.path)}`;
        
        // Update UI
        const currentIndexEl = document.getElementById('currentImageIndex');
        if (currentIndexEl) currentIndexEl.textContent = index + 1;
        
        this.updateImageNavButtons();
        this.updateActiveThumbnail(index);
    }
    
    updateImageFileInfo(file) {
        const fileName = document.querySelector('.image-file-name');
        const fileSize = document.querySelector('.image-file-size');
        
        if (fileName) fileName.textContent = file.name;
        if (fileSize) fileSize.textContent = this.formatFileSize(file.size);
    }
    
    updateImageNavButtons() {
        const prevBtn = document.getElementById('prevImageBtn');
        const nextBtn = document.getElementById('nextImageBtn');
        
        if (prevBtn) {
            prevBtn.disabled = this.currentImageIndex === 0;
        }
        
        if (nextBtn) {
            nextBtn.disabled = this.currentImageIndex === this.currentImageFiles.length - 1;
        }
    }
    
    generateImageThumbnails() {
        const thumbnailsContainer = document.getElementById('imageThumbnails');
        if (!thumbnailsContainer) return;
        
        thumbnailsContainer.innerHTML = '';
        
        this.currentImageFiles.forEach((file, index) => {
            const thumbnail = document.createElement('div');
            thumbnail.className = 'image-thumbnail';
            if (index === this.currentImageIndex) {
                thumbnail.classList.add('active');
            }
            
            const img = document.createElement('img');
            img.src = `/stream/${encodeURIComponent(file.path)}`;
            img.alt = file.name;
            img.loading = 'lazy';
            
            thumbnail.appendChild(img);
            thumbnail.addEventListener('click', () => {
                this.currentImageIndex = index;
                this.loadImageAtIndex(index);
            });
            
            thumbnailsContainer.appendChild(thumbnail);
        });
    }
    
    updateActiveThumbnail(index) {
        const thumbnails = document.querySelectorAll('.image-thumbnail');
        thumbnails.forEach((thumb, i) => {
            thumb.classList.toggle('active', i === index);
        });
        
        // Scroll active thumbnail into view
        const activeThumbnail = thumbnails[index];
        if (activeThumbnail) {
            activeThumbnail.scrollIntoView({ 
                behavior: 'smooth', 
                inline: 'center',
                block: 'nearest'
            });
        }
    }
    
    downloadCurrentImage() {
        const currentFile = this.currentImageFiles[this.currentImageIndex];
        if (currentFile) {
            const link = document.createElement('a');
            link.href = `/download/${encodeURIComponent(currentFile.path)}`;
            link.download = currentFile.name;
            link.click();
            this.showToast('Downloading image...', 'success');
        }
    }
    
    toggleImageViewerUI() {
        const imageModal = document.getElementById('imageViewerModal');
        if (imageModal) {
            imageModal.classList.toggle('hide-ui');
        }
    }
    
    closeImageViewer() {
        const imageModal = document.getElementById('imageViewerModal');
        if (imageModal) {
            imageModal.style.display = 'none';
        }
        
        // Remove event listeners
        this.removeImageViewerEvents();
        
        // Clear state
        this.currentImageFiles = [];
        this.currentImageIndex = -1;
        
        // Add to history if not navigating back
        if (!this.isNavigatingBack) {
            this.pushHistoryState(this.currentPath, this.currentView, false);
        }
    }
    
    async performSearch() {
        const query = document.getElementById('searchInput').value.trim();
        if (!query) return;
        
        try {
            this.showLoading();
            const response = await fetch(`/api/search?q=${encodeURIComponent(query)}&path=${encodeURIComponent(this.currentPath)}`);
            const data = await response.json();
            
            if (data.success) {
                this.files = data.files;
                this.renderFiles();
                this.showToast(`Found ${data.files.length} results for "${query}"`, 'success');
            } else {
                this.showToast('Search failed: ' + data.message, 'error');
            }
        } catch (error) {
            this.showToast('Search error: ' + error.message, 'error');
        } finally {
            this.hideLoading();
        }
    }
    
    async downloadFile(path) {
        try {
            console.log('📥 Downloading file:', path);
            window.open(`/api/download?path=${encodeURIComponent(path)}`, '_blank');
        } catch (error) {
            console.error('❌ Download error:', error);
            this.showToast('Download failed: ' + error.message, 'error');
        }
    }
    
    async deleteFile(path) {
        if (!confirm('Are you sure you want to delete this item?')) return;
        
        try {
            const response = await fetch(`/api/delete?path=${encodeURIComponent(path)}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.showToast('Item deleted successfully', 'success');
                this.loadFiles();
            } else {
                this.showToast('Failed to delete: ' + data.message, 'error');
            }
        } catch (error) {
            this.showToast('Network error: ' + error.message, 'error');
        }
    }
    
    showContextMenu(event, fileItem) {
        const contextMenu = document.getElementById('contextMenu');
        const path = fileItem.dataset.path;
        
        // Position menu
        contextMenu.style.left = event.pageX + 'px';
        contextMenu.style.top = event.pageY + 'px';
        contextMenu.style.display = 'block';
        
        // Add event listeners
        contextMenu.onclick = (e) => {
            const action = e.target.closest('.context-item')?.dataset.action;
            if (action) {
                this.handleContextAction(action, path);
                this.hideContextMenu();
            }
        };
    }
    
    hideContextMenu() {
        document.getElementById('contextMenu').style.display = 'none';
    }
    
    handleContextAction(action, path) {
        switch (action) {
            case 'download':
                this.downloadFile(path);
                break;
            case 'delete':
                this.deleteFile(path);
                break;
            case 'rename':
                this.renameFile(path);
                break;
            case 'info':
                this.showFileInfo(path);
                break;
        }
    }

    hideModals() {
        const wasModalOpen = this.isModalOpen();
        console.log('🔒 hideModals called, was modal open:', wasModalOpen);
        
        // Close image viewer if open
        const imageModal = document.getElementById('imageViewerModal');
        if (imageModal && imageModal.style.display === 'flex') {
            this.closeImageViewer();
        }
        
        document.querySelectorAll('.modal').forEach(modal => {
            console.log('🔒 Hiding modal:', modal.id, 'current display:', modal.style.display);
            modal.style.display = 'none';
        });
        
        // If we closed a modal and we're not navigating back, push new history state
        if (wasModalOpen && !this.isNavigatingBack) {
            console.log('🔒 Pushing new history state after closing modal');
            this.pushHistoryState(this.currentPath, this.currentView, false);
        }
    }
    
    showLoading() {
        document.getElementById('loadingSpinner').style.display = 'flex';
    }
    
    hideLoading() {
        document.getElementById('loadingSpinner').style.display = 'none';
    }
    
    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        
        document.getElementById('toastContainer').appendChild(toast);
        
        setTimeout(() => {
            toast.remove();
        }, 5000);
    }

    showContextMenu(event, file) {
        // Remove existing context menu
        const existingMenu = document.querySelector('.context-menu');
        if (existingMenu) {
            existingMenu.remove();
        }

        const contextMenu = document.createElement('div');
        contextMenu.className = 'context-menu';
        contextMenu.style.position = 'fixed';
        contextMenu.style.left = event.clientX + 'px';
        contextMenu.style.top = event.clientY + 'px';
        contextMenu.style.backgroundColor = 'white';
        contextMenu.style.border = '1px solid #ccc';
        contextMenu.style.borderRadius = '4px';
        contextMenu.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
        contextMenu.style.zIndex = '1000';
        contextMenu.style.minWidth = '150px';

        const menuItems = [];
        
        if (file.type === 'folder') {
            menuItems.push({ label: 'Open', action: () => this.loadFiles(file.path) });
        } else {
            menuItems.push({ label: 'Download', action: () => this.downloadFile(file.path) });
        }
        
        menuItems.push(
            { label: 'Rename', action: () => this.renameFile(file) },
            { label: 'Delete', action: () => this.deleteFile(file.path) },
            { label: 'Copy Path', action: () => this.copyPath(file.path) }
        );

        menuItems.forEach(item => {
            const menuItem = document.createElement('div');
            menuItem.textContent = item.label;
            menuItem.style.padding = '8px 12px';
            menuItem.style.cursor = 'pointer';
            menuItem.style.borderBottom = '1px solid #f0f0f0';
            
            menuItem.addEventListener('click', () => {
                item.action();
                contextMenu.remove();
            });
            
            menuItem.addEventListener('mouseover', () => {
                menuItem.style.backgroundColor = '#f5f5f5';
            });
            
            menuItem.addEventListener('mouseout', () => {
                menuItem.style.backgroundColor = 'white';
            });
            
            contextMenu.appendChild(menuItem);
        });

        document.body.appendChild(contextMenu);

        // Close menu when clicking outside
        const closeMenu = (e) => {
            if (!contextMenu.contains(e.target)) {
                contextMenu.remove();
                document.removeEventListener('click', closeMenu);
            }
        };
        
        setTimeout(() => {
            document.addEventListener('click', closeMenu);
        }, 10);
    }

    async renameFile(file) {
        const newName = prompt('Enter new name:', file.name);
        if (!newName || newName === file.name) return;

        try {
            const response = await fetch('/api/rename', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: file.path, name: newName })
            });

            const data = await response.json();
            if (data.success) {
                this.showToast('File renamed successfully', 'success');
                this.loadFiles();
            } else {
                this.showToast('Rename failed: ' + data.error, 'error');
            }
        } catch (error) {
            this.showToast('Rename error: ' + error.message, 'error');
        }
    }

    copyPath(path) {
        navigator.clipboard.writeText(path).then(() => {
            this.showToast('Path copied to clipboard', 'success');
        }).catch(() => {
            this.showToast('Failed to copy path', 'error');
        });
    }
    
    async loadMediaFiles() {
        try {
            console.log('🎬 loadMediaFiles called with', this.files.length, 'total files');
            
            // Filter current files for media types (video and audio)
            const mediaFiles = this.files.filter(file => 
                (file.type === 'video' || file.type === 'audio') && 
                !file.isDirectory
            );
            
            // Store media files for player navigation
            this.mediaFiles = mediaFiles;
            
            console.log('🎬 Found', mediaFiles.length, 'media files');
            this.renderMediaPlaylist(mediaFiles);
            
            // Hide loading spinner after rendering
            this.hideLoading();
        } catch (error) {
            console.error('❌ Error in loadMediaFiles:', error);
            this.hideLoading();
            this.showToast('Failed to load media files: ' + error.message, 'error');
        }
    }
    
    async loadImageFiles() {
        try {
            console.log('🖼️ loadImageFiles called with', this.files.length, 'total files');
            
            // Filter current files for image types
            const imageFiles = this.files.filter(file => 
                file.type === 'image' && 
                !file.isDirectory
            );
            
            console.log('🖼️ Found', imageFiles.length, 'image files');
            this.renderImageGallery(imageFiles);
            
            // Hide loading spinner after rendering
            this.hideLoading();
        } catch (error) {
            console.error('❌ Error in loadImageFiles:', error);
            this.hideLoading();
            this.showToast('Failed to load images: ' + error.message, 'error');
        }
    }
    
    renderMediaPlaylist(mediaFiles) {
        const playlist = document.getElementById('playlist');
        const playlistCount = document.getElementById('playlistCount');
        
        if (!playlist) {
            console.error('❌ Playlist element not found');
            return;
        }
        
        console.log('🎬 Rendering modern media playlist with', mediaFiles.length, 'files');
        playlist.innerHTML = '';
        
        // Update playlist count
        if (playlistCount) {
            playlistCount.textContent = `${mediaFiles.length} files`;
        }
        
        if (mediaFiles.length === 0) {
            playlist.innerHTML = `
                <div style="text-align: center; padding: 40px 20px; color: #64748b;">
                    <i class="fas fa-music" style="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                    <h3 style="margin-bottom: 8px; font-size: 16px;">No media files found</h3>
                    <p style="font-size: 14px;">Upload some videos or audio files to get started</p>
                </div>
            `;
            return;
        }
        
        mediaFiles.forEach((file, index) => {
            const item = document.createElement('div');
            item.className = 'modern-playlist-item';
            item.dataset.index = index;
            item.dataset.path = file.path;
            
            // Determine file type icon
            let iconClass = 'fas fa-file';
            if (file.type === 'video' || file.name.toLowerCase().match(/\.(mp4|avi|mov|mkv|wmv|flv|webm|m4v|3gp)$/)) {
                iconClass = 'fas fa-film';
            } else if (file.type === 'audio' || file.name.toLowerCase().match(/\.(mp3|wav|flac|aac|ogg|wma|m4a)$/)) {
                iconClass = 'fas fa-music';
            }
            
            // Get file extension for display
            const extension = file.name.split('.').pop().toUpperCase();
            
            item.innerHTML = `
                <div class="playlist-item-icon">
                    <i class="${iconClass}"></i>
                </div>
                <div class="playlist-item-info">
                    <div class="playlist-item-name" title="${file.name}">${file.name}</div>
                    <div class="playlist-item-meta">
                        <span>${extension}</span>
                        <span>•</span>
                        <span>${this.formatFileSize(file.size)}</span>
                    </div>
                </div>
                <div class="playlist-item-duration">--:--</div>
                <button class="playlist-play-btn" title="Play">
                    <i class="fas fa-play"></i>
                </button>
            `;
            
            // Add click handlers
            item.addEventListener('click', () => {
                this.playMediaFile(file, index);
            });
            
            const playBtn = item.querySelector('.playlist-play-btn');
            playBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.playMediaFile(file, index);
            });
            
            playlist.appendChild(item);
        });
        
        // Initialize filter buttons
        this.initPlaylistFilters(mediaFiles);
    }
    
    initPlaylistFilters(mediaFiles) {
        const filterButtons = document.querySelectorAll('.filter-btn');
        
        filterButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                // Remove active class from all buttons
                filterButtons.forEach(b => b.classList.remove('active'));
                // Add active class to clicked button
                btn.classList.add('active');
                
                const filter = btn.dataset.filter;
                this.filterPlaylist(filter, mediaFiles);
            });
        });
    }
    
    filterPlaylist(filter, allFiles) {
        const playlist = document.getElementById('playlist');
        let filteredFiles = allFiles;
        
        if (filter === 'video') {
            filteredFiles = allFiles.filter(file => 
                file.type === 'video' || file.name.toLowerCase().match(/\.(mp4|avi|mov|mkv|wmv|flv|webm|m4v|3gp)$/)
            );
        } else if (filter === 'audio') {
            filteredFiles = allFiles.filter(file => 
                file.type === 'audio' || file.name.toLowerCase().match(/\.(mp3|wav|flac|aac|ogg|wma|m4a)$/)
            );
        }
        
        // Re-render playlist with filtered files
        const playlistCount = document.getElementById('playlistCount');
        if (playlistCount) {
            playlistCount.textContent = `${filteredFiles.length} files`;
        }
        
        playlist.innerHTML = '';
        
        if (filteredFiles.length === 0) {
            playlist.innerHTML = `
                <div style="text-align: center; padding: 40px 20px; color: #64748b;">
                    <i class="fas fa-search" style="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                    <h3 style="margin-bottom: 8px; font-size: 16px;">No ${filter} files found</h3>
                    <p style="font-size: 14px;">Try a different filter or upload more files</p>
                </div>
            `;
            return;
        }
        
        filteredFiles.forEach((file, index) => {
            const item = document.createElement('div');
            item.className = 'modern-playlist-item';
            item.dataset.index = index;
            item.dataset.path = file.path;
            
            // Determine file type icon
            let iconClass = 'fas fa-file';
            if (file.type === 'video' || file.name.toLowerCase().match(/\.(mp4|avi|mov|mkv|wmv|flv|webm|m4v|3gp)$/)) {
                iconClass = 'fas fa-film';
            } else if (file.type === 'audio' || file.name.toLowerCase().match(/\.(mp3|wav|flac|aac|ogg|wma|m4a)$/)) {
                iconClass = 'fas fa-music';
            }
            
            const extension = file.name.split('.').pop().toUpperCase();
            
            item.innerHTML = `
                <div class="playlist-item-icon">
                    <i class="${iconClass}"></i>
                </div>
                <div class="playlist-item-info">
                    <div class="playlist-item-name" title="${file.name}">${file.name}</div>
                    <div class="playlist-item-meta">
                        <span>${extension}</span>
                        <span>•</span>
                        <span>${this.formatFileSize(file.size)}</span>
                    </div>
                </div>
                <div class="playlist-item-duration">--:--</div>
                <button class="playlist-play-btn" title="Play">
                    <i class="fas fa-play"></i>
                </button>
            `;
            
            item.addEventListener('click', () => {
                this.playMediaFile(file, index);
            });
            
            const playBtn = item.querySelector('.playlist-play-btn');
            playBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.playMediaFile(file, index);
            });
            
            playlist.appendChild(item);
        });
    }
    
    playMediaFile(file, index) {
        console.log('🎵 Playing media file:', file.name);
        
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const audioWrapper = document.getElementById('audioPlayerWrapper');
        const placeholder = document.getElementById('playerPlaceholder');
        const controlsOverlay = document.getElementById('videoControlsOverlay');
        const audioControlsContainer = document.getElementById('audioControlsContainer');
        const audioProgressContainer = document.getElementById('audioProgressContainer');
        
        // Hide all players first
        if (videoPlayer) videoPlayer.style.display = 'none';
        if (audioWrapper) audioWrapper.style.display = 'none';
        if (placeholder) placeholder.style.display = 'none';
        if (controlsOverlay) controlsOverlay.style.display = 'none';
        if (audioControlsContainer) audioControlsContainer.style.display = 'none';
        if (audioProgressContainer) audioProgressContainer.style.display = 'none';
        
        // Update playlist visual state
        document.querySelectorAll('.modern-playlist-item').forEach(item => {
            item.classList.remove('playing');
        });
        
        const currentItem = document.querySelector(`[data-path="${file.path}"]`);
        if (currentItem) {
            currentItem.classList.add('playing');
        }
        
        const streamUrl = `/stream/${encodeURIComponent(file.path)}`;
        
        // Check if it's a video file
        if (file.type === 'video' || file.name.toLowerCase().match(/\.(mp4|avi|mov|mkv|wmv|flv|webm|m4v|3gp)$/)) {
            if (videoPlayer && controlsOverlay) {
                // Remove native controls and show custom overlay
                videoPlayer.controls = false;
                videoPlayer.src = streamUrl;
                videoPlayer.style.display = 'block';
                controlsOverlay.style.display = 'flex';
                
                // Show controls initially (YouTube-style)
                controlsOverlay.classList.add('show');
                
                // Update video info in overlay
                const videoTitle = document.getElementById('videoTitle');
                const videoInfo = document.getElementById('videoInfo');
                if (videoTitle) videoTitle.textContent = file.name;
                if (videoInfo) videoInfo.textContent = `${this.formatFileSize(file.size)} • ${file.name.split('.').pop().toUpperCase()}`;
                
                // Auto-play the video
                videoPlayer.play().catch(e => console.log('Video play failed:', e));
            }
        } 
        // Check if it's an audio file
        else if (file.type === 'audio' || file.name.toLowerCase().match(/\.(mp3|wav|flac|aac|ogg|wma|m4a)$/)) {
            if (audioWrapper && audioPlayer && audioControlsContainer && audioProgressContainer) {
                // Remove native controls
                audioPlayer.controls = false;
                audioPlayer.src = streamUrl;
                audioWrapper.style.display = 'flex';
                audioControlsContainer.style.display = 'flex';
                audioProgressContainer.style.display = 'block';
                
                // Update audio info
                const audioTitle = document.getElementById('audioTitle');
                const audioArtist = document.getElementById('audioArtist');
                const currentTrackTitle = document.getElementById('currentTrackTitle');
                const currentTrackDetails = document.getElementById('currentTrackDetails');
                
                const trackName = file.name.replace(/\.[^/.]+$/, ""); // Remove extension
                if (audioTitle) audioTitle.textContent = trackName;
                if (audioArtist) audioArtist.textContent = 'Unknown Artist';
                if (currentTrackTitle) currentTrackTitle.textContent = file.name;
                if (currentTrackDetails) currentTrackDetails.textContent = `${this.formatFileSize(file.size)} • ${file.name.split('.').pop().toUpperCase()}`;
                
                audioPlayer.play().catch(e => console.log('Audio play failed:', e));
            }
        }
        
        // Store current playing info
        this.currentMediaFile = file;
        this.currentMediaIndex = index;
    }
    
    updatePlayPauseButton(isPlaying) {
        const playPauseBtn = document.getElementById('playPauseBtn');
        if (playPauseBtn) {
            const icon = playPauseBtn.querySelector('i');
            if (icon) {
                icon.className = isPlaying ? 'fas fa-pause' : 'fas fa-play';
            }
        }
    }
    
    renderImageGallery(imageFiles) {
        const gallery = document.getElementById('imageGallery');
        gallery.innerHTML = '';
        
        imageFiles.forEach(file => {
            const item = document.createElement('div');
            item.className = 'gallery-item';
            item.innerHTML = `
                <img src="/stream/${encodeURIComponent(file.path)}" alt="${file.name}" loading="lazy">
                <div class="gallery-info">
                    <div class="gallery-name">${file.name}</div>
                    <div class="gallery-size">${this.formatFileSize(file.size)}</div>
                </div>
            `;
            
            item.addEventListener('click', () => {
                this.viewImage(file);
            });
            
            gallery.appendChild(item);
        });
    }
    
    async loadStoragePath() {
        try {
            const response = await fetch('/api/info');
            const data = await response.json();
            
            if (data.success && data.server && data.server.storagePath) {
                const storageDisplay = document.getElementById('storagePathDisplay');
                if (storageDisplay) {
                    // Show just the last part of the path for cleaner display
                    const pathParts = data.server.storagePath.split(/[/\\]/);
                    const displayPath = pathParts.slice(-2).join('/'); // Show last 2 parts
                    storageDisplay.textContent = displayPath;
                    storageDisplay.title = data.server.storagePath; // Full path on hover
                }
            }
        } catch (error) {
            console.warn('Could not load storage path info:', error);
            const storageDisplay = document.getElementById('storagePathDisplay');
            if (storageDisplay) {
                storageDisplay.textContent = 'Storage Path';
            }
        }
    }
}

// Global functions for media player controls
function closeMediaPlayer() {
    if (window.app) {
        window.app.closeMediaPlayer();
    }
}

function toggleFullscreen() {
    const videoPlayer = document.getElementById('videoPlayer');
    if (videoPlayer && videoPlayer.requestFullscreen) {
        if (!document.fullscreenElement) {
            videoPlayer.requestFullscreen();
        } else {
            document.exitFullscreen();
        }
    }
}

function downloadCurrentMedia() {
    if (window.app && window.app.currentMediaFile) {
        const file = window.app.currentMediaFile;
        window.open(`/download/${encodeURIComponent(file.path)}`, '_blank');
    }
}

function togglePlayPause() {
    if (window.app) {
        window.app.togglePlayPause();
    }
}

function previousTrack() {
    if (window.app) {
        window.app.playPreviousTrack();
    }
}

function nextTrack() {
    if (window.app) {
        window.app.playNextTrack();
    }
}

function toggleShuffle() {
    // TODO: Implement shuffle functionality
    console.log('Shuffle toggle - not yet implemented');
}

function toggleRepeat() {
    // TODO: Implement repeat functionality  
    console.log('Repeat toggle - not yet implemented');
}

function togglePlaylist() {
    const playlist = document.querySelector('.media-playlist');
    if (playlist) {
        const isVisible = playlist.style.display !== 'none';
        playlist.style.display = isVisible ? 'none' : 'block';
        
        const toggleBtn = document.querySelector('.playlist-toggle');
        if (toggleBtn) {
            toggleBtn.textContent = isVisible ? '▲' : '▼';
        }
    }
}

// Initialize app when DOM is loaded
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new UDriveApp();
    // Make app globally accessible for media player functions
    window.app = app;
});
