
# Road Condition Monitoring System

An IoT-based project designed to monitor road surface conditions using motion sensors, GPS positioning, and cloud data storage.

## Overview

The system collects motion sensor data and GPS coordinates to help identify potential road anomalies. The collected data can be stored in the cloud and viewed through a monitoring interface.

## Objectives

- Collect motion sensor data for road condition analysis.
- Record GPS coordinates associated with detected road anomalies.
- Send collected data to a cloud platform.
- Display and monitor recorded information through a Flutter application.
- Establish a foundation for future road anomaly classification.

## Technology Stack

| Component | Purpose |
|---|---|
| Raspberry Pi 4 | Main processing unit |
| BNO055 / motion sensor | Motion and orientation measurements |
| GPS module | Location coordinates |
| Firebase | Cloud data storage |
| Python | Hardware integration and data processing |
| Flutter | Mobile monitoring interface |

## System Workflow

1. Initialize the sensors and GPS module.
2. Collect motion measurements and location data.
3. Process the collected readings.
4. Send the data to the cloud.
5. Display recorded information in the monitoring application.
6. Analyze the data to identify potential road anomalies.

## Repository Structure

```text
road-condition-monitoring-system/
├── README.md
├── src/
├── hardware/
├── docs/
└── images/
```

*The folders will be populated as the source code, hardware files, documentation, and project images are added.*

## Current Status

Project documentation and repository setup are in progress. Implementation details, testing results, and supported features will be documented as they are added.

## Future Improvements

- Develop a machine learning model to distinguish potholes from speed bumps and other road irregularities.
- Improve detection reliability across different vehicle speeds.
- Add visualization of detected locations on a map.
- Evaluate detection performance using collected test data.

## Author

**Atharva Jadhav**

Electronics and Telecommunication Engineering

- GitHub: https://github.com/atharva-446
- Portfolio: https://atharvajadhav.co.in

---

This project is intended for educational and engineering development purposes.
