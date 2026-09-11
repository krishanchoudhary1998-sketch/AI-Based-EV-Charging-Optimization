%% BUILD_EV_SMART_GRID_MODEL Programmatically create EV_SmartGrid.slx

model = 'EV_SmartGrid';
if bdIsLoaded(model)
    close_system(model,0);
end
if isfile(model + ".slx")
    delete(model + ".slx");
end

new_system(model);
open_system(model);
load_system('simulink');

matlabFcnBlocks = find_system('simulink','LookUnderMasks','all', ...
    'FollowLinks','on','Name','MATLAB Function');
assert(~isempty(matlabFcnBlocks), ...
    'The Simulink MATLAB Function block is not installed.');
matlabFcnBlock = matlabFcnBlocks{1};

% Source profiles
add_block('simulink/Sources/From Workspace',[model '/Base Load'], ...
    'VariableName','baseLoadTS','Position',[35 55 145 85]);
add_block('simulink/Sources/From Workspace',[model '/Renewable Power'], ...
    'VariableName','renewableTS','Position',[35 125 145 155]);
add_block('simulink/Sources/From Workspace',[model '/Electricity Price'], ...
    'VariableName','priceTS','Position',[35 195 145 225]);
add_block('simulink/Sources/From Workspace',[model '/Connected EV Fraction'], ...
    'VariableName','connectedTS','Position',[35 265 145 295]);

% EMS has five explicit scalar inputs. Its code calls the editable baseline
% controller in ev_ems_controller.m.
add_block(matlabFcnBlock,[model '/EMS Controller'], ...
    'Position',[260 105 455 235]);
rt = sfroot;
emsChart = rt.find('-isa','Stateflow.EMChart', ...
    'Path',[model '/EMS Controller']);
emsChart.Script = sprintf([ ...
    'function Pev = fcn(Pbase, Pres, price, soc, connectedFraction)\n' ...
    'Pev = ev_ems_controller([Pbase; Pres; price; soc; connectedFraction]);\n' ...
    'end\n']);

% Battery/fleet SOC dynamics
add_block(matlabFcnBlock,[model '/SOC Rate'], ...
    'Position',[535 225 685 295]);
socChart = rt.find('-isa','Stateflow.EMChart','Path',[model '/SOC Rate']);
socChart.Script = sprintf([ ...
    'function dSOCdt = fcn(Pev, soc)\n' ...
    'dSOCdt = ev_soc_rate([Pev; soc]);\n' ...
    'end\n']);
add_block('simulink/Discrete/Discrete-Time Integrator',[model '/Fleet SOC'], ...
    'SampleTime','0.25','InitialCondition','0.45', ...
    'LimitOutput','on','UpperSaturationLimit','0.95', ...
    'LowerSaturationLimit','0.20','Position',[720 215 775 265]);

% Grid power balance: Pgrid = Pbase - Prenewable + Pev
add_block('simulink/Math Operations/Sum',[model '/Grid Power Balance'], ...
    'Inputs','+-+','Position',[525 65 555 135]);

% Results: [base, renewable, EV, grid]
add_block('simulink/Signal Routing/Mux',[model '/Power Results'], ...
    'Inputs','4','Position',[650 30 655 165]);
add_block('simulink/Sinks/To Workspace',[model '/Save Power Results'], ...
    'VariableName','powerResults','SaveFormat','Timeseries', ...
    'Position',[730 75 850 105]);
add_block('simulink/Sinks/To Workspace',[model '/Save SOC'], ...
    'VariableName','socResult','SaveFormat','Timeseries', ...
    'Position',[830 225 930 255]);
add_block('simulink/Sinks/To Workspace',[model '/Save Price'], ...
    'VariableName','priceResult','SaveFormat','Timeseries', ...
    'Position',[285 305 385 335]);

% Connections to EMS
add_line(model,'Base Load/1','EMS Controller/1','autorouting','on');
add_line(model,'Renewable Power/1','EMS Controller/2','autorouting','on');
add_line(model,'Electricity Price/1','EMS Controller/3','autorouting','on');
add_line(model,'Fleet SOC/1','EMS Controller/4','autorouting','on');
add_line(model,'Connected EV Fraction/1','EMS Controller/5','autorouting','on');

% Grid power calculation
add_line(model,'Base Load/1','Grid Power Balance/1','autorouting','on');
add_line(model,'Renewable Power/1','Grid Power Balance/2','autorouting','on');
add_line(model,'EMS Controller/1','Grid Power Balance/3','autorouting','on');

% SOC calculation
add_line(model,'EMS Controller/1','SOC Rate/1','autorouting','on');
add_line(model,'Fleet SOC/1','SOC Rate/2','autorouting','on');
add_line(model,'SOC Rate/1','Fleet SOC/1','autorouting','on');

% Result collection
add_line(model,'Base Load/1','Power Results/1','autorouting','on');
add_line(model,'Renewable Power/1','Power Results/2','autorouting','on');
add_line(model,'EMS Controller/1','Power Results/3','autorouting','on');
add_line(model,'Grid Power Balance/1','Power Results/4','autorouting','on');
add_line(model,'Power Results/1','Save Power Results/1','autorouting','on');
add_line(model,'Fleet SOC/1','Save SOC/1','autorouting','on');
add_line(model,'Electricity Price/1','Save Price/1','autorouting','on');

set_param(model, ...
    'StartTime','0', ...
    'StopTime','24', ...
    'SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete', ...
    'FixedStep','0.25', ...
    'ReturnWorkspaceOutputs','on');

set_param(model,'ZoomFactor','FitSystem');
save_system(model);
close_system(model);
disp('Created EV_SmartGrid.slx');
