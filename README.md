# Intelligent EV Charging and V2G Energy Management in a Smart Grid

MATLAB/Simulink project for coordinating electric-vehicle charging and
vehicle-to-grid operation using feeder demand, renewable generation,
electricity price, connected-fleet availability, and aggregate battery state
of charge.

## Project overview

The project uses a two-timescale design:

1. A 24-hour supervisory smart-grid model performs fleet-level scheduling with
   15-minute time steps.
2. Selected commands can later be evaluated using a short-duration detailed
   bidirectional charger model.

Positive EV power represents grid-to-vehicle charging. Negative EV power
represents V2G discharging.

```text
Grid power = base load - renewable power + EV power
```

## Requirements

- MATLAB R2024a or R2024b
- Simulink
- Fuzzy Logic Toolbox for the planned ANFIS controller
- Optimization Toolbox for the planned optimal scheduler
- Simscape Electrical for future detailed converter integration

## Run the model

1. Download or clone this repository.
2. Open MATLAB and set the Current Folder to the repository root.
3. Run:

   ```matlab
   run("scripts/run_ev_smart_grid.m")
   ```

4. Open the model from:

   ```text
   models/supervisory/EV_SmartGrid.slx
   ```

The script initializes the scenario, runs the simulation, prints the main
performance indicators, and updates the files in `results/`.

## Current baseline results

![Twenty-four-hour smart-grid result](results/baseline_results.png)

| Metric | Result |
|---|---:|
| Peak grid demand | 446.2 kW |
| Peak-to-average ratio | 2.101 |
| Grid energy imported | 5151.0 kWh |
| Grid energy exported | 0.0 kWh |
| Renewable utilization | 100.0% |
| Final aggregate fleet SOC | 81.2% |

These values describe the present rule-based baseline, not the final optimized
or ANFIS controller.

## Redesigned G2V output

![G2V charging outputs](images/g2v_charging_outputs.png)

During grid-to-vehicle operation, battery SOC increases gradually. Battery
current shows a short starting transient followed by controlled switching
ripple, while battery voltage approaches its regulated value.

## Redesigned V2G output

![V2G discharging outputs](images/v2g_discharging_outputs.png)

During vehicle-to-grid operation, battery SOC decreases gradually while
battery current and voltage remain approximately constant. These two detailed
converter panels are improved presentations of the supplied reference output
traces. They should be replaced with newly exported results after the detailed
charger is connected to the supervisory controller.

## Baseline controller

The current controller follows this priority:

1. Enforce SOC and connected-fleet safety.
2. Absorb available renewable surplus.
3. Charge during low-price periods.
4. Discharge during feeder peaks or high-price periods.
5. Maintain useful departure SOC.
6. Enforce charger and transformer limits.

## Main parameters

| Parameter | Value |
|---|---:|
| Simulation horizon | 24 hours |
| Sample time | 0.25 hour |
| Fleet size | 50 EVs |
| Aggregate capacity | 3000 kWh |
| Initial SOC | 45% |
| Target SOC | 80% |
| Minimum SOC | 20% |
| Maximum SOC | 95% |
| Maximum charge power | 360 kW |
| Maximum V2G power | 250 kW |
| Transformer limit | 500 kW |

## Repository structure

```text
.
|-- models/
|   `-- supervisory/EV_SmartGrid.slx
|-- scripts/
|   |-- init_ev_smart_grid.m
|   |-- ev_ems_controller.m
|   |-- ev_soc_rate.m
|   |-- build_ev_smart_grid_model.m
|   `-- run_ev_smart_grid.m
|-- results/
|   |-- baseline_results.png
|   `-- baseline_results.mat
|-- images/
|   |-- g2v_charging_outputs.png
|   `-- v2g_discharging_outputs.png
|-- report/
|   `-- EV_SmartGrid_V2G_Project_Report.pdf
`-- README.md
```

## Future development

- Add uncontrolled-charging and no-EV comparison cases.
- Generate optimal schedules using constrained optimization.
- Train a Sugeno ANFIS controller from the optimized schedules.
- Add a three-state charge, idle, and discharge command interface.
- Validate selected commands using a detailed bidirectional charger.
- Measure converter efficiency, DC-link stability, battery stress, and grid
  current total harmonic distortion.
- Create an interactive MATLAB App Designer dashboard.

## Project report

The complete project explanation, equations, parameters, results, redesigned
output figures, integration method, and future development plan are provided in
[`report/EV_SmartGrid_V2G_Project_Report.pdf`](report/EV_SmartGrid_V2G_Project_Report.pdf).

## Disclaimer

This model is intended for simulation, education, and research. It has not been
validated for direct control of real chargers, batteries, or utility equipment.
