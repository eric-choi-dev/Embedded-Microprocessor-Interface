# ⚡ Embedded System Interface & Control

> **Low-level hardware interfacing and real-time system control using Assembly & C.**
> Optimized for Motorola HCS12 microprocessor architecture.

## 🛠 Tech Stack
- **Language**: Assembly (HCS12), C
- **Hardware**: Dragon12-Plus2 (HCS12), LEDs, 7-Segment Displays, DC Motors
- **Tools**: CodeWarrior IDE, D-Bug12 Monitor

## 🚀 Key Features & Implementation
* **Direct Memory Access**: Manual stack pointer management and memory allocation for optimized performance.
* **GPIO & Port Control**: Low-level drivers for LED arrays and 7-segment display multiplexing.
* **Real-Time Interrupts (RTI)**: Implemented non-blocking interrupt service routines (ISR) for precise timing without CPU waste.
* **PWM Motor Control**: Developed a Pulse Width Modulation driver to control DC motor speed and direction.
* **Hardware Debouncing**: Software-based signal processing to eliminate mechanical switch noise.

## 📂 Project Structure
- `HCS12-Assembly-Setup/`: Environment configuration and memory mapping.
- `GPIO-Port-Control/`: Bidirectional port interfacing logic.
- `DC-Motor-PWM-Driver/`: Timer-based motor control subsystem.
- `Autonomous-Robot-Navigation/`: Final implementation of logic for sensor-based movement.