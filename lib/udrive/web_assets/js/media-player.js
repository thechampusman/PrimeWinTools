// Media Player functionality for UDrive
class UDriveMediaPlayer {
    constructor() {
        this.currentPlaylist = [];
        this.currentIndex = 0;
        this.isPlaying = false;
        this.isShuffle = false;
        this.isRepeat = false;
        this.volume = 0.8;
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.setupPlayers();
    }
    
    bindEvents() {
        // Media controls
        document.getElementById('playPauseBtn').addEventListener('click', () => {
            this.togglePlayPause();
        });
        
        document.getElementById('nextBtn').addEventListener('click', () => {
            this.playNext();
        });
        
        document.getElementById('prevBtn').addEventListener('click', () => {
            this.playPrevious();
        });
        
        const shuffleBtn = document.getElementById('shuffleBtn');
        if (shuffleBtn) {
            shuffleBtn.addEventListener('click', () => {
                this.toggleShuffle();
            });
        }
        
        const repeatBtn = document.getElementById('repeatBtn');
        if (repeatBtn) {
            repeatBtn.addEventListener('click', () => {
                this.toggleRepeat();
            });
        }
        
        // Volume control
        const volumeSlider = document.getElementById('volumeSlider');
        if (volumeSlider) {
            volumeSlider.addEventListener('input', (e) => {
                this.setVolume(e.target.value / 100);
            });
        }
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.target.tagName.toLowerCase() === 'input') return;
            
