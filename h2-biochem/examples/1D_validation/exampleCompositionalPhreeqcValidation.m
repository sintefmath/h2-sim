function result=exampleCompositionalPhreeqcValidation(varargin)
%EXAMPLECOMPOSITIONALPHREEQCVALIDATION Injection benchmark against external UGFACT.
% The first 50-day injection phase of UGFACT H2Storage1D is compared on its
% original 50-cell domain and moderate kinetic rates. Both use Soreide-Whitson
% with the same 2.865 mol/kg NaCl molality. No extra diffusion/chemotaxis models.
% ugfactRoot is an external upstream checkout; it is never modified.
% Five PHREEQC substeps per 2-day UGFACT flow step versus one H2sim split.
% Saved full states and setups allow the comparison to be replotted.
opt=merge_options(struct('ugfactRoot','','injectionDays',50, ...
 'plotResults',true,'outputDirectory',fullfile(pwd,'build','phreeqc-validation')),varargin{:});
assert(isfile(fullfile(opt.ugfactRoot,'examples','H2Storage1D.m')), ...
 'Set ugfactRoot to a separate UGFACT checkout.');
validateattributes(opt.injectionDays,{'numeric'},{'scalar','positive','<=',50});
assert(mod(opt.injectionDays,2)==0,'Use an integer number of 2-day steps.');
if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
[~,model,schedule,state0]=setupH2StorageExampleWithSRB_benchmark( ...
 'gridCells',50,'domainLength',50,'rate','medrate','scheduleMode','injection', ...
 'injectionCO2',0,'bacteriamodel',true,'bactDiffusion',false, ...
 'chemotaxisEffect',false,'molecularDiffusion',false,'molecularDispersion',false, ...
 'bioClogging',false,'carbonateBuffer',true,'carbonateBufferPH',6.24, ...
 'initialHCO3',1.370e-3,'initialOverallCO2',0,'equilibrateInitialCO2',false, ...
 'phreeqcTimestepCoupling',true,'phreeqcBackend','sequential-compositional-phreeqc', ...
 'phreeqcDatabaseFile',which('h2_biogeochemistry.dat'));
validationStepCount=opt.injectionDays/2;schedule.step.val=schedule.step.val(1:validationStepCount);schedule.step.control=schedule.step.control(1:validationStepCount);
solver=NonLinearSolver();solver.maxTimestepCuts=12;
problem=packH2simSimulationProblem(state0,model,schedule,'H2_COMPOSITIONAL_PHREEQC_VALIDATION_SW', ...
 'NonLinearSolver',solver);t=tic;ok=simulatePackedProblem(problem,'continueOnError',false);assert(ok);
[ws,states,reports]=getPackedSimulatorOutput(problem);
h2sim=struct('model',model,'state0',state0,'schedule',schedule,'states',{states}, ...
 'wellSols',{ws},'reports',{reports},'packedProblem',problem,'elapsedSeconds',toc(t));
% Execute the upstream setup with an explicit shared-EOS adapter. Running
% from its examples directory resolves its relative PHREEQC database path.
originalPath=path;originalFolder=pwd;cleanup=onCleanup(@() restore(originalPath,originalFolder)); %#ok<NASGU>
% Stage reference sources locally so relative COM database paths work from WSL.
% Retain upstream kinetics; use the configured flow EOS for its chemistry reflash.
referenceRunRoot=tempname;mkdir(referenceRunRoot);
copyfile(fullfile(opt.ugfactRoot,'Modified_Models'),fullfile(referenceRunRoot,'Modified_Models'));
mkdir(fullfile(referenceRunRoot,'examples'));
copyfile(fullfile(opt.ugfactRoot,'examples','database'),fullfile(referenceRunRoot,'examples','database'));
for name={'mass2Zi.m','mass2Zi_Parpool.m'}
 adapterFile=fullfile(referenceRunRoot,'Modified_Models',name{1});
 adapterSource=fileread(adapterFile);
 originalEOS='eos = EquationOfStateModel([], model.EOSModel.CompositionalMixture, ''Peng-Robinson'');';
 assert(contains(adapterSource,originalEOS),'Reference chemistry reflash changed.');
 adapterSource=strrep(adapterSource,originalEOS,'eos = model.EOSModel;');
 fid=fopen(adapterFile,'w');fwrite(fid,adapterSource,'char');fclose(fid);
