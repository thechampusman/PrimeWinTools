// UDrive Personal Cloud Server - Main Application
import { UDriveAPI } from './udrive-api.js';
import { UDriveUI } from './udrive-ui.js';

class UDriveApp {
    constructor() {
        this.api = new UDriveAPI();
        this.ui = new UDriveUI();
        this.currentPath = '/';
        this.currentView = 'files';
        this.files = [];
        this.mediaFiles = [];
        this.currentMedia = null;
        this.mediaIndex = 0;
        this.serverStats = {
            totalFiles: 0,
            storageUsed: 0,
            uptime: 0,
            activeUsers: 1
        };
        
        this.init();
    }

    async init() {
        console.log('🚀 Initializing UDrive Personal Cloud Server...');
        
        try {
            // Setup event listeners
            this.setupEventListeners();
            
            // Load initial data
            await this.loadServerInfo();
            await this.loadFiles();
            await this.detectNetworkInfo();
            
            // Start periodic updates
            this.startPeriodicUpdates();
            
            // Hide loading screen and show app
            this.hideLoading();
            
            console.log('✅ UDrive initialized successfully');
        } catch (error) {
            console.error('❌ Failed to initialize UDrive:', error);
            this.ui.showError('Failed to initialize UDrive server');
        }
    }

    setupEventListeners() {
        // Search
        const searchInput = document.getElementById('searchInput');
        searchInput?.addEventListener('input', (e) => this.handleSearch(e.target.value));

        // Navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => this.handleNavigation(e.currentTarget));
        });

        // Upload
        const uploadBtn = document.getElementById('uploadBtn');
        uploadBtn?.addEventListener('click', () => this.showUploadModal());

        // Settings
        const settingsBtn = document.getElementById('settingsBtn');
        settingsBtn?.addEventListener('click', () => this.showSettingsModal());

        // Media Player
        const streamBtn = document.getElementById('streamBtn');
        streamBtn?.addEventListener('click', () => this.toggleMediaPlayer());

        // View controls
        const gridViewBtn = document.getElementById('gridViewBtn');
        const listViewBtn = document.getElementById('listViewBtn');
        gridViewBtn?.addEventListener('click', () => this.setView('grid'));
        listViewBtn?.addEventListener('click', () => this.setView('list'));

        // Copy URL
        const copyUrlBtn = document.getElementById('copyUrlBtn');
        copyUrlBtn?.addEventListener('click', () => this.copyServerUrl());

        // File operations
        this.setupFileHandlers();
        this.setupUploadHandlers();
        this.setupMediaControls();
    }

    setupFileHandlers() {
        const fileList = document.getElementById('fileList');
        if (fileList) {
            fileList.addEventListener('click', (e) => {
                const fileItem = e.target.closest('.file-item');
                if (fileItem) {
                    const filePath = fileItem.dataset.path;
                    const fileType = fileItem.dataset.type;
                    this.handleFileClick(filePath, fileType);
                }
            });

            fileList.addEventListener('dblclick', (e) => {
                const fileItem = e.target.closest('.file-item');
                if (fileItem) {
                    const filePath = fileItem.dataset.path;
                    const fileType = fileItem.dataset.type;
                    this.handleFileDoubleClick(filePath, fileType);
                }
            });
        }
    }

    setupUploadHandlers() {
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');

        if (uploadArea && fileInput) {
            // Click to browse
            uploadArea.addEventListener('click', () => fileInput.click());

            // File selection
            fileInput.addEventListener('change', (e) => {
                if (e.target.files.length > 0) {
                    this.uploadFiles(Array.from(e.target.files));
                }
            });

            // Drag and drop
            uploadArea.addEventListener('dragover', (e) => {
                e.preventDefault();
                uploadArea.classList.add('drag-over');
            });

            uploadArea.addEventListener('dragleave', () => {
                uploadArea.classList.remove('drag-over');
            });

            uploadArea.addEventListener('drop', (e) => {
                e.preventDefault();
                uploadArea.classList.remove('drag-over');
                const files = Array.from(e.dataTransfer.files);
                if (files.length > 0) {
                    this.uploadFiles(files);
                }
            });
        }
    }

    setupMediaControls() {
        const playPauseBtn = document.getElementById('playPauseBtn');
        const prevBtn = document.getElementById('prevBtn');
        const nextBtn = document.getElementById('nextBtn');
        const fullscreenBtn = document.getElementById('fullscreenBtn');

        playPauseBtn?.addEventListener('click', () => this.togglePlayPause());
        prevBtn?.addEventListener('click', () => this.playPrevious());
        nextBtn?.addEventListener('click', () => this.playNext());
        fullscreenBtn?.addEventListener('click', () => this.toggleFullscreen());

        // Keyboard shortcuts for media
        document.addEventListener('keydown', (e) => {
            if (this.currentView === 'media' && this.currentMedia) {
                switch (e.key) {
                    case ' ':
                        e.preventDefault();
                        this.togglePlayPause();
                        break;
                    case 'ArrowLeft':
                        e.preventDefault();
                        this.seek(-10);
                        break;
                    case 'ArrowRight':
                        e.preventDefault();
                        this.seek(10);
                        break;
                    case 'ArrowUp':
                        e.preventDefault();
                        this.adjustVolume(0.1);
                        break;
                    case 'ArrowDown':
                        e.preventDefault();
                        this.adjustVolume(-0.1);
                        break;
                }
            }
        });
    }

    async loadServerInfo() {
        try {
            const info = await this.api.getServerInfo();
            this.updateServerStats(info);
            this.updateNetworkInfo(info);
        } catch (error) {
            console.error('Failed to load server info:', error);
        }
    }

    async loadFiles() {
        try {
            const files = await this.api.getFiles(this.currentPath);
            this.files = files;
            this.categorizeFiles();
            this.renderFiles();
            this.updateFileCounts();
        } catch (error) {
            console.error('Failed to load files:', error);
            this.ui.showError('Failed to load files');
        }
    }

    categorizeFiles() {
        this.mediaFiles = {
            videos: [],
            audio: [],
            images: []
        };

        this.files.forEach(file => {
            if (file.type === 'file') {
                const ext = file.name.split('.').pop()?.toLowerCase();
                if (['mp4', 'webm', 'ogg', 'avi', 'mov', 'mkv'].includes(ext)) {
                    this.mediaFiles.videos.push(file);
                } else if (['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].includes(ext)) {
                    this.mediaFiles.audio.push(file);
                } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext)) {
                    this.mediaFiles.images.push(file);
                }
            }
        });
    }

    renderFiles() {
        const fileList = document.getElementById('fileList');
        if (!fileList) return;

        let filesToShow = this.files;

        // Filter based on current view
        if (this.currentView === 'videos') {
            filesToShow = this.mediaFiles.videos;
        } else if (this.currentView === 'music') {
            filesToShow = this.mediaFiles.audio;
        } else if (this.currentView === 'photos') {
            filesToShow = this.mediaFiles.images;
        }

        fileList.innerHTML = '';

        if (filesToShow.length === 0) {
            fileList.innerHTML = `
                <div class="empty-state">
                    <span class="material-icons">folder_open</span>
                    <h3>No files found</h3>
                    <p>Upload some files to get started</p>
                </div>
            `;
            return;
        }

        filesToShow.forEach(file => {
            const fileElement = this.createFileElement(file);
            fileList.appendChild(fileElement);
        });
    }

    createFileElement(file) {
        const div = document.createElement('div');
        div.className = 'file-item';
        div.dataset.path = file.path;
        div.dataset.type = file.type;

        const icon = this.getFileIcon(file);
        const size = file.type === 'file' ? this.formatFileSize(file.size) : '';
        const modified = file.modified ? new Date(file.modified).toLocaleDateString() : '';

        div.innerHTML = `
            <div class="file-icon">
                <span class="material-icons">${icon}</span>
            </div>
            <div class="file-info">
                <div class="file-name">${file.name}</div>
                <div class="file-details">
                    ${size} ${size && modified ? '•' : ''} ${modified}
                </div>
            </div>
            <div class="file-actions">
                <button class="action-btn" title="More actions">
                    <span class="material-icons">more_vert</span>
                </button>
            </div>
        `;

        return div;
    }

    getFileIcon(file) {
        if (file.type === 'directory') return 'folder';
        
        const ext = file.name.split('.').pop()?.toLowerCase();
        const iconMap = {
            'mp4': 'movie', 'webm': 'movie', 'avi': 'movie', 'mov': 'movie', 'mkv': 'movie',
            'mp3': 'audiotrack', 'wav': 'audiotrack', 'flac': 'audiotrack', 'aac': 'audiotrack',
            'jpg': 'image', 'jpeg': 'image', 'png': 'image', 'gif': 'image', 'webp': 'image',
            'pdf': 'picture_as_pdf', 'doc': 'description', 'docx': 'description',
            'txt': 'text_snippet', 'zip': 'archive', 'rar': 'archive'
        };
        
        return iconMap[ext] || 'insert_drive_file';
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    handleNavigation(navItem) {
        // Remove active class from all nav items
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Add active class to clicked item
        navItem.classList.add('active');

        // Get the view type
        const view = navItem.dataset.view;
        if (view) {
            this.currentView = view;
            this.renderFiles();
            
            // Show/hide media player based on view
            if (['videos', 'music', 'photos'].includes(view)) {
                this.showMediaView();
            } else {
                this.hideMediaView();
            }
        }
    }

    handleFileClick(filePath, fileType) {
        if (fileType === 'directory') {
            this.navigateToDirectory(filePath);
        } else if (this.isMediaFile(filePath)) {
            this.playMedia(filePath);
        }
    }

    handleFileDoubleClick(filePath, fileType) {
        if (fileType === 'file') {
            if (this.isMediaFile(filePath)) {
                this.playMedia(filePath);
            } else {
                this.downloadFile(filePath);
            }
        }
    }

    isMediaFile(filePath) {
        const ext = filePath.split('.').pop()?.toLowerCase();
        return ['mp4', 'webm', 'ogg', 'avi', 'mov', 'mkv', 'mp3', 'wav', 'flac', 'aac', 'm4a', 'jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
    }

    async playMedia(filePath) {
        try {
            this.currentMedia = filePath;
            this.showMediaPlayer();
            
            const ext = filePath.split('.').pop()?.toLowerCase();
            const videoPlayer = document.getElementById('videoPlayer');
            const audioPlayer = document.getElementById('audioPlayer');
            const imageViewer = document.getElementById('imageViewer');
            const imageDisplay = document.getElementById('imageDisplay');
            const playerTitle = document.getElementById('playerTitle');

            // Hide all players
            videoPlayer?.classList.add('hidden');
            audioPlayer?.classList.add('hidden');
            imageViewer?.classList.add('hidden');

            // Set title
            const fileName = filePath.split('/').pop();
            if (playerTitle) playerTitle.textContent = fileName;

            // Show appropriate player
            if (['mp4', 'webm', 'ogg', 'avi', 'mov', 'mkv'].includes(ext)) {
                videoPlayer?.classList.remove('hidden');
                if (videoPlayer) {
                    videoPlayer.src = `/stream${filePath}`;
                    videoPlayer.load();
                }
            } else if (['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].includes(ext)) {
                audioPlayer?.classList.remove('hidden');
                if (audioPlayer) {
                    audioPlayer.src = `/stream${filePath}`;
                    audioPlayer.load();
                }
            } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext)) {
                imageViewer?.classList.remove('hidden');
                if (imageDisplay) {
                    imageDisplay.src = `/stream${filePath}`;
                }
            }

            // Find media index for navigation
            const allMedia = [...this.mediaFiles.videos, ...this.mediaFiles.audio, ...this.mediaFiles.images];
            this.mediaIndex = allMedia.findIndex(file => file.path === filePath);

        } catch (error) {
            console.error('Failed to play media:', error);
            this.ui.showError('Failed to play media file');
        }
    }

    showMediaPlayer() {
        const mediaPlayer = document.getElementById('mediaPlayer');
        const fileList = document.getElementById('fileList');
        
        mediaPlayer?.classList.remove('hidden');
        fileList?.classList.add('hidden');
    }

    hideMediaPlayer() {
        const mediaPlayer = document.getElementById('mediaPlayer');
        const fileList = document.getElementById('fileList');
        
        mediaPlayer?.classList.add('hidden');
        fileList?.classList.remove('hidden');
    }

    showMediaView() {
        // Implementation for media-focused view
        this.hideMediaPlayer();
    }

    hideMediaView() {
        // Implementation to hide media view
        this.hideMediaPlayer();
    }

    toggleMediaPlayer() {
        const mediaPlayer = document.getElementById('mediaPlayer');
        if (mediaPlayer?.classList.contains('hidden')) {
            if (this.currentMedia) {
                this.showMediaPlayer();
            } else {
                // Play first available media file
                const allMedia = [...this.mediaFiles.videos, ...this.mediaFiles.audio, ...this.mediaFiles.images];
                if (allMedia.length > 0) {
                    this.playMedia(allMedia[0].path);
                }
            }
        } else {
            this.hideMediaPlayer();
        }
    }

    togglePlayPause() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const playPauseBtn = document.getElementById('playPauseBtn');
        
        let player = null;
        if (!videoPlayer?.classList.contains('hidden')) {
            player = videoPlayer;
        } else if (!audioPlayer?.classList.contains('hidden')) {
            player = audioPlayer;
        }

        if (player) {
            if (player.paused) {
                player.play();
                if (playPauseBtn) {
                    playPauseBtn.innerHTML = '<span class="material-icons">pause</span>';
                }
            } else {
                player.pause();
                if (playPauseBtn) {
                    playPauseBtn.innerHTML = '<span class="material-icons">play_arrow</span>';
                }
            }
        }
    }

    playNext() {
        const allMedia = [...this.mediaFiles.videos, ...this.mediaFiles.audio, ...this.mediaFiles.images];
        if (allMedia.length > 0) {
            this.mediaIndex = (this.mediaIndex + 1) % allMedia.length;
            this.playMedia(allMedia[this.mediaIndex].path);
        }
    }

    playPrevious() {
        const allMedia = [...this.mediaFiles.videos, ...this.mediaFiles.audio, ...this.mediaFiles.images];
        if (allMedia.length > 0) {
            this.mediaIndex = (this.mediaIndex - 1 + allMedia.length) % allMedia.length;
            this.playMedia(allMedia[this.mediaIndex].path);
        }
    }

    seek(seconds) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        let player = null;
        if (!videoPlayer?.classList.contains('hidden')) {
            player = videoPlayer;
        } else if (!audioPlayer?.classList.contains('hidden')) {
            player = audioPlayer;
        }

        if (player) {
            player.currentTime = Math.max(0, Math.min(player.duration, player.currentTime + seconds));
        }
    }

    adjustVolume(delta) {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        let player = null;
        if (!videoPlayer?.classList.contains('hidden')) {
            player = videoPlayer;
        } else if (!audioPlayer?.classList.contains('hidden')) {
            player = audioPlayer;
        }

        if (player) {
            player.volume = Math.max(0, Math.min(1, player.volume + delta));
        }
    }

    toggleFullscreen() {
        const mediaPlayer = document.getElementById('mediaPlayer');
        if (mediaPlayer) {
            if (document.fullscreenElement) {
                document.exitFullscreen();
            } else {
                mediaPlayer.requestFullscreen();
            }
        }
    }

    async uploadFiles(files) {
        const uploadModal = document.getElementById('uploadModal');
        const uploadProgress = document.getElementById('uploadProgress');
        const progressFill = document.getElementById('progressFill');
        const progressText = document.getElementById('progressText');

        this.showUploadModal();
        uploadProgress?.classList.remove('hidden');

        try {
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const progress = ((i + 1) / files.length) * 100;
                
                if (progressFill) progressFill.style.width = `${progress}%`;
                if (progressText) progressText.textContent = `Uploading ${file.name}... (${i + 1}/${files.length})`;

                await this.api.uploadFile(file, this.currentPath);
            }

            // Refresh file list
            await this.loadFiles();
            this.hideUploadModal();
            this.ui.showSuccess(`Uploaded ${files.length} file(s) successfully`);

        } catch (error) {
            console.error('Upload failed:', error);
            this.ui.showError('Failed to upload files');
        }
    }

    async downloadFile(filePath) {
        try {
            const url = `/download${filePath}`;
            const link = document.createElement('a');
            link.href = url;
            link.download = filePath.split('/').pop();
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (error) {
            console.error('Download failed:', error);
            this.ui.showError('Failed to download file');
        }
    }

    updateServerStats(info) {
        const totalFilesEl = document.getElementById('totalFiles');
        const activeUsersEl = document.getElementById('activeUsers');
        const storageUsedEl = document.getElementById('storageUsed');
        const storagePathEl = document.getElementById('storagePath');
        const storageProgressEl = document.getElementById('storageProgress');

        if (info.totalFiles !== undefined && totalFilesEl) {
            totalFilesEl.textContent = info.totalFiles;
        }
        
        if (info.activeConnections !== undefined && activeUsersEl) {
            activeUsersEl.textContent = info.activeConnections;
        }
        
        if (info.storageUsed !== undefined && storageUsedEl) {
            storageUsedEl.textContent = this.formatFileSize(info.storageUsed);
        }
        
        if (info.storagePath && storagePathEl) {
            storagePathEl.textContent = info.storagePath;
        }

        // Update storage bar (assuming some total storage limit)
        if (info.storageUsed !== undefined && info.totalStorage && storageProgressEl) {
            const percentage = (info.storageUsed / info.totalStorage) * 100;
            storageProgressEl.style.width = `${Math.min(percentage, 100)}%`;
        }
    }

    updateNetworkInfo(info) {
        const networkUrlEl = document.getElementById('networkUrl');
        const shareUrlEl = document.getElementById('shareUrl');

        if (info.serverUrl) {
            if (networkUrlEl) networkUrlEl.textContent = info.serverUrl.replace('http://', '');
            if (shareUrlEl) shareUrlEl.textContent = info.serverUrl;
        }
    }

    updateFileCounts() {
        const allFilesCountEl = document.getElementById('allFilesCount');
        const videoCountEl = document.getElementById('videoCount');
        const audioCountEl = document.getElementById('audioCount');
        const imageCountEl = document.getElementById('imageCount');

        if (allFilesCountEl) allFilesCountEl.textContent = this.files.length;
        if (videoCountEl) videoCountEl.textContent = this.mediaFiles.videos.length;
        if (audioCountEl) audioCountEl.textContent = this.mediaFiles.audio.length;
        if (imageCountEl) imageCountEl.textContent = this.mediaFiles.images.length;
    }

    async detectNetworkInfo() {
        try {
            // Get local IP for network access
            const response = await fetch('/api/info');
            const info = await response.json();
            this.updateNetworkInfo(info);
        } catch (error) {
            console.warn('Could not detect network info:', error);
        }
    }

    copyServerUrl() {
        const shareUrl = document.getElementById('shareUrl')?.textContent;
        if (shareUrl) {
            navigator.clipboard.writeText(shareUrl).then(() => {
                this.ui.showSuccess('URL copied to clipboard!');
            }).catch(() => {
                this.ui.showError('Failed to copy URL');
            });
        }
    }

    handleSearch(query) {
        // Implement search functionality
        console.log('Searching for:', query);
    }

    showUploadModal() {
        const modal = document.getElementById('uploadModal');
        modal?.classList.remove('hidden');
    }

    hideUploadModal() {
        const modal = document.getElementById('uploadModal');
        const uploadProgress = document.getElementById('uploadProgress');
        modal?.classList.add('hidden');
        uploadProgress?.classList.add('hidden');
    }

    showSettingsModal() {
        const modal = document.getElementById('settingsModal');
        modal?.classList.remove('hidden');
    }

    hideSettingsModal() {
        const modal = document.getElementById('settingsModal');
        modal?.classList.add('hidden');
    }

    setView(viewType) {
        const gridBtn = document.getElementById('gridViewBtn');
        const listBtn = document.getElementById('listViewBtn');
        
        gridBtn?.classList.remove('active');
        listBtn?.classList.remove('active');
        
        if (viewType === 'grid') {
            gridBtn?.classList.add('active');
        } else {
            listBtn?.classList.add('active');
        }
    }

    startPeriodicUpdates() {
        // Update server uptime every second
        setInterval(() => {
            this.updateUptime();
        }, 1000);

        // Refresh server stats every 30 seconds
        setInterval(() => {
            this.loadServerInfo();
        }, 30000);

        // Refresh file list every 5 minutes
        setInterval(() => {
            this.loadFiles();
        }, 300000);
    }

    updateUptime() {
        const uptimeEl = document.getElementById('serverUptime');
        if (uptimeEl) {
            this.serverStats.uptime += 1;
            const hours = Math.floor(this.serverStats.uptime / 3600);
            const minutes = Math.floor((this.serverStats.uptime % 3600) / 60);
            const seconds = this.serverStats.uptime % 60;
            uptimeEl.textContent = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
    }

    hideLoading() {
        setTimeout(() => {
            this.ui.hideLoadingOverlay();
        }, 1000);
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new UDriveApp();
});

export { UDriveApp };