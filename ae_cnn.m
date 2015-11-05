% Angular embedding on CNN pairwise predictions.
function [ae] = ae_cnn(b_pred, fg_pred, stencil, sigma_b, sigma_fg)
   % default arguments
   if ((nargin < 4) || isempty(sigma_b)),  sigma_b  = 0.1; end
   if ((nargin < 5) || isempty(sigma_fg)), sigma_fg = 0.1; end
   % flip stencil y-coordinates to conform to matlab indexing
   stencil(:,2) = -stencil(:,2);
   % extract CNN probabilities from raw prediction value
   b_prob = 1 - b_pred;             % boundary probability
   f_prob = fg_pred;                % conditional figure probability
   g_prob = 1 - fg_pred;            % conditional ground probability
   % interpolate on-edge probability
   emap = mean(b_prob(:,:,1:8),3);
   [es_prob ed_prob] = unary2slab(emap, stencil, 1);
   % compute transition probabilities
   tf_prob = (1-es_prob).*(b_prob).*(1-ed_prob).*(f_prob);
   tg_prob = (1-es_prob).*(b_prob).*(1-ed_prob).*(g_prob);
   % error probability
   Eb = b_prob;                     % chance of error in binding
   Ef = 1 - tf_prob;                % chance of error in figure transition
   Eg = 1 - tg_prob;                % chance or error in ground transition
   % convert error probability to confidence
   Cb = exp(-Eb ./ sigma_b);        % binding force
   Cf = exp(-Ef ./ sigma_fg);       % ground -> figure transition force
   Cg = exp(-Eg ./ sigma_fg);       % figure -> ground transition force
   % define figure/ground rotational constant
   phi = pi./16;
   % generalized affinity
   W_slab = Cb + Cf.*exp(i.*phi) + Cg.*exp(-i.*phi);
   W_mx = slab2sparse(W_slab, stencil);
   % symmetrize affinity
   W_mx = sparse_symmetrize(W_mx, 'amean');
   % extract magnitude and argument
   C_mx = abs(W_mx);
   T_mx = angle(W_mx);
   % compress rotational action
   rot_total = sum(abs(T_mx(:)));
   rot_scale = (pi./2)./(rot_total + eps);
   % rescale rotation component
   Theta_mx = T_mx.*rot_scale;
   % assemble angular embedding problem
   C_arr     = { C_mx };
   Theta_arr = { Theta_mx };
   U_arr     = { [] };
   % eigensolver options
   opts = struct( ...
      'k', [1 1 1], ...
      'k_rate', sqrt(2), ...
      'tol_err', 10.^-4, ...
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
   spb = (rspb + ispb)./2;
   % figure/ground extraction
   fg = reshape(angle(evecs(:,1)), [size(b_pred,1) size(b_pred,2)]);
   fg_norm = (fg - min(fg(:)))./(max(fg(:))-min(fg(:))+eps);
   % return data
   ae = struct( ...
      'fg',      {fg}, ...
      'fg_norm', {fg_norm}, ...
      'spb',     {spb} ...
   );
end
