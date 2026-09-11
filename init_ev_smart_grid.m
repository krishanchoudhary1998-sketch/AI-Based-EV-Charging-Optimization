%% INIT_EV_SMART_GRID Create one day of input data for the Simulink model
% Simulink time is expressed in hours. One sample represents 15 minutes.

Ts = 0.25;
t = (0:Ts:24)';

% Illustrative residential feeder load (kW): morning and evening peaks.
baseLoad = 220 ...
    + 85*exp(-0.5*((t-8.0)/1.6).^2) ...
    + 155*exp(-0.5*((t-19.0)/2.0).^2) ...
    + 15*sin(2*pi*(t-5)/24);

% Solar and wind production (kW).
solar = 260*max(0,sin(pi*(t-6)/12)).^1.7;
wind = 35 + 12*sin(2*pi*(t+2)/8) + 7*sin(2*pi*t/3.5);
wind = max(wind,8);
renewable = solar + wind;

% Time-of-use energy price (EUR/kWh).
price = 0.15*ones(size(t));
price(t < 6) = 0.09;
price(t >= 17 & t < 22) = 0.30;
price(t >= 22) = 0.11;

% Fraction of the EV fleet plugged in at home/work.
connected = 0.18*ones(size(t));
connected(t < 7) = 0.82;
connected(t >= 9 & t < 16) = 0.28;
connected(t >= 17 & t < 19) = 0.48;
connected(t >= 19) = 0.86;

% Variables consumed by From Workspace blocks.
baseLoadTS = timeseries(baseLoad,t);
renewableTS = timeseries(renewable,t);
priceTS = timeseries(price,t);
connectedTS = timeseries(connected,t);

% Aggregate fleet parameters used by ev_ems_controller and ev_soc_rate.
evp.sampleTime_h = Ts;
evp.fleetSize = 50;
evp.totalCapacity_kWh = 50*60;
evp.maxCharge_kW = 50*7.2;
evp.maxDischarge_kW = 50*5.0;
evp.chargeEfficiency = 0.94;
evp.dischargeEfficiency = 0.92;
evp.initialSOC = 0.45;
evp.minimumSOC = 0.20;
evp.maximumSOC = 0.95;
evp.targetSOC = 0.80;
evp.transformerLimit_kW = 500;

