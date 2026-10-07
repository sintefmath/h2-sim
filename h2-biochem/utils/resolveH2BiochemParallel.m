function enabled = resolveH2BiochemParallel(requested, availabilityCheck)
%RESOLVEH2BIOCHEMPARALLEL Keep serial workflows usable without optional PCT.
% Serial is the default. A requested parallel flash falls back to serial
% when Parallel Computing Toolbox or its license is unavailable.
validateattributes(requested, {'logical'}, {'scalar'});
if ~requested, enabled=false; return; end
if nargin<2
 availabilityCheck=@() license('test','Distrib_Computing_Toolbox') && ~isempty(ver('parallel'));
end
validateattributes(availabilityCheck, {'function_handle'}, {'scalar'});
enabled=logical(availabilityCheck());
if ~enabled
 warning('H2Biochem:ParallelUnavailable', ...
  'Parallel Computing Toolbox is unavailable; using serial pressure flashes.');
end
end
