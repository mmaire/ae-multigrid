% Angular embedding on CNN pairwise predictions.
function [ae] = ae_cnn(b_pred, fg_pred, stencil, sigma_b, sigma_fg)
   % default arguments
   if ((nargin < 4) || isempty(sigma_b)),  sigma_b  = 0.1; end
   if ((nargin < 5) || isempty(sigma_fg)), sigma_fg = 0.1; end
   % flip stencil y-coordinates to conform to matlab indexing
   stencil(:,2) = -stencil(:,2);
   % extract CNN probabilities from raw prediction value
   b_prob = 1 - b_pred;             % boundary probability
   f_prob = 1 - 2.*fg_pred;         % figure probability
   g_prob = 2.*fg_pred - 1;         % ground probability
   % clip figure/ground probabilities
   f_prob = f_prob.*(f_prob > 0);
   g_prob = g_prob.*(g_prob > 0);
   % convert CNN probabilities to error probability
   Eb = b_prob;
   Ef = f_prob;
   Eg = g_prob;
   % hack - don't trust immediate neighbors
   Ef(:,:,1:16) = 1;
   Eg(:,:,1:16) = 1;
   % convert error probability to confidence
   Cb = exp(-Eb ./ sigma_b);           % binding force
   Cf = (1-Cb).*exp(-Ef ./ sigma_fg);  % ground -> figure transition force
   Cg = (1-Cb).*exp(-Eg ./ sigma_fg);  % figure -> ground transition force
   % hack - get a per-pixel boundary map
   %bmap = mean(b_prob
   % define figure/ground rotational constant
   phi = pi./16;
   % compute generalized affinity
   W_slab = Cb + Cf.*exp(i.*phi) + Cg.*exp(-i.*phi);
   % build sparse affinity matrix
   W_mx = slab2sparse(W_slab, stencil);
   % extract magnitude and argument
   C_mx = abs(W_mx);
   T_mx = angle(W_mx);
   % compress rotational action
   %rot_total = sum(abs(T_mx(:)));
   %rot_scale = (pi./2)./rot_total;
   % rescale rotation component
   %Theta_mx = T_mx.*rot_scale;
   Theta_mx = T_mx;
   % assemble angular embedding problem
   C_arr     = { C_mx };
   Theta_arr = { Theta_mx };
   U_arr     = { [] };
   % eigensolver options
   opts = struct( ...
      'k', [1 1 1], ...
      'k_rate', sqrt(2), ...
      'tol_err', 10.^-2, ...
      'disp', true ...
   );
   % eigensolver
   tic;
   [evecs evals info] = ae_multigrid(C_arr, Theta_arr, U_arr, 16, opts);
   time = toc;
   disp(['Wall clock time for eigensolver: ' num2str(time) ' seconds']);
   % spectral boundary extraction - real
   [rspb_arr rspbo_arr rspb rspbo rspb_nmax] = multiscale_spb( ...
      real(evecs), ...
      abs(evals), ...
      { zeros([size(b_pred,1) size(b_pred,2)]) } ...
   );
   % spectral boundary extraction - imag
   [ispb_arr ispbo_arr ispb ispbo ispb_nmax] = multiscale_spb( ...
      imag(evecs), ...
      abs(evals), ...
      { zeros([size(b_pred,1) size(b_pred,2)]) } ...
   );
   spb = rspb + ispb;
   % return data
   ae = struct( ...
      'fg',  {reshape(angle(evecs(:,1)), [size(b_pred,1) size(b_pred,2)])}, ...
      'spb', {spb} ...
   );
end
