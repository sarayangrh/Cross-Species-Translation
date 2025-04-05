from PIL import Image
import os
import sys

def create_app_icons(source_image_path):
    # Verify the image file exists and is valid
    if not os.path.exists(source_image_path):
        print(f"Error: Image file '{source_image_path}' not found!")
        return False
        
    if os.path.getsize(source_image_path) < 1000:  # Less than 1KB
        print(f"Error: Image file '{source_image_path}' appears to be invalid (too small)!")
        return False
    
    try:
        # Create the AppIcon.appiconset directory if it doesn't exist
        output_dir = "DogBarkTranslator/Assets.xcassets/AppIcon.appiconset"
        os.makedirs(output_dir, exist_ok=True)
        
        # Open and convert the source image to RGBA
        img = Image.open(source_image_path)
        img = img.convert('RGBA')
        
        # Crop to square
        width, height = img.size
        size = min(width, height)
        left = (width - size) // 2
        top = (height - size) // 2
        right = left + size
        bottom = top + size
        img = img.crop((left, top, right, bottom))
        
        # Define all required icon sizes
        icon_sizes = {
            # iPhone
            "AppIcon-20@2x.png": (40, 40),    # 20pt @2x
            "AppIcon-20@3x.png": (60, 60),    # 20pt @3x
            "AppIcon-29@2x.png": (58, 58),    # 29pt @2x
            "AppIcon-29@3x.png": (87, 87),    # 29pt @3x
            "AppIcon-40@2x.png": (80, 80),    # 40pt @2x
            "AppIcon-40@3x.png": (120, 120),  # 40pt @3x
            "AppIcon-60@2x.png": (120, 120),  # 60pt @2x
            "AppIcon-60@3x.png": (180, 180),  # 60pt @3x
            
            # iPad
            "AppIcon-20.png": (20, 20),       # 20pt @1x
            "AppIcon-29.png": (29, 29),       # 29pt @1x
            "AppIcon-40.png": (40, 40),       # 40pt @1x
            "AppIcon-76.png": (76, 76),       # 76pt @1x
            "AppIcon-76@2x.png": (152, 152),  # 76pt @2x
            "AppIcon-83.5@2x.png": (167, 167),# 83.5pt @2x
            
            # App Store
            "AppIcon-1024.png": (1024, 1024)  # 1024pt @1x
        }
        
        # Generate each icon size
        for filename, size in icon_sizes.items():
            # Resize the square image to the target size
            resized = img.resize(size, Image.Resampling.LANCZOS)
            
            # Save the icon
            output_path = os.path.join(output_dir, filename)
            resized.save(output_path, 'PNG')
            print(f"Generated {filename} ({size[0]}x{size[1]})")
        
        return True
        
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return False

if __name__ == "__main__":
    # Use the provided image
    source_image = "app_icon_source.jpg"
    if not create_app_icons(source_image):
        sys.exit(1)
    print("\nApp icons generated successfully!") 