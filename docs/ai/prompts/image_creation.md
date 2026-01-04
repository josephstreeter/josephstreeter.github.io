---
title: "AI Image Creation Guide"
description: "A comprehensive guide to creating high-quality images using AI, covering prompt engineering, style techniques, and best practices for various image generation models"
author: "Joseph Streeter"
ms.date: "2025-12-30"
ms.topic: "guide"
keywords: ["ai", "image generation", "dall-e", "midjourney", "stable diffusion", "prompt engineering", "ai art", "generative ai"]
uid: docs.ai.image-creation
---

A comprehensive reference for creating high-quality images using AI image generation models. This guide covers prompt engineering techniques, style descriptors, technical parameters, and best practices for tools like DALL-E, Midjourney, Stable Diffusion, and other generative AI platforms.

## Understanding AI Image Generation

AI image generation models use diffusion processes or transformer architectures to create images from text descriptions. The quality and accuracy of results depend heavily on:

- **Prompt clarity and specificity**
- **Style and aesthetic descriptors**
- **Technical parameters** (resolution, aspect ratio, seed values)
- **Model capabilities and limitations**
- **Negative prompts** (what to avoid)

## Core Prompt Structure

Effective prompts follow a structured format:

```text
[Subject] + [Action/Pose] + [Environment/Setting] + [Style] + [Lighting] + [Technical Parameters]
```

### Example

```text
A majestic red dragon perched on a mountain peak, wings spread wide, 
overlooking a medieval castle at sunset, fantasy art style, dramatic 
golden hour lighting, cinematic composition, 8K resolution, highly detailed
```

## Describing Subjects in Detail

The subject is the focal point of your image and requires the most detailed description. A well-described subject helps the AI understand exactly what you want to create. The level of detail you provide directly impacts the quality and accuracy of the generated image.

### Subject Categories

#### People and Characters

When describing people, include:

##### Physical Characteristics

- **Age range**: infant, toddler, child, teenager, young adult, middle-aged, elderly, ancient
- **Gender presentation**: masculine, feminine, androgynous, non-binary
- **Body type**: slender, athletic, muscular, heavyset, petite, tall, short
- **Facial features**: round face, angular jaw, high cheekbones, button nose, expressive eyes
- **Hair**: long flowing black hair, short curly red hair, braided blonde hair, bald, silver beard
- **Skin tone**: pale, fair, olive, tan, bronze, dark, ebony
- **Distinctive features**: freckles, scars, tattoos, birthmarks, piercings, wrinkles

**Example**: "A middle-aged woman with silver-streaked auburn hair tied in a loose bun, olive skin, laugh lines around her hazel eyes, wearing wire-rimmed glasses"

##### Clothing and Accessories

- **Style**: casual, formal, business, athletic, traditional, fantasy, futuristic
- **Specific garments**: leather jacket, flowing gown, armor plates, lab coat, kimono
- **Colors and materials**: crimson silk, weathered denim, polished steel, soft cotton
- **Accessories**: jewelry, weapons, tools, bags, hats, scarves
- **Condition**: pristine, worn, tattered, ornate, minimalist

**Example**: "Wearing a weathered brown leather duster coat with brass buttons, tall black boots, carrying an ornate staff with glowing runes"

##### Expression and Emotion

- **Facial expression**: smiling, frowning, laughing, crying, contemplative, angry, surprised, serene
- **Mood indicators**: tears streaming down face, eyes crinkled with joy, furrowed brow
- **Body language**: relaxed posture, tense shoulders, confident stance

**Example**: "Expression of determined focus, eyes narrowed with concentration, slight smile playing at the corners of her mouth"

#### Animals and Creatures

When describing animals or creatures:

##### Species and Type

- Be specific: "Bengal tiger" not just "tiger", "Golden Retriever" not just "dog"
- For fantasy creatures, reference known mythology: "dragon", "griffin", "phoenix"
- Hybrid descriptions: "wolf-dragon hybrid", "mechanical lion"

##### Physical Details

