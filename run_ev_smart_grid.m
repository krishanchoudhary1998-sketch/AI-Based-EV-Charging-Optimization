%% RUN_EV_SMART_GRID Initialize, simulate, evaluate, and plot the model

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
modelDirectory = fullfile(projectRoot,'models','supervisory');
resultsDirectory = fullfile(projectRoot,'results');
modelFile = fullfile(modelDirectory,'EV_SmartGrid.slx');

addpath(scriptDirectory,modelDirectory);
init_ev_smart_grid;

if ~isfile(modelFile)
    previousDirectory = pwd;
    directoryCleanup = onCleanup(@() cd(previousDirectory));
    cd(modelDirectory);
    build_ev_smart_grid_model;
    clear directoryCleanup;
end

load_system(modelFile);
out = sim('EV_SmartGrid');
powerResults = out.powerResults;
socResult = out.socResult;
priceResult = out.priceResult;

tp = powerResults.Time;
P = powerResults.Data;
tsoc = socResult.Time;
soc = socResult.Data;

Pbase = P(:,1);
Prenewable = P(:,2);
% The saved model Mux order is [base, renewable, grid, EV].
Pgrid = P(:,3);
Pev = P(:,4);

peakGrid_kW = max(Pgrid);
peakToAverageRatio = peakGrid_kW/mean(Pgrid);
gridImport_kWh = sum(max(Pgrid,0))*Ts;
gridExport_kWh = sum(max(-Pgrid,0))*Ts;
renewableUsed_kWh = sum(min(Prenewable,max(Pbase+Pev,0)))*Ts;
renewableAvailable_kWh = sum(Prenewable)*Ts;
renewableUtilization_pct = 100*renewableUsed_kWh/renewableAvailable_kWh;
finalSOC_pct = 100*soc(end);

fprintf('\nEV smart-grid starter-model results\n');
fprintf('Peak grid demand:          %.1f kW\n',peakGrid_kW);
fprintf('Peak-to-average ratio:     %.3f\n',peakToAverageRatio);
fprintf('Grid energy imported:      %.1f kWh\n',gridImport_kWh);
fprintf('Grid energy exported:      %.1f kWh\n',gridExport_kWh);
fprintf('Renewable utilization:     %.1f %%\n',renewableUtilization_pct);
fprintf('Final aggregate fleet SOC: %.1f %%\n\n',finalSOC_pct);

if ~isfolder(resultsDirectory)
    mkdir(resultsDirectory);
end

navy = [7 27 51]/255;
blue = [23 107 255]/255;
cyan = [29 214 232]/255;
teal = [0 191 166]/255;
green = [45 190 92]/255;
violet = [128 92 255]/255;
coral = [255 82 105]/255;
panel = [244 248 255]/255;

fig = figure('Color',panel,'Position',[100 100 1120 760]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

nexttile;
plot(tp,Pbase,'Color',blue,'LineWidth',1.8); hold on;
plot(tp,Prenewable,'Color',teal,'LineWidth',1.8);
plot(tp,Pgrid,'Color',violet,'LineWidth',2.1);
yline(evp.transformerLimit_kW,'--','Transformer limit', ...
    'Color',coral,'LineWidth',1.2);
grid on; xlim([0 24]); ylabel('Power (kW)');
legend('Base load','Renewable','Grid','Location','best');
title('EV charging in a smart grid - baseline EMS');

nexttile;
stairs(tp,Pev,'Color',cyan,'LineWidth',1.9);
yline(0,'-','Color',navy,'LineWidth',0.9); grid on; xlim([0 24]);
ylabel('EV power (kW)');
legend('Positive: charge, negative: V2G','Location','best');

nexttile;
plot(tsoc,100*soc,'Color',green,'LineWidth',2.1);
yline(100*evp.minimumSOC,'--','Minimum SOC', ...
    'Color',coral,'LineWidth',1.2);
yline(100*evp.targetSOC,'--','Target SOC', ...
    'Color',teal,'LineWidth',1.2);
grid on; xlim([0 24]); ylim([15 100]);
xlabel('Time (hour)'); ylabel('Fleet SOC (%)');

allAxes = findall(fig,'Type','axes');
set(allAxes,'Color',[0.985 0.992 1.0], ...
    'XColor',navy,'YColor',navy,'GridColor',[0.35 0.55 0.75], ...
    'GridAlpha',0.18,'FontName','Arial','FontSize',10, ...
    'LineWidth',0.8);

exportgraphics(fig,fullfile(resultsDirectory,'baseline_results.png'), ...
    'Resolution',180);
save(fullfile(resultsDirectory,'baseline_results.mat'),'tp','P','tsoc','soc', ...
    'peakGrid_kW','peakToAverageRatio','gridImport_kWh', ...
    'gridExport_kWh','renewableUtilization_pct','finalSOC_pct');

disp('Saved results/baseline_results.png and results/baseline_results.mat');
