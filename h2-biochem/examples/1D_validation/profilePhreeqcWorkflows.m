function results = profilePhreeqcWorkflows(varargin)
% Profile both PHREEQC workflows with fixed grid, timesteps and tolerances.
% Run after startupH2sim. Timings are unprofiled and alternating paired runs.
opt = merge_options(struct('trials', 3, 'maximumFlowSteps', 2, 'backends', {{'multirate','compositional'}}, ...
    'collectProfiles', true, 'profileOnly', false, 'reuseCompletedTrials', false, ...
    'outputDirectory', fullfile(pwd,'build','phreeqc-performance')), varargin{:});
validateattributes(opt.trials, {'numeric'}, {'scalar','integer','positive'});
validateattributes(opt.maximumFlowSteps, {'numeric'}, {'scalar','integer','positive'});
assert(iscell(opt.backends) && all(ismember(opt.backends, ...
    {'multirate','compositional'})), 'Unknown benchmark backend.');
cleanupProfile = onCleanup(@() profile('off')); %#ok<NASGU>
validateattributes(opt.collectProfiles, {'logical'}, {'scalar'});
validateattributes(opt.profileOnly, {'logical'}, {'scalar'});
validateattributes(opt.reuseCompletedTrials, {'logical'}, {'scalar'});
results = struct;
for backend = opt.backends
    name = backend{1};
    if opt.collectProfiles
        profile clear; profile on;
        baseline = runCase(name, false, opt.maximumFlowSteps);
        profile off;
        results.(name).profile = profile('info');
        results.(name).baseline = struct('states',{baseline.states}, ...
            'elapsedSeconds',baseline.elapsedSeconds);
        saveCheckpoint(results,opt.outputDirectory,name);
        table = results.(name).profile.FunctionTable;
        [~,indices] = sort([table.TotalTime],'descend');
        for index = indices(1:min(20,numel(indices)))
            fprintf('%10.3f %8d %s\n', table(index).TotalTime, ...
                table(index).NumCalls,table(index).FunctionName);
        end
    else
        checkpoint = fullfile(opt.outputDirectory,[name,'_benchmark.mat']);
        if isfile(checkpoint)
            previous = load(checkpoint,'results');
            results.(name) = previous.results.(name);
        end
    end
    if opt.profileOnly, continue; end
    seconds = zeros(opt.trials, 2);
    difference = zeros(opt.trials, 1);
    for trial = 1:opt.trials
        order = [false true];
        if mod(trial,2)==0, order=fliplr(order); end
        paired = cell(1,2);
        reuse = opt.reuseCompletedTrials && isfield(results,name) && ...
            isfield(results.(name),'trials') && ...
            size(results.(name).trials,1)>=trial && ...
            all(~cellfun(@isempty,results.(name).trials(trial,:)));
        if reuse
            paired = results.(name).trials(trial,:);
            assert(all(cellfun(@(x) numel(x.states)==opt.maximumFlowSteps,paired)), ...
                'Saved trials use a different number of flow steps.');
            fprintf('Reusing saved %s pair %d.\n',name,trial);
        else
            for enabled = order
                paired{1+enabled} = runCase(name, enabled, opt.maximumFlowSteps);
            end
        end
        for enabled = order
            seconds(trial,1+enabled) = paired{1+enabled}.elapsedSeconds;
        end
        for pairIndex=1:2
            current=paired{pairIndex};
            results.(name).trials{trial,pairIndex}=struct( ...
                'states',{current.states},'elapsedSeconds',current.elapsedSeconds);
        end
        saveCheckpoint(results,opt.outputDirectory,name);
        [difference(trial),comparison] = compareStates(paired{1}, paired{2}, name);
        results.(name).comparisons{trial}=comparison;
        fprintf('%s pair %d: %.6g -> %.6g s, relative difference %.4g\n', ...
            name,trial,seconds(trial,1),seconds(trial,2),difference(trial));
    end
    results.(name).seconds = seconds;
    results.(name).speedup = median(seconds(:,1))/median(seconds(:,2));
    results.(name).maximumRelativeDifference = max(difference);
    saveCheckpoint(results,opt.outputDirectory,name);
    fprintf('%s: median %.6g -> %.6g s, speedup %.4g, difference %.4g\n', ...
        name,median(seconds(:,1)),median(seconds(:,2)), ...
        results.(name).speedup,max(difference));
end
end

function summary = runCase(backend, enabled, steps)
if strcmp(backend,'multirate')
    summary = exampleSequentialBiochemistryPhreeqc1D( ...
        'maximumFlowSteps',steps,'phreeqcReflashLocalBracket',enabled, ...
        'simulationDirectory',tempname); % Fresh outputs: never time cache retrieval.
    for k=1:numel(summary.states)
        assert(all(summary.states{k}.sequentialH2BiochemPhreeqcReflashPass(:)), ...
            'Post-flash inventory audit failed.');
    end
    return
end
[~,model,schedule,state0] = setupH2StorageExampleWithSRB_benchmark( ...
    'rate','highrate','scheduleMode','complete','injectionCO2',0, ...
    'bacteriamodel',true,'bactDiffusion',false,'chemotaxisEffect',false, ...
    'molecularDiffusion',false,'molecularDispersion',false,'bioClogging',false, ...
    'carbonateBuffer',true,'carbonateBufferPH',6.24,'initialHCO3',1.370e-3, ...
    'initialOverallCO2',0,'equilibrateInitialCO2',false, ...
    'phreeqcTimestepCoupling',true,'phreeqcBackend','sequential-compositional-phreeqc', ...
    'phreeqcDatabaseFile',which('h2_biogeochemistry.dat'), ...
    'sequentialCompositionalPhreeqcBatchSize',1);
