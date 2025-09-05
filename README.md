# MapMaker - Compass App

A standalone iOS compass app that displays a precise north-pointing needle using Core Location heading data.

## Features

- **Accurate Compass**: Points to true north (when available) or magnetic north
- **Smooth Animation**: Circular low-pass filtering for stable, jitter-free rotation
- **Accuracy Indicator**: Color-coded accuracy display (green/yellow/red)
- **Debug Mode**: Tap "Debug" to see raw heading, smoothed heading, and accuracy
- **Battery Efficient**: Stops updates when app goes to background

## How to Test

### Basic Testing
1. **Grant Location Permission**: When prompted, allow location access for compass functionality
2. **Go Outside**: For best accuracy, test outdoors away from metal objects
3. **Rotate Slowly**: Turn your device slowly - the needle should track smoothly
4. **Compare with Apple Compass**: Open the built-in Compass app to verify readings match

### Accuracy Testing
- **Green Indicator**: Excellent accuracy (<10°) - readings should be very stable
- **Yellow Indicator**: Good accuracy (10-25°) - readings should be reasonably stable  
- **Red Indicator**: Poor accuracy (>25°) - readings may be jumpy

### Edge Case Testing
- **Indoors**: Test near metal objects, electronics - accuracy should degrade gracefully
- **Near 0°/360°**: Rotate through north - no sudden jumps or flips
- **Background/Foreground**: App should stop/start updates when backgrounded

## Technical Details

### Smoothing Algorithm
- Uses circular low-pass filtering on unit vectors
- Exponential moving average with 15% smoothing factor
- Prevents angle wraparound issues (359°→0°)
- Target responsiveness: 150-300ms

### Accuracy Filtering
- Discards readings with accuracy < 0° or > 25°
- Prefers true north over magnetic north
- Shows accuracy warning when > 15°

### Performance
- 60 FPS rendering
- Minimal layout recalculations
- Efficient Core Location usage

## Troubleshooting

- **"Compass Unavailable"**: Device doesn't support compass (rare on modern iPhones)
- **Poor Accuracy**: Move to open area, away from metal objects
- **Jumpy Needle**: Check for magnetic interference, try recalibrating
- **No Updates**: Check location permissions in Settings

## Manual Test Checklist

- [ ] Needle points north when device faces north
- [ ] Smooth rotation with no stutter near 0°/360°
- [ ] Readings match Apple Compass app within accuracy bounds
- [ ] Accuracy indicator responds to environment changes
- [ ] App remains stable in poor signal conditions
- [ ] Background/foreground transitions work correctly
