function diagnostics=collectPhreeqcValidationDiagnostics(result)
%COLLECTPHREEQCVALIDATIONDIAGNOSTICS Full-cycle comparison observables.
names={'h2sim','ugfact'};diagnostics=struct();
for j=1:2
 r=result.(names{j});t=double(cumsum(r.schedule.step.val(:)))/day;n=numel(r.states);
 assert(n>0 && n==numel(t),'H2sim:ValidationStateCount','States must match the nonempty accepted schedule.');
 d=struct('timeDays',t,'coordinates',r.model.G.cells.centroids,'h2',[], ...
  'pH',[],'dic',[],'consumption',zeros(r.model.G.cells.num,n,3));
 for k=1:n
  s=r.states{k};d.h2(:,k)=s.x(:,2);
  if j==1,d.pH(:,k)=s.phreeqcPH;d.dic(:,k)=s.phreeqcTotalCarbon;
  else
   d.pH(:,k)=s.Solution.pH;
   assert(isfield(s.Solution,'TotalDIC'),'Reference total-DIC diagnostic required.');
   d.dic(:,k)=s.Solution.TotalDIC;
  end
 end
 for c=1:3
  if j==1,[~,d.consumption(:,:,c)]=computeH2Consumption(r.states,r.schedule,r.model,c);
  else
   reactionNames={'MET_Rate','ACE_Rate','SRB_Rate'};
   for k=1:n
    s=r.states{k}.Solution;increment=s.(reactionNames{c}).*s.Water/1000*r.schedule.step.val(k)/day;
    if k==1,d.consumption(:,k,c)=increment;
    else,d.consumption(:,k,c)=d.consumption(:,k-1,c)+increment;end
   end
  end
 end
 injected=0;
 for k=1:n
  W=r.schedule.control(r.schedule.step.control(k)).W;
  for wi=1:numel(W)
   w=W(wi);if w.sign<=0 || ~w.status,continue;end
   if strcmp(w.type,'rate'),q=w.val*w.compi(r.model.getVaporIndex());
   elseif strcmp(w.type,'grat'),q=w.val;else,continue;end
   injected=injected+q*w.components(2)*r.schedule.step.val(k)* ...
    r.model.FacilityModel.pressure/(8.314462618*r.model.FacilityModel.T);
  end
 end
 assert(isfinite(injected) && injected>0,'H2sim:ValidationInjection','Validation requires a positive prescribed H2 injection.');
 d.injectedMoles=injected;d.lossPercent=100*reshape(sum(sum(d.consumption,1),3),n,1)/injected;
 diagnostics.(names{j})=d;
end
end
