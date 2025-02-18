class Controls {
    constructor() {
        this.settings = { ...CONFIG.defaults };
        this.initializeControls();
        this.setupEventListeners();
    }

    initializeControls() {
        this.elements = {
            resolution: document.getElementById('resolution'),
            autoTime: document.getElementById('auto-time'),
            currentTime: document.getElementById('current-time'),
            showHeightmap: document.getElementById('show-heightmap'),
            showBlob: document.getElementById('show-blob'),
            showVignette: document.getElementById('show-vignette'),
            showFilmGrain: document.getElementById('show-film-grain'),
            showEndingEffect: document.getElementById('show-ending-effect'),
            waterIterations: document.getElementById('water-iterations'),
            skyIterations: document.getElementById('sky-iterations'),
            waveAmplitude: document.getElementById('wave-amplitude'),
            waveFrequency: document.getElementById('wave-frequency'),
            heightmapZoom: document.getElementById('heightmap-zoom'),
        };

        // Initialize all controls with default values
        Object.entries(this.elements).forEach(([key, element]) => {
            if (element) {
                const settingKey = this.getSettingKey(element.id);
                const defaultValue = this.settings[settingKey];
                
                if (element.type === 'checkbox') {
                    element.checked = defaultValue;
                } else if (element.type === 'range') {
                    element.value = defaultValue;
                    const display = element.nextElementSibling;
                    if (display) {
                        display.textContent = this.formatValue(element.id, Number(defaultValue));
                    }
                } else if (element.tagName === 'SELECT') {
                    const defaultRes = `${defaultValue.width}x${defaultValue.height}`;
                    element.value = defaultRes;
                }
            }
        });

        this.updateDisabledStates();
    }

    setupEventListeners() {
        document.querySelectorAll('input[type="range"]').forEach(input => {
            const display = input.nextElementSibling;
            if (display) {
                input.addEventListener('input', () => {
                    const value = Number(input.value);
                    display.textContent = this.formatValue(input.id, value);
                    this.updateSetting(input.id, value);
                });
            }
        });

        document.querySelectorAll('input[type="checkbox"], select').forEach(input => {
            input.addEventListener('change', () => {
                const value = input.type === 'checkbox' ? input.checked : input.value;
                this.updateSetting(input.id, value);
                if (input.id === 'auto-time') {
                    if (input.checked) {
                        startTime = performance.now() - (this.settings.currentTime * 1000);
                    }
                    this.updateDisabledStates();
                } else if (input.id === 'show-heightmap') {
                    this.updateDisabledStates();
                }
            });
        });
    }

    formatValue(id, value) {
        const numValue = Number(value);
        switch(id) {
            case 'current-time':
                return numValue + 's';
            case 'wave-frequency':
            case 'heightmap-zoom':
                return numValue.toFixed(1);
            default:
                return numValue.toString();
        }
    }

    updateSetting(id, value) {
        if (id === 'resolution') {
            const [width, height] = value.split('x').map(Number);
            this.settings.resolution = { width, height };
            if (app && app.renderer) {
                app.renderer.resize(width, height);
            }
            return;
        }

        const settingKey = this.getSettingKey(id);
        this.settings[settingKey] = value;
    }

    getSettingKey(id) {
        return id.replace(/-([a-z])/g, g => g[1].toUpperCase());
    }

    updateDisabledStates() {
        if (this.elements.currentTime) {
            this.elements.currentTime.disabled = this.elements.autoTime.checked;
        }
        
        // Control heightmap zoom
        if (this.elements.heightmapZoom) {
            this.elements.heightmapZoom.disabled = !this.elements.showHeightmap.checked;
        }
    }

    getSettings() {
        return { ...this.settings };
    }
}