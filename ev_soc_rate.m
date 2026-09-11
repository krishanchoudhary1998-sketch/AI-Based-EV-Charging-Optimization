function dSOCdt = ev_soc_rate(u)
%EV_SOC_RATE Aggregate fleet SOC derivative in per-hour units.
%   u = [Pev_kW; SOC]. SOC is included for readable block wiring and future
%   battery-limit extensions.

Pev = u(1);
totalCapacity_kWh = 50*60;
chargeEfficiency = 0.94;
dischargeEfficiency = 0.92;

if Pev >= 0
    dSOCdt = chargeEfficiency*Pev/totalCapacity_kWh;
else
    dSOCdt = Pev/(dischargeEfficiency*totalCapacity_kWh);
end
end