            switch (e.code) {
                case 'Space':
                    e.preventDefault();
                    this.togglePlayPause();
                    break;
                case 'ArrowRight':
                    e.preventDefault();
                    this.seek(10);
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    this.seek(-10);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    this.changeVolume(0.1);
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    this.changeVolume(-0.1);
                    break;
            }
        });
    }
    
    setupPlayers() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        // Video player events
        videoPlayer.addEventListener('ended', () => {
            this.onMediaEnded();
        });
        
        videoPlayer.addEventListener('play', () => {
            this.updatePlayButton(true);
        });
        
        videoPlayer.addEventListener('pause', () => {
            this.updatePlayButton(false);
        });
        
        videoPlayer.addEventListener('error', (e) => {
            this.handleMediaError(e);
        });
        
        // Audio player events
        audioPlayer.addEventListener('ended', () => {
            this.onMediaEnded();
        });
        
        audioPlayer.addEventListener('play', () => {
            this.updatePlayButton(true);
        });
        
        audioPlayer.addEventListener('pause', () => {
            this.updatePlayButton(false);
        });
        
        audioPlayer.addEventListener('error', (e) => {
            this.handleMediaError(e);
        });
        
        // Set initial volume
        this.setVolume(this.volume);
    }
    
    playMedia(file, playlist = null) {
        if (playlist) {
            this.currentPlaylist = playlist;
            this.currentIndex = playlist.findIndex(f => f.path === file.path);
        } else {
            this.currentPlaylist = [file];
            this.currentIndex = 0;
        }
        
        this.loadAndPlayCurrent();
    }
    
    loadAndPlayCurrent() {
        if (this.currentIndex < 0 || this.currentIndex >= this.currentPlaylist.length) {
            return;
        }
        
        const file = this.currentPlaylist[this.currentIndex];
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const imageViewer = document.getElementById('imageViewer');
        const currentImage = document.getElementById('currentImage');
        
        // Hide all players
        videoPlayer.style.display = 'none';
        audioPlayer.style.display = 'none';
        imageViewer.style.display = 'none';
        
        // Stop current playback
        this.pauseAll();
        
        const streamUrl = `/stream/${encodeURIComponent(file.path)}`;
        
        switch (file.type) {
            case 'video':
                videoPlayer.src = streamUrl;
                videoPlayer.style.display = 'block';
                videoPlayer.load();
                this.playVideo();
                break;
                
            case 'audio':
                audioPlayer.src = streamUrl;
                audioPlayer.style.display = 'block';
                audioPlayer.load();
                this.playAudio();
                break;
                
            case 'image':
                currentImage.src = streamUrl;
                imageViewer.style.display = 'block';
                this.updatePlayButton(false);
                // Auto-advance for images after 5 seconds if in playlist mode
                if (this.currentPlaylist.length > 1) {
                    setTimeout(() => {
                        if (this.getCurrentPlayer() === currentImage) {
                            this.playNext();
                        }
                    }, 5000);
                }
                break;
        }
        
        this.updateNowPlaying(file);
        this.updatePlaylistHighlight();
    }
    
    playVideo() {
        const videoPlayer = document.getElementById('videoPlayer');
        videoPlayer.play().catch(e => {
            console.error('Video play failed:', e);
            app.showToast('Failed to play video', 'error');
        });
    }
    
    playAudio() {
        const audioPlayer = document.getElementById('audioPlayer');
        audioPlayer.play().catch(e => {
            console.error('Audio play failed:', e);
            app.showToast('Failed to play audio', 'error');
        });
    }
    
    togglePlayPause() {
        const currentPlayer = this.getCurrentPlayer();
        
        if (!currentPlayer || currentPlayer.tagName === 'IMG') {
            return;
        }
        
        if (currentPlayer.paused) {
            currentPlayer.play();
        } else {
            currentPlayer.pause();
        }
    }
    
    playNext() {
        if (this.currentPlaylist.length <= 1) return;
        
        if (this.isShuffle) {
            this.currentIndex = Math.floor(Math.random() * this.currentPlaylist.length);
        } else {
            this.currentIndex = (this.currentIndex + 1) % this.currentPlaylist.length;
        }
        
        this.loadAndPlayCurrent();
    }
    
    playPrevious() {
        if (this.currentPlaylist.length <= 1) return;
        
        if (this.isShuffle) {
            this.currentIndex = Math.floor(Math.random() * this.currentPlaylist.length);
        } else {
            this.currentIndex = this.currentIndex <= 0 
                ? this.currentPlaylist.length - 1 
                : this.currentIndex - 1;
        }
        
        this.loadAndPlayCurrent();
    }
    
    onMediaEnded() {
        if (this.isRepeat) {
            this.loadAndPlayCurrent();
        } else if (this.currentPlaylist.length > 1) {
            this.playNext();
        } else {
            this.updatePlayButton(false);
        }
    }
    
    toggleShuffle() {
        this.isShuffle = !this.isShuffle;
        const shuffleBtn = document.getElementById('shuffleBtn');
        shuffleBtn.classList.toggle('active', this.isShuffle);
        shuffleBtn.style.color = this.isShuffle ? '#667eea' : '';
        
        app.showToast(`Shuffle ${this.isShuffle ? 'enabled' : 'disabled'}`, 'info');
    }
    
    toggleRepeat() {
        this.isRepeat = !this.isRepeat;
        const repeatBtn = document.getElementById('repeatBtn');
        repeatBtn.classList.toggle('active', this.isRepeat);
        repeatBtn.style.color = this.isRepeat ? '#667eea' : '';
        
        app.showToast(`Repeat ${this.isRepeat ? 'enabled' : 'disabled'}`, 'info');
    }
    
    setVolume(volume) {
        this.volume = Math.max(0, Math.min(1, volume));
        
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const volumeSlider = document.getElementById('volumeSlider');
        
        if (videoPlayer) videoPlayer.volume = this.volume;
        if (audioPlayer) audioPlayer.volume = this.volume;
        if (volumeSlider) volumeSlider.value = this.volume * 100;
        
        // Update volume icon
        const volumeIcon = document.querySelector('.volume-control i');
        if (this.volume === 0) {
            volumeIcon.className = 'fas fa-volume-mute';
        } else if (this.volume < 0.5) {
            volumeIcon.className = 'fas fa-volume-down';
        } else {
            volumeIcon.className = 'fas fa-volume-up';
        }
    }
    
    changeVolume(delta) {
        this.setVolume(this.volume + delta);
    }
    
    seek(seconds) {
        const currentPlayer = this.getCurrentPlayer();
        
        if (currentPlayer && !currentPlayer.tagName === 'IMG') {
            currentPlayer.currentTime += seconds;
        }
    }
    
    getCurrentPlayer() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        const imageViewer = document.getElementById('currentImage');
        
        if (videoPlayer.style.display !== 'none' && videoPlayer.src) {
            return videoPlayer;
        } else if (audioPlayer.style.display !== 'none' && audioPlayer.src) {
            return audioPlayer;
        } else if (imageViewer.style.display !== 'none' && imageViewer.src) {
            return imageViewer;
        }
        
        return null;
    }
    
    pauseAll() {
        const videoPlayer = document.getElementById('videoPlayer');
        const audioPlayer = document.getElementById('audioPlayer');
        
        if (!videoPlayer.paused) videoPlayer.pause();
        if (!audioPlayer.paused) audioPlayer.pause();
    }
    
    updatePlayButton(isPlaying) {
        const playPauseBtn = document.getElementById('playPauseBtn');
        const icon = playPauseBtn.querySelector('i');
        
        if (isPlaying) {
            icon.className = 'fas fa-pause';
        } else {
            icon.className = 'fas fa-play';
        }
        
        this.isPlaying = isPlaying;
    }
    
    updateNowPlaying(file) {
        // Update document title
        document.title = `UDrive - ${file.name}`;
        
        // Could add a "Now Playing" display here
        console.log('Now playing:', file.name);
    }
    
    updatePlaylistHighlight() {
        // Remove existing highlights
        document.querySelectorAll('.playlist-item').forEach(item => {
            item.classList.remove('playing');
        });
        
        // Highlight current item
        const playlistItems = document.querySelectorAll('.playlist-item');
        if (playlistItems[this.currentIndex]) {
            playlistItems[this.currentIndex].classList.add('playing');
        }
    }
    
    handleMediaError(error) {
        console.error('Media error:', error);
        app.showToast('Media playback error. File may be corrupted or unsupported.', 'error');
        
        // Try to play next item
        if (this.currentPlaylist.length > 1) {
            setTimeout(() => {
                this.playNext();
            }, 1000);
        }
    }
    
    // Create playlist from current media files
    createPlaylistFromMediaFiles(mediaFiles) {
        this.currentPlaylist = mediaFiles.filter(file => 
            ['video', 'audio', 'image'].includes(file.type)
        );
        this.currentIndex = 0;
        
        this.renderPlaylist();
    }
    
    renderPlaylist() {
        const playlist = document.getElementById('playlist');
        playlist.innerHTML = '';
        
        this.currentPlaylist.forEach((file, index) => {
            const item = document.createElement('div');
            item.className = 'playlist-item';
            if (index === this.currentIndex) {
                item.classList.add('playing');
            }
            
            item.innerHTML = `
                <div class="playlist-icon">${this.getFileIcon(file)}</div>
                <div class="playlist-info">
                    <div class="playlist-name">${file.name}</div>
                    <div class="playlist-meta">${this.formatFileSize(file.size)} • ${file.type}</div>
                </div>
                <button class="playlist-play" onclick="mediaPlayer.playFromPlaylist(${index})">
                    <i class="fas fa-play"></i>
                </button>
            `;
            
            playlist.appendChild(item);
        });
    }
    
    playFromPlaylist(index) {
        this.currentIndex = index;
        this.loadAndPlayCurrent();
    }
    
    getFileIcon(file) {
        switch (file.type) {
            case 'video': return '<i class="fas fa-film"></i>';
            case 'audio': return '<i class="fas fa-music"></i>';
            case 'image': return '<i class="fas fa-image"></i>';
            default: return '<i class="fas fa-file"></i>';
        }
    }
    
    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
    }
    
    // Picture-in-Picture support
    async togglePictureInPicture() {
        const videoPlayer = document.getElementById('videoPlayer');
        
        if (videoPlayer.style.display === 'none') {
            app.showToast('No video playing', 'warning');
            return;
        }
        
        try {
            if (document.pictureInPictureElement) {
                await document.exitPictureInPicture();
            } else {
                await videoPlayer.requestPictureInPicture();
            }
        } catch (error) {
            console.error('Picture-in-Picture error:', error);
            app.showToast('Picture-in-Picture not supported', 'warning');
        }
    }
    
    // Fullscreen support
    async toggleFullscreen() {
        const container = document.querySelector('.media-player-container');
        
        try {
            if (document.fullscreenElement) {
                await document.exitFullscreen();
            } else {
                await container.requestFullscreen();
            }
        } catch (error) {
            console.error('Fullscreen error:', error);
            app.showToast('Fullscreen not supported', 'warning');
        }
    }
}

// Initialize media player
let mediaPlayer;
document.addEventListener('DOMContentLoaded', () => {
    mediaPlayer = new UDriveMediaPlayer();
});

// Expose globally
window.mediaPlayer = mediaPlayer;
