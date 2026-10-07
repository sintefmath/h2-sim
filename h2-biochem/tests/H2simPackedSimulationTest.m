classdef H2simPackedSimulationTest < matlab.unittest.TestCase
 methods (Test)
  function savedSetupDistinguishesChangedInputs(test)
   mrstModule add ad-core ad-props ad-blackoil
   G=computeGeometry(cartGrid([2,1,1],[2,1,1]));
   rock=makeRock(G,100*milli*darcy,0.2);
   fluid=initSimpleADIFluid('phases','OG','rho',[1000,1]);
   model=GenericBlackOilModel(G,rock,fluid,'water',false,'disgas',false,'vapoil',false);
   state=initResSol(G,1e7,[1,0]);schedule=simpleSchedule(day);
   folder=tempname;mkdir(folder);cleanup=onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
   first=packH2simSimulationProblem(state,model,schedule,'CACHE_TEST','Directory',folder);
   again=packH2simSimulationProblem(state,model,schedule,'CACHE_TEST','Directory',folder);
   test.verifyEqual(first.Name,again.Name);
   changed=state;changed.pressure(2)=changed.pressure(2)+1;
   second=packH2simSimulationProblem(changed,model,schedule,'CACHE_TEST','Directory',folder);
   test.verifyNotEqual(first.Name,second.Name);
   loaded=load(fullfile(first.OutputHandlers.states.getDataPath(),'packed_setup.mat'),'problem');
   test.verifyEqual(loaded.problem.SimulatorSetup.state0.pressure,state.pressure);
   test.verifyEqual(loaded.problem.SimulatorSetup.schedule.step.val,schedule.step.val);
   loaded=load(fullfile(second.OutputHandlers.states.getDataPath(),'packed_setup.mat'),'problem');
   test.verifyEqual(loaded.problem.SimulatorSetup.state0.pressure,changed.pressure);
  end
 end
end
