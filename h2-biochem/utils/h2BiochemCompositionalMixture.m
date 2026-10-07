function mixture = h2BiochemCompositionalMixture(names, outnames)
%H2BIOCHEMCOMPOSITIONALMIXTURE Tabulated MRST fluids plus legacy acetate data.
% Keep H2sim's acetic-acid component independent of local MRST table edits.
% The acetate parameters retain the values used by the existing H2sim setup;
% they are an EOS parameterization, not PHREEQC aqueous speciation constants.
if nargin<2, outnames=names; end
assert(numel(names)==numel(outnames));
acid=strcmpi(names,'AceticAcid');
if ~any(acid)
    mixture=TableCompositionalMixture(names,outnames); return
end
n=numel(names); [Tc,Pc,Vc,acc,mass]=deal(zeros(1,n));
if any(~acid)
base=TableCompositionalMixture(names(~acid),outnames(~acid));
Tc(~acid)=base.Tcrit; Pc(~acid)=base.Pcrit; Vc(~acid)=base.Vcrit;
acc(~acid)=base.acentricFactors; mass(~acid)=base.molarMass;
end
Tc(acid)=592; Pc(acid)=5790000; mass(acid)=0.060050;
Vc(acid)=0.060050/276; acc(acid)=0.466;
mixture=CompositionalMixture(outnames,Tc,Pc,Vc,acc,mass);
mixture.name='MRST tabulated fluids with H2sim acetate parameters';
end
