const CONFIG = {
    defaults: {
        resolution: { width: 320, height: 240 },
        autoTime: true,
        currentTime: 0,
        showBlob: true,
        showVignette: true,
        showFilmGrain: true,
        showEndingEffect: true,
        waterIterations: 16,
        skyIterations: 4,
        waveAmplitude: 40,
        waveFrequency: 2,
        maxWaveScale: 40,
        showHeightmap: false,
        heightmapZoom: 1
    }
};

let startTime = performance.now();

function randomf() {
    return Math.random();
}

function time() {
    if (app && app.controls) {
        if (!app.controls.settings.autoTime) {
            return Number(app.controls.settings.currentTime);
        }
    }
    return (performance.now() - startTime) / 1000;
}