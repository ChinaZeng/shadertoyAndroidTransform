precision mediump float;//精度 为float

varying vec2      texCoord;//纹理位置  接收于vertex_shader

//这些是shaderToy的参数
uniform vec3      iResolution;// viewport resolution (in pixels)
uniform float     iTime;// shader playback time (in seconds)
uniform int       iFrame;// shader playback frame
uniform vec4      iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;// input channel. XX = 2D/Cube
uniform sampler2D iChannel1;// input channel. XX = 2D/Cube
uniform sampler2D iChannel2;// input channel. XX = 2D/Cube


//https://www.shadertoy.com/view/XdlSDs
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0*fragCoord.xy-iResolution.xy)/iResolution.y;
    float tau = 3.1415926535*2.0;
    float a = atan(p.x, p.y);
    float r = length(p)*1.5;
    vec2 uv = vec2(a/tau, r);

    //get the color
    float xCol = (uv.x - (iTime / 3.0)) * 3.0;
    xCol = mod(xCol, 3.0);
    vec3 horColour = vec3(0.25, 0.25, 0.25);

    if (xCol < 1.0) {
        horColour.r += 1.0 - xCol;
        horColour.g += xCol;
    }
    else if (xCol < 2.0) {
        xCol -= 1.0;
        horColour.g += 1.0 - xCol;
        horColour.b += xCol;
    }
    else {
        xCol -= 2.0;
        horColour.b += 1.0 - xCol;
        horColour.r += xCol;
    }

    // draw color beam
    uv = (2.0 * uv) - 1.0;
    float beamWidth = (0.7+0.5*cos(uv.x*10.0*tau*0.15*clamp(floor(5.0 + 0.0*cos(iTime)), 0.0, 40.0))) * abs(1.0 / (30.0 * uv.y));
    vec3 horBeam = vec3(beamWidth);
    fragColor = vec4(((horBeam) * horColour), 1.0);
}

void main() {
    mainImage(gl_FragColor, texCoord * iResolution.xy);
}