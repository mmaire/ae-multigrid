% Angular embedding on CNN pairwise predictions.
function [ae] = ae_cnn(b_pred, fg_pred, stencil, sigma_b, sigma_fg)
   % default arguments
   if ((nargin < 4) || isempty(sigma_b)),  sigma_b  = 0.1; end
   if ((nargin < 5) || isempty(sigma_fg)), sigma_fg = 0.1; end
   % flip stencil y-coordinates to conform to matlab indexing
   stencil(:,2) = -stencil(:,2);
   % extract CNN probabilities from raw prediction value
   b_prob = 1 - b_pred;             % boundary probability
   %FIXME: figure/ground
   % convert CNN probabilities to confidence
   Cb = exp(-b_prob ./ sigma_b);    % binding force
   %FIXME: figure/ground
   % build sparse affinity matrix for confidence
   Cmx = slab2sparse(Cb, stencil);
   % eigensolver options
   opts = struct( ...
      'k', [1 1 1], ...
      'k_rate', sqrt(2), ...
      'tol_err', 10.^-2, ...
      'disp', true ...
   );
   % assemble multiscale input
   C_arr     = { Cmx };
   Theta_arr = { [] };
   U_arr     = { [] };
   % eigensolver
   tic;
   [evecs evals info] = ae_multigrid(C_arr, Theta_arr, U_arr, 16, opts);
   time = toc;
   disp(['Wall clock time for eigensolver: ' num2str(time) ' seconds']);
   % spectral boundary extraction
   [spb_arr spbo_arr spb spbo spb_nmax] = multiscale_spb( ...
      evecs, evals, { zeros([size(b_pred,1) size(b_pred,2)]) } ...
   );
   % return data
   ae = struct( ...
      'spb_arr',  {spb_arr}, ...
      'spbo_arr', {spbo_arr}, ...
      'spb',      {spb}, ...
      'spbo',     {spbo}, ...
      'spb_nmax', {spb_nmax} ...
   );
end
