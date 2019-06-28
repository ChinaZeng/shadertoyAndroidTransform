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


//https://www.shadertoy.com/view/llGXWc

/*

    Geodesic tiling
    ---------------

    I've been looking for a way to create geodesic geometry
    (subdivided polyhedra) in sdf land for a while.

    I'd initially tried folding/mirroring as with knighty's
    icosahedron method below, however I never found a way
    of generalising it, and getting a cell id was painful:

    // Subdivided icosahedron
    https://www.shadertoy.com/view/lsV3RV

    // With cell ids
    https://www.shadertoy.com/view/4syGDG

    // Using hexagons
    https://www.shadertoy.com/view/4tG3zW

    This method allows any level of subdivision, and the
    tiling approach allows creating interesting geometry
    with variation based on position:

    // Animated hexagons
    https://www.shadertoy.com/view/llVXRd

    One drawback is you don't get the point's full absolute
    position in space, as everything is mirrored around
    the icosahedron's schwarz triangle, you can see this
    in the colouring. This is fixed here:

    // Version with full absolute positions
    https://www.shadertoy.com/view/XtKSWc

*/


// --------------------------------------------------------
// Icosahedral domain mirroring
// knighty https://www.shadertoy.com/view/MsKGzw
//
// Also get the face normal, and tangent planes used to
// calculate the uv coordinates later.
// --------------------------------------------------------

const float  PI =  3.14159265359f;

vec3 facePlane;
vec3 uPlane;
vec3 vPlane;

int Type=5;
vec3 nc;
vec3 pab;
vec3 pbc;
vec3 pca;

void init() {
    float cospin=cos(PI/float(Type)), scospin=sqrt(0.75-cospin*cospin);
    nc=vec3(-0.5, -cospin, scospin);
    pbc=vec3(scospin, 0., 0.5);
    pca=vec3(0., scospin, cospin);
    pbc=normalize(pbc); pca=normalize(pca);
    pab=vec3(0, 0, 1);

    facePlane = pca;
    uPlane = cross(vec3(1, 0, 0), facePlane);
    vPlane = vec3(1, 0, 0);
}

void fold(inout vec3 p) {
    for (int i=0;i<5 /*Type*/;i++){
        p.xy = abs(p.xy);
        p -= 2. * min(0., dot(p, nc)) * nc;
    }
}


// --------------------------------------------------------
// Triangle tiling
// Adapted from mattz https://www.shadertoy.com/view/4d2GzV
//
// Finds the closest triangle center on a 2D plane
// --------------------------------------------------------

const float sqrt3 = 1.7320508075688772;
const float i3 = 0.5773502691896258;

const mat2 cart2tri = mat2(1, 0, i3, 2. * i3);
const mat2 tri2cart = mat2(1, 0, -.5, .5 * sqrt3);

vec2 closestTri(vec2 p) {
    p = cart2tri * p;
    vec2 pf = fract(p);
    vec2 v = vec2(1./3., 2./3.);
    vec2 tri = mix(v, v.yx, step(pf.y, pf.x));
    tri += floor(p);
    tri = tri2cart * tri;
    return tri;
}


// --------------------------------------------------------
// Geodesic tiling
//
// Finds the closest triangle center on the surface of a
// sphere:
//
// 1. Intersect position with the face plane
// 2. Convert that into 2D uv coordinates
// 3. Find the closest triangle center (tile the plane)
// 4. Convert back into 3D coordinates
// 5. Project onto a unit sphere (normalize)
//
// You can use any tiling method, such as one that returns
// hex centers or adjacent cells, so you can create more
// interesting geometry later.
// --------------------------------------------------------

// Intersection point of vector and plane
vec3 intersection(vec3 n, vec3 planeNormal, float planeOffset) {
    float denominator = dot(planeNormal, n);
    float t = (dot(vec3(0), planeNormal) + planeOffset) / -denominator;
    return n * t;
}

// 3D position -> 2D (uv) coordinates on the icosahedron face
vec2 icosahedronFaceCoordinates(vec3 p) {
    vec3 i = intersection(normalize(p), facePlane, -1.);
    return vec2(dot(i, uPlane), dot(i, vPlane));
}

// 2D (uv) coordinates -> 3D point on a unit sphere
vec3 faceToSphere(vec2 facePoint) {
    return normalize(facePlane + (uPlane * facePoint.x) + (vPlane * facePoint.y));
}

// Edge length of an icosahedron with an inscribed sphere of radius of 1
const float edgeLength = 1. / ((sqrt(3.) / 12.) * (3. + sqrt(5.)));
// Inner radius of the icosahedron's face
const float faceRadius = (1./6.) * sqrt(3.) * edgeLength;