- **Size**: massive, towering, tiny, miniature, human-sized
- **Coloration**: striped, spotted, solid color, iridescent, color gradients
- **Texture**: smooth scales, fluffy fur, feathered wings, rough hide
- **Distinctive features**: horns, antlers, multiple tails, extra limbs, glowing eyes
- **Proportions**: elongated neck, powerful haunches, oversized claws

**Example**: "A massive ice dragon with crystalline blue scales that shimmer like diamonds, four powerful legs with razor-sharp talons, enormous bat-like wings, rows of icicle-shaped spines along its back, piercing white eyes that glow with cold light"

##### Behavior and Pose

- **Static poses**: sitting, standing, lying down, perched, coiled
- **Dynamic actions**: running, flying, leaping, hunting, roaring, swimming
- **Interaction**: playing with cubs, stalking prey, fighting, protecting territory

**Example**: "Rearing up on hind legs, wings spread to full span, head thrown back mid-roar, frost breath visible in the air"

#### Objects and Items

When describing objects:

##### Type and Function

- Clearly state what it is: sword, chair, vehicle, building, device
- Specify the purpose: ceremonial sword, throne, racing car, cathedral

##### Material and Construction

- **Materials**: wood, metal, glass, stone, fabric, crystal, energy
- **Finish**: polished, rusty, worn, pristine, engraved, painted
- **Construction style**: handcrafted, industrial, futuristic, ancient, ornate

**Example**: "An ancient longsword forged from dark damascus steel with intricate silver inlays forming runic patterns along the blade, wrapped leather grip worn smooth with age, pommel set with a blood-red ruby"

##### Details and Embellishments

- **Decorative elements**: engravings, gemstones, patterns, insignia
- **Condition**: battle-worn, pristine, magical glow, rust spots
- **Scale**: massive, miniature, life-sized
- **Unique features**: glowing elements, moving parts, ethereal qualities

**Example**: "The blade emanates a faint blue glow, small runes pulsing with inner light, crossguard shaped like dragon wings"

#### Environments and Locations

When describing settings:

##### Location Type

- Natural: forest, mountain, desert, ocean, cave, valley
- Urban: city, village, ruins, fortress, temple
- Interior: room, hall, chamber, dungeon
- Fantasy/Sci-fi: floating island, space station, parallel dimension

##### Atmosphere and Conditions

- **Weather**: sunny, stormy, foggy, snowy, clear
- **Time of day**: dawn, midday, dusk, midnight, twilight
- **Season**: spring bloom, autumn leaves, winter frost, summer heat
- **Mood**: peaceful, ominous, chaotic, serene, abandoned

**Example**: "A misty ancient forest at twilight, massive trees with gnarled roots, shafts of purple-tinted light filtering through thick canopy, floating bioluminescent spores drifting through the air, moss-covered stone ruins half-hidden by undergrowth"

##### Environmental Details

- **Vegetation**: types of plants, density, condition
- **Architecture**: building style, materials, age, condition
- **Natural features**: rock formations, water features, terrain
- **Inhabitants**: signs of life, creatures, people

### Layering Subject Details

Build subject descriptions in layers for maximum impact:

#### Layer 1: Basic Identity

Start with the fundamental "what is it"

- "A warrior"
- "A steampunk airship"
- "A cybernetic tiger"

#### Layer 2: Primary Characteristics

Add the most important visual details

- "A female elven warrior with long silver hair"
- "A massive brass steampunk airship with rotating propellers"
- "A sleek cybernetic tiger with glowing circuit patterns"

#### Layer 3: Distinctive Features

Include unique identifying features

- "A female elven warrior with long silver hair, intricate face tattoos, and luminous green eyes"
- "A massive brass steampunk airship with rotating propellers, steam vents, and ornate Victorian-style railings"
- "A sleek cybernetic tiger with glowing cyan circuit patterns visible beneath translucent synthetic skin, metallic claws"

#### Layer 4: Fine Details

Add finishing touches and specifics

