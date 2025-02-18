class Renderer {
    constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.palette = new Uint32Array(256);
        this.updatePalette();
        this.resize(CONFIG.defaults.resolution.width, CONFIG.defaults.resolution.height);
    }

    resize(width, height) {
        this.width = width;
        this.height = height;
        this.canvas.width = width;
        this.canvas.height = height;
        this.centerX = this.width / 2;
        this.centerY = this.height / 2;
        this.baseScale = Math.sqrt((this.width * this.height) / (320 * 240));
        this.imageData = this.ctx.createImageData(width, height);
        this.data = this.imageData.data;
        this.ctx.clearRect(0, 0, width, height);
    }

    updatePalette() {
        for (let i = 0; i < 32; i++) {
            const step = i * 0x203;
            for (let j = 0; j < 4; j++) {
                const idx = i * 4 + j;
                this.palette[idx] = 
                    ((step & 0xFF0000) << 8) |
                    ((step & 0x00FF00) << 8) |
                    ((step & 0x0000FF) << 8) |
                    0xFF;
            }
        }

        const lastStep = 31 * 0x203;
        const lastR = (lastStep & 0xFF0000) >> 16;
        const lastG = (lastStep & 0x00FF00) >> 8;
        const lastB = lastStep & 0x0000FF;

        for (let i = 128; i < 256; i++) {
            const t = (i - 128) / 127;
            const r = Math.floor(lastR + t * (0xFF - lastR));
            const g = Math.floor(lastG + t * (0xFF - lastG));
            const b = Math.floor(lastB + t * (0xE0 - lastB));
            const color = (r << 16) | (g << 8) | b;
            this.palette[i] = 
                ((color & 0xFF0000) << 8) |
                ((color & 0x00FF00) << 8) |
                ((color & 0x0000FF) << 8) |
                0xFF;
        }
    }

    line(x, y1, y2, color) {
        const xx = Math.floor(x);
        const startY = Math.floor(Math.min(y1, y2));
        const endY = Math.ceil(Math.max(y1, y2));
        
        if (xx < 0 || xx >= this.width) return;
        
        for (let y = startY; y <= endY; y++) {
            if (y >= 0 && y < this.height) {
                const idx = (y * this.width + xx) * 4;
                const paletteColor = this.palette[color & 0xFF];
                this.data[idx] = (paletteColor >> 24) & 0xFF;     // R
                this.data[idx + 1] = (paletteColor >> 16) & 0xFF; // G
                this.data[idx + 2] = (paletteColor >> 8) & 0xFF;  // B
                this.data[idx + 3] = paletteColor & 0xFF;         // A
            }
        }
    }

    calculateWaveHeight(fx, fy, t, settings) {
        if (settings.showHeightmap) {
            // For heightmap view, calculate direct 2D mapping with zoom
            const zoom = settings.heightmapZoom;
            const dx = (fx - this.centerX) * zoom;
            const dy = (fy - this.centerY) * zoom;
            const dist = Math.sqrt(dx * dx + dy * dy);
            
            let wave_height = 0;
            
            // Add ending effect if enabled
            if (settings.showEndingEffect) {
                wave_height = Math.sin(settings.waveAmplitude * dist) * Math.max(0, t/2-40);
            }
            
            // Use same iterations for both sky and water in heightmap mode
            const iterations = settings.waterIterations;
            for (let i = 0; i < iterations; i++) {
                const amplitude = (i * settings.waveAmplitude) / 1000;
                const frequency = settings.waveFrequency + Math.cos(i);
                const wave_dx = Math.sin(i*i);
                const wave_dy = Math.cos(i*i*i);
                const time_shift = t/14*iterations;
                wave_height += amplitude * Math.sin(
                    (frequency * ((fy * zoom/this.height) * wave_dy + (fx * zoom/this.width) * wave_dx)) + time_shift
                );
            }
            
            return wave_height;
        } else {
            // For perspective view
            const vp_x = this.centerX;
            const vp_y = this.centerY + 0.5;
            const d = this.centerX;
            const cx = vp_x - fx;
            const cy = vp_y - fy;
            const nx = cx / cy / 2;
            const ny = this.width / cy;
            const dist = Math.sqrt(cx*cx + cy*cy);
            
            let wave_height = 0;
            
            // Add ending effect if enabled
            if (settings.showEndingEffect) {
                wave_height = Math.sin(settings.waveAmplitude * dist / this.baseScale) * Math.max(0, t/2-40);
            }
            
            // Add wave iterations
            const iterations = fy < this.centerY ? settings.skyIterations : settings.waterIterations;
            for (let i = 0; i < iterations; i++) {
                const amplitude = (i * settings.waveAmplitude) / 1000;
                const frequency = settings.waveFrequency + Math.cos(i);
                const dx = Math.sin(i*i);
                const dy = Math.cos(i*i*i);
                const time_shift = t/14*iterations;
                wave_height -= amplitude * Math.abs(Math.sin(
                    (frequency * (ny * dy + nx * dx)) + time_shift
                ));
            }
            
            return wave_height;
        }
    }

    render(settings) {
        const t = time();
        this.updatePalette();
        
        for (let fx = 0; fx < this.width; fx++) {
            let prev_wave_height = 0;
            
            for (let fy = 0; fy < this.height; fy++) {
                const wave_height = this.calculateWaveHeight(fx, fy, t, settings);
                const wave_scale = Math.min(2*t, settings.maxWaveScale);
                
                if (settings.showHeightmap) {
                    // For heightmap, normalize the wave height to 0-255 range
                    const normalized_height = (wave_height + 1) / 2;  // Now properly maps -1 to 1 range to 0 to 1
                    const final_color = Math.floor(Math.max(0, Math.min(255, normalized_height * 255)));
                    this.line(fx, fy, fy, final_color);
                } else {
                    // For perspective view
                    const vp_x = this.centerX;
                    const vp_y = this.centerY + 0.5;
                    const d = this.centerX;
                    const cx = vp_x - fx;
                    const cy = vp_y - fy;
                    const dist = Math.sqrt(cx*cx + cy*cy);
                    
                    const perspective_height = wave_height * wave_scale * cy / d;
                    const h_color = 1 - Math.abs(perspective_height - prev_wave_height)/6;
                    const radius = Math.min(2*t-70, 50);
                    const blob_color = dist/radius;
                    const color = (settings.showBlob && dist < radius) ? blob_color : h_color;
                    
                    let p_color;
                    if (settings.showVignette) {
                        p_color = Math.max(0, color + (cy - dist)/(512 * this.baseScale));
                    } else {
                        p_color = color;
                    }
                    
                    let final_color = Math.min(255, Math.floor(250 * p_color));
                    
                    if (settings.showFilmGrain) {
                        final_color += 6 * randomf();
                    }
                    
                    this.line(
                        fx,
                        fy + Math.floor(perspective_height),
                        fy + Math.floor(prev_wave_height),
                        Math.floor(final_color)
                    );
                    
                    prev_wave_height = perspective_height;
                }
            }
        }
        
        this.ctx.putImageData(this.imageData, 0, 0);
    }
}