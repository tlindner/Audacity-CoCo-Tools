# Audacity-CoCo-Tools
A set of Nyquist plugins to aid with data recovery of Radio Shack Color Computer data audio tapes.

## label-coco-leaders.ny
Scans selected audio to identify CoCo tape leaders (consistent frequency patterns that precede data blocks).

### What it does
Creates a label track marking leader blocks longer than 0.25 seconds. Each label shows:
1. Average high and low frequencies in the block (e.g., "850Hz/500Hz")
2. Frequency ratio (e.g., "r=1.70")
3. Number of wave pairs detected (e.g., "x42")

### Parameters
- **Target Ratio**: The frequency ratio to search for (default: 1.7)
- **Threshold (%)**: How close matches need to be to the target (default: 10%)
- **Zero Threshold**: Treat samples near zero as crossings (default: 0.01)

### Installation
1. Copy `label-coco-leaders.ny` to your Audacity Plug-Ins folder
2. Restart Audacity or use Analyze > Plug-in Manager to enable it
3. Find it under Analyze > Label CoCo Leaders

### Usage
1. Select the audio region to analyze
2. Run Analyze > Label CoCo Leaders
3. Adjust parameters if needed
4. Review the generated label track
