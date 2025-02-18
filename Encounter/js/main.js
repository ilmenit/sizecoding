class App {
    constructor() {
        this.canvas = document.getElementById('screen');
        this.controls = new Controls();
        this.renderer = new Renderer(this.canvas);
        
        requestAnimationFrame(this.render.bind(this));
    }

    render() {
        this.renderer.render(this.controls.getSettings());
        requestAnimationFrame(this.render.bind(this));
    }
}

// Global app instance
let app;

window.addEventListener('load', () => {
    app = new App();
});