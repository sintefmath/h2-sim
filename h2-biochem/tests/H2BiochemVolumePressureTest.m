classdef H2BiochemVolumePressureTest < matlab.unittest.TestCase
    methods (Test)
        function localRootsInBothDirections(test)
            for correction = [-0.01, 0.01]
                root = log(1e7) + correction;
                residual = @(p) exp(root - p) - 1;
                [actual, info] = solveH2BiochemVolumePressure(residual, log(1e7));
                test.verifyEqual(actual, root, 'AbsTol', 1e-12);
                test.verifyLessThan(abs(residual(actual)), 1e-12);
                test.verifyTrue(info.localBracket);
                test.verifyFalse(info.fallback);
            end
        end

        function nondecreasingResponseFallsBack(test)
            [actual, info] = solveH2BiochemVolumePressure(@(p) p - 2, 1);
            test.verifyEqual(actual, 2, 'AbsTol', 1e-12);
            test.verifyTrue(info.fallback);
        end

        function distantPressureRootsUseFallback(test)
            % A factor-four change exceeds the local bracket's factor-two cap.
            for correction = [-log(4), log(4)]
                initial = log(1e7);
                root = initial + correction;
                residual = @(p) exp(root - p) - 1;
                [actual, info] = solveH2BiochemVolumePressure(residual, initial);
                test.verifyEqual(actual, root, 'AbsTol', 1e-12);
                test.verifyTrue(info.fallback);
                test.verifyFalse(info.localBracket);
            end
        end

        function exactInitialRootNeedsOneFlash(test)
            [actual, info] = solveH2BiochemVolumePressure(@(p) p - 2, 2);
            test.verifyEqual(actual, 2);
            test.verifyEqual(info.evaluations, 1);
        end

        function repeatedProbesDoNotRepeatFlash(test)
            seen = [];
            [actual, info] = solveH2BiochemVolumePressure(@countedResidual, 10);
            test.verifyEqual(actual, 10.01, 'AbsTol', 1e-12);
            test.verifyEqual(numel(seen), numel(unique(seen)));
            test.verifyEqual(info.evaluations, numel(seen));

            function result = countedResidual(p)
                seen(end + 1) = p;
                result = exp(10.01 - p) - 1;
            end
        end
    end
end