- "A female elven warrior with long silver hair braided with golden thread, intricate tribal face tattoos in deep blue ink, luminous green eyes with cat-like pupils, wearing leaf-shaped earrings"
- "A massive brass steampunk airship with rotating propellers driven by exposed gears, billowing steam vents along the hull, ornate Victorian-style railings with floral engravings, a crow's nest topped with a weathervane"
- "A sleek cybernetic tiger with glowing cyan circuit patterns visible beneath translucent synthetic skin panels, retractable metallic claws with diamond tips, LED eyes that shift from amber to red, exposed mechanical spine with pulsing energy cores"

### Subject Detail Best Practices

#### Be Specific, Not Generic

- ❌ Generic: "A beautiful woman"
- ✅ Specific: "A graceful woman in her thirties with cascading auburn curls, porcelain skin dusted with freckles, wearing an emerald silk evening gown"

#### Use Sensory Language

- Visual: colors, textures, patterns, shapes
- Implied texture: rough, smooth, soft, hard, flowing, rigid
- Material qualities: metallic sheen, matte finish, translucent, opaque

#### Maintain Coherence

- Ensure all details work together logically
- Avoid contradicting descriptions
- Consider scale relationships between elements

**Example of Coherent Description**:

```text
A towering mechanical guardian, 20 feet tall, constructed from weathered bronze plates riveted together, powered by a glowing blue energy core visible through gaps in its chest armor, with oversized hands capable of crushing boulders, head shaped like an ancient Greek helmet with a single glowing eye"
```

![Guardian](/images/ai/guardian.png)

### Common Subject Description Mistakes

1. **Too Vague**: "A nice person standing somewhere"
   - Fix: Be specific about every element

2. **Conflicting Details**: "A young elderly man with long short hair"
   - Fix: Ensure consistency in descriptions

3. **Overloading**: Including 20+ unrelated details that confuse the AI
   - Fix: Focus on 5-10 most important characteristics

4. **Missing Scale**: Not indicating size relationships
   - Fix: Include size comparisons or specific measurements

5. **Ambiguous Pronouns**: "She is holding it near the thing"
   - Fix: Name subjects explicitly: "The warrior is holding the sword near the altar"

### Subject Description Templates

#### Character Template

```text
[Age/Type] [Species/Race] [Gender] with [Hair description], [Skin description], 
[Distinctive facial features], [Eye description], wearing [Clothing details], 
[Accessories], [Expression/emotion], [Unique characteristics]
```

#### Creature Template

```text
[Size] [Species/Type] [Creature name] with [Color pattern], [Texture description], 
[Distinctive features], [Number and type of limbs/appendages], [Eyes/face], 
[Special abilities or elements], in [Pose/action]
```

#### Object Template

```text
[Type of object] made of [Materials], [Size], [Color], [Surface treatment], 
with [Decorative elements], [Condition/age], [Special properties], 
[Function or purpose visible]
```

#### Environment Template

```text
[Location type], [Time of day], [Weather/atmospheric conditions], featuring 
[Major landscape features], [Vegetation/structures], [Scale indicators], 
[Mood/atmosphere], [Lighting conditions]
```

### Advanced Subject Techniques

#### Using Reference Points

Compare to known entities for clarity:

- "Dragon the size of a three-story building"
- "Sword as tall as a grown man"
- "Eyes that glow like molten gold"

#### Implying Motion and Life

Even in static images, suggest dynamism:

- "Hair whipping in an unseen wind"
- "Muscles tensed mid-stride"
- "Cape billowing dramatically"
- "Eyes following the viewer"

#### Creating Focal Hierarchies

Guide attention through detail density:

- **High detail**: Primary subject (face, main object)
- **Medium detail**: Supporting elements (clothing, nearby objects)
- **Low detail**: Background (distant elements, atmosphere)

**Example**:

```text
A knight in intricately detailed plate armor with every rivet and scratch visible (high detail), standing before a moderately detailed stone castle (medium detail), with misty mountains barely visible in the background (low detail)"
```

![knight](/images/ai/knight.png)

## Style Categories

### Photorealistic Styles

#### Ultra Realistic / Photorealistic

- Keywords: `photorealistic`, `ultra realistic`, `8K`, `high detail`, `sharp focus`, `DSLR quality`
- Use cases: Product photography, portraits, architectural visualization
- Example: "Photorealistic portrait of an elderly woman with deep wrinkles, natural lighting, 85mm lens, shallow depth of field"

