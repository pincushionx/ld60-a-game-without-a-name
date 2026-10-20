shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Textures
uniform sampler2D texture_water : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_grass : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_mountain : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

// Tiling/Scaling
uniform vec3 texture_scale = vec3(1.0);

// Height Blending Parameters
uniform float water_level = 0.5;
uniform float mountain_level = 1.5;
uniform float blend_sharpness = 10.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

// Triplanar Sampling Function
vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    vec4 samp = vec4(0.0);
    samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
    samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
    samp += texture(p_sampler, p_triplanar_pos.zy) * p_weights.x;
    return samp;
}

void fragment() {
    // Calculate triplanar weights based on normal
    vec3 triplanar_weights = pow(abs(v_world_normal), vec3(blend_sharpness));
    triplanar_weights /= dot(triplanar_weights, vec3(1.0));
    
    vec3 triplanar_pos = v_world_pos * texture_scale;

    // Sample textures
    vec4 col_water = triplanar_texture(texture_water, triplanar_weights, triplanar_pos);
    vec4 col_grass = triplanar_texture(texture_grass, triplanar_weights, triplanar_pos);
    vec4 col_mountain = triplanar_texture(texture_mountain, triplanar_weights, triplanar_pos);

    // Height-based blending
    float height = v_world_pos.y;
    
    // Blend Water to Grass
    float blend_w_g = smoothstep(water_level - 0.1, water_level + 0.1, height);
    vec3 final_color = mix(col_water.rgb, col_grass.rgb, blend_w_g);
    
    // Blend Grass to Mountain
    float blend_g_m = smoothstep(mountain_level - 0.2, mountain_level + 0.2, height);
    final_color = mix(final_color, col_mountain.rgb, blend_g_m);

    ALBEDO = final_color;
    
    // Optional: Roughness adjustment
    ROUGHNESS = 1.0;//mix(0.1, 0.9, blend_w_g); 
}
