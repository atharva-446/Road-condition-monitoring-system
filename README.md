
# Road Condition & Vehicle Leaf-Spring Monitoring System

An IoT-based edge monitoring system designed to analyze road-induced vehicle vibrations, monitor left and right leaf-spring behavior, and associate sensor observations with geographical locations.

<p align="center">
  <strong>Embedded Systems • IoT • Edge Computing • PCB Design • Mobile Application</strong>
</p>

---

## Overview

Road condition assessment is often manual, time-consuming, and dependent on subjective inspection. Road irregularities can affect vehicle suspension systems, while excessive vehicle loading can contribute to increased stress on vehicle components and road infrastructure.

This project proposes an integrated monitoring platform that combines inertial sensing, GNSS positioning, Raspberry Pi-based processing, cloud data storage, and a Flutter mobile application.

The system is designed to collect vibration and orientation data, record geographical coordinates, monitor independent left and right leaf-spring behavior, and provide a convenient interface for viewing monitoring sessions.

## Key Objectives

- Collect motion and orientation measurements associated with vehicle vibrations.
- Monitor left and right leaf-spring behavior independently.
- Record geographical coordinates using a GNSS module.
- Process sensor readings using a Raspberry Pi edge-computing platform.
- Store monitoring data for subsequent analysis and reporting.
- Provide mobile access to live telemetry and previous monitoring sessions.
- Establish a foundation for automated road-anomaly classification and vehicle suspension analysis.

## System Architecture

The system is organized into five major stages:

1. **Sensing:** The BNO055 captures inertial measurements associated with vehicle motion and vibration.
2. **Positioning:** The Reyax RY352A GNSS module provides geographical positioning data.
3. **Edge processing:** The Raspberry Pi 4 Model B collects and processes incoming sensor data.
4. **Storage and analysis:** The proposed architecture includes cloud/database storage, CSV-based data handling, and TinyML-based analysis.
5. **Mobile monitoring:** The Flutter application presents telemetry, location information, sensor calibration controls, and monitoring-session logs.

### High-Level Data Flow

```text
Vehicle Leaf-Spring Assembly
            |
            v
      BNO055 Sensor
            |
            +------------------+
                               |
      Reyax RY352A GNSS -------+
                               |
                               v
                   Raspberry Pi 4 Model B
                               |
                               v
                  Data Processing / Logging
                               |
                 +-------------+-------------+
                 |             |             |
                 v             v             v
            Cloud / DB      CSV Data      TinyML*
                 |             |             |
                 +-------------+-------------+
                               |
                               v
                    Flutter Mobile App
                               |
                               v
                 Telemetry / Maps / Logs /
                   Session Report Export
```

*TinyML integration and automated classification are architectural objectives; their operational status should be verified against the current source code.*

## Hardware Components

| Component | Purpose |
|---|---|
| Raspberry Pi 4 Model B | Main processing and edge-computing unit |
| BNO055 9-DOF sensor | Inertial sensing and orientation measurements |
| Reyax RY352A GNSS module | Geographical positioning |
| Lithium-ion battery cells | Portable power supply |
| LM2596 DC-DC buck converter | Regulated voltage conversion |
| 2S Battery Management System (BMS) | Battery protection and management |

### Sensor and Positioning Subsystem

The BNO055 provides inertial measurements that can be used to analyze vehicle movement and vibration. GNSS positioning associates collected observations with geographical coordinates.

Combining motion data and location information provides the basis for investigating road irregularities and correlating observations with specific road segments.

### Power Subsystem

The battery pack, LM2596 buck converter, and 2S BMS form the proposed portable power subsystem. Appropriate voltage regulation, battery protection, and wiring must be verified before field deployment.

## Software and Development Tools

| Tool / Platform | Role |
|---|---|
| Python | Raspberry Pi-side programming, if used in the implementation |
| Flutter | Cross-platform mobile application |
| Firebase | Cloud/database services, as configured |
| Google Sheets | Data logging and analysis workflow, where integrated |
| KiCad | Electronic schematic and PCB design |
| SolidWorks | 3D mechanical design, as applicable |
| MATLAB | Sensor-data analysis and signal processing, as applicable |
| CSV | Structured data export and analysis |

The exact libraries, communication interfaces, cloud configuration, and processing algorithms will be documented alongside the corresponding source files.

