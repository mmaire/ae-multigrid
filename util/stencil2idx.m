% Create index slabs corresponding to stencil offsets.
%
% [idx_src idx_dst] = stencil2idx([sx sy nc], stencil)
%
% Input:
%    [sx sy nc] - feature map dimensions, nc  = number of channels
%    stencil    - (nc x 2) offset stencil
%
% Output:
%    idx_src    - index of source pixel at each feature map cell
%    idx_dst    - index of destination pixel at each feature map cell
%
% Note that some returned destination pixel indices may lie outside the valid
% index range of 1:(sx*sy).
function [idx_src idx_dst] = stencil2idx(dims, stencil)
   % extract slab dimensions
   sx = dims(1);
   sy = dims(2);
   nc = dims(3);
   % check stencil size
   if (nc ~= size(stencil,1))
      error('size mismatch between slab and stencil');
   end
   % convert stencil to channel offset vector
   dx = stencil(:,1);
   dy = stencil(:,2);
   offsets = dx + sx.*dy;
   % create offset slab
   offset_slab = repmat(reshape(offsets,[1 1 nc]),[sx sy]);
   % create source and destination index slabs
   idx_src = repmat(reshape(1:(sx.*sy),[sx sy]),[1 1 nc]);
   idx_dst = idx_src + offset_slab;
end
