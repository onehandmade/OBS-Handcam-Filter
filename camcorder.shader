// camcorder.shader
// "Camcorder" - 2005 consumer camcorder (MiniDV / Handycam-style) filter for OBS.
// For the obs-shaderfilter plugin: add a "User-defined shader" filter to your
// handcam source, tick "Load shader from file", and pick this file.
//
// Effects: 480-line video, low-resolution color (chroma bleed), edge sharpening
// halos, interlace combing and scanlines, tape wobble, rolling tracking glitch
// bands, tape noise, warm saturated color, bloomed highlights, blinking REC dot.

uniform float res_y<
    string label = "Vertical Resolution (lines)";
    string widget_type = "slider";
    float minimum = 240.0;
    float maximum = 720.0;
    float step = 1.0;
> = 480.0;

uniform float chroma_div<
    string label = "Color Smear (chroma divider)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 8.0;
    float step = 0.1;
> = 4.0;

uniform float softness<
    string label = "Softness";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.35;

uniform float sharpen<
    string label = "Edge Sharpening (halos)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 2.0;
    float step = 0.01;
> = 0.8;

uniform float interlace<
    string label = "Interlace Combing (pixels)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 3.0;
    float step = 0.05;
> = 1.0;

uniform float scanlines<
    string label = "Scanlines";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.4;

uniform float saturation<
    string label = "Saturation";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 2.0;
    float step = 0.01;
> = 1.15;

uniform float contrast<
    string label = "Contrast";
    string widget_type = "slider";
    float minimum = 0.5;
    float maximum = 1.5;
    float step = 0.01;
> = 1.05;

uniform float brightness<
    string label = "Brightness";
    string widget_type = "slider";
    float minimum = -0.3;
    float maximum = 0.3;
    float step = 0.005;
> = 0.0;

uniform float blowout<
    string label = "Highlight Blowout";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 2.0;
    float step = 0.01;
> = 0.5;

uniform float warm_cast<
    string label = "Warm Cast (- cool, + warm)";
    string widget_type = "slider";
    float minimum = -1.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.25;

uniform float wobble<
    string label = "Tape Wobble";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 3.0;
    float step = 0.01;
> = 1.0;

uniform float glitch<
    string label = "Tracking Glitch Bands";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.4;

uniform float noise_amount<
    string label = "Video Noise";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.4;

uniform float tape_noise<
    string label = "Tape Line Noise";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.4;

uniform float vignette<
    string label = "Vignette";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 2.0;
    float step = 0.01;
> = 0.5;

uniform float show_rec<
    string label = "Blinking REC Dot (0 off, 1 on)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 1.0;
> = 1.0;

uniform float rec_size<
    string label = "REC Dot Size";
    string widget_type = "slider";
    float minimum = 0.5;
    float maximum = 4.0;
    float step = 0.1;
> = 1.5;

float hash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float luma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Video grid at camcorder line count, keeping the source aspect ratio.
    float aspect = uv_size.y / uv_size.x;
    float2 res = float2(res_y / aspect, res_y);
    float line_id = floor(uv.y * res.y);
    float frame_seed = floor(elapsed_time * 30.0);
    float field = fmod(line_id, 2.0);

    // Tape wobble: slow horizontal sway.
    float wob = sin(uv.y * 40.0 + elapsed_time * 2.0) * wobble * 0.002;

    // Tracking glitch: a band that rolls up the picture, on about half of its passes.
    float band_speed = 0.08;
    float band_pos = frac(elapsed_time * band_speed);
    float band_active = step(0.5, hash21(float2(floor(elapsed_time * band_speed), 7.0)));
    float in_band = saturate(1.0 - abs(uv.y - band_pos) / 0.04) * band_active * glitch;
    float band_shift = (hash21(float2(line_id, frame_seed)) - 0.5) * in_band * 0.1;

    uv.x += wob + band_shift;

    // Luma: sampled on the video grid with interlace combing between fields.
    float2 cell = floor(float2(uv.x * res.x, uv.y * res.y));
    float2 px = 1.0 / res;
    float2 puv = (cell + 0.5) / res;
    puv.x += (field * 2.0 - 1.0) * interlace * px.x * 0.5;

    float4 s0 = image.Sample(textureSampler, puv);
    float y0 = luma(s0.rgb);
    float y_blur = luma(image.Sample(textureSampler, puv - float2(px.x, 0.0)).rgb);
    y_blur += luma(image.Sample(textureSampler, puv + float2(px.x, 0.0)).rgb);
    y_blur += luma(image.Sample(textureSampler, puv - float2(0.0, px.y)).rgb);
    y_blur += luma(image.Sample(textureSampler, puv + float2(0.0, px.y)).rgb);
    y_blur *= 0.25;

    // Soft lens, then electronic edge sharpening (the bright and dark halos).
    float y = lerp(y0, y_blur, softness) + (y0 - y_blur) * sharpen;

    // Chroma: much lower horizontal resolution than luma, so colors smear sideways.
    float2 cres = float2(res.x / chroma_div, res.y);
    float2 cuv = (floor(float2(uv.x * cres.x, uv.y * cres.y)) + 0.5) / cres;
    float3 cc = image.Sample(textureSampler, cuv).rgb;
    float3 chroma = (cc - luma(cc)) * saturation;

    float3 c = float3(y, y, y) + chroma;

    // Exposure: contrast, brightness, bloomed highlights.
    c = (c - 0.5) * contrast + 0.5 + brightness;
    c += max(c - 0.7, 0.0) * blowout;

    // Warm consumer white balance.
    c.r += warm_cast * 0.05;
    c.g += warm_cast * 0.015;
    c.b -= warm_cast * 0.06;

    // Interlace scanlines.
    c *= 1.0 - scanlines * 0.2 * field;

    // Blinking REC dot in the top-left corner (1 second blink).
    float2 dd = (v_in.uv - float2(0.06, 0.09)) * uv_size;
    float rec_radius = rec_size * uv_size.y * 0.01;
    float blink = step(0.5, frac(elapsed_time));
    float dot_mask = show_rec * blink * (1.0 - smoothstep(rec_radius - 1.0, rec_radius + 1.0, length(dd)));
    c = lerp(c, float3(0.9, 0.05, 0.05), dot_mask);

    // Video noise, per-line tape noise, and extra noise and brightening inside the glitch band.
    float pn = hash21(cell + float2(frame_seed * 13.7, frame_seed * 5.3)) - 0.5;
    float ln = hash21(float2(line_id, frame_seed)) - 0.5;
    float shadow_boost = saturate(1.3 - y);
    c += pn * noise_amount * 0.2 * shadow_boost;
    c += ln * tape_noise * 0.05;
    c += (pn * 1.5) * in_band;
    c += in_band * 0.1;

    // Vignette.
    float2 d = v_in.uv - 0.5;
    c *= saturate(1.0 - vignette * dot(d, d) * 2.0);

    return float4(saturate(c), s0.a);
}
