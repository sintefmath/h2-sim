classdef H2BiochemMixtureTest < matlab.unittest.TestCase
 methods (Test)
  function preservesTabulatedComponentsAndOrdering(test)
   names={'Water','AceticAcid','Hydrogen'}; symbols={'H2O','CH3COOH','H2'};
   mix=h2BiochemCompositionalMixture(names,symbols);
   base=TableCompositionalMixture(names([1,3]),symbols([1,3]));
   test.verifyEqual(mix.names,symbols);
   for name={'Tcrit','Pcrit','Vcrit','acentricFactors','molarMass'}
    test.verifyEqual(mix.(name{1})([1,3]),base.(name{1}));
   end
   test.verifyEqual(mix.molarMass(2),0.060050);
   test.verifyEqual(mix.Vcrit(2),0.060050/276);
  end
 end
end
