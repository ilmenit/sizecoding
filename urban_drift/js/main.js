// Main application class
class App {
    constructor() {
        this.canvas = document.getElementById('canvas');
        this.controls = new Controls();
        this.engine = new Engine(this.controls.getSettings());
        this.renderer = new Renderer(this.canvas, this.engine);
        
        const initialSettings = this.controls.getSettings();
        this.renderer.resize(initialSettings.resolution.width, initialSettings.resolution.height);
        
        requestAnimationFrame(this.render.bind(this));
    }

    render() {
        this.renderer.render(this.controls.getSettings());
        requestAnimationFrame(this.render.bind(this));
    }
}

// Global app instance (needed for controls callbacks)
let app;

// Initialize when the page loads
window.addEventListener('load', () => {
    app = new App();
});