// Closest geodesic point (triangle center) on unit sphere's surface
vec3 geodesicTri(vec3 p, float subdivisions) {
    // faceRadius is used as a scale multiplier so that our triangles
    // always stop at the edge of the face
    float uvScale = subdivisions / faceRadius / 2.;

    vec2 uv = icosahedronFaceCoordinates(p);
    vec2 tri = closestTri(uv * uvScale);
    return faceToSphere(tri / uvScale);
}


// --------------------------------------------------------
// Modelling
// --------------------------------------------------------

struct Model {
    float dist;
    vec3 color;
};

void spin(inout vec3 p) {
    float r = iTime / 6.;
    mat2 rot = mat2(cos(r), -sin(r), sin(r), cos(r));
    p.xz *= rot;
    p.zy *= rot;
}

// Smooth transition between subdivisions
float animSubdivitions(float start, float end) {

    float t = mod(iTime, 2.) - 1. + .5;
    t = clamp(t, 0., 1.);
    t = cos(t * PI + PI) * .5 + .5;

    float n = floor(iTime / 2.);

    float diff = end - start;
    n = mod(n, diff + 1.);

    if (n == diff) {
        return end - diff * t;
    }

    return n + start + t;
}

// The actual model
Model map(vec3 p) {

    // Spin the whole model
    spin(p);

    // Fold space into an icosahedron,
    // disable this to get a better idea of what
    // geodesicTri is doing
    fold(p);

    float subdivisions = animSubdivitions(1., 10.);
    vec3 point = geodesicTri(p, subdivisions);

    float sphere = length(p - point) - .195 / subdivisions;

    // Use red/green to indicate point's position,
    // you can see that space always mirrored at the
    // Icosahedron's schwarz triangle
    vec3 color = vec3(0, point.yx * 3. + .5);
    color = clamp(color, 0., 1.);

    return Model(sphere, color);
}


// --------------------------------------------------------
// Ray Marching
// Adapted from cabbibo https://www.shadertoy.com/view/Xl2XWt
// --------------------------------------------------------

const float MAX_TRACE_DISTANCE = 8.;
const float INTERSECTION_PRECISION = .001;
const int NUM_OF_TRACE_STEPS = 100;

struct CastRay {
    vec3 origin;
    vec3 direction;
};

struct Ray {
    vec3 origin;
    vec3 direction;
    float len;
};

struct Hit {
    Ray ray;
    Model model;
    vec3 pos;
    bool isBackground;
    vec3 normal;
    vec3 color;
};

vec3 calcNormal(in vec3 pos){
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 nor = vec3(
    map(pos+eps.xyy).dist - map(pos-eps.xyy).dist,
    map(pos+eps.yxy).dist - map(pos-eps.yxy).dist,
    map(pos+eps.yyx).dist - map(pos-eps.yyx).dist);
    return normalize(nor);
}

Hit raymarch(CastRay castRay){

    float currentDist = INTERSECTION_PRECISION * 2.0;
    Model model;

    Ray ray = Ray(castRay.origin, castRay.direction, 0.);

    for (int i=0; i< NUM_OF_TRACE_STEPS; i++){
        if (currentDist < INTERSECTION_PRECISION || ray.len > MAX_TRACE_DISTANCE) {
            break;
        }
        model = map(ray.origin + ray.direction * ray.len);
        currentDist = model.dist;
        ray.len += currentDist;
    }

    bool isBackground = false;
    vec3 pos = vec3(0);
    vec3 normal = vec3(0);
    vec3 color = vec3(0);

    if (ray.len > MAX_TRACE_DISTANCE) {
        isBackground = true;
    } else {
        pos = ray.origin + ray.direction * ray.len;
        normal = calcNormal(pos);
    }

    return Hit(ray, model, pos, isBackground, normal, color);
}


// --------------------------------------------------------
// Rendering
// --------------------------------------------------------

vec3 render(Hit hit){
    if (hit.isBackground) {
        return vec3(0);
    }
    vec3 color = hit.model.color;
    color += sin(dot(hit.normal, vec3(0, 1, 0))) * .2;// lighting
    color *= 1. - clamp(hit.ray.len * .4 - .8, 0., 1.);// fog
    return color;
}


// --------------------------------------------------------
// Camera
// https://www.shadertoy.com/view/Xl2XWt
// --------------------------------------------------------

mat3 calcLookAtMatrix(in vec3 ro, in vec3 ta, in float roll)
{
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(sin(roll), cos(roll), 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    init();

    vec2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;

    vec3 camPos = vec3(0, 0, 2.5);
    vec3 camTar = vec3(0);
    float camRoll = 0.;
    mat3 camMat = calcLookAtMatrix(camPos, camTar, camRoll);

    vec3 rd = normalize(camMat * vec3(p.xy, 2.));
    Hit hit = raymarch(CastRay(camPos, rd));

    vec3 color = render(hit);
    fragColor = vec4(color, 1.0);
}

void main() {
    mainImage(gl_FragColor, texCoord * iResolution.xy);
}
