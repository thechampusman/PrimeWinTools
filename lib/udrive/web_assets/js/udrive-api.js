// UDrive API Helper - Handles all server communication

class UDriveAPI {
    constructor(baseUrl = '') {
        this.baseUrl = baseUrl;
        this.timeout = 30000; // 30 second timeout
    }
    
    // Generic fetch wrapper with error handling
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const defaultOptions = {
            timeout: this.timeout,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };
        
        // Merge options
        const requestOptions = { ...defaultOptions, ...options };
        
        // Remove Content-Type for FormData
        if (options.body instanceof FormData) {
            delete requestOptions.headers['Content-Type'];
        }
        
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), requestOptions.timeout);
            
            const response = await fetch(url, {
                ...requestOptions,
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            
            if (!response.ok) {
                const errorData = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorData || response.statusText}`);
            }
            
            // Handle different response types
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            } else {
                return await response.text();
            }
            
        } catch (error) {
            if (error.name === 'AbortError') {
                throw new Error('Request timeout');
            }
            throw error;
        }
    }
    
    // File and folder operations
    async listFiles(path = '/') {
        return await this.request(`/api/files?path=${encodeURIComponent(path)}`);
    }
    
    async getFileInfo(path) {
        return await this.request(`/api/info?path=${encodeURIComponent(path)}`);
    }
    
    async downloadFile(path) {
        // Return the download URL instead of fetching the file
        return `${this.baseUrl}/api/download?path=${encodeURIComponent(path)}`;
    }
    
    async uploadFiles(files, targetPath = '/') {
        const formData = new FormData();
        
        // Add each file to form data
        files.forEach((file, index) => {
            formData.append('files', file);
        });
        
        formData.append('path', targetPath);
        
        return await this.request('/api/upload', {
            method: 'POST',
            body: formData
        });
    }
    
    async uploadSingleFile(file, targetPath = '/') {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('path', targetPath);
        
        return await this.request('/api/upload', {
            method: 'POST',
            body: formData
        });
    }
    
    async createFolder(path, name) {
        return await this.request('/api/folder', {
            method: 'POST',
            body: JSON.stringify({ path, name })
        });
    }
    
    async deleteFiles(paths) {
        return await this.request('/api/delete', {
            method: 'DELETE',
            body: JSON.stringify({ paths })
        });
    }
    
    async renameFile(oldPath, newName) {
        return await this.request('/api/rename', {
            method: 'POST',
            body: JSON.stringify({ oldPath, newName })
        });
    }
    
    async moveFiles(paths, targetPath) {
        return await this.request('/api/move', {
            method: 'POST',
            body: JSON.stringify({ paths, targetPath })
        });
    }
    
    async copyFiles(paths, targetPath) {
        return await this.request('/api/copy', {
            method: 'POST',
            body: JSON.stringify({ paths, targetPath })
        });
    }
    
    // Search functionality
    async searchFiles(query, path = '/') {
        return await this.request(`/api/search?q=${encodeURIComponent(query)}&path=${encodeURIComponent(path)}`);
    }
    
    // Storage information
    async getStorageInfo() {
        return await this.request('/api/info');
    }
    
    // File preview and thumbnails
    getFileViewUrl(path) {
        return `${this.baseUrl}/download/${encodeURIComponent(path)}`;
    }
    
    getThumbnailUrl(path, size = 200) {
        return `${this.baseUrl}/download/${encodeURIComponent(path)}`;
    }
    
    getFileStreamUrl(path) {
        return `${this.baseUrl}/stream/${encodeURIComponent(path)}`;
    }
    
    // Sharing functionality (if implemented)
    async createShareLink(path, options = {}) {
        return await this.request('/api/share/create', {
            method: 'POST',
            body: JSON.stringify({ path, ...options })
        });
    }
    
    async getSharedFiles() {
        return await this.request('/api/share/list');
    }
    
    async deleteShareLink(shareId) {
        return await this.request(`/api/share/${shareId}`, {
            method: 'DELETE'
        });
    }
    
    // System information
    async getSystemInfo() {
        return await this.request('/api/system/info');
    }
    
    async getServerStatus() {
        return await this.request('/api/status');
    }
    
    // Batch operations
    async batchOperation(operation, paths, options = {}) {
        return await this.request('/api/batch', {
            method: 'POST',
            body: JSON.stringify({
                operation,
                paths,
                ...options
            })
        });
    }
    
    // File operations with progress tracking
    async uploadWithProgress(files, targetPath, onProgress) {
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            const formData = new FormData();
            
            files.forEach(file => {
                formData.append('files', file);
            });
            formData.append('path', targetPath);
            
            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable && onProgress) {
                    const percentComplete = (e.loaded / e.total) * 100;
                    onProgress(percentComplete, e.loaded, e.total);
                }
            });
            
            xhr.addEventListener('load', () => {
                if (xhr.status >= 200 && xhr.status < 300) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        resolve(response);
                    } catch (error) {
                        resolve(xhr.responseText);
                    }
                } else {
                    reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`));
                }
            });
            
            xhr.addEventListener('error', () => {
                reject(new Error('Upload failed'));
            });
            
            xhr.addEventListener('timeout', () => {
                reject(new Error('Upload timeout'));
            });
            
            xhr.timeout = this.timeout;
            xhr.open('POST', `${this.baseUrl}/api/upload`);
            xhr.send(formData);
        });
    }
    
    // WebSocket for real-time updates (if implemented)
    createWebSocket(path = '/') {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/api/ws?path=${encodeURIComponent(path)}`;
        
        return new WebSocket(wsUrl);
    }
    
    // Utility methods
    isImage(filename) {
        const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico'];
        const ext = this.getFileExtension(filename);
        return imageExts.includes(ext);
    }
    
    isVideo(filename) {
        const videoExts = ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', 'm4v'];
        const ext = this.getFileExtension(filename);
        return videoExts.includes(ext);
    }
    
    isAudio(filename) {
        const audioExts = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'];
        const ext = this.getFileExtension(filename);
        return audioExts.includes(ext);
    }
    
    isDocument(filename) {
        const docExts = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'];
        const ext = this.getFileExtension(filename);
        return docExts.includes(ext);
    }
    
    isArchive(filename) {
        const archiveExts = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'];
        const ext = this.getFileExtension(filename);
        return archiveExts.includes(ext);
    }
    
    getFileExtension(filename) {
        return filename.split('.').pop()?.toLowerCase() || '';
    }
    
    getMimeType(filename) {
        const ext = this.getFileExtension(filename);
        const mimeMap = {
            // Images
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp',
            'svg': 'image/svg+xml',
            'bmp': 'image/bmp',
            'ico': 'image/x-icon',
            
            // Videos
            'mp4': 'video/mp4',
            'avi': 'video/x-msvideo',
            'mkv': 'video/x-matroska',
            'mov': 'video/quicktime',
            'wmv': 'video/x-ms-wmv',
            'flv': 'video/x-flv',
            'webm': 'video/webm',
            'm4v': 'video/x-m4v',
            
            // Audio
            'mp3': 'audio/mpeg',
            'wav': 'audio/wav',
            'flac': 'audio/flac',
            'aac': 'audio/aac',
            'ogg': 'audio/ogg',
            'm4a': 'audio/x-m4a',
            'wma': 'audio/x-ms-wma',
            
            // Documents
            'pdf': 'application/pdf',
            'doc': 'application/msword',
            'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'txt': 'text/plain',
            'rtf': 'application/rtf',
            'odt': 'application/vnd.oasis.opendocument.text',
            
            // Archives
            'zip': 'application/zip',
            'rar': 'application/x-rar-compressed',
            '7z': 'application/x-7z-compressed',
            'tar': 'application/x-tar',
            'gz': 'application/gzip',
            'bz2': 'application/x-bzip2',
            
            // Code
            'js': 'application/javascript',
            'json': 'application/json',
            'html': 'text/html',
            'css': 'text/css',
            'py': 'text/x-python',
            'java': 'text/x-java-source',
            'cpp': 'text/x-c++src',
            'c': 'text/x-csrc',
            'xml': 'application/xml'
        };
        
        return mimeMap[ext] || 'application/octet-stream';
    }
    
    // Format file size
    formatFileSize(bytes) {
        if (!bytes || bytes === 0) return '0 bytes';
        
        const k = 1024;
        const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }
    
    // Format date
    formatDate(date, options = {}) {
        const d = new Date(date);
        const now = new Date();
        const diff = now - d;
        
        // Default to relative formatting
        if (options.relative !== false) {
            // Less than 1 minute
            if (diff < 60000) {
                return 'Just now';
            }
            
            // Less than 1 hour
            if (diff < 3600000) {
                const minutes = Math.floor(diff / 60000);
                return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`;
            }
            
            // Less than 24 hours
            if (diff < 86400000) {
                const hours = Math.floor(diff / 3600000);
                return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
            }
            
            // Less than 7 days
            if (diff < 604800000) {
                const days = Math.floor(diff / 86400000);
                return `${days} day${days !== 1 ? 's' : ''} ago`;
            }
        }
        
        // Same year
        if (d.getFullYear() === now.getFullYear()) {
            return d.toLocaleDateString('en-US', { 
                month: 'short', 
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit'
            });
        }
        
        // Different year
        return d.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }
    
    // Validate file name
    validateFileName(name) {
        const invalidChars = /[<>:"/\\|?*\x00-\x1f]/g;
        const reservedNames = /^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i;
        
        if (!name || name.trim() === '') {
            return { valid: false, error: 'File name cannot be empty' };
        }
        
        if (name.length > 255) {
            return { valid: false, error: 'File name is too long (max 255 characters)' };
        }
        
        if (invalidChars.test(name)) {
            return { valid: false, error: 'File name contains invalid characters' };
        }
        
        if (reservedNames.test(name)) {
            return { valid: false, error: 'File name is reserved by the system' };
        }
        
        if (name.startsWith('.') || name.endsWith('.')) {
            return { valid: false, error: 'File name cannot start or end with a dot' };
        }
        
        return { valid: true };
    }
    
    // Generate safe file name
    sanitizeFileName(name) {
        return name
            .replace(/[<>:"/\\|?*\x00-\x1f]/g, '_')
            .replace(/^\.+|\.+$/g, '')
            .substring(0, 255);
    }
    
    // Path utilities
    joinPath(...parts) {
        return parts
            .map(part => part.toString().replace(/^\/+|\/+$/g, ''))
            .filter(part => part.length > 0)
            .join('/');
    }
    
    getParentPath(path) {
        if (path === '/' || !path) return '/';
        const parts = path.split('/').filter(p => p);
        if (parts.length <= 1) return '/';
        return '/' + parts.slice(0, -1).join('/');
    }
    
    getBaseName(path) {
        if (path === '/') return '';
        return path.split('/').pop() || '';
    }
    
    // Error handling utilities
    handleApiError(error) {
        console.error('API Error:', error);
        
        if (error.message.includes('timeout')) {
            return 'Request timed out. Please try again.';
        }
        
        if (error.message.includes('404')) {
            return 'File or folder not found.';
        }
        
        if (error.message.includes('403')) {
            return 'Access denied. You don\'t have permission to perform this action.';
        }
        
        if (error.message.includes('413')) {
            return 'File is too large to upload.';
        }
        
        if (error.message.includes('507')) {
            return 'Not enough storage space available.';
        }
        
        if (error.message.includes('Network')) {
            return 'Network error. Please check your connection.';
        }
        
        return error.message || 'An unexpected error occurred.';
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UDriveAPI;
} else {
    window.UDriveAPI = UDriveAPI;
}

// ES6 export for module imports
export { UDriveAPI };