class Renderer {
    constructor(canvas, engine) {
        this.canvas = canvas;
        this.engine = engine;
        this.ctx = canvas.getContext('2d');
        this.frameCount = 0;
        this.bayerSize = 8;
        this.updateBayerMatrix(16);
    }

    updateBayerMatrix(size) {
        this.bayerMatrix = new Uint8Array(this.bayerSize * this.bayerSize);
        for(let y = 0; y < this.bayerSize; y++) {
            for(let x = 0; x < this.bayerSize; x++) {
                let m = 0;
                for(let bit = 0; bit < 6; bit++) {
                    const mask = 1 << bit;
                    m |= (((x & mask) >> bit) << (2 * bit + 1)) | 
                         (((y & mask) >> bit) << (2 * bit));
                }
                this.bayerMatrix[y * this.bayerSize + x] = m;
            }
        }
        this.bayerDivisor = size;
    }

    resize(width, height) {
        this.canvas.width = width;
        this.canvas.height = height;
        this.imageData = this.ctx.createImageData(width, height);
        this.calculateScaleFactor();
    }

    calculateScaleFactor() {
        // Get the container dimensions
        const container = this.canvas.parentElement;
        const containerWidth = container.clientWidth;
        const containerHeight = container.clientHeight;
        
        // Calculate the scale needed to fit the canvas to the container
        const containerRatio = containerWidth / containerHeight;
        const canvasRatio = this.canvas.width / this.canvas.height;
        
        if (containerRatio > canvasRatio) {
            // Container is wider than needed
            this.canvas.style.height = containerHeight + 'px';
            this.canvas.style.width = (containerHeight * canvasRatio) + 'px';
        } else {
            // Container is taller than needed
            this.canvas.style.width = containerWidth + 'px';
            this.canvas.style.height = (containerWidth / canvasRatio) + 'px';
        }
        
        // Calculate scale factors for internal use
        this.scaleX = this.canvas.width / 320;  // Base scale factor
        this.scaleY = this.canvas.height / 240;
    }

    calculateAngle(settings) {
        if (settings.autoRotate) {
            return MathUtils.time() / settings.rotationSpeed;
        }
        return settings.rotationAngle * (Math.PI / 180);
    }

    render(settings) {
        const angle = this.calculateAngle(settings);
        const s = MathUtils.sin(angle);
        const c = MathUtils.cos(angle);

        const patternOffset = this.frameCount % this.bayerDivisor;
        const data = this.imageData.data;

        for (let y = 0; y < this.canvas.height; y++) {
            const v = (100 - y / this.scaleY) / 100;

            for (let x = 0; x < this.canvas.width; x++) {
                // Use Bayer matrix for temporal sampling
                const bayerX = Math.floor(x / this.scaleX) % this.bayerSize;
                const bayerY = Math.floor(y / this.scaleY) % this.bayerSize;
                const bayerValue = this.bayerMatrix[bayerY * this.bayerSize + bayerX];
                
                if ((bayerValue % this.bayerDivisor) !== patternOffset) {
                    continue;
                }

                const u = (160 - x / this.scaleX) / 100;
                const rdX = -c * u - 2 * s;
                const rdY = v - 0.7;
                const rdZ = s * u - 2 * c;
                
                const light = this.engine.raycast(
                    4 * s,
                    4 - Math.abs(MathUtils.fmod(angle/4, 2)-1),
                    4 * c,
                    rdX, rdY, rdZ,
                    settings.reflectionDepth // Pass the reflection depth directly from settings
                );

                const color = Math.floor(240 * light);
                const idx = (y * this.canvas.width + x) * 4;
                
                data[idx] = color;
                data[idx + 1] = color;
                data[idx + 2] = color;
                data[idx + 3] = 255;
            }
        }

        this.ctx.putImageData(this.imageData, 0, 0);
        this.frameCount++;
    }
}