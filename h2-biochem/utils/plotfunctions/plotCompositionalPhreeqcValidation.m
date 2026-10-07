function figures=plotCompositionalPhreeqcValidation(result,varargin)
%PLOTCOMPOSITIONALPHREEQCVALIDATION Compare saved injection benchmark states.
opt=merge_options(struct('outputDirectory',''),varargin{:});
a=result.h2sim;b=result.ugfact;
x=a.model.G.cells.centroids(:,1);assert(isequal(x,b.model.G.cells.centroids(:,1)));
t=cumsum(a.schedule.step.val)/day;assert(isequal(t,cumsum(b.schedule.step.val)/day));
sa=a.states{end};sb=b.states{end};
f=figure('Color','w','Units','centimeters','Position',[2,2,26,10]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile;plot(ax,x,sa.x(:,2),'-',x,sb.x(:,2),'--','LineWidth',1.8);xlabel(ax,'Distance (m)');ylabel(ax,'Aqueous H_2 mole fraction (-)');title(ax,sprintf('End of injection · day %g',t(end)));
ax2=nexttile;plot(ax2,x,sa.phreeqcPH,'-',x,sb.Solution.pH,'--','LineWidth',1.8);xlabel(ax2,'Distance (m)');ylabel(ax2,'pH (-)');title(ax2,'Aqueous chemistry');
[~,cum]=computeH2Consumption(a.states,a.schedule,a.model,1);consumed=sum(cum,1).';
for j=2:3,[~,cum]=computeH2Consumption(a.states,a.schedule,a.model,j);consumed=consumed+sum(cum,1).';end
ref=zeros(numel(t),1);
for k=1:numel(t)
 s=b.states{k}.Solution;increment=sum((s.MET_Rate+s.ACE_Rate+s.SRB_Rate).*s.Water/1000)*b.schedule.step.val(k)/day;
 ref(k)=increment;if k>1,ref(k)=ref(k)+ref(k-1);end
end
ax3=nexttile;plot(ax3,t,consumed,'-',t,ref,'--','LineWidth',1.8);xlabel(ax3,'Time (days)');ylabel(ax3,'Cumulative H_2 reaction consumption (mol)');title(ax3,'Microbial consumption');
for a=[ax,ax2,ax3]
 colororder(a,[.04,.5,.51;.85,.5,.2]);
 set(a,'FontName','Arial','FontSize',10);box(a,'on');grid(a,'on');
end
lg=legend(ax3,{'Compositional PHREEQC','Reference'},'Orientation','horizontal','FontSize',9);
lg.Layout.Tile='south';
if ~isempty(opt.outputDirectory)
 if ~isfolder(opt.outputDirectory),mkdir(opt.outputDirectory);end
 exportgraphics(f,fullfile(opt.outputDirectory,'compositional_phreeqc_validation.png'),'Resolution',200);
 exportgraphics(f,fullfile(opt.outputDirectory,'compositional_phreeqc_validation.pdf'),'ContentType','vector');
end
figures=f;
end
