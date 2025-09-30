// Upload functionality for UDrive
class UDriveUploader {
    constructor() {
        this.maxFileSize = 100 * 1024 * 1024; // 100MB
        this.allowedTypes = [
            // Images
            'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
            // Videos
            'video/mp4', 'video/webm', 'video/ogg', 'video/avi', 'video/mov',
            // Audio
            'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac', 'audio/flac',
            // Documents
            'application/pdf', 'text/plain', 'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            // Archives
            'application/zip', 'application/x-rar-compressed', 'application/x-7z-compressed',
            // Others
            'application/json', 'text/html', 'text/css', 'text/javascript'
        ];
        
        this.init();
    }
    
    init() {
        this.bindEvents();
    }
    
    bindEvents() {
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        
        // Click to browse
        uploadArea.addEventListener('click', () => {
            fileInput.click();
        });
        
        // File input change
        fileInput.addEventListener('change', (e) => {
            this.handleFiles(e.target.files);
        });
        
        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.style.borderColor = '#667eea';
            uploadArea.style.background = 'rgba(102, 126, 234, 0.1)';
        });
        
        uploadArea.addEventListener('dragleave', (e) => {
            e.preventDefault();
            uploadArea.style.borderColor = 'rgba(102, 126, 234, 0.3)';
            uploadArea.style.background = 'transparent';
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.style.borderColor = 'rgba(102, 126, 234, 0.3)';
            uploadArea.style.background = 'transparent';
            
            const files = e.dataTransfer.files;
            this.handleFiles(files);
        });
    }
    
    handleFiles(files) {
        const validFiles = [];
        const errors = [];
        
        for (let file of files) {
            const validation = this.validateFile(file);
            if (validation.valid) {
                validFiles.push(file);
            } else {
                errors.push(`${file.name}: ${validation.error}`);
            }
        }
        
        if (errors.length > 0) {
            app.showToast('Some files were rejected:\n' + errors.join('\n'), 'error');
        }
        
        if (validFiles.length > 0) {
            this.uploadFiles(validFiles);
        }
    }
    
    validateFile(file) {
        // Check file size
        if (file.size > this.maxFileSize) {
            return {
                valid: false,
                error: `File too large (max ${this.formatFileSize(this.maxFileSize)})`
            };
        }
        
        // Check file type (more permissive for local usage)
        if (file.size === 0) {
            return {
                valid: false,
                error: 'Empty file'
            };
        }
        
        return { valid: true };
    }
    
    async uploadFiles(files) {
        const totalFiles = files.length;
        let uploadedFiles = 0;
        
        this.showProgress(0);
        
        for (let file of files) {
            try {
                await this.uploadSingleFile(file);
                uploadedFiles++;
                const progress = (uploadedFiles / totalFiles) * 100;
                this.updateProgress(progress, `Uploaded ${uploadedFiles} of ${totalFiles} files`);
            } catch (error) {
                app.showToast(`Failed to upload ${file.name}: ${error.message}`, 'error');
            }
        }
        
        if (uploadedFiles === totalFiles) {
            app.showToast(`Successfully uploaded ${uploadedFiles} files`, 'success');
            setTimeout(() => {
                app.hideModals();
                app.loadFiles(); // Refresh file list
            }, 1000);
        } else {
            app.showToast(`Uploaded ${uploadedFiles} of ${totalFiles} files`, 'warning');
        }
        
        this.hideProgress();
    }
    
    async uploadSingleFile(file) {
        return new Promise((resolve, reject) => {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('path', app.currentPath);
            
            const xhr = new XMLHttpRequest();
            
            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percentComplete = (e.loaded / e.total) * 100;
                    this.updateProgress(percentComplete, `Uploading ${file.name}...`);
                }
            });
            
            xhr.addEventListener('load', () => {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response.success) {
                            resolve(response);
                        } else {
                            reject(new Error(response.message || 'Upload failed'));
                        }
                    } catch (e) {
                        reject(new Error('Invalid server response'));
                    }
                } else {
                    reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`));
                }
            });
            
            xhr.addEventListener('error', () => {
                reject(new Error('Network error during upload'));
            });
            
            xhr.addEventListener('timeout', () => {
                reject(new Error('Upload timeout'));
            });
            
            xhr.timeout = 300000; // 5 minutes
            xhr.open('POST', '/api/files');
            xhr.send(formData);
        });
    }
    
    showProgress(percentage) {
        const progressContainer = document.getElementById('uploadProgress');
        const uploadArea = document.getElementById('uploadArea');
        
        uploadArea.style.display = 'none';
        progressContainer.style.display = 'block';
        
        this.updateProgress(percentage, 'Preparing upload...');
    }
    
    updateProgress(percentage, message) {
        const progressFill = document.getElementById('progressFill');
        const progressText = document.getElementById('progressText');
        
        progressFill.style.width = percentage + '%';
        progressText.textContent = message || `${Math.round(percentage)}%`;
    }
    
    hideProgress() {
        setTimeout(() => {
            const progressContainer = document.getElementById('uploadProgress');
            const uploadArea = document.getElementById('uploadArea');
            
            progressContainer.style.display = 'none';
            uploadArea.style.display = 'block';
            
            // Reset file input
            document.getElementById('fileInput').value = '';
        }, 1000);
    }
    
    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
    }
}

// Drag and drop for the entire document
class DocumentDropHandler {
    constructor() {
        this.init();
    }
    
    init() {
        // Prevent default drag behaviors on document
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            document.addEventListener(eventName, this.preventDefaults, false);
        });
        
        // Handle document-wide drop
        document.addEventListener('drop', this.handleDocumentDrop.bind(this));
        
        // Visual feedback for document-wide drag
        document.addEventListener('dragenter', this.handleDocumentDragEnter.bind(this));
        document.addEventListener('dragleave', this.handleDocumentDragLeave.bind(this));
    }
    
    preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
    handleDocumentDrop(e) {
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            // Show upload modal and handle files
            app.showUploadModal();
            setTimeout(() => {
                window.uploader.handleFiles(files);
            }, 100);
        }
        
        this.removeDragOverlay();
    }
    
    handleDocumentDragEnter(e) {
        // Only show overlay if dragging files from outside the upload area
        const uploadArea = document.getElementById('uploadArea');
        if (!uploadArea.contains(e.target) && e.dataTransfer.types.includes('Files')) {
            this.showDragOverlay();
        }
    }
    
    handleDocumentDragLeave(e) {
        // Only hide overlay if leaving the document entirely
        if (e.clientX === 0 && e.clientY === 0) {
            this.removeDragOverlay();
        }
    }
    
    showDragOverlay() {
        let overlay = document.getElementById('dragOverlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = 'dragOverlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(102, 126, 234, 0.1);
                backdrop-filter: blur(5px);
                z-index: 9999;
                display: flex;
                align-items: center;
                justify-content: center;
                pointer-events: none;
            `;
            
            overlay.innerHTML = `
                <div style="
                    background: rgba(255, 255, 255, 0.9);
                    border-radius: 12px;
                    padding: 40px;
                    text-align: center;
                    box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
                ">
                    <i class="fas fa-cloud-upload-alt" style="font-size: 48px; color: #667eea; margin-bottom: 15px;"></i>
                    <h3 style="color: #667eea; margin-bottom: 10px;">Drop files to upload</h3>
                    <p style="color: #666;">Release to upload files to UDrive</p>
                </div>
            `;
            
            document.body.appendChild(overlay);
        }
    }
    
    removeDragOverlay() {
        const overlay = document.getElementById('dragOverlay');
        if (overlay) {
            overlay.remove();
        }
    }
}

// Initialize uploader when DOM is loaded
let uploader, documentDropHandler;
document.addEventListener('DOMContentLoaded', () => {
    uploader = new UDriveUploader();
    documentDropHandler = new DocumentDropHandler();
});

// Expose uploader globally for access from other scripts
window.uploader = uploader;
