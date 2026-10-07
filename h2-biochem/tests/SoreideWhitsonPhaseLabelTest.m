classdef SoreideWhitsonPhaseLabelTest < matlab.unittest.TestCase
 methods (Test)
  function heterogeneousBatchMatchesIndependentCells(test)
   fluid=TableCompositionalMixture({'Water','Hydrogen'});
   eos=SoreideWhitsonEos([],fluid);
   p=[1e5;5e6;5e7;5e6]; T=[250;317.5;900;250];
   z=repmat([0.8,0.2],4,1); ZL=[0.1;0.7;0.3;0.8]; ZV=[0.12;0.9;0.31;0.1];
   batch=eos.singlePhaseLabel(p,T,z,ZL,ZV); single=zeros(4,1);
   for j=1:4, single(j)=eos.singlePhaseLabel(p(j),T(j),z(j,:),ZL(j),ZV(j)); end
   test.verifyEqual(batch,single); test.verifyEqual(size(batch),[4,1]);
   test.verifyGreaterThan(numel(unique(batch)),1);
  end
  function emptyBatchReturnsEmpty(test)
   fluid=TableCompositionalMixture({'Water','Hydrogen'});
   eos=SoreideWhitsonEos([],fluid);
   test.verifyEmpty(eos.singlePhaseLabel([],[],zeros(0,2),[],[]));
  end
 end
end
