function figures=plotBlackOilAquifer2D(result,varargin)
%PLOTBLACKOILAQUIFER2D Plume snapshots and well response from saved results.
opt=merge_options(struct('outputDirectory',''),varargin{:});
G=result.model.G;times=cumsum(result.schedule.step.val)/day;
ends=getCyclesLastSteps(result.schedule);
indices=[ends.cushion(1),ends.charge(end),ends.discharge(end)];
labels={'After build-up',sprintf('Injection · cycle %d',numel(ends.charge)),sprintf('Withdrawal · cycle %d',numel(ends.discharge))};
f=figure('Color','w','Units','centimeters','Position',[2,2,27,11]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
maximum=max(cellfun(@(s) max(s.s(:,2)),result.states));
for j=1:3
 ax=nexttile;plotCellData(G,result.states{indices(j)}.s(:,2),'EdgeColor','none');
 hold(ax,'on');x=linspace(0,50,150);plot(ax,x,25+5*sin(pi*x/50),'k-','LineWidth',1.1);
 wc=result.schedule.control(1).W.cells;plot(ax,G.cells.centroids(wc,1),G.cells.centroids(wc,2),'wo','MarkerFaceColor','k','MarkerSize',4);
 view(ax,2);axis(ax,'equal');axis(ax,[0,50,0,50]);xlabel(ax,'Horizontal distance (m)');ylabel(ax,'Elevation (m)');
 title(ax,sprintf('%s · day %.1f',labels{j},times(indices(j))));
 caxis(ax,[0,max(maximum,0.01)]);colormap(ax,parula(256));cb=colorbar(ax);ylabel(cb,'H_2 gas saturation (-)');
 set(ax,'FontName','Arial','FontSize',10);box(ax,'on');
end
exportPlot(f,opt.outputDirectory,'aquifer_plume');
g=figure('Color','w','Units','centimeters','Position',[2,2,23,10]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile;rate=cellfun(@(w) w(1).qGs,result.wellSols);plot(ax,times,rate*day,'LineWidth',1.8,'Color',[.04,.5,.51]);
yline(ax,0,':');xlabel(ax,'Time (days)');ylabel(ax,'Gas surface rate (m^3/day)');title(ax,'Injection and withdrawal');
ax2=nexttile;bhp=cellfun(@(w) w(1).bhp,result.wellSols);plot(ax2,times,bhp/1e5,'LineWidth',1.8,'Color',[.85,.5,.2]);
xlabel(ax2,'Time (days)');ylabel(ax2,'Bottom-hole pressure (bar)');title(ax2,'Well pressure');
for j=1:numel(ends.charge)
 if j==1,cycleStart=times(ends.cushion(1))+result.setup.timeShut/day;
 else,cycleStart=times(ends.discharge(j-1));end
 for a=[ax,ax2]
  xline(a,cycleStart,':','Color',[.65,.65,.65],'HandleVisibility','off');
 end
 text(ax,cycleStart+result.setup.timeCharge/day/2,max(rate*day)*1.08,sprintf('Cycle %d',j),'HorizontalAlignment','center','FontSize',8);
end
ylim(ax,[min(rate*day)*1.15,max(rate*day)*1.2]);
for a=[ax,ax2],set(a,'FontName','Arial','FontSize',10);grid(a,'on');box(a,'on');end
exportPlot(g,opt.outputDirectory,'aquifer_well_response');figures=[f,g];
end
function exportPlot(f,folder,name)
if isempty(folder),return;end
if ~isfolder(folder),mkdir(folder);end
exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',200);
exportgraphics(f,fullfile(folder,[name,'.pdf']),'ContentType','vector');
end
