% Conjugate symmetrize a (possibly complex-valued) sparse matrix.
%
% [smx_symm] = sparse_symmetrize(smx, method)
%
% Input:
%    smx       - (np x np) sparse matrix
%    method    - averaging method {'amean', 'gmean'} (default: 'amean')
%                (arithmetic or geometric mean)
%
% Output:
%    smx_symm  - matrix with complex conjugate symmetry
function [smx_symm] = sparse_symmetrize(smx, method)
   % default arguments
   if ((nargin < 2) || isempty(method))
      method = 'amean';
   end
   % check input
   if (size(smx,1) ~= size(smx,2))
      error('square input matrix required');
   end
   % unpack matrix
   np = size(smx,1);
   [ii jj vv] = find(smx);
   % construct conjugate transpose
   smx_ct = sparse(jj, ii, conj(vv), np, np);
   % symmetrize
   if strcmp(method,'amean')
      smx_symm = 0.5.*(smx + smx_ct);
   elseif strcmp(method,'gmean')
      smx_symm = sqrt(smx.*smx_ct);
   else
      error('invalid method specified');
   end
end
