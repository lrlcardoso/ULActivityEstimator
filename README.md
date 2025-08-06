# RehabTrack Workflow – Upper Limb Activity Estimator

This is part of the [RehabTrack Workflow](https://github.com/lrlcardoso/RehabTrack_Workflow): a modular pipeline for **tracking and analysing physiotherapy movements**, using video and IMU data.  
This module estimates **upper limb activity** from binary “use” signals and synchronized IMU data, producing quantitative measures such as activity duration, intensity levels, and number of repetitions for each limb.

---

## 📌 Overview

This module performs:
- **Loading** binary “use” signals generated from GrossMovDetector stage, and synchronized IMU data generated from DataSynchronization stage.
- **Calculating** number of repetitions for each arm
- **Estimating** activity intensity and intensity levels
- **Measuring** total duration of activity per limb
- **Generating** patient-specific Excel sheets summarising results
- **Plotting and saving** activity graphs for visual inspection

**Inputs:**
- Binary “use” signals from the GrossMovDetector stage
- Synchronized IMU data generated from DataSynchronization stage
- Session and segment metadata

**Outputs:**
- Excel sheets summarising repetitions, duration, and intensity per limb
- Activity plots for each patient/session

---

## 📂 Repository Structure

```
UL_Activity_Estimator/
├── main.m                       # Main script to run the estimation pipeline
├── lib/                         # MATLAB helper functions
│   ├── create_patient_sheet.m    # Create summary Excel sheets
│   ├── intensity.m               # Compute overall intensity
│   ├── intensity_levels.m        # Classify activity into intensity levels
│   ├── natsort.m                  # Natural sorting utility
│   ├── number_of_repetitions.m   # Count repetitions
│   ├── plot_and_save_graphs.m    # Generate and save activity plots
│   ├── prepare_seg.m              # Prepare segment information
│   ├── segment_duration.m         # Calculate segment durations
└── README.md
```

---

## 🛠 Requirements

- MATLAB R2020b or later  
- Spreadsheet Toolbox (for Excel writing functions)

---

## 🚀 Usage

1. Open MATLAB and set the repo folder as the current working directory.
2. Edit `main.m` to update:
   - Paths to input “use” signal files
   - Output folder paths
   - Patient/session configuration
3. Run:
```matlab
main
```

**Inputs:**  
- Binary “use” signals from the GrossMovDetector stage
- Synchronized IMU data generated from DataSynchronization stage
- Session/segment metadata files  

**Outputs:**  
- Excel sheets summarising repetitions, durations, and intensity levels  
- Activity plots for each session/patient  

---

## 📖 Citation

If you use this module, please cite:
```
Cardoso, L. R. L. (2025). RehabTrack Workflow: A Modular Hybrid Video–IMU Pipeline for Analysing Upper-Limb Physiotherapy Data (v1.0.0). Zenodo. https://doi.org/10.5281/zenodo.16756215
```

---

## 📝 License

Code: [MIT License](LICENSE)  

---

## 🤝 Acknowledgments

- MATLAB Spreadsheet Toolbox
