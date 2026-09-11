function Pev = ev_ems_controller(u)
%EV_EMS_CONTROLLER Safe baseline charging/V2G controller.
%   u = [baseLoad_kW; renewable_kW; price_EURperkWh; SOC; connectedFraction]
%   Pev > 0 charges the fleet; Pev < 0 exports power through V2G.
%
% Replace this function with an ANFIS/Fuzzy Logic Controller block after
% generating and validating the neuro-fuzzy controller.

Pbase = u(1);
Pres = u(2);
price = u(3);
soc = u(4);
connectedFraction = min(max(u(5),0),1);

fleetChargeLimit = 360*connectedFraction;
fleetDischargeLimit = 250*connectedFraction;
transformerLimit = 500;
netWithoutEV = Pbase - Pres;

if connectedFraction < 0.02
    Pev = 0;
elseif soc <= 0.23
    % Battery protection has highest priority.
    Pev = fleetChargeLimit;
elseif Pres > Pbase && soc < 0.90
    % Absorb otherwise surplus renewable generation.
    Pev = min(fleetChargeLimit,Pres-Pbase);
elseif price <= 0.11 && soc < 0.80
    % Charge during the low-tariff period.
    Pev = 0.75*fleetChargeLimit;
elseif netWithoutEV >= 390 && soc > 0.55
    % Support the grid close to its peak.
    Pev = -min(fleetDischargeLimit,netWithoutEV-350);
elseif price >= 0.28 && soc > 0.60
    Pev = -0.45*fleetDischargeLimit;
elseif soc < 0.65
    % Gentle background charging to preserve departure readiness.
    Pev = 0.25*fleetChargeLimit;
else
    Pev = 0;
end

% Physical safety limits.
if soc <= 0.20 && Pev < 0
    Pev = 0;
elseif soc >= 0.95 && Pev > 0
    Pev = 0;
end

Pev = min(Pev,fleetChargeLimit);
Pev = max(Pev,-fleetDischargeLimit);

% Do not exceed the grid import/transformer limit.
Pev = min(Pev,transformerLimit-netWithoutEV);
Pev = max(Pev,-fleetDischargeLimit);
end

