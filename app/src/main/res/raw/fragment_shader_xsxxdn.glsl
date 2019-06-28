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


//https://www.shadertoy.com/view/XsXXDn

#define t iTime
#define r iResolution.xy

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec3 c;
    float l,z=t;
    for(int i=0;i<3;i++) {
        vec2 uv,p=fragCoord.xy/r;
        uv=p;
        p-=.5;
        p.x*=r.x/r.y;
        z+=.07;
        l=length(p);
        uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z*2.));
        c[i]=.01/length(abs(mod(uv,1.)-.5));
    }
    fragColor=vec4(c/l,t);
}
void main() {
    mainImage(gl_FragColor, texCoord);
}