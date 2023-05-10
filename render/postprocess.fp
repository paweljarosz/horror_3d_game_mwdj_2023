#define SAMPLES 32.

varying mediump vec2 var_texcoord0;

uniform lowp vec4 enable_effects1;
uniform lowp vec4 enable_effects2;

uniform lowp vec4 effects1;
uniform lowp vec4 effects2;
uniform lowp vec4 effects3;

uniform lowp sampler2D tex0;
//uniform lowp vec4 tint;

#define BLOOM enable_effects1.x
#define CHROMATIC enable_effects1.y
#define VIGNETTE enable_effects1.z
#define NOISE enable_effects1.w

#define VHS enable_effects2.x
#define SCANLINES enable_effects2.y
#define CRT enable_effects2.z
#define TIME enable_effects2.w

#define BLOOM_RADIUS effects1.x
#define BLOOM_INTENSITY effects1.y
#define BLOOM_THRESHOLD effects1.z
#define CHROMATIC_STRENGTH effects1.w

#define VIG_STRENGTH effects2.x
#define VIG_INTENSITY effects2.y
#define NOISE_STRENGTH effects2.z
#define DIST_STRENGTH effects2.w

#define SCAN_STRENGTH effects3.x
#define CRT_CURVE effects3.y

float noise(vec2 uv)
{
    return fract(sin(uv.x*12.9898+uv.y*78.233)*437.585453*TIME);
}

vec4 vhs(vec2 uv)
{
    vec2 tcoord = uv;
    tcoord.x += sin(TIME*noise(uv));
    return texture2D(tex0 , tcoord)*DIST_STRENGTH;
}

float vig(vec2 uv)
{
    uv *= 1.0 - uv;
    return ( pow(uv.x*uv.y*VIG_INTENSITY*10., VIG_STRENGTH) );
}

vec3 chromatic(vec2 uv, float offset)
{
    float _r = texture2D( tex0, vec2(uv.x+offset, uv.y)).r;
    float _g = texture2D( tex0, uv).g;
    float _b = texture2D( tex0, vec2(uv.x-offset, uv.y)).b;
    return vec3(_r,_g,_b);
}

vec2 warp(vec2 uv){
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta.xy, delta.xy);
    float delta4 = delta2 * delta2;
    float delta_offset = delta4 * CRT_CURVE;

    return uv + delta * delta_offset;
}

vec4 blur(vec2 uv, vec2 texel)
{
    float total = 0.;
    float rad = 1.;
    mat2 ang = mat2(.73736882209777832,-.67549037933349609,.67549037933349609,.73736882209777832);
    vec2 point = normalize(fract(cos(uv*mat2(195,174,286,183))*742.)-.5)*(BLOOM_RADIUS/sqrt(SAMPLES));
    vec4 amount = vec4(0);

    for ( float i=0.; i<SAMPLES; i++ )
    {
        point*=ang;
        rad+=1./rad;
        vec4 samp = texture2D(tex0, uv + point * (rad-1.) * texel);

        float mul = 1.;
        float lum = ( samp.r+samp.g+samp.b )/3.;
        if ( lum < BLOOM_THRESHOLD ){ mul = 0.; }

        amount += samp*(1./rad)*mul;
        total+=(1./rad);
    }
    amount /= total;
    return amount*BLOOM_INTENSITY;
}

// -- SSAO

// SSAO (Screen Space AO) - by moranzcw - 2021
// Email: moranzcw@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265359
#define AOradius 2.0
#define Samples 64.0

// --------------------------------------
// oldschool rand() from Visual Studio
// --------------------------------------
int   seed = 1;
void  srand(int s ) { seed = s; }
int   rand(void)  { seed=seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
// --------------------------------------
// hash by Hugo Elias
// --------------------------------------
int hash( int n ) { n=(n<<13)^n; return n*(n*n*15731+789221)+1376312589; }

vec3 sphereVolumeRandPoint()
{
    vec3 p = vec3(frand(),frand(),frand()) * 2.0 - 1.0;
    while(length(p)>1.0)
    {
        p = vec3(frand(),frand(),frand()) * 2.0 - 1.0;
    }
    return p;
}

float depth(sampler2D tex, vec2 coord)
{
    //vec2 uv = coord;//*vec2(iResolution.y/iResolution.x,1.0);
    return texture2D(tex, coord).x;
}

float SSAO(sampler2D tex, vec2 coord)
{
    float cd = depth(tex, coord);
    float screenRadius = 0.5 * (AOradius / cd) / 0.53135;
    float li = 0.0;
    float count = 0.0;
    for(float i=0.0; i<Samples; i++)
    {
        vec3 p = sphereVolumeRandPoint() * frand();
        vec2 sp = vec2(coord.x + p.x * screenRadius, coord.y + p.y * screenRadius);
        float d = depth(tex, sp);
        float at = pow(length(p)-1.0, 2.0);
        li += step(cd + p.z * AOradius, d) * at;
        count += at;
    }
    return li / count;
}

vec3 background(float yCoord) 
{	    
    return mix(vec3(0.1515, 0.2375, 0.5757), vec3(0.0546, 0.0898, 0.1953), yCoord);
}

void main()
{
    vec2 uv = var_texcoord0;
    if (CRT > 0.5) uv = warp(uv);

    /*/ init random seed
    ivec2 q = ivec2(var_texcoord0);
    srand( hash(q.x+hash(q.y+hash(1117*1))));

    // coordinate
    //vec2 uv = fragCoord/iResolution.xy;
    //vec2 coord = fragCoord/iResolution.y;

    float d = depth(tex0, uv);
    vec3 ao = vec3(0.4) + step(d, 1e5-1.0) * vec3(0.8) * SSAO(tex0, var_texcoord0);
    vec3 bg_color = mix(background(uv.y), ao, 1.0 - smoothstep(0.0, 0.99, d*d/1e3));;
    bg_color = pow(bg_color,vec3(1.0/2.2)); // gamma
    vec4 color = vec4(bg_color, 1.0);*/

    vec4 color = texture2D(tex0, uv);

    if (CHROMATIC > 0.5) color.rgb = /*tint.rgb * */ chromatic(uv, CHROMATIC_STRENGTH * 0.01);
    if (SCANLINES > 0.5) color.rgb *= (1.-SCAN_STRENGTH)+(sin(uv.y*1024.)*SCAN_STRENGTH);
    if (BLOOM > 0.5) color.rgb += blur(uv, vec2(1.)).rgb;
    if (NOISE > 0.5) color.rgb += noise(uv) * NOISE_STRENGTH;
    if (VHS > 0.5) color += vhs(uv);
    if (VIGNETTE > 0.5) color.rgb *= vig(uv);

    // cutoff edges
    if (CRT > 0.5 && ( uv.x<0.||uv.y<0.||uv.x>1.||uv.y>1. ))
    {
        color.rgb *= 0.;
    }


    // Pre-multiply alpha since all runtime textures already are
    gl_FragColor = vec4(color.rgb,1.0);
}