if enabled, model.phreeqcCouplingOptions.sequentialCompositionalPhreeqcBatchSize=model.G.cells.num; end
assert(steps<=numel(schedule.step.val),'Requested more steps than the schedule contains.');
schedule.step.val=schedule.step.val(1:steps);
schedule.step.control=schedule.step.control(1:steps);
solver=NonLinearSolver(); solver.maxTimestepCuts=12;
t=tic;
[~,states,report]=simulateScheduleAD(state0,model,schedule,'nonlinearSolver',solver);
seconds=toc(t);
assert(~report.Failure,'Simulation failed.');
% Keep the simulation's warning-based audit policy and retain all diagnostics.
% A baseline audit warning must not prevent collecting the requested profile.
auditFailures=zeros(numel(states),1);
for k=1:numel(states)
    auditFailures(k)=nnz(~states{k}.phreeqcElementBalancePass);
end
summary=struct('states',{states},'elapsedSeconds',seconds, ...
    'elementAuditFailures',auditFailures);
fprintf('Element audit warning entries by step: %s\n',mat2str(auditFailures.'));
end

function [difference,comparison] = compareStates(a,b,backend)
assert(numel(a.states)==numel(b.states));
fields={'pressure','components','s','nbact','phreeqcPH', ...
    'tracerHCO3','tracerSO4','tracerHS','tracerCa','tracerMg', ...
    'phreeqcMineralCalcite','phreeqcMineralDolomite','phreeqcMineralAnhydrite', ...
    'phreeqcMineralQuartz','phreeqcMineralGoethite','phreeqcMineralBrucite', ...
    'phreeqcMineralPortlandite','phreeqcMineralPyrite','phreeqcMineralGypsum'};
if strcmp(backend,'multirate')
    fields=[fields, {'sequentialH2BiochemPhreeqcReflashActualMoles','h2ConsumptionRate', ...
        'sequentialH2BiochemPhreeqcCumulativeH2ConsumptionMoles'}];
else
    fields=[fields, {'sequentialCompositionalPhreeqcReactionRates', ...
        'sequentialCompositionalPhreeqcBiomassMET', ...
        'sequentialCompositionalPhreeqcBiomassACE', ...
        'sequentialCompositionalPhreeqcBiomassSRB'}];
end
difference=0; comparison=struct;
for k=1:numel(a.states)
    for field=fields
        x=value(a.states{k}.(field{1})); y=value(b.states{k}.(field{1}));
        assert(all(isfinite(x(:))) && all(isfinite(y(:))));
        maximumConcentrationDifference=[];
        if startsWith(field{1},'tracer')
            % Compare on the recorded chemistry handoff's water-mass basis.
            % Concentrations are mol/m^3; waterMass/1000 is aqueous volume.
            if strcmp(backend,'multirate')
                waterField='sequentialH2BiochemPhreeqcInputWaterMass';
            else
                waterField='sequentialCompositionalPhreeqcInputWaterMass';
            end
            maximumConcentrationDifference=max(abs(x(:)-y(:)));
            x=x(:).*a.states{k}.(waterField)/1000;
            y=y(:).*b.states{k}.(waterField)/1000;
        end
        absoluteTolerance=1e-10;
        if strcmp(field{1},'pressure'), absoluteTolerance=1; end
        if strcmp(field{1},'nbact') || strcmp(field{1},'phreeqcPH')
            absoluteTolerance=1e-8;
        end
        if startsWith(field{1},'tracer') || startsWith(field{1},'phreeqcMineral') || ...
                endsWith(field{1},'ActualMoles') || endsWith(field{1},'ConsumptionMoles')
            absoluteTolerance=1e-7;
        end
        scale=max(abs(x(:)),abs(y(:)));
        residual=abs(x(:)-y(:));
        limit=absoluteTolerance+1e-6*scale;
        normalized=max(residual./limit);
        d=max(residual./max(scale,absoluteTolerance));
        fprintf('  %s step %d: absolute %.4g, tolerance fraction %.4g\n', ...
            field{1},k,max(residual),normalized);
        comparison(k).(field{1})=struct('maximumAbsoluteDifference',max(residual), ...
            'maximumRelativeDifference',d,'maximumToleranceFraction',normalized, ...
            'maximumConcentrationDifference',maximumConcentrationDifference);
        assert(normalized<=1,'Optimization changed %s beyond its tolerance (%.6g).', ...
            field{1},normalized);
        difference=max(difference,d);
    end
end
end

function saveCheckpoint(results,directory,backend)
% MATLAB HDF5 writes can fail on WSL UNC paths; write locally, then copy.
if isempty(directory), return; end
if ~isfolder(directory), mkdir(directory); end
localFile = [tempname,'.mat'];
cleanup = onCleanup(@() delete(localFile)); %#ok<NASGU>
save(localFile,'results','-v7');
copyfile(localFile,fullfile(directory,[backend,'_benchmark.mat']),'f');
end
