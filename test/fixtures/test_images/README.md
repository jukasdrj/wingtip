# Test Images

This directory contains sample book spine images for testing.

## Image Files

- `book_spine_clear.jpg` - Clear, well-lit book spine (high quality)
- `book_spine_blurry.jpg` - Blurry book spine (low quality)
- `book_spine_dark.jpg` - Dark/poorly lit book spine (low quality)
- `empty_bookshelf.jpg` - Empty bookshelf with no books (no books found)

## Usage

These images are used in:
- Unit tests for image processing
- Widget tests for camera preview
- Integration tests for full scan workflow

## Generating Real Images

To replace these placeholder images with real test data:

1. Take photos of actual book spines in various conditions
2. Resize images to ~1920px width to match app behavior
3. Compress to JPEG quality 85
4. Name according to the convention above

## Image Properties

All test images should be:
- JPEG format
- Orientation: Portrait or Landscape (matching typical camera usage)
- Size: 1920x1080 or similar (to match typical camera resolution)
- Quality: Varied (clear, blurry, dark) for different test scenarios