#### Documentary / Journalistic

- Keywords: `documentary photography`, `candid`, `natural light`, `authentic`, `raw`
- Use cases: Street photography, reportage, real-world scenes
- Example: "Documentary style photograph of busy Tokyo street at night, neon lights reflecting on wet pavement, candid moment"

#### Studio Photography

- Keywords: `studio lighting`, `professional photography`, `commercial`, `clean background`, `product shot`
- Use cases: Product images, fashion, advertising
- Example: "Studio product photography of luxury watch, dramatic side lighting, black background, macro detail"

### Artistic Styles

#### Illustration Styles

- **Chibi**: Cute, super-deformed characters with large heads and small bodies
  - Keywords: `chibi style`, `kawaii`, `cute`, `simplified features`, `big eyes`
  - Example: "Chibi illustration of warrior knight, oversized sword, pastel colors, adorable expression"

- **Anime/Manga**: Japanese animation and comic book styles
  - Keywords: `anime style`, `manga`, `cel-shaded`, `vibrant colors`, `detailed line art`
  - Example: "Anime style portrait, magical girl transformation, sparkles and ribbons, dynamic pose"

- **Comic Book**: Western comic book aesthetics
  - Keywords: `comic book style`, `bold outlines`, `halftone dots`, `speech bubbles`, `action lines`
  - Example: "Comic book style superhero in action pose, bold colors, dramatic perspective, BAM effect"

#### Painting Styles

- **Oil Painting**: Traditional oil painting techniques
  - Keywords: `oil painting`, `canvas texture`, `brushstrokes visible`, `classical`, `renaissance style`
  - Example: "Oil painting portrait in the style of Rembrandt, chiaroscuro lighting, rich earth tones"

- **Watercolor**: Soft, translucent painting style
  - Keywords: `watercolor`, `soft edges`, `color bleeding`, `paper texture`, `delicate`
  - Example: "Watercolor landscape of cherry blossoms, soft pink tones, flowing colors, dreamy atmosphere"

- **Digital Painting**: Modern digital art techniques
  - Keywords: `digital painting`, `concept art`, `matte painting`, `detailed`, `professional illustration`
  - Example: "Digital painting of futuristic city, neon accents, detailed architecture, concept art quality"

### Cinematic & Fantasy Styles

#### Cinematic

- Keywords: `cinematic`, `film still`, `anamorphic lens`, `color grading`, `movie quality`, `establishing shot`
- Use cases: Dramatic scenes, storytelling, movie-like imagery
- Example: "Cinematic shot of lone astronaut on alien planet, wide angle, dramatic clouds, color graded like Blade Runner 2049"

#### Surreal Cinematic Fantasy

- Keywords: `surreal`, `dreamlike`, `fantasy`, `ethereal`, `otherworldly`, `magical realism`
- Use cases: Imaginative scenes, fantasy art, conceptual imagery
- Example: "Surreal cinematic fantasy scene, floating islands in purple sky, giant crystals, ethereal lighting, mystical atmosphere"

#### Dark Cinematic / Horror

- Keywords: `dark`, `ominous`, `horror`, `moody`, `gothic`, `dramatic shadows`, `sinister`
- Use cases: Horror themes, dark fantasy, intense atmospheric scenes
- Example: "Ultra intense dark cinematic scene, abandoned cathedral, moonlight through stained glass, ominous shadows, horror atmosphere"

### Modern & Stylized

#### 3D Render

- Keywords: `3D render`, `octane render`, `unreal engine`, `ray tracing`, `CGI`, `subsurface scattering`
- Use cases: Product visualization, game art, architectural renders
- Example: "3D render of futuristic vehicle, octane render, metallic materials, ray-traced reflections, studio lighting"

#### Minimalist

- Keywords: `minimalist`, `simple`, `clean`, `negative space`, `geometric`, `flat design`
- Use cases: Icons, logos, modern design, abstract concepts
- Example: "Minimalist illustration of mountain landscape, limited color palette, geometric shapes, clean lines"

#### Retro / Vintage

