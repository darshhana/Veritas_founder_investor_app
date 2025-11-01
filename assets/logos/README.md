# Logo Assets

## How to Add Your Logo

1. **Place your logo file here** with the name: `app_logo.png`

2. **Logo Requirements:**
   - **Format**: PNG (recommended) or SVG converted to PNG
   - **Recommended Size**: 
     - Minimum: 512x512 pixels (for high quality)
     - Optimal: 1024x1024 pixels
   - **Background**: Transparent background is recommended
   - **Aspect Ratio**: Square (1:1) works best

3. **File Name**: The logo must be named exactly `app_logo.png`

4. **Alternative Sizes** (optional, for different screen densities):
   - `app_logo@2x.png` (for 2x density)
   - `app_logo@3x.png` (for 3x density)

5. **After adding the logo:**
   - Run `flutter pub get` to ensure assets are registered
   - Hot restart the app (not just hot reload) to see the changes

## Current Usage

The logo is displayed on:
- **Dual Login Screen**: Top of the page (120x120 size)
- Falls back to a blue circle with rocket icon if logo not found

## Notes

- The logo should have a transparent or light background to work well with the gradient background
- If your logo is rectangular, consider adding padding to make it square
- For best results, use a logo with a clear, recognizable design that works at different sizes

