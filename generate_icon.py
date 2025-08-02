from PIL import Image, ImageDraw
import os

def create_period_tracker_icon():
    # Create different sizes for iOS app icons
    sizes = [
        (20, 20), (29, 29), (40, 40), (58, 58), (60, 60), (76, 76), (80, 80),
        (87, 87), (114, 114), (120, 120), (152, 152), (167, 167), (180, 180),
        (1024, 1024)
    ]
    
    # Create base icon at largest size
    base_size = 1024
    img = Image.new('RGB', (base_size, base_size), '#FFE4E1')  # Light pink background
    draw = ImageDraw.Draw(img)
    
    # Draw calendar background
    calendar_margin = base_size * 0.1
    calendar_width = base_size - (2 * calendar_margin)
    calendar_height = calendar_width * 0.85
    
    # Calendar background (white with rounded corners effect)
    draw.rectangle([calendar_margin, calendar_margin, 
                   calendar_margin + calendar_width, 
                   calendar_margin + calendar_height], 
                   fill='white', outline='#E0E0E0', width=4)
    
    # Calendar header (pink)
    header_height = calendar_height * 0.2
    draw.rectangle([calendar_margin, calendar_margin,
                   calendar_margin + calendar_width,
                   calendar_margin + header_height],
                   fill='#FF69B4', outline='#FF69B4')
    
    # Calendar grid lines
    grid_start_y = calendar_margin + header_height
    grid_height = calendar_height - header_height
    
    # Draw horizontal grid lines
    for i in range(1, 6):  # 5 rows for weeks
        y = grid_start_y + (i * grid_height / 5)
        draw.line([calendar_margin, y, calendar_margin + calendar_width, y], 
                 fill='#E0E0E0', width=2)
    
    # Draw vertical grid lines
    for i in range(1, 7):  # 6 vertical lines for 7 days
        x = calendar_margin + (i * calendar_width / 7)
        draw.line([x, grid_start_y, x, calendar_margin + calendar_height], 
                 fill='#E0E0E0', width=2)
    
    # Add period dots (red circles) to simulate marked period days
    dot_radius = base_size * 0.025
    
    # Period dots in different cells
    period_positions = [
        (2, 1), (3, 1), (4, 1), (5, 1),  # First week
        (2, 3), (3, 3), (4, 3),          # Third week
    ]
    
    for col, row in period_positions:
        cell_width = calendar_width / 7
        cell_height = grid_height / 5
        
        dot_x = calendar_margin + (col * cell_width) + (cell_width / 2)
        dot_y = grid_start_y + (row * cell_height) + (cell_height / 2)
        
        draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                     dot_x + dot_radius, dot_y + dot_radius],
                     fill='#DC143C', outline='#DC143C')
    
    # Add a small heart symbol in the header
    heart_size = base_size * 0.04
    heart_x = calendar_margin + calendar_width - heart_size * 2
    heart_y = calendar_margin + header_height / 2
    
    # Simple heart shape using circles and triangle
    draw.ellipse([heart_x - heart_size/2, heart_y - heart_size/3,
                 heart_x, heart_y + heart_size/3],
                 fill='white')
    draw.ellipse([heart_x, heart_y - heart_size/3,
                 heart_x + heart_size/2, heart_y + heart_size/3],
                 fill='white')
    draw.polygon([heart_x - heart_size/2, heart_y,
                 heart_x + heart_size/2, heart_y,
                 heart_x, heart_y + heart_size/2],
                 fill='white')
    
    # Save the base icon
    img.save('/Users/chenen.liang/Desktop/code/PTracker/icon_1024.png')
    
    # Create all required sizes
    icons_dir = '/Users/chenen.liang/Desktop/code/PTracker/AppIcon'
    os.makedirs(icons_dir, exist_ok=True)
    
    icon_mapping = {
        (20, 20): 'icon_20pt.png',
        (29, 29): 'icon_29pt.png', 
        (40, 40): 'icon_40pt.png',
        (58, 58): 'icon_29pt@2x.png',
        (60, 60): 'icon_60pt.png',
        (76, 76): 'icon_76pt.png',
        (80, 80): 'icon_40pt@2x.png',
        (87, 87): 'icon_29pt@3x.png',
        (114, 114): 'icon_57pt@2x.png',
        (120, 120): 'icon_60pt@2x.png',
        (152, 152): 'icon_76pt@2x.png',
        (167, 167): 'icon_83.5pt@2x.png',
        (180, 180): 'icon_60pt@3x.png',
        (1024, 1024): 'icon_1024pt.png'
    }
    
    for size, filename in icon_mapping.items():
        resized_img = img.resize(size, Image.Resampling.LANCZOS)
        resized_img.save(os.path.join(icons_dir, filename))
    
    print("Period tracker app icons created successfully!")
    print(f"Icons saved in: {icons_dir}")
    
    return icons_dir

if __name__ == "__main__":
    create_period_tracker_icon()