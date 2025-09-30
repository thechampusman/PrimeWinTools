// UDrive UI Utilities - Additional UI components and helpers

class UDriveUI {
    constructor() {
        this.activeModals = [];
        this.activeToasts = [];
        this.dragCounter = 0;
    }
    
    // Enhanced Modal System
    showModal(config) {
        const modal = this.createModal(config);
        document.body.appendChild(modal);
        this.activeModals.push(modal);
        
        // Animate in
        requestAnimationFrame(() => {
            modal.classList.add('show');
        });
        
        // Focus management
        this.trapFocus(modal);
        
        return modal;
    }
    
    createModal(config) {
        const {
            title,
            content,
            size = 'medium',
            closable = true,
            buttons = [],
            onClose
        } = config;
        
        const overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        
        const modal = document.createElement('div');
        modal.className = `modal ${size}`;
        
        // Header
        const header = document.createElement('div');
        header.className = 'modal-header';
        header.innerHTML = `
            <h3>${title}</h3>
            ${closable ? '<button class="modal-close"><span class="material-icons">close</span></button>' : ''}
        `;
        
        // Body
        const body = document.createElement('div');
        body.className = 'modal-body';
        if (typeof content === 'string') {
            body.innerHTML = content;
        } else {
            body.appendChild(content);
        }
        
        // Footer
        let footer = null;
        if (buttons.length > 0) {
            footer = document.createElement('div');
            footer.className = 'modal-footer';
            
            buttons.forEach(button => {
                const btn = document.createElement('button');
                btn.className = button.primary ? 'primary-btn' : 'secondary-btn';
                btn.textContent = button.text;
                btn.onclick = button.onclick;
                if (button.disabled) btn.disabled = true;
                footer.appendChild(btn);
            });
        }
        
        // Assemble modal
        modal.appendChild(header);
        modal.appendChild(body);
        if (footer) modal.appendChild(footer);
        overlay.appendChild(modal);
        
        // Event listeners
        if (closable) {
            const closeBtn = header.querySelector('.modal-close');
            closeBtn.onclick = () => this.hideModal(overlay, onClose);
            
            overlay.onclick = (e) => {
                if (e.target === overlay) {
                    this.hideModal(overlay, onClose);
                }
            };
        }
        
        // Keyboard handler
        overlay.onkeydown = (e) => {
            if (e.key === 'Escape' && closable) {
                this.hideModal(overlay, onClose);
            }
        };
        
        return overlay;
    }
    
    hideModal(modal, onClose) {
        if (onClose && onClose() === false) {
            return; // Prevent closing if onClose returns false
        }
        
        modal.classList.add('hiding');
        setTimeout(() => {
            if (modal.parentNode) {
                modal.parentNode.removeChild(modal);
            }
            this.activeModals = this.activeModals.filter(m => m !== modal);
        }, 200);
    }
    
    hideAllModals() {
        this.activeModals.forEach(modal => {
            this.hideModal(modal);
        });
    }
    
    // Enhanced Toast System
    showToast(message, type = 'info', duration = 5000, actions = []) {
        const toast = this.createToast(message, type, actions);
        
        let container = document.querySelector('.toast-container');
        if (!container) {
            container = document.createElement('div');
            container.className = 'toast-container';
            document.body.appendChild(container);
        }
        
        container.appendChild(toast);
        this.activeToasts.push(toast);
        
        // Auto-dismiss
        if (duration > 0) {
            setTimeout(() => {
                this.hideToast(toast);
            }, duration);
        }
        
        return toast;
    }
    
    createToast(message, type, actions) {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        
        const content = document.createElement('div');
        content.className = 'toast-content';
        content.innerHTML = `<span class="toast-message">${message}</span>`;
        
        // Add action buttons
        if (actions.length > 0) {
            const actionsContainer = document.createElement('div');
            actionsContainer.className = 'toast-actions';
            
            actions.forEach(action => {
                const btn = document.createElement('button');
                btn.className = 'toast-action-btn';
                btn.textContent = action.text;
                btn.onclick = () => {
                    action.onclick();
                    this.hideToast(toast);
                };
                actionsContainer.appendChild(btn);
            });
            
            content.appendChild(actionsContainer);
        }
        
        // Close button
        const closeBtn = document.createElement('button');
        closeBtn.className = 'toast-close';
        closeBtn.innerHTML = '<span class="material-icons">close</span>';
        closeBtn.onclick = () => this.hideToast(toast);
        
        toast.appendChild(content);
        toast.appendChild(closeBtn);
        
        return toast;
    }
    
