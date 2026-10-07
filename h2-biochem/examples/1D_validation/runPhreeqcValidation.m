function result = runPhreeqcValidation(varargin)
%RUNPHREEQCVALIDATION Compare compositional PHREEQC with an external reference.
% Specify ugfactRoot as a separate upstream checkout. Serial execution is used.
% Full setups, accepted outputs, and a redrawable comparison are saved.
result = exampleCompositionalPhreeqcValidation(varargin{:});
end
