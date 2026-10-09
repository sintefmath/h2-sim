classdef PhreeqcValidationDiagnosticsTest < matlab.unittest.TestCase
 methods (Test)
  function countsOnlyActivePrescribedInjection(test)
   result=fixture();d=collectPhreeqcValidationDiagnostics(result);
   test.verifyEqual(d.h2sim.injectedMoles,2,'AbsTol',1e-12);
   test.verifyEqual(d.h2sim.lossPercent,[10.5;21],'AbsTol',1e-12);
   test.verifyEqual(d.h2sim.timeDays,[2;4]);
   test.verifyEqual(d.h2sim.consumption,d.ugfact.consumption,'AbsTol',1e-14);
   test.verifyEqual(d.h2sim.lossPercent,d.ugfact.lossPercent,'AbsTol',1e-12);
  end
  function rejectsMissingStepsAndZeroInjection(test)
   result=fixture();result.h2sim.states=result.h2sim.states(1);
   test.verifyError(@() collectPhreeqcValidationDiagnostics(result),'H2sim:ValidationStateCount');
   result=fixture();result.h2sim.schedule.control(1).W.status=false;
   test.verifyError(@() collectPhreeqcValidationDiagnostics(result),'H2sim:ValidationInjection');
  end
 end
end
function result=fixture()
p=101325;T=288.15;
model=struct('G',struct('cells',struct('num',2,'centroids',[.5,0;1.5,0])), ...
 'biochemFluid',struct('nbioreact',3),'getVaporIndex',@() 2, ...
 'FacilityModel',struct('pressure',p,'T',T));
w=struct('sign',1,'status',true,'type','rate','val',8.314462618*T/p/day, ...
 'compi',[0,1],'components',[0,1,0]);
closed=w;closed.status=false;closed.val=100*w.val;
schedule=struct('control',struct('W',{w,closed}), ...
 'step',struct('val',[2;2]*day,'control',[1;2]));
increment=[1,2,3;4,5,6]/100;states=cell(2,1);reference=states;
for k=1:2
 states{k}=struct('x',[.9,.1;.8,.2],'phreeqcPH',[6;7], ...
  'phreeqcTotalCarbon',[.001;.002],'cumulativeH2ConsumptionMoles',k*increment);
 solution=struct('pH',[6;7],'TotalDIC',[.001;.002],'Water',[1000;1000], ...
  'MET_Rate',increment(:,1)/2,'ACE_Rate',increment(:,2)/2,'SRB_Rate',increment(:,3)/2);
 reference{k}=struct('x',states{k}.x,'Solution',solution);
end
result=struct('h2sim',struct('model',model,'schedule',schedule,'states',{states}), ...
 'ugfact',struct('model',model,'schedule',schedule,'states',{reference}));
end
