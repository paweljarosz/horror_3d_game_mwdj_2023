varying highp vec4 var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_light;

uniform highp sampler2D DIFFUSE_TEXTURE;
uniform highp sampler2D DATA_TEXTURE;
uniform highp sampler2D LIGHT_TEXTURE;
uniform highp sampler2D SPECULAR_TEXTURE;
uniform highp sampler2D NORMAL_TEXTURE;

uniform highp vec4 surface;

varying highp vec3 camera_position;
varying highp vec3 world_position;
varying highp vec3 view_position;
varying highp vec3 world_normal;
varying highp vec2 texture_coord;
varying highp vec2 light_map_coord;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(DIFFUSE_TEXTURE, var_texcoord0.xy) * tint_pm;

    // Diffuse light calculations
    vec3 ambient_light = vec3(0.2);
    vec3 diff_light = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light = max(dot(var_normal,diff_light), 0.0) + ambient_light;
    diff_light = clamp(diff_light, 0.0, 1.0);

    gl_FragColor = vec4(color.rgb*diff_light,1.0);
}

