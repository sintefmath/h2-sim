function results = benchmarkSequentialPhreeqcVolumeFlash(databaseFile)
% Run after startupH2sim on Windows MATLAB with IPhreeqcCOM registered.
% Timings surround the entire example call, including setup and reporting.
% Alternate ordering over three paired trials to expose startup/order noise.
% No grid, timestep, EOS tolerance, or inventory tolerance changes.

previous = warning('error', 'H2Biochem:PhreeqcReflashInventory');
cleanup = onCleanup(@() warning(previous)); %#ok<NASGU>
seconds = zeros(3, 2);
pressureRelativeDifference = zeros(3, 1);
inventoryRelativeDifference = zeros(3, 1);
for trial = 1:3
    order = [false, true];
    if mod(trial, 2) == 0
        order = fliplr(order);
    end
    summaries = cell(1, 2);
    for enabled = order
        timer = tic;
        summary = exampleSequentialBiochemistryPhreeqc1D( ...
            'maximumFlowSteps', 2, 'phreeqcDatabaseFile', databaseFile, ...
            'phreeqcReflashLocalBracket', enabled);
        seconds(trial, 1 + enabled) = toc(timer);
        summaries{1 + enabled} = summary;
        for step = 1:numel(summary.states)
            state = summary.states{step};
            assert(all(state.sequentialH2BiochemPhreeqcReflashPass(:)), ...
                'The post-flash inventory audit failed.');
        end
    end
    baseline = summaries{1};
    candidate = summaries{2};
    assert(numel(baseline.states) == numel(candidate.states));
    for step = 1:numel(baseline.states)
        a = baseline.states{step};
        b = candidate.states{step};
        pressureRelativeDifference(trial) = max(pressureRelativeDifference(trial), ...
            max(abs(a.pressure - b.pressure)./max(abs(a.pressure), 1)));
        am = a.sequentialH2BiochemPhreeqcReflashActualMoles;
        bm = b.sequentialH2BiochemPhreeqcReflashActualMoles;
        inventoryRelativeDifference(trial) = max(inventoryRelativeDifference(trial), ...
            max(abs(am(:) - bm(:))./max(abs(am(:)), 1e-7)));
    end
end
results = struct('seconds', seconds, ...
    'medianSeconds', median(seconds, 1), ...
    'speedup', median(seconds(:, 1))/median(seconds(:, 2)), ...
    'pressureRelativeDifference', pressureRelativeDifference, ...
    'inventoryRelativeDifference', inventoryRelativeDifference);
disp(results);
end
