# RailGuard

RailGuard is a MATLAB-based fog security model for detecting data manipulation attacks in railway signaling and control networks.

The project implements a 3-tier Edge-Fog-Cloud architecture and deploys multi-model threat detection at the fog layer for low-latency security monitoring in safety-critical railway environments.

Author: Rahul Yadav

## Project Overview

This project focuses on protecting railway signaling and control systems against cyber attacks such as false data injection, replay, spoofing, and man-in-the-middle manipulation. It combines statistical detection, classical machine learning, deep learning, and rule-based methods to identify attacks close to the source at fog nodes rather than relying only on cloud-side analysis.

## Architecture

3-tier architecture:

- Edge Layer
  - 5 simulated devices:
    - Signal Controller (S1)
    - Track Circuit Monitor (TC1)
    - Points Machine (P1)
    - Axle Counter (AC1)
    - Eurobalise (B1)
- Fog Layer
  - 3 fog nodes:
    - Station Fog Node
    - Junction Fog Node
    - Lineside Fog Node
- Cloud Layer
  - Centralized monitoring
  - Model retraining
  - Alert aggregation

Security mechanisms:
- AES-256 encryption
- RSA-2048 key exchange
- Fog-layer low-latency inference

## Dataset

- Total samples: 15,000
- Normal samples: 10,000
- Attack samples: 5,000
- Engineered features: 20
- Train/test split used in report: 80/20

Feature groups include:
- Signal state, speed, track occupancy
- Deviation metrics
- Network metrics such as latency and packet size
- Integrity validation / hash checks
- Safety consistency checks

## Attack Types Covered

- False Data Injection (FDI)
- Replay Attack
- Man-in-the-Middle (MITM)
- Denial of Service (DoS)
- Signal Spoofing
- Command Manipulation

## Detection Models

The project includes seven detection approaches:

1. Statistical Anomaly Detector
2. Support Vector Machine (SVM)
3. Random Forest
4. K-Nearest Neighbors (KNN)
5. LSTM Neural Network
6. Rule-Based IDS
7. Weighted Ensemble Model

## Reported Results

From the included project report:

| Model | Accuracy | Precision | Recall | F1-Score |
|---|---:|---:|---:|---:|
| Statistical | 0.8060 | 0.6359 | 0.9780 | 0.7707 |
| SVM | 0.9380 | 0.9744 | 0.8360 | 0.8999 |
| Random Forest | 0.9990 | 1.0000 | 0.9970 | 0.9985 |
| KNN | 0.8980 | 0.8998 | 0.7810 | 0.8362 |
| LSTM | 0.9710 | 0.9989 | 0.9140 | 0.9546 |
| Rule-Based | 0.5703 | 0.4022 | 0.5940 | 0.4796 |
| Ensemble | 0.9907 | 0.9755 | 0.9970 | 0.9862 |

Key findings:
- Best single model: Random Forest
- Ensemble accuracy: 99.1%
- Ensemble recall: 99.7%
- Fog detection latency advantage: about 25.2x faster than cloud-side processing
- Real-time target under 500 ms: achieved

## Standards and Compliance

The report references alignment with:
- ERTMS/ETCS SUBSET-026
- EN 50129
- IEC 62443

## Repository Structure

```text
RailGuard/
├── README.md
├── 10_Rahul.pdf
├── main.m
├── setup.m
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
    ├── tables/
    └── logs/
```

## Important Files

- `10_Rahul.pdf` - project report
- `main.m` - main execution pipeline
- `setup.m` - environment setup
- `run_pipeline.m` - data pipeline execution
- `run_security_models.m` - model training and evaluation
- `run_tuning_and_visualization.m` - visualization and tuning workflow
- `run_phase7_only.m` - targeted phase execution
- `results/FULL_PROJECT_REPORT.txt` - full text project report
- `results/PROJECT_SUMMARY.txt` - concise project summary

## How to Run

Typical MATLAB workflow:

1. Open the project in MATLAB or MATLAB Online
2. Run `setup.m`
3. Run `main.m`

For staged execution, use:
- `run_pipeline.m`
- `run_security_models.m`
- `run_tuning_and_visualization.m`
- `run_phase7_only.m`

## Outputs Included

This repository includes:
- Source code under `src/`
- Test files under `tests/`
- Data artifacts under `data/`
- Trained models under `models/`
- Visualization figures under `results/figures/`
- Logs and summary outputs under `results/`

## Notes

The README description was prepared from the report files included in this folder, especially:
- `10_Rahul.pdf`
- `results/FULL_PROJECT_REPORT.txt`
- `results/PROJECT_SUMMARY.txt`