- Keywords: `retro`, `vintage`, `1980s`, `vaporwave`, `synthwave`, `nostalgic`, `film grain`
- Use cases: Nostalgic themes, retro aesthetics, period pieces
- Example: "Retro 1980s style poster, neon grid, sunset gradient, synthwave aesthetic, VHS quality"

## Lighting Techniques

Lighting dramatically impacts mood and quality:

### Natural Lighting

- **Golden Hour**: Warm, soft light during sunrise/sunset
  - Keywords: `golden hour`, `sunset lighting`, `warm tones`, `soft shadows`

- **Blue Hour**: Cool, soft light before sunrise/after sunset
  - Keywords: `blue hour`, `twilight`, `cool tones`, `ethereal`

- **Overcast**: Diffused, even lighting
  - Keywords: `overcast`, `soft lighting`, `diffused`, `even illumination`

### Studio Lighting

- **Rembrandt Lighting**: Triangular light on cheek
- **Butterfly Lighting**: Light from above, shadow under nose
- **Rim Lighting**: Backlight creating outline
- **Three-Point Lighting**: Key, fill, and back lights

### Dramatic Lighting

- **Chiaroscuro**: Strong contrast between light and dark
  - Keywords: `chiaroscuro`, `dramatic contrast`, `deep shadows`

- **Volumetric Lighting**: God rays, visible light beams
  - Keywords: `volumetric lighting`, `god rays`, `atmospheric`, `light beams`

- **Neon Lighting**: Colorful artificial lights
  - Keywords: `neon lighting`, `cyberpunk`, `glowing signs`, `colorful reflections`

## Camera & Composition Terms

### Lens Types

- **Wide Angle**: `wide angle lens`, `14mm`, `35mm`, `distorted perspective`
- **Standard**: `50mm lens`, `natural perspective`, `standard lens`
- **Portrait**: `85mm lens`, `105mm`, `flattering compression`
- **Telephoto**: `200mm lens`, `compressed perspective`, `shallow depth of field`
- **Macro**: `macro lens`, `extreme close-up`, `detailed texture`

### Camera Angles

- **Eye Level**: Natural, neutral perspective

- **Low Angle**: Looking up, dramatic, powerful
  - Keywords: `low angle shot`, `looking up`, `worm's eye view`

- **High Angle**: Looking down, vulnerable, overview
  - Keywords: `high angle shot`, `bird's eye view`, `aerial view`

- **Dutch Angle**: Tilted, dynamic, unsettling
  - Keywords: `dutch angle`, `tilted horizon`, `dynamic composition`

### Composition Techniques

- **Rule of Thirds**: Subject positioned at intersection points
- **Leading Lines**: Lines guiding eye to subject
- **Framing**: Using elements to frame subject
- **Symmetry**: Balanced, harmonious composition
- **Negative Space**: Empty space emphasizing subject

## Quality & Technical Parameters

### Resolution & Detail

- `8K resolution`, `4K`, `highly detailed`, `intricate details`
- `ultra HD`, `high resolution`, `crisp`, `sharp focus`
- `hyper-detailed`, `extreme detail`, `fine details`

### Image Quality

- `masterpiece`, `award winning`, `professional quality`
- `trending on artstation`, `featured on behance`
- `high quality`, `premium`, `best quality`

### Rendering Quality

- `unreal engine 5`, `octane render`, `cinema 4D`
- `ray tracing`, `global illumination`, `ambient occlusion`
- `physically based rendering`, `PBR materials`

## Negative Prompts

Specify what to avoid for better results:

### Common Negative Prompts

- Quality issues: `low quality`, `blurry`, `pixelated`, `compressed`, `jpeg artifacts`
- Anatomical issues: `deformed`, `extra limbs`, `bad anatomy`, `disfigured`, `mutated`
- Style issues: `cartoon` (if wanting realistic), `anime` (if wanting realistic)
- Technical issues: `watermark`, `text`, `signature`, `logo`, `username`
- Compositional issues: `cropped`, `out of frame`, `duplicate`

### Example Usage

```text
Prompt: Beautiful mountain landscape at sunset, photorealistic, 8K
Negative: blurry, low quality, overexposed, distorted, watermark
```

