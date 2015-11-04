% Convert pairwise pixel relationships encoded as a feature map (slab) into a
% sparse matrix.
%
% [smx] = slab2sparse(slab, stencil)
%
% Input:
%    slab    - (sx x sy x nc) feature map, nc = number of channels
%    stencil - (nc x 2) offset stencil
%
% Output:
%    smx     - (sx*sy) x (sx*sy) sparse matrix of pairwise relationships
function [smx] = slab2sparse(slab, stencil)
   % get slab dimensions
   [sx sy nc] = size(slab);
   np = sx.*sy;
   % check stencil size
   if (nc ~= size(stencil,1))
      error('size mismatch between slab and stencil');
   end
   % create source and destination index slabs
   [idx_src idx_dst] = stencil2idx([sx sy nc], stencil);
   % reshape slabs
   ni = np.*nc;
   idx_src = reshape(idx_src,[ni 1]);
   idx_dst = reshape(idx_dst,[ni 1]);
   vals    = reshape(slab,[ni 1]);
   % extract valid indices
   inds = find((idx_dst >= 1) & (idx_dst <= np));
   ii = idx_src(inds);
   jj = idx_dst(inds);
   vv = vals(inds);
   % build sparse matrix
   smx = sparse(ii, jj, vv, np, np);
end
