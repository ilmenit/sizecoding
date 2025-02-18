// Math utility functions
const MathUtils = {
    abs: Math.abs, 
    min: Math.min,
    max: Math.max,
    sin: Math.sin,
    cos: Math.cos,
    sqrt: Math.sqrt,
    fmod: (x, y) => x % y,
    time: () => performance.now() / 1000
};

// Default configuration
const CONFIG = {
    defaults: {
        resolution: { width: 320, height: 240 },
        bayerPattern: 16,
        autoRotate: true,
        rotationAngle: 0,
        rotationSpeed: 16,
        shadowsEnabled: true,
        shadowQuality: 16,
        raycastSteps: 64,
        autoDaytime: true,
        dayTime: 50,
        daySpeed: 64,
        epsilon: 0.013671875,
        buildingSize: 0.4375,
        windowSizeH: 0.875,
        windowSizeV: 0.875,
        reflectionsEnabled: true,
        infiniteReflections: true,
        reflectionDepth: 8,
        windowLightsEnabled: true
    }
};