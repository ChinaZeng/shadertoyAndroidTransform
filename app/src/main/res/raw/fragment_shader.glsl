precision mediump float;//精度 为float

varying vec2      texCoord;//纹理位置  接收于vertex_shader

//这些是shaderToy的参数
uniform vec3      iResolution;// viewport resolution (in pixels)
uniform float     iTime;// shader playback time (in seconds)
uniform int       iFrame;                // shader playback frame
uniform vec4      iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;// input channel. XX = 2D/Cube
uniform sampler2D iChannel1;// input channel. XX = 2D/Cube
uniform sampler2D iChannel2;// input channel. XX = 2D/Cube

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0, 2, 4));
    // Output to screen
    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(gl_FragColor, texCoord);
}