end
addpath(fullfile(referenceRunRoot,'Modified_Models'));
source=fileread(fullfile(opt.ugfactRoot,'examples','H2Storage1D.m'));
source=strrep(source,'clear;clc;close all','');
source=strrep(source,'''CH4''','''C1'''); % SW methane interaction alias
source=regexprep(source,'mrstModule add UGFACT2[^\n]*','');
marker=strfind(source,'%% Running the simulation');assert(~isempty(marker),'Upstream setup marker changed.');
source=source(1:marker(1)-1);
% Match flow and post-chemistry thermodynamics; upstream kinetic equations stay unchanged.
source=strrep(source,'model = GenericOverallCompositionModel_Modified(arg{:});', ...
 ['model = GenericOverallCompositionModel_Modified(arg{:});',newline, ...
  'model.EOSModel = SoreideWhitsonEos(G, mixture, ''msalt'', 2.865, ''pH'', 6.24, ''initial_NaCl'', 2.865, ''initial_SO4'', 4.664e-3, ''rho_water'', 1000);']);
source=strrep(source,'eos = EquationOfStateModel([], mixture, ''Peng-Robinson'');', ...
 'eos = SoreideWhitsonEos([], mixture, ''msalt'', 2.865, ''pH'', 6.24, ''initial_NaCl'', 2.865, ''initial_SO4'', 4.664e-3, ''rho_water'', 1000);');
cd(fullfile(referenceRunRoot,'examples'));eval(source);
assert(model.Kinetic.mu_MET==1.109 && model.Kinetic.mu_ACE==.872 && model.Kinetic.mu_SRB==1.048);
model.parpool=false;schedule.step.val=schedule.step.val(1:validationStepCount);schedule.step.control=schedule.step.control(1:validationStepCount);
referenceProblem=packH2simSimulationProblem(state0,model,schedule,'REFERENCE_INJECTION_SETUP');
t=tic;[wellSol,states,report]=simulateScheduleAD_Modified(state0,model,schedule);
assert(~report.Failure,'UGFACT reference did not converge.');
assert(all(cellfun(@(s) all(isfinite(s.pressure)) && all(isfinite(s.x(:))),states)));
% Persist upstream outputs through MRST ResultHandlers as well as the MAT.
for k=1:numel(states)
 referenceProblem.OutputHandlers.states{k}=states{k};
 referenceProblem.OutputHandlers.wellSols{k}=wellSol{k};
 referenceProblem.OutputHandlers.reports{k}=report.ControlstepReports{k};
end
ugfact=struct('model',model,'state0',state0,'schedule',schedule,'states',{states}, ...
 'wellSols',{wellSol},'report',report,'packedProblem',referenceProblem,'elapsedSeconds',toc(t));
result=struct('h2sim',h2sim,'ugfact',ugfact,'ugfactRoot',opt.ugfactRoot,'referenceRunRoot',referenceRunRoot, ...
 'referenceAdapter','Shared SW flow/chemistry EOS and C1 methane alias; upstream kinetics retained', ...
 'description','PHREEQC injection validation; common Soreide-Whitson parameters; distinct chemistry splitting.');
file=[tempname,'.mat'];fileCleanup=onCleanup(@() delete(file)); %#ok<NASGU>
save(file,'result','-v7');copyfile(file,fullfile(opt.outputDirectory,'validation_results.mat'),'f');
if opt.plotResults,plotCompositionalPhreeqcValidation(result,'outputDirectory',opt.outputDirectory);end
end
function restore(savedPath,folder)
path(savedPath);cd(folder);
end
