classdef MolecularDiffusionTest < matlab.unittest.TestCase
    % Gas-mixture coefficient limits without running a storage simulation.
    properties
        model
        state
    end
    methods (TestClassSetup)
        function setupModel(test)
            mrstModule add compositional ad-core ad-props ad-blackoil deckformat
            [~, model, ~, state] = setupH2StorageExampleWithSRB_benchmark( ...
                'gridCells', 3, 'domainLength', 1, 'scheduleMode', 'injection', ...
                'molecularDiffusion', true, 'molecularDispersion', false);
            test.model = model.validateModel();
            test.state = state;
        end
    end
    methods (Test)
        function pureHydrogenRemainsFinite(test)
            model = test.model;
            state = test.state;
            state.y = zeros(3, 6);
            state.y(:, 2) = 1;
            diffusivity = DispersiveDiffusivity(model);
            coefficients = diffusivity.evaluateOnDomain(model, state);
            hydrogen = coefficients{2, model.getVaporIndex()};
            test.verifyTrue(all(isfinite(hydrogen)));
            test.verifyGreaterThan(min(hydrogen), 0);
            test.verifyLessThan(max(hydrogen), 1e-5);
        end

        function binaryLimitIndependentOfTraceAmount(test)
            model = test.model;
            state = test.state;
            trace = [0.1; 1e-8; 1e-14];
            state.y = zeros(3, 6);
            state.y(:, 2) = 1 - trace;
            state.y(:, 4) = trace;
            diffusivity = DispersiveDiffusivity(model);
            coefficients = diffusivity.evaluateOnDomain(model, state);
            hydrogen = coefficients{2, model.getVaporIndex()};
            test.verifyEqual(hydrogen, repmat(hydrogen(1), 3, 1), 'RelTol', 1e-12);
        end

        function gasCoefficientScalesInverselyWithPressure(test)
            model = test.model;
            state = test.state;
            state.y = repmat([0, 0.5, 0, 0.5, 0, 0], 3, 1);
            diffusivity = DispersiveDiffusivity(model);
            initial = diffusivity.evaluateOnDomain(model, state);
            state.pressure = 2 * state.pressure;
            doubled = diffusivity.evaluateOnDomain(model, state);
            test.verifyEqual(doubled{2, model.getVaporIndex()}, ...
                initial{2, model.getVaporIndex()} / 2, 'RelTol', 1e-12);
            test.verifyEqual(doubled{2, model.getLiquidIndex()}, ...
                initial{2, model.getLiquidIndex()}, 'RelTol', 1e-12);
        end

        function gasCoefficientRetainsTemperatureScaling(test)
            model = test.model;
            state = test.state;
            state.y = repmat([0, 0.5, 0, 0.5, 0, 0], 3, 1);
            diffusivity = DispersiveDiffusivity(model);
            initial = diffusivity.evaluateOnDomain(model, state);
            state.T = 1.1 * state.T;
            warmer = diffusivity.evaluateOnDomain(model, state);
            test.verifyEqual(warmer{2, model.getVaporIndex()}, ...
                initial{2, model.getVaporIndex()} * 1.1^diffusivity.gasDiffExponent, ...
                'RelTol', 1e-12);
        end
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of h2sim.

h2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

h2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
%}
