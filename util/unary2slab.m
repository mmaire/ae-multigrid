% Create slabs encoding unary potentials at source and destination pixel pairs.
%
% [u_src u_dst] = unary2slab(umap, stencil, def_val)
%
% Input:
%    umap    - (sx x sy) unary potential map
%    stencil - (nc x 2) offset stencil, nc = number of channels
%    def_val - default value to use for potentials at off-map locations
%
% Output:
%    u_src   - unary potential at source pixel of each cell in slab
%    u_dst   - unary potential at destination pixel of each cell in slab
function [u_src u_dst] = unary2slab(umap, stencil, def_val)
   % get potential map dimensions
   [sx sy] = size(umap);
   np = sx.*sy;
   % get stencil size
   nc = size(stencil,1);
   % create source and destination index slabs
   [idx_src idx_dst] = stencil2idx([sx sy nc], stencil);
   % lookup unary source potential
   u_src = umap(idx_src);
   % lookup unary destination potential
   u_dst = repmat(def_val, [sx sy nc]);
   idx_dst = reshape(idx_dst,[(np.*nc) 1]);
   inds = find((idx_dst >= 1) & (idx_dst <= np));
   u_dst(inds) = umap(idx_dst(inds));
end
