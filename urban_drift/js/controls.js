class Controls {
    constructor() {
        this.settings = { ...CONFIG.defaults };
        this.initializeControls();
        this.setupEventListeners();
    }

    initializeControls() {
        this.elements = {
            resolution: document.getElementById('resolution'),
            bayerPattern: document.getElementById('bayer-pattern'),
            autoRotate: document.getElementById('auto-rotate'),
            rotationAngle: document.getElementById('rotation-angle'),
            rotationSpeed: document.getElementById('rotation-speed'),
            shadowsEnabled: document.getElementById('shadows-enabled'),
            shadowQuality: document.getElementById('shadow-quality'),
            raycastSteps: document.getElementById('raycast-steps'),
            autoDaytime: document.getElementById('auto-daytime'),
            dayTime: document.getElementById('day-time'),
            daySpeed: document.getElementById('day-speed'),
            epsilon: document.getElementById('epsilon'),
            buildingSize: document.getElementById('building-size'),
            windowSizeH: document.getElementById('window-size-h'),
            windowSizeV: document.getElementById('window-size-v'),
            reflectionsEnabled: document.getElementById('reflections-enabled'),
            infiniteReflections: document.getElementById('infinite-reflections'),
            reflectionDepth: document.getElementById('reflection-depth'),
            windowLightsEnabled: document.getElementById('window-lights-enabled')
        };

        this.updateValueDisplays();
        this.updateDisabledStates();
    }

    setupEventListeners() {
        document.querySelectorAll('input[type="range"]').forEach(input => {
            const display = input.nextElementSibling;
            if (display) {
                input.addEventListener('input', () => {
                    const value = this.convertInputToValue(input.id, input.value);
                    display.textContent = this.formatValue(input.id, value);
                    this.updateSetting(input.id, value);
                });
            }
        });

        document.querySelectorAll('input[type="checkbox"], select').forEach(input => {
            input.addEventListener('change', () => {
                const value = input.type === 'checkbox' ? input.checked : input.value;
                this.updateSetting(input.id, value);
                if (input.type === 'checkbox') {
                    this.updateDisabledStates();
                }
            });
        });
    }

    convertInputToValue(id, value) {
        switch(id) {
            case 'epsilon':
                return Number(value) / 1000;
            case 'building-size':
                return Number(value) / 100;
            case 'window-size-h':
            case 'window-size-v':
                return Number(value) / 100;
            default:
                return Number(value);
        }
    }

    updateSetting(id, value) {
        if (id === 'resolution') {
            const [width, height] = value.split('x').map(Number);
            this.settings.resolution = { width, height };
            this.onSettingsChange({ resolution: { width, height }});
            return;
        }

        const settingKey = this.getSettingKey(id);
        this.settings[settingKey] = value;

        // Handle reflection depth calculations
        this.updateReflectionSettings(id, value);

        this.onSettingsChange({ [settingKey]: value });
    }

    updateReflectionSettings(id, value) {
        if (id === 'reflections-enabled' || id === 'infinite-reflections' || id === 'reflection-depth') {
            const reflectionsEnabled = this.elements.reflectionsEnabled.checked;
            const infiniteReflections = this.elements.infiniteReflections.checked;
            const depthValue = Number(this.elements.reflectionDepth.value);

            this.settings.reflectionDepth = !reflectionsEnabled ? 0 :
                                          infiniteReflections ? -1 :
                                          depthValue;
        }
    }

    getSettingKey(id) {
        return id.replace(/-([a-z])/g, g => g[1].toUpperCase());
    }

    formatValue(id, value) {
        switch(id) {
            case 'rotation-angle':
                return value + '°';
            case 'day-time':
                return value + '%';
            case 'epsilon':
            case 'building-size':
            case 'window-size-h':
            case 'window-size-v':
                return value.toFixed(3);
            default:
                return value.toString();
        }
    }

    updateValueDisplays() {
        document.querySelectorAll('input[type="range"]').forEach(input => {
            const display = input.nextElementSibling;
            if (display) {
                const value = this.convertInputToValue(input.id, input.value);
                display.textContent = this.formatValue(input.id, value);
            }
        });
    }

    updateDisabledStates() {
        this.elements.rotationSpeed.disabled = !this.elements.autoRotate.checked;
        this.elements.rotationAngle.disabled = this.elements.autoRotate.checked;
        this.elements.daySpeed.disabled = !this.elements.autoDaytime.checked;
        this.elements.dayTime.disabled = this.elements.autoDaytime.checked;
        
        // Update reflection controls disabled states
        const reflectionsEnabled = this.elements.reflectionsEnabled.checked;
        this.elements.infiniteReflections.disabled = !reflectionsEnabled;
        this.elements.reflectionDepth.disabled = !reflectionsEnabled || this.elements.infiniteReflections.checked;

        // Update reflection settings when disabled states change
        this.updateReflectionSettings('reflections-enabled', reflectionsEnabled);
    }

    getSettings() {
        return { ...this.settings };
    }

    onSettingsChange(changedSettings) {
        if (app) {
            if (changedSettings.resolution) {
                app.renderer.resize(changedSettings.resolution.width, changedSettings.resolution.height);
            }
            if (changedSettings.bayerPattern) {
                app.renderer.updateBayerMatrix(changedSettings.bayerPattern);
            }
            app.engine.updateSettings(this.settings);
        }
    }
}