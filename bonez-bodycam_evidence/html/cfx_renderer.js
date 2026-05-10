// bonez-bodycam_evidence | html/cfx_renderer.js
// ES module: sets up window.MainRender using CfxTexture (FiveM game framebuffer).
// Pattern identical to bbs_bodycam/script.js — no stutter, no GPU readback.

import {
    OrthographicCamera,
    Scene,
    WebGLRenderTarget,
    LinearFilter,
    NearestFilter,
    RGBAFormat,
    UnsignedByteType,
    CfxTexture,
    ShaderMaterial,
    PlaneBufferGeometry,
    Mesh,
    WebGLRenderer,
} from '/module/Three.js';

var isAnimated = false;

class GameRender {
    constructor() {
        window.addEventListener('resize', () => this.resize());

        const gameTexture = new CfxTexture();
        gameTexture.needsUpdate = true;

        const material = new ShaderMaterial({
            uniforms: { tDiffuse: { value: gameTexture } },
            vertexShader: `
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`,
            fragmentShader: `
varying vec2 vUv;
uniform sampler2D tDiffuse;
void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);
}`,
        });

        this.material    = material;
        this.renderer    = null;
        this.canvas      = null;
        this.sceneRTT    = null;
        this.cameraRTT   = null;
        this.rtTexture   = null;
        this.gameTexture = gameTexture;

        this.animate = this.animate.bind(this);
        requestAnimationFrame(this.animate);
    }

    resize() {
        if (!this.canvas) return;

        const width  = this.canvas.width;
        const height = this.canvas.height;

        const cameraRTT = new OrthographicCamera(
            width / -2, width / 2, height / 2, height / -2, -10000, 10000
        );
        cameraRTT.position.z = 0;
        cameraRTT.setViewOffset(width, height, 0, 0, width, height);
        this.cameraRTT = cameraRTT;

        this.sceneRTT = new Scene();
        const plane = new PlaneBufferGeometry(width, height);
        const quad  = new Mesh(plane, this.material);
        quad.position.z = -100;
        this.sceneRTT.add(quad);

        this.rtTexture = new WebGLRenderTarget(width, height, {
            minFilter: LinearFilter,
            magFilter: NearestFilter,
            format:    RGBAFormat,
            type:      UnsignedByteType,
        });

        if (this.renderer) {
            this.renderer.setSize(width, height);
        }
    }

    animate() {
        requestAnimationFrame(this.animate);
        if (isAnimated && this.renderer && this.sceneRTT && this.cameraRTT) {
            this.renderer.render(this.sceneRTT, this.cameraRTT);
        }
    }

    renderToTarget(element) {
        this.canvas   = element;
        this.renderer = new WebGLRenderer({ canvas: this.canvas });
        this.resize();
        isAnimated = true;
    }

    stop() {
        isAnimated = false;
        this.canvas   = null;
        this.renderer = null;
    }
}

setTimeout(function () {
    window.MainRender = new GameRender();
}, 500);