## Platform-Specific Tips

### Midjourney

- Use `--v 6` for latest version
- Aspect ratios: `--ar 16:9`, `--ar 1:1`, `--ar 9:16`
- Stylization: `--s 100` (default), higher = more artistic
- Quality: `--q 2` for maximum quality
- Chaos: `--chaos 50` for more variation

### DALL-E 3

- Natural language prompts work best
- Be descriptive but concise
- Specify style clearly at beginning or end
- Good at following complex instructions
- Limited to 1024x1024, 1024x1792, 1792x1024

### Stable Diffusion

- CFG Scale: 7-12 (guidance scale)
- Steps: 20-50 sampling steps
- Samplers: Euler a, DPM++ 2M Karras
- Use LoRA models for specific styles
- Upscale with SD Upscale or Real-ESRGAN

## Best Practices

### Do's

- ✅ Be specific and descriptive
- ✅ Use multiple style descriptors
- ✅ Specify lighting conditions
- ✅ Include camera/perspective details
- ✅ Use quality enhancement keywords
- ✅ Iterate and refine prompts
- ✅ Keep negative prompts comprehensive

### Don'ts

- ❌ Be vague or ambiguous
- ❌ Mix conflicting styles
- ❌ Overload with too many concepts
- ❌ Ignore composition principles
- ❌ Forget aspect ratio considerations
- ❌ Use copyrighted character names (without permission)

## Prompt Templates

### Portrait Template

```text
[Description] portrait of [subject], [expression/emotion], 
[clothing/accessories], [lighting style], [camera angle], 
[lens type], [background], [art style], high quality, detailed
```

### Landscape Template

```text
[Environment] landscape, [time of day], [weather], [season], 
[lighting], [composition style], [camera angle], [art style], 
[technical quality], detailed, panoramic
```

### Product Photography Template

```text
Professional product photography of [product], [material/texture], 
[background], [lighting setup], [camera angle], [focus], 
commercial quality, high resolution, marketing image
```

### Fantasy/Sci-Fi Template

```text
[Subject] in [environment], [action/pose], [atmosphere/mood], 
[lighting], [color palette], [art style], epic composition, 
highly detailed, [technical quality], concept art
```

## Advanced Techniques

### Prompt Weighting

Some platforms support emphasis:

- Midjourney: Use `::2` for double weight (e.g., `sunset::2`)
- Stable Diffusion: Use parentheses `(sunset:1.5)` or brackets `[less important]`

### Prompt Blending

Combine multiple concepts:

- `fantasy castle::1.5 modern architecture::1 at sunset`

### Multi-Prompting

Create complex scenes by breaking into parts:

- `(foreground dragon:1.3), (midground castle:1.0), (background mountains:0.8)`

### Style Mixing

Combine artistic styles:

- `anime style::0.5 watercolor::0.3 photorealistic::0.2`

## Common Pitfalls

1. **Too Many Concepts**: Focus on 1-3 main elements
2. **Conflicting Styles**: Don't mix "photorealistic" with "cartoon"
3. **Missing Key Details**: Always specify lighting and perspective
4. **Generic Descriptions**: "Beautiful scene" is too vague
5. **Ignoring Negative Prompts**: They significantly improve quality

## Resources & Inspiration

- **Prompt Libraries**: Lexica.art, PromptHero, OpenArt
- **Style References**: ArtStation, Behance, Pinterest
- **Communities**: Reddit (r/StableDiffusion, r/midjourney), Discord servers
- **Tutorials**: YouTube channels, platform documentation
- **Model Cards**: Read capabilities and limitations of specific models

## Examples

Here are some example prompts taken from an AI group on Facebook that show different styles of writing prompts for image creation.

### Example 1

