#!/bin/bash
# Deployment script for AeraSync to GitHub Pages
set -e # Exit immediately if a command exits with a non-zero status

# Change to project directory
cd /home/luisvinatea/Dev/Repos/AeraSync/AeraSync || { echo "Failed to change directory"; exit 1; }

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean || { echo "Flutter clean failed"; exit 1; }

# Get dependencies
echo "Getting dependencies..."
flutter pub get || { echo "Flutter pub get failed"; exit 1; }

# Build web release
echo "Building web release..."
flutter build web --release || { echo "Flutter build failed"; exit 1; }

# Copy to gh-pages directory
echo "Copying build to gh-pages..."
cp -r build/web/* ../AeraSync-gh-pages/ || { echo "Copy failed"; exit 1; }

# Commit and push changes
cd ../AeraSync-gh-pages || { echo "Failed to change to gh-pages directory"; exit 1; }

echo "Committing changes..."
git add . || { echo "Git add failed"; exit 1; }
git commit -m "Update with latest changes" || { echo "Git commit failed"; exit 1; }
git push origin gh-pages || { echo "Git push failed"; exit 1; }

echo "✅ Deployment completed successfully"