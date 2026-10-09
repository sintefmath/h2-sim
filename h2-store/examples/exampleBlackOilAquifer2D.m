function result=exampleBlackOilAquifer2D(varargin)
%EXAMPLEBLACKOILAQUIFER2D Structural trapping and five hydrogen storage cycles.
% Reuses modelForSimple2DAquifer and the public h2storage Eclipse deck:
% gravity, layered rock, capillarity, and tabulated dissolved H2 are active.
% Default teaching grid: 2 m target spacing; original model defaults remain.
% No PHREEQC or parallel toolbox. Packed setup/states/wells/reports persist.
opt=merge_options(struct('gridSpacing',[2,2],'numCycles',5,'plotResults',true, ...
 'minimumProductionBhp',35*barsa,'deckFile','','outputDirectory',fullfile(pwd,'build','aquifer-2d')),varargin{:});
validateattributes(opt.numCycles,{'numeric'},{'scalar','integer','positive'});
mrstModule add ad-core ad-props ad-blackoil deckformat upr test-suite spe10
deckFile=opt.deckFile;
if isempty(deckFile)
 deckFile=fullfile(fileparts(mfilename('fullpath')),'data','Aquifer2D','H2STORAGE_RS.DATA');
end
assert(isfile(deckFile),'Aquifer Eclipse deck not found: %s',deckFile);
deck=readEclipseDeck(deckFile);
[description,setup,state0,model,schedule]=modelForSimple2DAquifer(deck, ...
 'gridSpacing',opt.gridSpacing,'numCycles',opt.numCycles);
% A pressure limit lets withdrawal relax when the requested rate is unavailable.
for k=1:numel(schedule.control)
 % Use one physical well throughout; stage names are plot metadata.
 schedule.control(k).W(1).stage=schedule.control(k).W(1).name;
 schedule.control(k).W(1).name='Storage';
 if strcmp(schedule.control(k).W(1).stage,'discharge')
  schedule.control(k).W(1).lims.bhp=opt.minimumProductionBhp;
 end
end
state0.wellSol(1).name='Storage';
% Start the injector above perforation pressure to avoid an initial sign shut-in.
state0.wellSol(1).bhp=max(state0.pressure(schedule.control(1).W.cells))+5*barsa;
solver=NonLinearSolver();solver.maxTimestepCuts=12;solver.LinearSolver=selectLinearSolverAD(model);
problem=packH2simSimulationProblem(state0,model,schedule,'H2_BLACKOIL_AQUIFER_2D', ...
 'NonLinearSolver',solver);
t=tic;ok=simulatePackedProblem(problem,'continueOnError',false);elapsed=toc(t);
assert(ok,'Aquifer simulation did not complete.');
[ws,states,reports]=getPackedSimulatorOutput(problem);
result=struct('description',description,'setup',setup,'model',model, ...
 'schedule',schedule,'state0',state0,'states',{states},'wellSols',{ws}, ...
 'reports',{reports},'packedProblem',problem,'elapsedSeconds',elapsed, ...
 'deckFile',deckFile,'outputDirectory',opt.outputDirectory);
if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
file=[tempname,'.mat'];cleanup=onCleanup(@() delete(file)); %#ok<NASGU>
save(file,'result','-v7');copyfile(file,fullfile(opt.outputDirectory,'aquifer_results.mat'),'f');
if opt.plotResults
 plotBlackOilAquifer2D(result,'outputDirectory',opt.outputDirectory);
 plotAquiferFluidTables(result,'outputDirectory',opt.outputDirectory);
end
end
