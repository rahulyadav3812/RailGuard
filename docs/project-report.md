# RailGuard Project Report

Clean markdown summary of the included academic report for the RailGuard project.

Original report sources used for this document:
- `10_Rahul.pdf`
- `results/FULL_PROJECT_REPORT.txt`
- `results/PROJECT_SUMMARY.txt`

## Project title

Design of a MATLAB-Based Fog Security Model to Detect Data Manipulation in Railway Signaling and Control Networks

## Abstract

This project presents a fog computing-based security model for detecting data manipulation attacks in railway signaling and control networks. The system uses a 3-tier Edge-Fog-Cloud architecture and deploys machine learning detection at the fog layer for low-latency threat identification. Seven detection models are trained and evaluated across six railway-specific attack types.

## Objectives

- detect malicious data manipulation in railway signaling environments
- reduce detection latency by moving inference closer to edge devices
- compare statistical, machine learning, deep learning, and rule-based approaches
- evaluate whether fog-layer security monitoring can meet real-time constraints
- align the system with relevant railway and industrial cybersecurity standards

## System architecture

### Edge layer

The edge layer simulates five operational devices:
- Signal Controller (S1)
- Track Circuit Monitor (TC1)
- Points Machine (P1)
- Axle Counter (AC1)
- Eurobalise (B1)

### Fog layer

The fog layer contains three nodes responsible for local real-time detection:
- Station Fog Node
- Junction Fog Node
- Lineside Fog Node

### Cloud layer

The cloud layer is responsible for:
- centralized monitoring
- alert aggregation
- long-term analysis
- model retraining

### Security mechanisms

The report references the following security measures:
- AES-256 encryption
- RSA-2048 key exchange

## Dataset

| Metric | Value |
|---|---|
| Total samples | 15,000 |
| Normal samples | 10,000 |
| Attack samples | 5,000 |
| Train/test split | 80/20 |
| Training set | 12,000 samples |
| Testing set | 3,000 samples |
| Engineered features | 20 |

Feature categories include:
- signal state, speed, and track occupancy
- deviation metrics
- network metrics such as latency and packet size
- integrity checks based on hash validation
- safety consistency checks across railway signals and commands

## Attack types evaluated

| Attack type | Samples | Description |
|---|---:|---|
| False Data Injection | 1,000 | Manipulates sensor readings |
| Replay Attack | 800 | Replays captured packets |
| Man-in-the-Middle | 800 | Intercepts and modifies data |
| Denial of Service | 800 | Floods the network with traffic |
| Signal Spoofing | 800 | Fakes signal aspects |
| Command Manipulation | 800 | Alters control commands |

## Detection models

### 1. Statistical Anomaly Detector
- Z-score based detection
- threshold = 2.5
- baseline derived from normal training data

### 2. Support Vector Machine
- RBF kernel
- automatic kernel scale
- posterior probability calibration

### 3. Random Forest
- 100 trees
- minimum leaf size = 5
- out-of-bag prediction and feature importance support

### 4. K-Nearest Neighbors
- K = 5
- squared-inverse distance weighting
- standardized features

### 5. LSTM Neural Network
- 2-layer LSTM
- 128 and 64 hidden units
- dropout = 0.3
- Adam optimizer
- 30 epochs

### 6. Rule-Based IDS
- 20 railway-specific safety rules
- weighted rule-violation scoring

### 7. Weighted Ensemble
- model weights: `[0.15, 0.15, 0.35, 0.10, 0.15, 0.10]`
- decision threshold = 0.35
- strongest weighting assigned to Random Forest

## Results summary

| Model | Accuracy | Precision | Recall | F1-Score |
|---|---:|---:|---:|---:|
| Statistical | 0.8060 | 0.6359 | 0.9780 | 0.7707 |
| SVM | 0.9380 | 0.9744 | 0.8360 | 0.8999 |
| Random Forest | 0.9990 | 1.0000 | 0.9970 | 0.9985 |
| KNN | 0.8980 | 0.8998 | 0.7810 | 0.8362 |
| LSTM | 0.9710 | 0.9989 | 0.9140 | 0.9546 |
| Rule-Based | 0.5703 | 0.4022 | 0.5940 | 0.4796 |
| Ensemble | 0.9907 | 0.9755 | 0.9970 | 0.9862 |

## Key findings

- Best single model: Random Forest with F1 score of 0.9985
- Ensemble model accuracy: 99.1%
- Ensemble model recall: 99.7%
- Ensemble model precision: 97.6%
- Fog-based detection achieved strong real-time performance in the reported evaluation

## Per-attack detection rates

| Attack type | Samples | Detected | Rate |
|---|---:|---:|---:|
| FDI | 200 | 200 | 100.0% |
| Replay | 160 | 157 | 98.1% |
| MITM | 160 | 160 | 100.0% |
| DoS | 160 | 160 | 100.0% |
| Spoofing | 160 | 160 | 100.0% |
| Command Manipulation | 160 | 160 | 100.0% |

## Latency analysis

| Metric | Value |
|---|---|
| Fog layer latency (1000 samples) | 4.14 ms |
| Cloud layer latency (1000 samples) | 104.14 ms |
| Per-sample fog latency | 0.0041 ms |
| Per-sample cloud latency | 0.1041 ms |
| Fog speedup | 25.2x faster |
| Real-time target | < 500 ms achieved |

## Figures generated

The report references the following generated figures:
- `results/figures/01_architecture.png`
- `results/figures/02_data_distribution.png`
- `results/figures/03_attack_distribution.png`
- `results/figures/04_correlation.png`
- `results/figures/05_pca.png`
- `results/figures/06_performance.png`
- `results/figures/07_roc.png`
- `results/figures/08_confusion.png`
- `results/figures/09_per_attack.png`
- `results/figures/10_latency.png`
- `results/figures/11_training.png`
- `results/figures/12_fog_stats.png`

## Repository assets referenced by the report

- `main.m`
- `setup.m`
- `run_pipeline.m`
- `run_security_models.m`
- `run_tuning_and_visualization.m`
- `src/`
- `tests/`
- `data/`
- `models/`
- `results/`

## Standards and compliance references

The report references alignment with:
- ERTMS/ETCS SUBSET-026
- EN 50129
- IEC 62443
- SIL-4 detection target
- real-time detection target under 500 ms

## Conclusions

According to the included report, the project demonstrates:

1. High detection accuracy for railway data-manipulation attack detection
2. Low-latency fog-layer inference compared with cloud-only processing
3. Broad attack coverage across six attack classes
4. A scalable Edge-Fog-Cloud security architecture
5. A defense-in-depth strategy that combines ML, deep learning, statistical detection, and safety rules

## Notes

This markdown document is a cleaned and repository-friendly rewrite of the included report materials. It is intended to make the project easier to review on GitHub without relying on the original PDF alone.
