classdef H2BiochemParallelTest < matlab.unittest.TestCase
 methods (Test)
  function serialDefaultDoesNotProbeToolbox(test)
   test.verifyFalse(resolveH2BiochemParallel(false,@() error('Unexpected license check')));
  end
  function unavailableToolboxFallsBack(test)
   test.verifyWarning(@() resolveH2BiochemParallel(true,@() false), ...
      'H2Biochem:ParallelUnavailable');
   saved=warning('off','H2Biochem:ParallelUnavailable');
   cleanup=onCleanup(@() warning(saved)); %#ok<NASGU>
   test.verifyFalse(resolveH2BiochemParallel(true,@() false));
  end
  function availableToolboxHonorsRequest(test)
   test.verifyTrue(resolveH2BiochemParallel(true,@() true));
  end
 end
end