```text
Ultra-realistic cinematic fantasy scene of a young male adventurer riding a small dragon, identical composition and environment as reference.

Male rider details:
Same face as given in picture of Young adult man no change 100% same cheerful smile, expressive eyes, joyful and adventurous expression
– Short, slightly messy black hair moving naturally with motion
– Wearing the exact same outfit: fitted beige/tan adventure jumpsuit, leather harness straps, brown gloves, knee pads, and vintage aviator goggles resting on the head
– Slim, athletic build, natural masculine facial structure

Dragon details (unchanged):
– Small, friendly dragon with blue-gray textured scales
– Large yellow expressive eyes, open smiling mouth with visible teeth
– Leather saddle and harness exactly as reference
– Dynamic mid-run / mid-jump pose, claws extended, tail visible

Environment (unchanged):
– Explosive clouds of colorful smoke (pink, teal, yellow, and orange) surrounding the scene
– Outdoor natural setting with soft blurred background
– Floating dust particles and debris for motion effect

Lighting & style:
– Natural daylight, soft cinematic lighting
– Shallow depth of field, DSLR-style photography
– Ultra-detailed textures, realistic skin and fabric folds
– High contrast, vibrant colors, fantasy adventure vibe

Camera & quality:
– Dynamic action shot, eye-level angle
– Ultra-realistic, 8K quality, sharp focus, professional cinematic composition

Important:
– Change only the rider’s gender to male
– Keep pose, dragon, colors, outfit, framing, and background exactly the same image size must be 9:16
```

![Reference](/images/ai/reference_example1.jpeg)

![Results](/images/ai/result_example1.png)

### Example 2

```text
Ultra-realistic 8K outdoor portrait of a female in her mid 20s with identity preservation. She has long voluminous blonde hair with caramel highlights styled in soft waves. She has grey-olive eyes with natural catchlight. Skin has sunlit tactile realism with golden warmth. Scene captured on yacht steps facing the Emirates Palace across the water in Abu Dhabi, replicating the original pose, angle, and lighting exactly.

Mood and Concept:
Relaxed luxury with warm coastal sunlight. Soft breeze lifting hair. Serene expression with eyes closed and chin tilted slightly upward. Golden ambiance from high sun reflecting off the yacht, water, and sandstone architecture.

Outfit and Styling:
Pale ice blue satin long sleeve blouse tied at the waist. Charcoal gray bikini bottom. No footwear. Small minimal earrings. No added accessories.

Hair:
Long, weighty soft waves with caramel streaks glowing under sunlight. Natural movement from light breeze framing the face.
Make-up and Nails:
Soft bronzed complexion. Gentle contour. Neutral eyeshadow with defined lashes. Pink lips with subtle sheen. Nails in barely there tint.

Accessories:
Small subtle earrings. No rings or necklaces visible.
Pose and Composition:
Subject seated on polished wooden yacht steps. One leg raised on the upper step, the other extended downward with relaxed pointed toes. Torso angled toward camera with gentle arch. One hand touching jawline, the other behind head. Background softly compressed with shallow depth revealing Emirates Palace domes in warm beige tones.

Photography Specs:
Mirrorless full frame camera with 200mm lens
Aperture f/1.8 for shallow depth
Shutter speed 1/1250s for sharp sunlit capture
ISO 100 for clean bright tones
Slightly low camera angle for elongated lines
Aspect Ratio 5:7

Detail and Finish:
Warm sun highlights across shoulders, legs, and hair. Reflection from water adds gentle specular glow. Background softened with creamy bokeh. Skin texture maintained with editorial clarity. Subtle local contrast enhancement and controlled saturation for a clean, polished finish suitable for travel-luxury editorial visuals.
```

![Results](/images/ai/result_example2.png)

### Example 3

```text
A hyper-realistic, vertical extreme close-up portrait of an alternative woman with a head-tilt upward.

She is wearing round sunglasses with glowing red lenses and multiple black cord chokers. Dark leather attire, pale skin, and messy long platinum blonde hair with red highlights. 

Dramatic neon-noir lighting with intense red glow and deep teal shadows. Dark smoky background, shallow depth of field, moody and mysterious cinematic atmosphere, high-resolution digital art style.
```

![Results](/images/ai/result_example3.png)

## Conclusion

Mastering AI image generation is an iterative process. Start with clear, structured prompts, experiment with different styles and parameters, and refine based on results. The key to excellence is understanding how to communicate your vision effectively to the AI model through precise, descriptive prompting.
