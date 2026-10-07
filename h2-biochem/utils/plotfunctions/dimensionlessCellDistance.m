function x = dimensionlessCellDistance(G)
% Cell-center x/L measured from the left domain boundary, not first cell.
bounds = [min(G.nodes.coords(:,1)), max(G.nodes.coords(:,1))];
assert(all(isfinite(bounds)) && bounds(2)>bounds(1), ...
    'The grid must have a positive finite extent in x.');
x = (G.cells.centroids(:,1)-bounds(1))/(bounds(2)-bounds(1));
end
