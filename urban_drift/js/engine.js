class Engine {
    constructor(settings) {
        this.updateSettings(settings);
    }

    updateSettings(settings) {
        this.settings = settings;
    }

    sdf(px, py, pz) {
        const gx = Math.floor(px);
        const gz = Math.floor(pz);
        let d = py;
        
        for (let i = 0; i < 9; i++) {
            const dx = Math.floor(i / 3) - 1;
            const dz = (i % 3) - 1;

            const gxDx = gx + dx;
            const pxOffset = px - (gxDx + 0.5);
            const absX = MathUtils.abs(pxOffset) - this.settings.buildingSize;

            const h2 = Math.fround(((gxDx ^ (gz + dz)) & 7) / 4);
            const pzOffset = pz - ((gz + dz) + 0.5);
            const absZ = MathUtils.abs(pzOffset) - this.settings.buildingSize;
            const absY = MathUtils.abs(py - h2) - h2;

            d = MathUtils.min(d, MathUtils.max(absX, MathUtils.max(absY, absZ)));
        }
        return d;
    }

    raycast(px, py, pz, rdX, rdY, rdZ, reflectionDepth = -1) {
        let dist = 0;
        const day_time = this.calculateDayTime();

        for (let step = 0; step < this.settings.raycastSteps; step++) {
            let h = this.sdf(px, py, pz);

            if (h < this.settings.epsilon) {
                const nx = this.sdf(px + this.settings.epsilon, py, pz) - h;
                const ny = this.sdf(px, py + this.settings.epsilon, pz) - h;
                const nz = this.sdf(px, py, pz + this.settings.epsilon) - h;
                const nl = 1.0078125 / MathUtils.sqrt(nx * nx + ny * ny + nz * nz);

                let light = (nx + ny * day_time - nz * day_time) * nl;

                if (this.settings.shadowsEnabled) {
                    let t = 0.1248779296875;
                    let shadow_hit = false;
                    
                    for (let j = 0; j < this.settings.shadowQuality && !shadow_hit; j++) {
                        const sh = this.sdf(
                            px + t,
                            py + t * day_time,
                            pz - t * day_time
                        );
                        if (sh < this.settings.epsilon) {
                            light /= 8;
                            shadow_hit = true;
                        } else {
                            light = MathUtils.min(light, sh * (8/t));
                            t = t + sh;
                        }
                    }
                }

                if (MathUtils.abs(ny * nl) < this.settings.epsilon) {
                    const w = MathUtils.abs(nx) > MathUtils.abs(nz) ? pz : px;
                    const is_window_frame = MathUtils.abs(MathUtils.fmod(4 * w, 1)) <= this.settings.windowSizeH;
                    const is_window_frame2 = MathUtils.abs(MathUtils.fmod(4 * py, 1)) <= this.settings.windowSizeV;
                    
                    if (is_window_frame && is_window_frame2) {
                        if (this.settings.reflectionsEnabled && reflectionDepth !== 0) {
                            const ndotrd = 2 * (nx * rdX + ny * rdY + nz * rdZ) * nl * nl;
                            const rrX = rdX - ndotrd * nx;
                            const rrY = rdY - ndotrd * ny;
                            const rrZ = rdZ - ndotrd * nz;

                            const nextDepth = reflectionDepth > 0 ? reflectionDepth - 1 : reflectionDepth;
                            const reflLight = this.raycast(
                                px + rrX * this.settings.epsilon,
                                py + rrY * this.settings.epsilon,
                                pz + rrZ * this.settings.epsilon,
                                rrX, rrY, rrZ,
                                nextDepth
                            );

                            light = MathUtils.min((light + reflLight) * 0.5, 1);
                        }

                        if (this.settings.windowLightsEnabled) {
                            const wx = Math.floor(w * 16);
                            const wy = Math.floor(py * 16);

                            if (((wx ^ wy ^ Math.floor(wx / 2)) & 28) === 0) {
                                light = 3 + (light - 3) * day_time;
                            }
                        }
                    }
                }

                light += (day_time - light) / 8 * dist;
                return MathUtils.min(MathUtils.max(light, 0), 0.875);
            }

            h /= 4;
            px += rdX * h;
            py += rdY * h;
            pz += rdZ * h;
            dist += h;
        }
        return day_time;
    }

    calculateDayTime() {
        if (this.settings.autoDaytime) {
            return MathUtils.abs(MathUtils.fmod(MathUtils.time() / this.settings.daySpeed, 2) - 1);
        }
        return this.settings.dayTime / 100;
    }
}