## Mobile Application

The application interface shown in the project presentation includes the following features.

### 1. Home and Telemetry Dashboard

- Vehicle road-vibration monitoring interface.
- Left and right leaf-spring measurement panels.
- GPS telemetry and positioning status.
- Sensor calibration status and controls.
- Start and Stop controls for monitoring sessions.

### 2. GPS Route View

- Displays geographical position and route information.
- Supports associating monitoring sessions with locations.

### 3. Session Logs and Reports

- Displays previous monitoring sessions.
- Shows session timestamps and recorded event information.
- Includes a PDF report download option in the presented interface.

*Actual feature availability depends on the current application implementation and connected data services.*

## PCB Design

The hardware design workflow includes:

- Electronic schematic development in KiCad.
- Component and connector arrangement.
- PCB track routing.
- Three-dimensional PCB visualization.
- Interface planning for the Raspberry Pi, BNO055, and GNSS module.

The design files and rendered PCB views will be added to the `hardware/` and `docs/` directories as they are prepared for publication.

## Working Principle

1. Power on the monitoring system and initialize the connected hardware.
2. Initialize the inertial sensor and GNSS module.
3. Perform sensor calibration and verify positioning status.
4. Begin a monitoring session using the application controls.
5. Acquire motion measurements and geographical coordinates.
6. Process and record the collected data using the configured Raspberry Pi software.
7. Transfer data to the configured storage and logging services.
8. Present available telemetry and session information in the mobile application.
9. Stop the session and review the recorded data and available reports.

## Repository Structure

```text
road-condition-monitoring-system/
├── README.md
├── raspberry-pi/
│   ├── README.md
│   ├── requirements.txt
│   └── src/
├── mobile-app/
│   ├── README.md
│   ├── pubspec.yaml
│   └── lib/
├── hardware/
│   ├── schematic/
│   ├── pcb/
│   └── 3d-views/
├── docs/
│   ├── architecture/
│   └── reports/
├── images/
│   ├── app/
│   ├── hardware/
│   └── pcb/
└── .gitignore
```

This is the intended organization. Folder names and contents should match the files actually committed to the repository.

## Current Development Status

The project presentation documents the hardware selection, system architecture, schematic, PCB routing, 3D PCB views, and mobile application interface.

The public repository will be updated with the corresponding source code, hardware design files, setup instructions, and test results as they are prepared.

Implementation status of cloud synchronization, TinyML classification, automatic anomaly detection, and PDF report generation should be verified individually before describing those features as fully operational.

## Future Improvements

- Develop a machine-learning classifier to distinguish potholes, speed bumps, and other road irregularities.
- Evaluate sensor performance at different vehicle speeds.
- Improve sensor calibration, noise filtering, and measurement repeatability.
- Develop location-based road-condition visualization.
- Compare left and right leaf-spring behavior under different operating conditions.
- Add validated anomaly statistics and downloadable reports.
- Evaluate detection accuracy using labeled road-test data.

## Testing and Validation

Testing should evaluate:

- Sensor initialization and calibration.
- GNSS positioning reliability.
- Data collection and timestamp consistency.
- Cloud connectivity and data integrity.
- Mobile application Start/Stop behavior.
- PCB connectivity and power regulation.
- Repeatability of measurements under controlled conditions.

Measured results, accuracy values, and performance benchmarks will be added after testing. No quantitative performance claims are made here.

## Safety and Configuration

- Do not commit Firebase private keys, service-account files, API secrets, or Wi-Fi credentials.
- Store environment-specific configuration outside version control.
- Document hardware voltage requirements and power connections before replication.
- Test the system in a controlled environment before vehicle deployment.
- Follow applicable electrical, battery-handling, and road-testing safety procedures.

## Author

**Atharva Jadhav**

Electronics and Telecommunication Engineering

- GitHub: [atharva-446](https://github.com/atharva-446)
- Portfolio: [atharvajadhav.co.in](https://atharvajadhav.co.in)
- LinkedIn: [atharvajadhav01](https://linkedin.com/in/atharvajadhav01)

---

## Project Note

This repository documents an engineering project involving embedded systems, inertial sensing, GNSS, edge computing, PCB development, and mobile application design. Implementation details and test results will be maintained alongside the corresponding project files.
