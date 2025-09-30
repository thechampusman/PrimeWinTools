// UDrive Main JavaScript - Google Drive Style Interface

class UDriveApp {
    constructor() {
        this.currentPath = '/';
        this.viewMode = 'grid'; // 'grid' or 'list'
        this.selectedFiles = new Set();
        this.contextMenu = null;
        this.newMenu = null;
        this.currentSort = { field: 'name', direction: 'asc' };
        this.files = [];
        this.sidebarCollapsed = false;
        
        // Initialize API and UI utilities
        this.api = new UDriveAPI();
        this.ui = window.ui;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadCurrentDirectory();
        this.updateStorageInfo();
        this.hideLoading();
    }
    
    setupEventListeners() {
        // Search functionality
        const searchInput = document.querySelector('.search-input');
        searchInput.addEventListener('input', (e) => {
            this.debounce(this.handleSearch.bind(this), 300)(e.target.value);
        });
        
        // View mode toggle
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.setViewMode(e.target.dataset.view);
            });
        });
        
        // Sidebar toggle
        document.querySelector('.menu-btn').addEventListener('click', () => {
            this.toggleSidebar();
        });
        
        // New button and menu
        const newBtn = document.querySelector('.new-btn');
        const newMenu = document.querySelector('.new-menu');
        
        newBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.toggleNewMenu();
        });
        
        // New menu items
        document.querySelectorAll('.new-menu-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.stopPropagation();
                this.handleNewAction(item.dataset.action);
                this.hideNewMenu();
            });
        });
        
        // Navigation items
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                this.handleNavigation(item.dataset.path);
            });
        });
        
        // Sort options
        document.querySelectorAll('.toolbar-btn[data-sort]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.handleSort(btn.dataset.sort);
            });
        });
        
        // Global click handlers
        document.addEventListener('click', (e) => {
            this.hideContextMenu();
            this.hideNewMenu();
            this.clearSelection();
        });
        
        // Prevent selection clearing on file clicks
        document.addEventListener('click', (e) => {
            if (e.target.closest('.file-item') || e.target.closest('tr')) {
                e.stopPropagation();
            }
        });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            this.handleKeyboard(e);
        });
        
        // Upload handling
        this.setupUploadHandlers();
        
        // Breadcrumb navigation
        document.addEventListener('click', (e) => {
            if (e.target.closest('.breadcrumb-item')) {
                const path = e.target.closest('.breadcrumb-item').dataset.path;
                if (path !== undefined) {
                    this.navigateTo(path);
                }
            }
        });
    }
    
    setupUploadHandlers() {
        // File input for uploads
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.multiple = true;
        fileInput.style.display = 'none';
        document.body.appendChild(fileInput);
        
        fileInput.addEventListener('change', (e) => {
            this.handleFileUpload(Array.from(e.target.files));
            fileInput.value = ''; // Reset for next upload
        });
        
        // Store reference for other methods
        this.fileInput = fileInput;
        
        // Drag and drop
        const fileContent = document.querySelector('.file-content');
        
        fileContent.addEventListener('dragover', (e) => {
            e.preventDefault();
            fileContent.classList.add('dragover');
        });
        
        fileContent.addEventListener('dragleave', (e) => {
            if (!fileContent.contains(e.relatedTarget)) {
                fileContent.classList.remove('dragover');
            }
        });
        
        fileContent.addEventListener('drop', (e) => {
            e.preventDefault();
            fileContent.classList.remove('dragover');
            
            const files = Array.from(e.dataTransfer.files);
            if (files.length > 0) {
                this.handleFileUpload(files);
            }
        });
    }
    
    async loadCurrentDirectory() {
        try {
            this.ui.showLoadingOverlay('Loading files...');
            
            const data = await this.api.listFiles(this.currentPath);
            this.files = data.files || [];
            
            this.updateBreadcrumb();
            this.renderFiles();
            this.updateSelectionInfo();
            
        } catch (error) {
            console.error('Error loading directory:', error);
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
            this.files = [];
            this.renderFiles();
        } finally {
            this.ui.hideLoadingOverlay();
        }
    }
    
    renderFiles() {
        const container = document.querySelector('.file-content');
        const filesSection = container.querySelector('.files-section');
        
        if (this.files.length === 0) {
            this.renderEmptyState(filesSection);
            return;
        }
        
        if (this.viewMode === 'grid') {
            this.renderGridView(filesSection);
        } else {
            this.renderListView(filesSection);
        }
        
        this.updateSectionTitle();
    }
    
    renderGridView(container) {
        const sortedFiles = this.sortFiles([...this.files]);
        
        container.innerHTML = `
            <div class="section-header">
                <h3 class="section-title">${this.getSectionTitle()}</h3>
                <div class="section-actions">
                    <button class="text-btn" onclick="app.selectAll()">Select all</button>
                </div>
            </div>
            <div class="files-grid" id="filesGrid">
                ${sortedFiles.map(file => this.renderFileCard(file)).join('')}
            </div>
        `;
        
        // Add event listeners to file items
        this.attachFileEventListeners();
    }
    
    renderListView(container) {
        const sortedFiles = this.sortFiles([...this.files]);
        
        container.innerHTML = `
            <div class="section-header">
                <h3 class="section-title">${this.getSectionTitle()}</h3>
                <div class="section-actions">
                    <button class="text-btn" onclick="app.selectAll()">Select all</button>
                </div>
            </div>
            <div class="files-list">
                <table class="files-table">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Modified</th>
                            <th>Size</th>
                            <th>Type</th>
                        </tr>
                    </thead>
                    <tbody id="filesTableBody">
                        ${sortedFiles.map(file => this.renderFileRow(file)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        // Add event listeners to table rows
        this.attachFileEventListeners();
    }
    
    renderFileCard(file) {
        const isSelected = this.selectedFiles.has(file.path);
        const fileIcon = this.getFileIcon(file);
        const preview = this.getFilePreview(file);
        
        return `
            <div class="file-item ${isSelected ? 'selected' : ''}" 
                 data-path="${file.path}" 
                 data-name="${file.name}"
                 data-type="${file.type}">
                <div class="file-preview">
                    ${preview || `<span class="material-icons file-icon">${fileIcon}</span>`}
                </div>
                <div class="file-info">
                    <div class="file-name" title="${file.name}">${file.name}</div>
                    <div class="file-meta">
                        <span>${this.formatDate(file.modified)}</span>
                        <span>${this.formatSize(file.size)}</span>
                    </div>
                </div>
            </div>
        `;
    }
    
    renderFileRow(file) {
        const isSelected = this.selectedFiles.has(file.path);
        const fileIcon = this.getFileIcon(file);
        
        return `
            <tr class="${isSelected ? 'selected' : ''}" 
                data-path="${file.path}" 
                data-name="${file.name}"
                data-type="${file.type}">
                <td class="table-file-name">
                    <span class="material-icons table-file-icon">${fileIcon}</span>
                    <span class="table-name-text" title="${file.name}">${file.name}</span>
                </td>
                <td>${this.formatDate(file.modified)}</td>
                <td>${file.type === 'directory' ? '—' : this.formatSize(file.size)}</td>
                <td>${file.type === 'directory' ? 'Folder' : this.getFileType(file.name)}</td>
            </tr>
        `;
    }
    
    renderEmptyState(container) {
        const emptyMessage = this.currentPath === '/' 
            ? 'Your UDrive is empty' 
            : 'This folder is empty';
            
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-content">
                    <span class="material-icons empty-icon">folder_open</span>
                    <h3>${emptyMessage}</h3>
                    <p>Upload files or create folders to get started</p>
                    <button class="primary-btn" onclick="app.triggerUpload()">
                        <span class="material-icons">upload</span>
                        Upload files
                    </button>
                </div>
            </div>
        `;
    }
    
    attachFileEventListeners() {
        // File selection and double-click
        const fileElements = document.querySelectorAll('.file-item, .files-table tr:not(:first-child)');
        
        fileElements.forEach(element => {
            element.addEventListener('click', (e) => {
                e.stopPropagation();
                
                if (e.ctrlKey || e.metaKey) {
                    this.toggleFileSelection(element.dataset.path);
                } else if (e.shiftKey && this.selectedFiles.size > 0) {
                    this.selectFileRange(element.dataset.path);
                } else {
                    this.selectFile(element.dataset.path, true);
                }
            });
            
            element.addEventListener('dblclick', (e) => {
                e.stopPropagation();
                this.openFile(element.dataset.path, element.dataset.type);
            });
            
            element.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                this.selectFile(element.dataset.path, true);
                this.showContextMenu(e.clientX, e.clientY);
            });
        });
    }
    
    // File Operations
    async openFile(path, type) {
        if (type === 'directory') {
            this.navigateTo(path);
        } else {
            // Open file in browser or trigger download
            try {
                const encodedPath = encodeURIComponent(path);
                window.open(`/api/file/view?path=${encodedPath}`, '_blank');
            } catch (error) {
                console.error('Error opening file:', error);
                this.showToast('Error opening file', 'error');
            }
        }
    }
    
    async downloadFile(path) {
        try {
            const downloadUrl = await this.api.downloadFile(path);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = '';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            this.ui.showToast('Download started', 'success');
        } catch (error) {
            console.error('Error downloading file:', error);
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
        }
    }
    
    async deleteFiles(paths) {
        if (!confirm(`Are you sure you want to delete ${paths.length} item(s)?`)) {
            return;
        }
        
        try {
            await this.api.deleteFiles(paths);
            await this.loadCurrentDirectory();
            this.ui.showToast(`Deleted ${paths.length} item(s)`, 'success');
            
        } catch (error) {
            console.error('Error deleting files:', error);
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
        }
    }
    
    async renameFile(oldPath, newName) {
        try {
            await this.api.renameFile(oldPath, newName);
            await this.loadCurrentDirectory();
            this.ui.showToast('File renamed successfully', 'success');
            
        } catch (error) {
            console.error('Error renaming file:', error);
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
        }
    }
    
    async createFolder(name) {
        try {
            await this.api.createFolder(this.currentPath, name);
            await this.loadCurrentDirectory();
            this.ui.showToast('Folder created successfully', 'success');
            
        } catch (error) {
            console.error('Error creating folder:', error);
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
        }
    }
    
    async handleFileUpload(files) {
        if (files.length === 0) return;
        
        const modal = this.showUploadModal();
        const progressBar = modal.querySelector('.progress-fill');
        const progressText = modal.querySelector('.progress-text');
        
        try {
            await this.api.uploadWithProgress(
                files, 
                this.currentPath,
                (percentage, loaded, total) => {
                    progressBar.style.width = `${percentage}%`;
                    progressText.textContent = `Uploading... ${Math.round(percentage)}%`;
                }
            );
            
            this.ui.hideAllModals();
            await this.loadCurrentDirectory();
            this.ui.showToast(`Uploaded ${files.length} file(s) successfully`, 'success');
            
        } catch (error) {
            console.error('Error uploading files:', error);
            this.ui.hideAllModals();
            const errorMessage = this.api.handleApiError(error);
            this.ui.showToast(errorMessage, 'error');
        }
    }
    
    // Navigation
    navigateTo(path) {
        this.currentPath = path;
        this.clearSelection();
        this.loadCurrentDirectory();
        this.updateNavigation();
    }
    
    updateBreadcrumb() {
        const breadcrumb = document.querySelector('.breadcrumb');
        const pathParts = this.currentPath === '/' ? [''] : this.currentPath.split('/').filter(p => p);
        
        let currentPath = '';
        const items = [
            { name: 'My Drive', path: '/', icon: 'folder' }
        ];
        
        pathParts.forEach(part => {
            currentPath += '/' + part;
            items.push({ name: part, path: currentPath });
        });
        
        breadcrumb.innerHTML = items.map((item, index) => `
            <button class="breadcrumb-item ${index === items.length - 1 ? 'active' : ''}" 
                    data-path="${item.path}">
                ${item.icon ? `<span class="material-icons">${item.icon}</span>` : ''}
                ${item.name}
                ${index < items.length - 1 ? '<span class="material-icons">chevron_right</span>' : ''}
            </button>
        `).join('');
    }
    
    updateNavigation() {
        // Update sidebar active state
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
            if (item.dataset.path === this.currentPath) {
                item.classList.add('active');
            }
        });
    }
    
    // Selection Management
    selectFile(path, clearOthers = false) {
        if (clearOthers) {
            this.clearSelection();
        }
        
        this.selectedFiles.add(path);
        this.updateFileSelection();
        this.updateSelectionInfo();
    }
    
    toggleFileSelection(path) {
        if (this.selectedFiles.has(path)) {
            this.selectedFiles.delete(path);
        } else {
            this.selectedFiles.add(path);
        }
        
        this.updateFileSelection();
        this.updateSelectionInfo();
    }
    
    selectFileRange(endPath) {
        // Implement shift-click range selection
        const fileElements = Array.from(document.querySelectorAll('[data-path]'));
        const startIndex = fileElements.findIndex(el => this.selectedFiles.has(el.dataset.path));
        const endIndex = fileElements.findIndex(el => el.dataset.path === endPath);
        
        if (startIndex !== -1 && endIndex !== -1) {
            const start = Math.min(startIndex, endIndex);
            const end = Math.max(startIndex, endIndex);
            
            for (let i = start; i <= end; i++) {
                this.selectedFiles.add(fileElements[i].dataset.path);
            }
            
            this.updateFileSelection();
            this.updateSelectionInfo();
        }
    }
    
    clearSelection() {
        this.selectedFiles.clear();
        this.updateFileSelection();
        this.updateSelectionInfo();
    }
    
    selectAll() {
        this.files.forEach(file => {
            this.selectedFiles.add(file.path);
        });
        
        this.updateFileSelection();
        this.updateSelectionInfo();
    }
    
    updateFileSelection() {
        document.querySelectorAll('[data-path]').forEach(element => {
            const isSelected = this.selectedFiles.has(element.dataset.path);
            element.classList.toggle('selected', isSelected);
        });
    }
    
    updateSelectionInfo() {
        const count = this.selectedFiles.size;
        // Update any selection-related UI elements here
    }
    
    // Sorting
    sortFiles(files) {
        return files.sort((a, b) => {
            // Directories first
            if (a.type === 'directory' && b.type !== 'directory') return -1;
            if (b.type === 'directory' && a.type !== 'directory') return 1;
            
            let aVal = a[this.currentSort.field];
            let bVal = b[this.currentSort.field];
            
            if (this.currentSort.field === 'size') {
                aVal = a.size || 0;
                bVal = b.size || 0;
            } else if (this.currentSort.field === 'modified') {
                aVal = new Date(a.modified);
                bVal = new Date(b.modified);
            } else {
                aVal = (aVal || '').toString().toLowerCase();
                bVal = (bVal || '').toString().toLowerCase();
            }
            
            const result = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
            return this.currentSort.direction === 'asc' ? result : -result;
        });
    }
    
    handleSort(field) {
        if (this.currentSort.field === field) {
            this.currentSort.direction = this.currentSort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            this.currentSort.field = field;
            this.currentSort.direction = 'asc';
        }
        
        this.renderFiles();
    }
    
    // Search
    handleSearch(query) {
        // Implement search functionality
        if (!query.trim()) {
            this.renderFiles();
            return;
        }
        
        const filteredFiles = this.files.filter(file =>
            file.name.toLowerCase().includes(query.toLowerCase())
        );
        
        const originalFiles = this.files;
        this.files = filteredFiles;
        this.renderFiles();
        this.files = originalFiles;
    }
    
    // UI Helpers
    setViewMode(mode) {
        this.viewMode = mode;
        
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        
        document.querySelector(`[data-view="${mode}"]`).classList.add('active');
        
        this.renderFiles();
    }
    
    toggleSidebar() {
        this.sidebarCollapsed = !this.sidebarCollapsed;
        document.querySelector('.sidebar').classList.toggle('collapsed', this.sidebarCollapsed);
    }
    
    // Context Menu
    showContextMenu(x, y) {
        const selectedCount = this.selectedFiles.size;
        const selectedFile = selectedCount === 1 ? 
            this.files.find(f => this.selectedFiles.has(f.path)) : null;
        
        const menuItems = [];
        
        if (selectedCount === 1) {
            menuItems.push(
                { 
                    text: 'Open', 
                    icon: 'open_in_new', 
                    onclick: () => this.handleContextAction('open') 
                },
                { 
                    text: 'Rename', 
                    icon: 'edit', 
                    onclick: () => this.handleContextAction('rename'),
                    shortcut: 'F2'
                }
            );
        }
        
        if (selectedCount > 0) {
            if (selectedCount === 1) {
                menuItems.push({ separator: true });
            }
            
            menuItems.push(
                { 
                    text: 'Download', 
                    icon: 'download', 
                    onclick: () => this.handleContextAction('download') 
                },
                { separator: true },
                { 
                    text: 'Delete', 
                    icon: 'delete', 
                    danger: true,
                    onclick: () => this.handleContextAction('delete'),
                    shortcut: 'Del'
                }
            );
        }
        
        this.ui.showContextMenu(x, y, menuItems);
    }
    
    handleContextAction(action) {
        const selectedPaths = Array.from(this.selectedFiles);
        
        switch (action) {
            case 'open':
                if (selectedPaths.length === 1) {
                    const file = this.files.find(f => f.path === selectedPaths[0]);
                    this.openFile(file.path, file.type);
                }
                break;
            case 'download':
                selectedPaths.forEach(path => this.downloadFile(path));
                break;
            case 'delete':
                this.deleteFiles(selectedPaths);
                break;
            case 'rename':
                if (selectedPaths.length === 1) {
                    this.showRenameModal(selectedPaths[0]);
                }
                break;
        }
    }
    
    // New Menu
    toggleNewMenu() {
        if (this.newMenu) {
            this.hideNewMenu();
        } else {
            this.showNewMenu();
        }
    }
    
    showNewMenu() {
        const newBtn = document.querySelector('.new-btn');
        const menu = document.querySelector('.new-menu');
        
        menu.style.display = 'block';
        this.newMenu = menu;
        
        // Position relative to button
        const rect = newBtn.getBoundingClientRect();
        menu.style.left = `${rect.left}px`;
        menu.style.top = `${rect.bottom + 8}px`;
    }
    
    hideNewMenu() {
        const menu = document.querySelector('.new-menu');
        menu.style.display = 'none';
        this.newMenu = null;
    }
    
    handleNewAction(action) {
        switch (action) {
            case 'upload':
                this.triggerUpload();
                break;
            case 'folder':
                this.showNewFolderModal();
                break;
        }
    }
    
    triggerUpload() {
        this.fileInput.click();
    }
    
    // Modals
    showNewFolderModal() {
        this.ui.showModal({
            title: 'New Folder',
            content: `<input type="text" class="text-input" placeholder="Folder name" id="folderName" />`,
            size: 'small',
            buttons: [
                {
                    text: 'Cancel',
                    onclick: () => this.ui.hideAllModals()
                },
                {
                    text: 'Create',
                    primary: true,
                    onclick: () => {
                        const input = document.querySelector('#folderName');
                        const name = input.value.trim();
                        if (name) {
                            const validation = this.api.validateFileName(name);
                            if (validation.valid) {
                                this.createFolder(name);
                                this.ui.hideAllModals();
                            } else {
                                this.ui.showFieldError(input, validation.error);
                            }
                        }
                    }
                }
            ]
        });
        
        // Focus the input
        setTimeout(() => {
            const input = document.querySelector('#folderName');
            if (input) {
                input.focus();
                input.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter') {
                        const name = input.value.trim();
                        if (name) {
                            const validation = this.api.validateFileName(name);
                            if (validation.valid) {
                                this.createFolder(name);
                                this.ui.hideAllModals();
                            } else {
                                this.ui.showFieldError(input, validation.error);
                            }
                        }
                    }
                });
            }
        }, 100);
    }
    
    showRenameModal(path) {
        const file = this.files.find(f => f.path === path);
        if (!file) return;
        
        this.ui.showModal({
            title: 'Rename',
            content: `<input type="text" class="text-input" value="${file.name}" id="newFileName" />`,
            size: 'small',
            buttons: [
                {
                    text: 'Cancel',
                    onclick: () => this.ui.hideAllModals()
                },
                {
                    text: 'Rename',
                    primary: true,
                    onclick: () => {
                        const input = document.querySelector('#newFileName');
                        const newName = input.value.trim();
                        if (newName && newName !== file.name) {
                            const validation = this.api.validateFileName(newName);
                            if (validation.valid) {
                                this.renameFile(path, newName);
                                this.ui.hideAllModals();
                            } else {
                                this.ui.showFieldError(input, validation.error);
                            }
                        }
                    }
                }
            ]
        });
        
        // Focus and select the input
        setTimeout(() => {
            const input = document.querySelector('#newFileName');
            if (input) {
                input.focus();
                input.select();
                input.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter') {
                        const newName = input.value.trim();
                        if (newName && newName !== file.name) {
                            const validation = this.api.validateFileName(newName);
                            if (validation.valid) {
                                this.renameFile(path, newName);
                                this.ui.hideAllModals();
                            } else {
                                this.ui.showFieldError(input, validation.error);
                            }
                        }
                    }
                });
            }
        }, 100);
    }
    
    showUploadModal() {
        const progressBar = this.ui.createProgressBar({
            value: 0,
            max: 100,
            showText: true,
            className: 'upload-progress'
        });
        
        const modal = this.ui.showModal({
            title: 'Uploading files',
            content: progressBar,
            closable: false,
            buttons: []
        });
        
        return modal;
    }
    
    // Loading States
    hideLoading() {
        setTimeout(() => {
            this.ui.hideLoadingOverlay();
        }, 1000);
    }
    
    // Storage Info
    async updateStorageInfo() {
        try {
            const data = await this.api.getStorageInfo();
            
            // Extract storage info from server response structure
            const stats = data.stats || {};
            const used = stats.storageUsed || stats.used || 0;
            const total = stats.storageTotal || stats.total || used * 2; // Fallback calculation
            const percentage = total > 0 ? (used / total) * 100 : 0;
            
            const storageUsedElement = document.querySelector('.storage-used');
            const storageTextElement = document.querySelector('.storage-text');
            
            if (storageUsedElement) {
                storageUsedElement.style.width = `${Math.min(percentage, 100)}%`;
            }
            
            if (storageTextElement) {
                storageTextElement.textContent = 
                    `${this.api.formatFileSize(used)} of ${this.api.formatFileSize(total)} used`;
            }
                
        } catch (error) {
            console.error('Error updating storage info:', error);
        }
    }
    
    // Utility Functions
    getFileIcon(file) {
        if (file.type === 'directory') return 'folder';
        
        const ext = file.name.split('.').pop()?.toLowerCase();
        const iconMap = {
            pdf: 'picture_as_pdf',
            doc: 'description',
            docx: 'description',
            txt: 'description',
            jpg: 'image',
            jpeg: 'image',
            png: 'image',
            gif: 'image',
            svg: 'image',
            mp4: 'movie',
            avi: 'movie',
            mkv: 'movie',
            mp3: 'music_note',
            wav: 'music_note',
            flac: 'music_note',
            zip: 'archive',
            rar: 'archive',
            '7z': 'archive',
            js: 'code',
            py: 'code',
            html: 'code',
            css: 'code',
            json: 'code'
        };
        
        return iconMap[ext] || 'insert_drive_file';
    }
    
    getFilePreview(file) {
        if (this.api.isImage(file.name)) {
            const thumbnailUrl = this.api.getThumbnailUrl(file.path);
            return `<img src="${thumbnailUrl}" alt="${file.name}" />`;
        }
        
        return null;
    }
    
    getFileType(filename) {
        const ext = filename.split('.').pop()?.toLowerCase();
        const typeMap = {
            pdf: 'PDF Document',
            doc: 'Word Document',
            docx: 'Word Document',
            txt: 'Text Document',
            jpg: 'JPEG Image',
            jpeg: 'JPEG Image',
            png: 'PNG Image',
            gif: 'GIF Image',
            svg: 'SVG Image',
            mp4: 'MP4 Video',
            avi: 'AVI Video',
            mkv: 'MKV Video',
            mp3: 'MP3 Audio',
            wav: 'WAV Audio',
            flac: 'FLAC Audio',
            zip: 'ZIP Archive',
            rar: 'RAR Archive',
            '7z': '7-Zip Archive',
            js: 'JavaScript File',
            py: 'Python File',
            html: 'HTML Document',
            css: 'CSS Stylesheet',
            json: 'JSON File'
        };
        
        return typeMap[ext] || `${ext?.toUpperCase()} File` || 'File';
    }
    
    formatSize(bytes) {
        return this.api.formatFileSize(bytes);
    }
    
    formatDate(date) {
        return this.api.formatDate(date);
    }
    
    getSectionTitle() {
        return this.currentPath === '/' ? 'My Drive' : 'Files';
    }
    
    updateSectionTitle() {
        const title = document.querySelector('.section-title');
        if (title) {
            title.textContent = this.getSectionTitle();
        }
    }
    
    // Keyboard shortcuts
    handleKeyboard(e) {
        // Delete key
        if (e.key === 'Delete' && this.selectedFiles.size > 0) {
            e.preventDefault();
            this.deleteFiles(Array.from(this.selectedFiles));
        }
        
        // F2 for rename
        if (e.key === 'F2' && this.selectedFiles.size === 1) {
            e.preventDefault();
            this.showRenameModal(Array.from(this.selectedFiles)[0]);
        }
        
        // Ctrl+A for select all
        if (e.ctrlKey && e.key === 'a' && this.files.length > 0) {
            e.preventDefault();
            this.selectAll();
        }
        
        // Escape to clear selection
        if (e.key === 'Escape') {
            this.clearSelection();
            this.hideContextMenu();
            this.hideNewMenu();
        }
    }
    
    // Debounce utility
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
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new UDriveApp();
});