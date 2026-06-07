# RailGuard

MATLAB-based fog computing security project for detecting cyber attacks in railway signaling and control networks.

## Overview

RailGuard is a MATLAB implementation of a 3-tier Edge-Fog-Cloud security architecture designed to detect malicious data manipulation close to the source. The project focuses on low-latency attack detection for safety-critical railway environments by placing intelligence at the fog layer instead of relying only on centralized cloud-side analysis.

The project report and generated outputs in this repository describe a system that combines classical machine learning, deep learning, statistical anomaly detection, and rule-based detection to identify attacks on signaling and operational telemetry.

## Project Highlights

- MATLAB-based fog computing architecture for railway cybersecurity
- 3-tier deployment model: Edge -> Fog -> Cloud
- 15,000-sample dataset with 20 engineered features
- 7 detection approaches, including ensemble learning and LSTM
- Attack coverage for FDI, replay, MITM, DoS, spoofing, and command manipulation
- Reported real-time fog-layer detection within the project target
- Strong best-model and ensemble performance in the included report

## Architecture

The design uses distributed processing to perform security analysis at the fog layer.

- Edge layer
  - Signal Controller (S1)
  - Track Circuit Monitor (TC1)
  - Points Machine (P1)
  - Axle Counter (AC1)
  - Eurobalise (B1)
- Fog layer
  - Station Fog Node
  - Junction Fog Node
  - Lineside Fog Node
- Cloud layer
  - Centralized monitoring
  - Alert aggregation
  - Long-term storage
  - Model retraining

Security mechanisms described in the report:
- AES-256 encryption
- RSA-2048 key exchange
- Fog-layer low-latency inference

![RailGuard architecture](results/figures/01_architecture.png)

## Threat Model

RailGuard targets multiple cyber attack classes that can affect signaling integrity and operational decision-making:

- False Data Injection (FDI)
- Replay Attack
- Man-in-the-Middle (MITM)
- Denial of Service (DoS)
- Signal Spoofing
- Command Manipulation

## Dataset Summary

The included report notes the following dataset characteristics:

| Metric | Value |
|---|---|
| Total samples | 15,000 |
| Normal samples | 10,000 |
| Attack samples | 5,000 |
| Engineered features | 20 |
| Split referenced in report summary | 70/30 |

Feature groups include:
- signaling state and operating parameters
- deviation and consistency metrics
- latency and packet characteristics
- integrity and hash validation checks
- safety-rule consistency features

## Detection Models

RailGuard includes seven detection approaches:

1. Statistical Anomaly Detector
2. Support Vector Machine (SVM)
3. Random Forest
4. K-Nearest Neighbors (KNN)
5. LSTM Neural Network
6. Rule-Based IDS
7. Weighted Ensemble Model

## Reported Results

The following metrics are summarized from the project report files included in this repository:

| Model | Accuracy | Precision | Recall | F1-Score |
|---|---:|---:|---:|---:|
| Statistical | 0.8060 | 0.6359 | 0.9780 | 0.7707 |
| SVM | 0.9380 | 0.9744 | 0.8360 | 0.8999 |
| Random Forest | 0.9990 | 1.0000 | 0.9970 | 0.9985 |
| KNN | 0.8980 | 0.8998 | 0.7810 | 0.8362 |
| LSTM | 0.9710 | 0.9989 | 0.9140 | 0.9546 |
| Rule-Based | 0.5703 | 0.4022 | 0.5940 | 0.4796 |
| Ensemble | 0.9907 | 0.9755 | 0.9970 | 0.9862 |

Key takeaways from the report:
- Best single model: Random Forest
- Ensemble accuracy: about 99.1%
- Ensemble recall: 99.7%
- Fog-layer detection reported as significantly faster than cloud-side processing
- Real-time detection target under 500 ms reported as achieved

![Model performance comparison](results/figures/06_performance.png)

## Repository Structure

```text
RailGuard/
├── README.md
├── LICENSE
├── 10_Rahul.pdf
├── setup.m
├── main.m
├── run_pipeline.m
├── run_security_models.m
├── run_tuning_and_visualization.m
├── run_phase7_only.m
├── src/
│   ├── data_generation/
│   ├── fog_architecture/
│   ├── preprocessing/
│   ├── security_models/
│   ├── utils/
│   └── visualization/
├── tests/
├── data/
├── models/
└── results/
    ├── figures/
    ├── logs/
    └── tables/
```

## Important Files

| File | Purpose |
|---|---|
| `main.m` | Main execution pipeline |
| `setup.m` | Project setup and path initialization |
| `run_pipeline.m` | End-to-end data and workflow execution |
| `run_security_models.m` | Model training and evaluation |
| `run_tuning_and_visualization.m` | Visualization and tuning workflow |
| `run_phase7_only.m` | Focused execution for a later project stage |
| `tests/` | MATLAB test scripts |
| `results/FULL_PROJECT_REPORT.txt` | Full extracted report text |
| `results/PROJECT_SUMMARY.txt` | Concise report summary |
| `results/tables/model_comparison.csv` | Model comparison results |

## Getting Started

### Requirements

- MATLAB
- Statistics and Machine Learning Toolbox for classical ML workflows
- Deep Learning Toolbox for LSTM-related components

### Typical workflow

1. Open the project folder in MATLAB.
2. Run `setup.m`.
3. Run `main.m`.

### Alternative execution entry points

- `run_pipeline.m`
- `run_security_models.m`
- `run_tuning_and_visualization.m`
- `run_phase7_only.m`

## Outputs Included

This repository includes:
- source code under `src/`
- test files under `tests/`
- dataset artifacts under `data/`
- trained models under `models/`
- figures under `results/figures/`
- logs and summary outputs under `results/`

## Standards and References

The report references alignment with:
- ERTMS/ETCS SUBSET-026
- EN 50129
- IEC 62443

## Project Report Sources

This README is based on the project materials included in the repository, especially:
- `10_Rahul.pdf`
- `results/FULL_PROJECT_REPORT.txt`
- `results/PROJECT_SUMMARY.txt`

## Author

Rahul Yadav

## License

This project is released under the MIT License. See `LICENSE` for details.
