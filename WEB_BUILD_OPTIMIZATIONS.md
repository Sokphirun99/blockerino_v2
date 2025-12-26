# Web Build Optimizations

This document describes the optimizations applied to improve web performance.

## Build Commands

### Production Build (Recommended)
```bash
flutter build web --release \
  --web-renderer canvaskit \
  --source-maps \
  --tree-shake-icons \
  --dart-define=dart.vm.product=true
```

### Smaller Bundle Size (HTML renderer)
```bash
flutter build web --release \
  --web-renderer html \
  --tree-shake-icons \
  --dart-define=dart.vm.product=true
```

### Profile Build (for performance testing)
```bash
flutter build web --profile \
  --source-maps
```

## Optimization Flags Explained

- `--release`: Enables production optimizations (minification, tree-shaking)
- `--web-renderer canvaskit`: Better performance for graphics-heavy apps (like this game)
- `--web-renderer html`: Smaller bundle size, good for simple UIs
- `--tree-shake-icons`: Removes unused icons from the bundle
- `--source-maps`: Helps debug production issues
- `--dart-define=dart.vm.product=true`: Additional size optimizations

## Service Worker

The app now includes a service worker (`flutter_service_worker_template.js`) that:
- Caches critical resources for offline support
- Improves load times on repeat visits
- Implements cache-first strategy for assets

## Additional Optimizations Applied

1. **Removed unused Firebase services** (-2-3 MB)
   - Removed: messaging, storage, functions, remote_config, performance
   - Kept: core, auth, firestore, analytics, crashlytics

2. **Replaced google_fonts with asset fonts** (-500 KB)
   - No more runtime font downloads
   - Fonts loaded directly from assets

3. **Optimized audio assets** (-3.8 MB)
   - bgm_loop.mp3: 7.1 MB → 3.6 MB (50% reduction)
   - blast.wav → blast.mp3: 274 KB → 14 KB (95% reduction)

4. **Optimized icon images** (-4.7 MB)
   - app_icon_1.png: 2.8 MB → 429 KB (85% reduction)
   - app_icon.png: 2.4 MB → 375 KB (84% reduction)

5. **Web-specific optimizations**
   - Service worker for caching
   - Preconnect hints for external resources
   - Loading indicator to prevent blank screen
   - Progressive Web App (PWA) support

## Expected Performance Improvements

- **Initial Load Time**: 30-50% faster due to smaller bundle
- **Asset Load Time**: 60-80% faster due to optimized assets
- **Offline Support**: App works offline after first load
- **Repeat Visits**: 80-90% faster due to service worker caching

## Testing Performance

1. Build in profile mode:
   ```bash
   flutter run --profile --web-renderer canvaskit
   ```

2. Use Chrome DevTools:
   - Performance tab: Record loading and gameplay
   - Network tab: Check asset sizes and load times
   - Lighthouse: Run PWA and performance audits

3. Check bundle size:
   ```bash
   flutter build web --release
   du -sh build/web/
   ```

## Further Optimizations (Future)

- Implement deferred loading for non-critical features
- Use WebP images instead of PNG/JPEG
- Implement code splitting for different game modes
- Add asset preloading based on user behavior
- Consider using Wasm compilation when stable
