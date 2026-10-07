function result = exampleBlackOilH2Storage1D(varargin)
%EXAMPLEBLACKOILH2STORAGE1D Small serial hydrogen/brine injection tutorial.
% A horizontal homogeneous column uses MRST's two-phase black-oil model.
% The oil phase represents brine. This tutorial is immiscible: DISGAS and
% VAPOIL are off. H2 gas density uses the h2-store Brill-Beggs correlation;
% brine density/viscosity and gas viscosity are fixed tutorial assumptions.
% No PHREEQC, Parallel Computing Toolbox, NIST download, or field case.
opt=merge_options(struct('gridCells',40,'numSteps',12,'plotResults',true, ...
 'outputDirectory',fullfile(pwd,'build','example-figures')),varargin{:});
validateattributes(opt.gridCells,{'numeric'},{'scalar','integer','positive'});
validateattributes(opt.numSteps,{'numeric'},{'scalar','integer','positive'});
validateattributes(opt.plotResults,{'logical'},{'scalar'});
mrstModule add ad-core ad-props ad-blackoil
G=computeGeometry(cartGrid([opt.gridCells,1,1],[100,1,1]));
rock=makeRock(G,100*milli*darcy,0.2); T=317.15; p0=15*mega*Pascal;
pSurface=101325; molarMass=0.00201588; R=8.3144598;
zSurface=calculateBrillBreggsZfactorHydrogen(T,pSurface);
rhoSurface=pSurface*molarMass/(zSurface*R*T);
fluid=initSimpleADIFluid('phases','OG','mu',[0.7,0.009]*centi*poise, ...
 'rho',[1050,rhoSurface],'n',[2,2],'cO',4e-10,'pRef',p0);
fluid.bG=@(p,varargin) (p./calculateBrillBreggsZfactorHydrogen(T,p))/(pSurface/zSurface);
model=GenericBlackOilModel(G,rock,fluid,'water',false, ...
 'disgas',false,'vapoil',false,'gravity',[0,0,0]);
state0=initResSol(G,p0,[1,0]);
pv=sum(poreVolume(G,rock)); b0=fluid.bG(p0);
W=addWell([],G,rock,1,'Type','rate','Val',0.02*pv/day*b0, ...
 'comp_i',[0,1],'sign',1,'Name','H2 injector','Radius',0.1);
bc=pside([],G,'RIGHT',p0,'sat',[1,0]);
schedule=simpleSchedule(repmat(day,opt.numSteps,1),'W',W,'bc',bc);
problem=packH2simSimulationProblem(state0,model,schedule,'H2_BLACKOIL_1D_EXAMPLE');
ok=simulatePackedProblem(problem,'continueOnError',false);
assert(ok,'Black-oil tutorial did not complete.');
[wellSols,states,reports]=getPackedSimulatorOutput(problem);
report=struct('Failure',false,'StepReports',{reports});
assert(~report.Failure,'Black-oil tutorial did not converge.');
result=struct('model',model,'schedule',schedule,'state0',state0, ...
 'states',{states},'wellSols',{wellSols},'report',report,'packedProblem',problem, ...
 'temperatureK',T,'assumptions','Immiscible H2/brine; constant brine properties; no gravity.');
if opt.plotResults
 f=figure('Color','w','Units','centimeters','Position',[2,2,24,10]);
 tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
 ax1=nexttile;hold(ax1,'on');ax2=nexttile;hold(ax2,'on');
 colors=[0.04,0.5,0.51;0.85,0.5,0.2;0.22,0.32,0.57];
 steps=unique(max(1,round(linspace(opt.numSteps/3,opt.numSteps,3))));
 for j=1:numel(steps)
  k=steps(j);s=states{k};label=sprintf('Day %g',sum(schedule.step.val(1:k))/day);
  plot(ax1,G.cells.centroids(:,1),s.s(:,2),'LineWidth',1.8,'Color',colors(j,:),'DisplayName',label);
  plot(ax2,G.cells.centroids(:,1),s.pressure/1e6,'LineWidth',1.8,'Color',colors(j,:),'DisplayName',label);
 end
 xlabel(ax1,'Distance (m)');ylabel(ax1,'H_2 gas saturation (-)');ylim(ax1,[0,1]);
 xlabel(ax2,'Distance (m)');ylabel(ax2,'Pressure (MPa)');
 title(ax1,'Hydrogen displacement');title(ax2,'Pressure response');
 for ax=[ax1,ax2],box(ax,'on');grid(ax,'on');set(ax,'FontName','Arial','FontSize',10);legend(ax,'Location','best');end
 if ~isempty(opt.outputDirectory)
  if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
  exportgraphics(f,fullfile(opt.outputDirectory,'blackoil_profiles.pdf'),'ContentType','vector');
  exportgraphics(f,fullfile(opt.outputDirectory,'blackoil_profiles.png'),'Resolution',200);
 end
end
end
