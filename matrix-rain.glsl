// Faint Matrix "digital rain" background for Ghostty.
// The rain draws only on dark background pixels, so text stays readable.
//
// Tweak these values:
const float CELL_W  = 12.0;   // glyph cell width in px
const float CELL_H  = 18.0;   // glyph cell height in px
const float OPACITY = 0.18;   // overall strength (0.0 - 1.0). Lower = fainter.
const float TRAIL   = 20.0;   // trail length in cells
const float SPEED   = 0.6;    // global speed multiplier
const vec3  GREEN   = vec3(0.10, 1.00, 0.35);
const vec3  HEAD    = vec3(0.75, 1.00, 0.85);

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Procedural 5x7 pseudo-glyph that changes over time.
float glyph(vec2 cell, vec2 lp, float t) {
    vec2 g = lp * vec2(7.0, 9.0) - vec2(1.0);   // 1-dot margin around glyph
    if (g.x < 0.0 || g.y < 0.0 || g.x >= 5.0 || g.y >= 7.0) return 0.0;
    vec2 gi = floor(g);
    float rate = 0.3 + hash12(cell + 3.7) * 2.0;
    float seed = floor(t * rate + hash12(cell + 7.1) * 10.0);
    float on = step(0.45, hash12(cell * 17.0 + gi * 3.1 + mod(seed, 97.0) * 13.7));
    vec2 f = fract(g);
    float dotMask = smoothstep(0.0, 0.2, f.x) * smoothstep(1.0, 0.8, f.x)
                  * smoothstep(0.0, 0.2, f.y) * smoothstep(1.0, 0.8, f.y);
    return on * dotMask;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    // Top-down pixel coordinates (Ghostty's fragCoord origin is top-left).
    vec2 p = fragCoord;
    vec2 cs = vec2(CELL_W, CELL_H);
    vec2 cell = floor(p / cs);
    vec2 lp = fract(p / cs);
    float rows = iResolution.y / CELL_H;

    float intensity = 0.0;
    float head = 0.0;
    // Two independent drops per column.
    for (int i = 0; i < 2; i++) {
        float fi = float(i);
        float speed = (3.0 + hash12(vec2(cell.x, fi * 31.0 + 1.0)) * 9.0) * SPEED;
        float span  = rows + TRAIL + hash12(vec2(cell.x, fi + 5.0)) * rows;
        float pos   = mod(iTime * speed + hash12(vec2(cell.x, fi + 9.0)) * span, span);
        float d = floor(pos) - cell.y;
        if (d >= 0.0 && d < TRAIL) {
            float k = 1.0 - d / TRAIL;
            intensity = max(intensity, k * k);
            if (d < 1.0) head = 1.0;
        }
    }

    float g = glyph(cell, lp, iTime);
    vec3 rain = mix(GREEN, HEAD, head) * g * intensity;

    // Draw rain only where the terminal is dark (background), not over text.
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float mask = 1.0 - smoothstep(0.08, 0.30, lum);

    fragColor = vec4(term.rgb + rain * OPACITY * mask, term.a);
}
