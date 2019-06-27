attribute vec4 av_Position;//顶点位置
attribute vec2 af_Position;//纹理位置
varying vec2 texCoord;//纹理位置  与fragment_shader交互
void main() {
    texCoord = af_Position;
    gl_Position = av_Position;
}