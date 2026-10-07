function figures=plotCompositionalBacterial2DThreeReactions(results,varargin)
%PLOTCOMPOSITIONALBACTERIAL2DTHREEREACTIONS Redraw the existing 2D storage case.
% Maps show gas-phase mole fractions, masked where gas saturation < 0.001.
% Well-cell H2 fractions are local samples, not flow-weighted produced purity.
opt=merge_options(struct('outputDirectory',''),varargin{:});
assert(all([results.complete]),'Cycle figures require completed simulations.');
labels={'H_2','CO_2','CH_4'};components=[2,3,4];
colors=[.04,.5,.51;.85,.5,.2;.35,.35,.7];styles={'-','--',':'};
n=numel(results);f=figure('Color','w','Units','centimeters','Position',[2,2,27,9*n]);
tiledlayout(n,3,'TileSpacing','compact','Padding','compact');
for j=1:n
 r=results(j);ends=getCyclesLastSteps(r.schedule);index=ends.charge(end);
 t=sum(r.schedule.step.val(1:index))/day;s=r.states{index};
 for c=1:3
  ax=nexttile;data=s.y(:,components(c));data(s.s(:,2)<1e-3)=nan;
  plotCellData(r.model.G,data,'EdgeColor','none');hold(ax,'on');
  wc=r.schedule.control(1).W.cells;
  plot(ax,r.model.G.cells.centroids(wc,1),r.model.G.cells.centroids(wc,2),'ko','MarkerFaceColor','w','MarkerSize',3);
  view(ax,2);axis(ax,'equal');axis(ax,[0,50,0,50]);caxis(ax,[0,1]);colormap(ax,parula(256));
  xlabel(ax,'Horizontal distance (m)');ylabel(ax,'Elevation (m)');
  title(ax,sprintf('%s · %s · injection %d, day %g',labels{c},r.name,numel(ends.charge),t));
  cb=colorbar(ax);ylabel(cb,'Gas-phase mole fraction (-)');
  set(ax,'FontName','Arial','FontSize',9);box(ax,'on');
 end
end
exportPlot(f,opt.outputDirectory,'compositional_2d_gas_maps');
g=figure('Color','w','Units','centimeters','Position',[2,2,27,11]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile;hold(ax,'on');ax2=nexttile;hold(ax2,'on');ax3=nexttile;hold(ax3,'on');
for j=1:n
 r=results(j);t=cumsum(r.schedule.step.val)/day;wc=r.schedule.control(1).W.cells;
 rate=cellfun(@(w) sum([w.qGs]),r.wellSols)*day;
 bhp=cellfun(@(w) w(1).bhp,r.wellSols)/barsa;
 h2=cellfun(@(s) mean(s.y(wc,2)),r.states);
 color=colors(mod(j-1,size(colors,1))+1,:);
 plot(ax,t,rate,'Color',color,'LineStyle',styles{mod(j-1,3)+1},'LineWidth',1.5,'DisplayName',r.name);
 plot(ax2,t,bhp,'Color',color,'LineStyle',styles{mod(j-1,3)+1},'LineWidth',1.5,'DisplayName',r.name);
 plot(ax3,t,h2,'Color',color,'LineStyle',styles{mod(j-1,3)+1},'LineWidth',1.5,'DisplayName',r.name);
end
xlabel(ax,'Time (days)');ylabel(ax,'Gas surface rate (m^3/day)');title(ax,'Injection and withdrawal');yline(ax,0,':','HandleVisibility','off');
xlabel(ax2,'Time (days)');ylabel(ax2,'Bottom-hole pressure (bar)');title(ax2,'Well pressure');
xlabel(ax3,'Time (days)');ylabel(ax3,'Gas H_2 mole fraction at well cells (-)');title(ax3,'Local gas composition');ylim(ax3,[0,1]);
ends=getCyclesLastSteps(results(1).schedule);t=cumsum(results(1).schedule.step.val)/day;
for j=1:numel(ends.charge)
 if j==1,start=t(ends.cushion(1))+results(1).setup.timeShut/day;else,start=t(ends.discharge(j-1));end
 for a=[ax,ax2,ax3],xline(a,start,':','Color',[.65,.65,.65],'HandleVisibility','off');end
 limits=ylim(ax);midpoint=(start+t(ends.discharge(j)))/2;
 text(ax,midpoint,limits(2)-.08*diff(limits),sprintf('C%d',j),'HorizontalAlignment','center','FontSize',8);
end
for a=[ax,ax2,ax3]
 set(a,'FontName','Arial','FontSize',9);box(a,'on');grid(a,'on');legend(a,'Location','best','FontSize',8);
end
exportPlot(g,opt.outputDirectory,'compositional_2d_cycle_logs');figures=[f,g];
end
function exportPlot(f,folder,name)
if isempty(folder),return;end
if ~isfolder(folder),mkdir(folder);end
exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',200);
exportgraphics(f,fullfile(folder,[name,'.pdf']),'ContentType','vector');
end
