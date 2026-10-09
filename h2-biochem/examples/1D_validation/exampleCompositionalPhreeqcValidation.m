function result=exampleCompositionalPhreeqcValidation(varargin)
%EXAMPLECOMPOSITIONALPHREEQCVALIDATION Storage-cycle benchmark against external UGFACT.
% A 250-day injection/storage/production cycle is compared on a
% 20-cell, 50 m domain using the high-rate parameter set. Both use Soreide-Whitson
% with the same 2.865 mol/kg NaCl molality. No extra diffusion/chemotaxis models.
% ugfactRoot is an external upstream checkout; it is never modified.
% Five PHREEQC substeps per 2-day UGFACT flow step versus one H2sim split.
% Saved full states and setups allow the comparison to be replotted.
opt=merge_options(struct('ugfactRoot','','injectionDays',50,'totalDays',250,'gridCells',20,'rate','highrate', ...
 'plotResults',true,'outputDirectory',fullfile(pwd,'build','phreeqc-validation')),varargin{:});
assert(isfile(fullfile(opt.ugfactRoot,'examples','H2Storage1D.m')), ...
 'Set ugfactRoot to a separate UGFACT checkout.');
validateattributes(opt.injectionDays,{'numeric'},{'scalar','positive','<=',50});
validateattributes(opt.totalDays,{'numeric'},{'scalar','positive','<=',250});
assert(mod(opt.totalDays,2)==0,'totalDays must be an integer number of 2-day flow steps.');
assert(opt.injectionDays==50,'The complete cycle uses a 50-day injection phase.');
validateattributes(opt.gridCells,{'numeric'},{'scalar','integer','positive'});
opt.rate=validatestring(opt.rate,{'medrate','highrate'});
if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
[ok,folderInfo]=fileattrib(opt.outputDirectory);assert(ok);
opt.outputDirectory=folderInfo.Name; % Keep relative output paths valid after cd.
[~,model,schedule,state0]=setupH2StorageExampleWithSRB_benchmark( ...
 'gridCells',opt.gridCells,'domainLength',50,'rate',opt.rate,'scheduleMode','complete', ...
 'paperBiomassKinetics',true,'nbact0',100, ...
 'injectionCO2',0,'bacteriamodel',true,'bactDiffusion',false, ...
 'chemotaxisEffect',false,'molecularDiffusion',false,'molecularDispersion',false, ...
 'bioClogging',false,'carbonateBuffer',true,'carbonateBufferPH',6.24, ...
 'initialHCO3',1.370e-3,'initialOverallCO2',0,'equilibrateInitialCO2',false, ...
 'phreeqcTimestepCoupling',true,'phreeqcBackend','sequential-compositional-phreeqc', ...
 'phreeqcDatabaseFile',which('h2_biogeochemistry.dat'));
validationStepCount=opt.totalDays/2;schedule.step.val=schedule.step.val(1:validationStepCount);schedule.step.control=schedule.step.control(1:validationStepCount);
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
source=strrep(source,'[NX,NY,NZ]=deal(50,1,1);',sprintf('[NX,NY,NZ]=deal(%d,1,1);',opt.gridCells));
if strcmp(opt.rate,'highrate')
 source=regexprep(source,'model.Kinetic.mu_MET\s*=\s*1.109','model.Kinetic.mu_MET = 4.1');
 source=regexprep(source,'model.Kinetic.mu_ACE\s*=\s*0.872','model.Kinetic.mu_ACE = 1.9');
 source=regexprep(source,'model.Kinetic.mu_SRB\s*=\s*1.048','model.Kinetic.mu_SRB = 5.5');
 source=regexprep(source,'model.Kinetic.K_Dmet\s*=\s*10e-6','model.Kinetic.K_Dmet = 9e-6');
end
% Add a diagnostic of total DIC without changing reference reaction equations.
diagnosticFile=fullfile(referenceRunRoot,'Modified_Models','updateStatesFromPhreeqc.m');
diagnosticSource=fileread(diagnosticFile);
if ~contains(diagnosticSource,'Solution.TotalDIC')
 diagnosticSource=regexprep(diagnosticSource,'(C4\s*=\s*phaseData.C4;)', ...
  '$1 totalDIC = C4 + states{t,1}.x(:,3)./max(states{t,1}.x(:,1),eps)/MW_H2O;');
 diagnosticSource=regexprep(diagnosticSource,'(C4\(i\)\s*=\s*[^;]+;)', ...
  '$1 totalDIC(i) = output{end,6};');
 diagnosticSource=strrep(diagnosticSource,'states{t,1}.Solution.C4        = C4;', ...
  ['states{t,1}.Solution.C4        = C4;',newline,'states{t,1}.Solution.TotalDIC = totalDIC;']);
 fid=fopen(diagnosticFile,'w');fwrite(fid,diagnosticSource,'char');fclose(fid);
end
% Match flow and post-chemistry thermodynamics; upstream kinetic equations stay unchanged.
source=strrep(source,'model = GenericOverallCompositionModel_Modified(arg{:});', ...
 ['model = GenericOverallCompositionModel_Modified(arg{:});',newline, ...
  'model.EOSModel = SoreideWhitsonEos(G, mixture, ''msalt'', 2.865, ''pH'', 6.24, ''initial_NaCl'', 2.865, ''initial_SO4'', 4.664e-3, ''rho_water'', 1000);']);
source=strrep(source,'eos = EquationOfStateModel([], mixture, ''Peng-Robinson'');', ...
 'eos = SoreideWhitsonEos([], mixture, ''msalt'', 2.865, ''pH'', 6.24, ''initial_NaCl'', 2.865, ''initial_SO4'', 4.664e-3, ''rho_water'', 1000);');
cd(fullfile(referenceRunRoot,'examples'));eval(source);
assert(model.G.cells.num==opt.gridCells,'Reference grid adapter did not match the requested grid.');
if strcmp(opt.rate,'highrate')
 assert(model.Kinetic.mu_MET==4.1 && model.Kinetic.mu_ACE==1.9 && model.Kinetic.mu_SRB==5.5);
 assert(model.Kinetic.K_Dmet==9e-6,'Reference high-rate MET half-saturation must match H2sim.');
else
 assert(model.Kinetic.mu_MET==1.109 && model.Kinetic.mu_ACE==0.872 && model.Kinetic.mu_SRB==1.048);
end
model.parpool=false;schedule.step.val=repmat(2*day,validationStepCount,1);
schedule.step.control=ones(validationStepCount,1);
schedule.step.control(cumsum(schedule.step.val)>50*day)=2;
schedule.step.control(cumsum(schedule.step.val)>200*day)=3;
referenceProblem=packH2simSimulationProblem(state0,model,schedule,'PHREEQC_REFERENCE_CYCLE_SETUP');
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
 'description','Complete PHREEQC storage-cycle comparison; common SW parameters; distinct chemistry splitting.');
result.diagnostics=collectPhreeqcValidationDiagnostics(result);
file=[tempname,'.mat'];fileCleanup=onCleanup(@() delete(file)); %#ok<NASGU>
save(file,'result','-v7');copyfile(file,fullfile(opt.outputDirectory,'validation_results.mat'),'f');
if opt.plotResults,plotCompositionalPhreeqcValidation(result,'outputDirectory',opt.outputDirectory);end
end
function restore(savedPath,folder)
path(savedPath);cd(folder);
end
