# OBS 2005 Handcam Filter

Makes your OBS handcam look like it was filmed on a 2005 consumer camcorder (MiniDV / Handycam style): soft, noisy, smeared color, tape glitches, and a blinking REC light with a date and time stamp.

## Files

| File | What it is |
|------|------------|
| `handcam_2005.shader` | The video effect. Loaded into OBS through the "User-defined shader" filter. |
| `camcorder_osd.html` | The on-screen display: REC label, tape counter, battery, live date and time. Loaded as an OBS Browser source. |

## Requirements

- OBS Studio on Windows, macOS, or Linux
- The **obs-shaderfilter** plugin, which adds the "User-defined shader" filter to OBS
- Optional: the free **VCR OSD Mono** font, for the authentic on-screen text look (falls back to Courier New)

## Setup

### 1. The shader

1. Right-click your handcam source and choose **Filters**.
2. Under **Effect Filters**, click **+** and add **User-defined shader**.
3. Tick **Load shader from file** and select `handcam_2005.shader`.
4. Adjust the sliders that appear in the filter until it looks right.

### 2. The on-screen display

1. Add a **Browser** source above your handcam.
2. Tick **Local file** and select `camcorder_osd.html`.
3. Set its width and height to match your handcam source so the text lines up with the shader's REC dot.
4. Optional: tick "Refresh browser when scene becomes active" to restart the tape counter each time the scene appears.

### 3. Low frame rate (optional)

A shader can't make video choppy. For the low-framerate camcorder feel, set your handcam capture device to about 15 fps in its source properties.

## Shader controls

| Slider | What it does |
|--------|--------------|
| Vertical Resolution | Line count of the picture (480 is camcorder standard). |
| Color Smear | Higher value means color smears further sideways, like tape video. |
| Softness | Soft lens blur. |
| Edge Sharpening | Bright and dark halos around edges. |
| Interlace Combing | Sideways jitter between alternate lines. |
| Scanlines | Darkens alternate lines. |
| Saturation, Contrast, Brightness | Basic color and exposure. |
| Highlight Blowout | Bright areas bloom and clip. |
| Warm Cast | Shifts the white balance warmer or cooler. |
| Tape Wobble | Slow sideways sway of the picture. |
| Tracking Glitch Bands | Bands that sometimes roll up the picture. |
| Video Noise | Grain, stronger in dark areas. |
| Tape Line Noise | Per-line brightness flicker. |
| Vignette | Darkens the corners. |
| REC Dot / REC Dot Size | Blinking red dot in the top-left corner. |

## Looks to start from

- **Clean MiniDV:** Video Noise 0.2, Tape Line Noise 0.15, Tracking Glitch Bands 0.1, Tape Wobble 0.3.
- **Worn tape (default):** leave everything at its default.
- **Heavy damage:** Vertical Resolution 360, Color Smear 6, Video Noise 0.8, Tape Line Noise 0.8, Tracking Glitch Bands 0.8, Tape Wobble 2.

## Troubleshooting

- **The shader shows an error or nothing changes:** check that obs-shaderfilter is installed and that the file path in the filter is correct.
- **The REC text doesn't line up with the dot:** make the Browser source the same size as the handcam source. If it is still off, adjust the percentages near the top of `camcorder_osd.html` (the `#rec`, `#counter`, `#battery` and `#date` lines).
- **The picture looks too clean or too dirty:** raise or lower Video Noise, Tape Line Noise, and Color Smear.

## About

Created by Dani, who is handicapped.
