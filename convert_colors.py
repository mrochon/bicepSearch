import json

# Common color name to RGB mapping (0-255 scale)
COLOR_MAP = {
    'white': (255, 255, 255), 'black': (0, 0, 0), 'blue': (0, 0, 255),
    'brown': (150, 75, 0), 'tan': (210, 180, 140), 'grey': (128, 128, 128),
    'green': (0, 128, 0), 'pink': (255, 192, 203), 'purple': (128, 0, 128),
    'red': (255, 0, 0), 'silver': (192, 192, 192), 'gold': (255, 215, 0),
    'burgundy': (128, 0, 32), 'orange': (255, 165, 0), 'navy': (0, 0, 128),
    'yellow': (255, 255, 0), 'coral': (255, 127, 80), 'beige': (245, 245, 220),
    'cream': (255, 253, 208), 'olive': (128, 128, 0), 'khaki': (240, 230, 140),
    'charcoal': (54, 69, 79), 'maroon': (128, 0, 0), 'teal': (0, 128, 128),
    'lavender': (230, 230, 250), 'lime': (0, 255, 0), 'turquoise': (64, 224, 208),
    'cognac': (159, 72, 0), 'mint': (62, 180, 137), 'aqua': (0, 255, 255),
    'peach': (255, 218, 185), 'camel': (193, 154, 107), 'magenta': (255, 0, 255),
    'sage': (188, 209, 184), 'oxblood': (75, 0, 13), 'rose': (255, 0, 127),
    'bronze': (205, 127, 50), 'copper': (184, 115, 51), 'forest': (34, 139, 34),
    'indigo': (75, 0, 130), 'cyan': (0, 255, 255), 'lilac': (200, 162, 200),
    'espresso': (62, 36, 18), 'rust': (184, 65, 14), 'slate': (112, 128, 144),
    'mocha': (123, 71, 41), 'midnight': (25, 25, 112), 'ash': (178, 190, 181),
    'cherry': (222, 49, 99), 'violet': (238, 130, 238), 'champagne': (247, 231, 170),
    'moss': (139, 144, 84), 'ivory': (255, 255, 240), 'scarlet': (255, 36, 0),
    'mahogany': (192, 64, 0), 'sand': (194, 178, 128), 'sapphire': (15, 82, 186),
    'emerald': (80, 200, 120), 'blush': (222, 93, 131), 'onyx': (15, 15, 15),
    'granite': (102, 102, 102), 'pearl': (234, 231, 205), 'cobalt': (0, 71, 171),
    'amber': (255, 191, 0), 'graphite': (38, 38, 38), 'cedar': (82, 41, 26),
    'mauve': (224, 176, 255), 'tangerine': (242, 133, 0), 'platinum': (229, 228, 226),
    'chestnut': (205, 92, 72), 'smoke': (115, 130, 135), 'azure': (0, 127, 255),
    'fuchsia': (255, 0, 255), 'caramel': (175, 111, 53), 'ebony': (54, 42, 36),
    'pine': (3, 68, 49), 'crimson': (220, 20, 60), 'jade': (0, 168, 107),
    'lemon': (255, 247, 0), 'walnut': (93, 56, 31), 'storm': (79, 79, 79),
    'orchid': (218, 112, 214), 'ruby': (224, 17, 95), 'honey': (238, 168, 13),
    'coal': (28, 28, 28), 'fog': (218, 218, 218), 'steel': (70, 130, 180)
}

def rgb_to_lab(r, g, b):
    """Convert RGB (0-255 scale) to CIELAB"""
    # Normalize RGB values to 0-1
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    
    # Convert to linear RGB
    r = ((r + 0.055) / 1.055) ** 2.4 if r > 0.04045 else r / 12.92
    g = ((g + 0.055) / 1.055) ** 2.4 if g > 0.04045 else g / 12.92
    b = ((b + 0.055) / 1.055) ** 2.4 if b > 0.04045 else b / 12.92
    
    # Convert RGB to XYZ (D65 illuminant)
    x = (r * 0.4124 + g * 0.3576 + b * 0.1805) * 100
    y = (r * 0.2126 + g * 0.7152 + b * 0.0722) * 100
    z = (r * 0.0193 + g * 0.1192 + b * 0.9505) * 100
    
    # Normalize for D65 white point
    x, y, z = x / 95.047, y / 100.0, z / 108.883
    
    # Convert XYZ to LAB
    x = x ** (1/3) if x > 0.008856 else (7.787 * x) + (16/116)
    y = y ** (1/3) if y > 0.008856 else (7.787 * y) + (16/116)
    z = z ** (1/3) if z > 0.008856 else (7.787 * z) + (16/116)
    
    L = (116 * y) - 16
    a = 500 * (x - y)
    b_val = 200 * (y - z)
    
    return [round(L, 2), round(a, 2), round(b_val, 2)]

# Process the JSONL file
input_file = r'c:\temp\bicepSearch\indexDef\indexDefinitions\shoes\shoes.jsonl'
output_lines = []

with open(input_file, 'r') as f:
    for line in f:
        data = json.loads(line.strip())
        
        # Convert color names to CIELAB
        lab_colors = []
        for color_name in data['colors']:
            color_lower = color_name.lower()
            if color_lower in COLOR_MAP:
                rgb = COLOR_MAP[color_lower]
                lab_value = rgb_to_lab(rgb[0], rgb[1], rgb[2])
                lab_colors.append(lab_value)
            else:
                print(f'Warning: Color "{color_name}" not found in mapping for {data["id"]}')
                lab_colors.append(color_name)  # Keep original if not found
        
        data['colors'] = lab_colors
        output_lines.append(json.dumps(data))

# Write back to file
with open(input_file, 'w') as f:
    f.write('\n'.join(output_lines))

print(f'Successfully converted {len(output_lines)} records')
print(f'Sample output: {output_lines[0]}')
