function lastSteps=getCyclesLastSteps(schedule)
%GETCYCLESLASTSTEPS Last accepted control step of each storage stage.
% Include the final stage even when its name never changes again.
lastSteps=struct('charge',[],'discharge',[],'shut',[],'cushion',[]);
n=numel(schedule.step.control);
for i=1:n
 current=stageName(schedule.control(schedule.step.control(i)));
 if i<n,next=stageName(schedule.control(schedule.step.control(i+1)));else,next='';end
 if i==n || ~strcmp(current,next)
  if ~isfield(lastSteps,current),lastSteps.(current)=[];end
  lastSteps.(current)(end+1)=i;
 end
end
end

function name=stageName(control)
if isfield(control.W,'stage'),name=control.W(1).stage;else,name=control.W(1).name;end
end
