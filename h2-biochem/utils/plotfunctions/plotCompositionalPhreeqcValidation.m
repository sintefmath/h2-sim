function figures=plotCompositionalPhreeqcValidation(result,varargin)
%PLOTCOMPOSITIONALPHREEQCVALIDATION Full-cycle reference and chemistry plots.
opt=merge_options(struct('outputDirectory',''),varargin{:});
if isfield(result,'diagnostics'),d=result.diagnostics;
else,d=collectPhreeqcValidationDiagnostics(result);end
a=d.h2sim;b=d.ugfact;t=double(a.timeDays(:));x=a.coordinates(:,1);
assert(isequal(t,double(b.timeDays(:))) && isequal(x,b.coordinates(:,1)));
f=figure('Color','w','Units','centimeters','Position',[2,2,29,11]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile;plot(ax,t,a.lossPercent,'-',t,b.lossPercent,'--','LineWidth',1.8);
xlabel(ax,'Time (days)');ylabel(ax,'Consumed H_2 / total prescribed injection (%)');
title(ax,'Hydrogen consumption');legend(ax,{'Compositional PHREEQC','Reference'},'Location','best');grid(ax,'on');
maximum=max([a.h2(:);b.h2(:)]);
for j=1:2
 if j==1,r=a;name='Compositional PHREEQC';else,r=b;name='Reference';end
 ax=nexttile;imagesc(ax,t,x,r.h2);set(ax,'YDir','normal');caxis(ax,[0,maximum]);
 xlabel(ax,'Time (days)');ylabel(ax,'Distance (m)');title(ax,name);cb=colorbar(ax);ylabel(cb,'Aqueous H_2 mole fraction (-)');
end
g=figure('Color','w','Units','centimeters','Position',[2,2,26,18]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
fields={'pH','dic'};units={'pH (-)','DIC (mol/kg water)'};
for c=1:2
 lo=min([a.(fields{c})(:);b.(fields{c})(:)]);hi=max([a.(fields{c})(:);b.(fields{c})(:)]);
 for j=1:2
  if j==1,r=a;name='Compositional PHREEQC';else,r=b;name='Reference';end
  ax=nexttile;imagesc(ax,t,x,r.(fields{c}));set(ax,'YDir','normal');caxis(ax,[lo,hi]);
  xlabel(ax,'Time (days)');ylabel(ax,'Distance (m)');title(ax,[name,' · ',fields{c}]);
  cb=colorbar(ax);ylabel(cb,units{c});
 end
end
h=figure('Color','w','Units','centimeters','Position',[2,2,29,11]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');names={'MET','ACE','SRB'};
pa=100*reshape(sum(a.consumption,1),numel(t),3)/a.injectedMoles;
pb=100*reshape(sum(b.consumption,1),numel(t),3)/b.injectedMoles;
assert(max(abs(sum(pa,2)-a.lossPercent(:)))<1e-8);
assert(max(abs(sum(pb,2)-b.lossPercent(:)))<1e-8);
for c=1:3
 ax=nexttile;plot(ax,t,pa(:,c),'-',t,pb(:,c),'--','LineWidth',1.8);
 xlabel(ax,'Time (days)');ylabel(ax,'Consumed H_2 / total prescribed injection (%)');
 title(ax,names{c});legend(ax,{'Compositional PHREEQC','Reference'},'Location','best');grid(ax,'on');
end
figures=[f,g,h];
for fig=figures
 axesList=findall(fig,'Type','axes');
 for ax=reshape(axesList,1,[])
  xlim(ax,[0,t(end)]);set(ax,'FontName','Arial','FontSize',10);box(ax,'on');
  if t(end)>50,xline(ax,50,':','HandleVisibility','off');end
  if t(end)>200,xline(ax,200,':','HandleVisibility','off');end
 end
end
% Export once, after applying shared axes and stage markers.
files={'phreeqc_validation_full_cycle','phreeqc_geochemistry_full_cycle','phreeqc_reaction_loss_full_cycle'};
for j=1:3,exportPlot(figures(j),opt.outputDirectory,files{j});end
if ~isempty(opt.outputDirectory)
 writetable(array2table([t,a.lossPercent(:),b.lossPercent(:),pa,pb], ...
  'VariableNames',{'Time_days','H2sim_total_percent','Reference_total_percent', ...
  'H2sim_MET_percent','H2sim_ACE_percent','H2sim_SRB_percent', ...
  'Reference_MET_percent','Reference_ACE_percent','Reference_SRB_percent'}), ...
  fullfile(opt.outputDirectory,'phreeqc_loss_history.csv'));
end
end
function exportPlot(f,folder,name)
if isempty(folder),return;end
if ~isfolder(folder),mkdir(folder);end
exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',200);
exportgraphics(f,fullfile(folder,[name,'.pdf']),'ContentType','vector');
end