    hideToast(toast) {
        toast.classList.add('hiding');
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
            this.activeToasts = this.activeToasts.filter(t => t !== toast);
        }, 300);
    }
    
    // Progress Bar Component
    createProgressBar(config = {}) {
        const {
            value = 0,
            max = 100,
            showText = true,
            className = '',
            color = 'primary'
        } = config;
        
        const container = document.createElement('div');
        container.className = `progress-container ${className}`;
        
        const bar = document.createElement('div');
        bar.className = 'progress-bar';
        
        const fill = document.createElement('div');
        fill.className = `progress-fill ${color}`;
        fill.style.width = `${(value / max) * 100}%`;
        
        bar.appendChild(fill);
        container.appendChild(bar);
        
        if (showText) {
            const text = document.createElement('div');
            text.className = 'progress-text';
            text.textContent = `${Math.round((value / max) * 100)}%`;
            container.appendChild(text);
        }
        
        // Update method
        container.update = (newValue) => {
            const percentage = Math.round((newValue / max) * 100);
            fill.style.width = `${percentage}%`;
            if (showText) {
                container.querySelector('.progress-text').textContent = `${percentage}%`;
            }
        };
        
        return container;
    }
    
    // Loading States
    showLoadingOverlay(message = 'Loading...') {
        let overlay = document.querySelector('.loading-overlay');
        
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.className = 'loading-overlay';
            overlay.innerHTML = `
                <div class="loading-content">
                    <div class="loading-spinner"></div>
                    <div class="loading-message">${message}</div>
                </div>
            `;
            document.body.appendChild(overlay);
        } else {
            overlay.querySelector('.loading-message').textContent = message;
            overlay.style.display = 'flex';
        }
        
        return overlay;
    }
    
    hideLoadingOverlay() {
        const overlay = document.querySelector('.loading-overlay');
        const appContainer = document.getElementById('appContainer');
        
        if (overlay) {
            overlay.style.display = 'none';
        }
        
        if (appContainer) {
            appContainer.style.display = 'block';
        }
    }
    
    // Enhanced Drag and Drop
    setupDragAndDrop(element, callbacks) {
        const {
            onDragEnter,
            onDragLeave,
            onDragOver,
            onDrop
        } = callbacks;
        
        let dragCounter = 0;
        
        element.addEventListener('dragenter', (e) => {
            e.preventDefault();
            dragCounter++;
            if (dragCounter === 1) {
                element.classList.add('drag-over');
                if (onDragEnter) onDragEnter(e);
            }
        });
        
        element.addEventListener('dragleave', (e) => {
            e.preventDefault();
            dragCounter--;
            if (dragCounter === 0) {
                element.classList.remove('drag-over');
                if (onDragLeave) onDragLeave(e);
            }
        });
        
        element.addEventListener('dragover', (e) => {
            e.preventDefault();
            if (onDragOver) onDragOver(e);
        });
        
        element.addEventListener('drop', (e) => {
            e.preventDefault();
            dragCounter = 0;
            element.classList.remove('drag-over');
            if (onDrop) onDrop(e);
        });
    }
    
    // File Upload Component
    createFileUploadArea(config = {}) {
        const {
            multiple = true,
            accept = '*/*',
            maxSize = null,
            onFilesSelected,
            className = ''
        } = config;
        
        const container = document.createElement('div');
        container.className = `file-upload-area ${className}`;
        
        const input = document.createElement('input');
        input.type = 'file';
        input.multiple = multiple;
        input.accept = accept;
        input.style.display = 'none';
        
        const dropArea = document.createElement('div');
        dropArea.className = 'upload-drop-area';
        dropArea.innerHTML = `
            <div class="upload-icon">
                <span class="material-icons">cloud_upload</span>
            </div>
            <div class="upload-text">
                <h4>Drop files here or click to upload</h4>
                <p>Choose files from your computer</p>
            </div>
        `;
        
        container.appendChild(input);
        container.appendChild(dropArea);
        
        // Click to upload
        dropArea.onclick = () => input.click();
        
        // File selection
        input.onchange = (e) => {
            const files = Array.from(e.target.files);
            this.handleFileValidation(files, maxSize, onFilesSelected);
            input.value = ''; // Reset for next selection
        };
        
        // Drag and drop
        this.setupDragAndDrop(dropArea, {
            onDrop: (e) => {
                const files = Array.from(e.dataTransfer.files);
                this.handleFileValidation(files, maxSize, onFilesSelected);
            }
        });
        
        return container;
    }
    
    handleFileValidation(files, maxSize, callback) {
        if (maxSize) {
            const oversizedFiles = files.filter(file => file.size > maxSize);
            if (oversizedFiles.length > 0) {
                this.showToast(
                    `${oversizedFiles.length} file(s) exceed the maximum size limit`,
                    'warning'
                );
                files = files.filter(file => file.size <= maxSize);
            }
        }
        
        if (files.length > 0 && callback) {
            callback(files);
        }
    }
    
    // Context Menu System
    showContextMenu(x, y, items) {
        this.hideContextMenu();
        
        const menu = document.createElement('div');
        menu.className = 'context-menu';
        menu.style.left = `${x}px`;
        menu.style.top = `${y}px`;
        
        const list = document.createElement('ul');
        list.className = 'context-menu-list';
        
        items.forEach(item => {
            if (item.separator) {
                const separator = document.createElement('li');
                separator.className = 'context-menu-separator';
                list.appendChild(separator);
            } else {
                const menuItem = document.createElement('li');
                menuItem.className = `context-menu-item ${item.disabled ? 'disabled' : ''} ${item.danger ? 'danger' : ''}`;
                menuItem.innerHTML = `
                    ${item.icon ? `<span class="material-icons">${item.icon}</span>` : ''}
                    <span>${item.text}</span>
                    ${item.shortcut ? `<span class="shortcut">${item.shortcut}</span>` : ''}
                `;
                
                if (!item.disabled && item.onclick) {
                    menuItem.onclick = (e) => {
                        e.stopPropagation();
                        item.onclick();
                        this.hideContextMenu();
                    };
                }
                
                list.appendChild(menuItem);
            }
        });
        
        menu.appendChild(list);
        document.body.appendChild(menu);
        
        // Adjust position if menu goes off screen
        const rect = menu.getBoundingClientRect();
        if (rect.right > window.innerWidth) {
            menu.style.left = `${x - rect.width}px`;
        }
        if (rect.bottom > window.innerHeight) {
            menu.style.top = `${y - rect.height}px`;
        }
        
        // Close on outside click
        setTimeout(() => {
            document.addEventListener('click', this.hideContextMenu.bind(this), { once: true });
        }, 0);
        
        this.contextMenu = menu;
        return menu;
    }
    
    hideContextMenu() {
        if (this.contextMenu) {
            this.contextMenu.remove();
            this.contextMenu = null;
        }
    }
    
    // Form Validation
    validateForm(form, rules) {
        const errors = {};
        let isValid = true;
        
        Object.entries(rules).forEach(([fieldName, fieldRules]) => {
            const field = form.querySelector(`[name="${fieldName}"]`);
            if (!field) return;
            
            const value = field.value.trim();
            const fieldErrors = [];
            
            // Required validation
            if (fieldRules.required && !value) {
                fieldErrors.push('This field is required');
                isValid = false;
            }
            
            // Min length validation
            if (fieldRules.minLength && value.length < fieldRules.minLength) {
                fieldErrors.push(`Minimum length is ${fieldRules.minLength} characters`);
                isValid = false;
            }
            
            // Max length validation
            if (fieldRules.maxLength && value.length > fieldRules.maxLength) {
                fieldErrors.push(`Maximum length is ${fieldRules.maxLength} characters`);
                isValid = false;
            }
            
            // Pattern validation
            if (fieldRules.pattern && !fieldRules.pattern.test(value)) {
                fieldErrors.push(fieldRules.patternMessage || 'Invalid format');
                isValid = false;
            }
            
            // Custom validation
            if (fieldRules.validator) {
                const customError = fieldRules.validator(value);
                if (customError) {
                    fieldErrors.push(customError);
                    isValid = false;
                }
            }
            
            if (fieldErrors.length > 0) {
                errors[fieldName] = fieldErrors;
                this.showFieldError(field, fieldErrors[0]);
            } else {
                this.hideFieldError(field);
            }
        });
        
        return { isValid, errors };
    }
    
    showFieldError(field, message) {
        this.hideFieldError(field);
        
        field.classList.add('error');
        
        const errorElement = document.createElement('div');
        errorElement.className = 'field-error';
        errorElement.textContent = message;
        
        field.parentNode.appendChild(errorElement);
    }
    
    hideFieldError(field) {
        field.classList.remove('error');
        
        const errorElement = field.parentNode.querySelector('.field-error');
        if (errorElement) {
            errorElement.remove();
        }
    }
    
    // Focus Management
    trapFocus(element) {
        const focusableElements = element.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];
        
        if (firstElement) {
            firstElement.focus();
        }
        
        element.addEventListener('keydown', (e) => {
            if (e.key !== 'Tab') return;
            
            if (e.shiftKey) {
                if (document.activeElement === firstElement) {
                    e.preventDefault();
                    lastElement.focus();
                }
            } else {
                if (document.activeElement === lastElement) {
                    e.preventDefault();
                    firstElement.focus();
                }
            }
        });
    }
    
    // Responsive Utilities
    isMobile() {
        return window.innerWidth <= 768;
    }
    
    isTablet() {
        return window.innerWidth > 768 && window.innerWidth <= 1024;
    }
    
    isDesktop() {
        return window.innerWidth > 1024;
    }
    
    // Animation Helpers
    slideDown(element, duration = 300) {
        element.style.height = '0px';
        element.style.overflow = 'hidden';
        element.style.transition = `height ${duration}ms ease`;
        
        const targetHeight = element.scrollHeight;
        
        requestAnimationFrame(() => {
            element.style.height = `${targetHeight}px`;
        });
        
        setTimeout(() => {
            element.style.height = '';
            element.style.overflow = '';
            element.style.transition = '';
        }, duration);
    }
    
    slideUp(element, duration = 300) {
        const startHeight = element.offsetHeight;
        element.style.height = `${startHeight}px`;
        element.style.overflow = 'hidden';
        element.style.transition = `height ${duration}ms ease`;
        
        requestAnimationFrame(() => {
            element.style.height = '0px';
        });
        
        setTimeout(() => {
            element.style.display = 'none';
            element.style.height = '';
            element.style.overflow = '';
            element.style.transition = '';
        }, duration);
    }
    
    fadeIn(element, duration = 300) {
        element.style.opacity = '0';
        element.style.transition = `opacity ${duration}ms ease`;
        
        requestAnimationFrame(() => {
            element.style.opacity = '1';
        });
        
        setTimeout(() => {
            element.style.transition = '';
        }, duration);
    }
    
    fadeOut(element, duration = 300) {
        element.style.transition = `opacity ${duration}ms ease`;
        element.style.opacity = '0';
        
        setTimeout(() => {
            element.style.display = 'none';
            element.style.transition = '';
        }, duration);
    }
    
    // Utility Methods
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
    
    throttle(func, limit) {
        let lastFunc;
        let lastRan;
        return function(...args) {
            if (!lastRan) {
                func(...args);
                lastRan = Date.now();
            } else {
                clearTimeout(lastFunc);
                lastFunc = setTimeout(() => {
                    if ((Date.now() - lastRan) >= limit) {
                        func(...args);
                        lastRan = Date.now();
                    }
                }, limit - (Date.now() - lastRan));
            }
        };
    }
    
    // Clipboard Utilities
    async copyToClipboard(text) {
        try {
            await navigator.clipboard.writeText(text);
            this.showToast('Copied to clipboard', 'success', 2000);
            return true;
        } catch (error) {
            console.error('Failed to copy to clipboard:', error);
            this.showToast('Failed to copy to clipboard', 'error');
            return false;
        }
    }
    
    // Format utilities
    formatBytes(bytes, decimals = 1) {
        if (bytes === 0) return '0 bytes';
        
        const k = 1024;
        const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
    }
    
    formatDuration(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);
        
        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        } else {
            return `${minutes}:${secs.toString().padStart(2, '0')}`;
        }
    }
}

// Initialize UI utilities
if (typeof window !== 'undefined') {
    window.UDriveUI = UDriveUI;
    window.ui = new UDriveUI();
}

// ES6 export for module imports
export { UDriveUI };