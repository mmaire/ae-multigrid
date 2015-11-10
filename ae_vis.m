% Generate detailed ae results and visualization.
function aev = ae_vis(ae)
   % parameter - UCM visualization thresholds
   th_a = 0.10;
   th_b = 0.05;
   % extract results
   evecs = ae.evecs;
   evals = ae.evals;
   % get image size
   [sx sy] = size(ae.fg);
   % get #evecs
   nvec = size(evecs,2);
   % compute weights
   weights = zeros(size(evals));
   for v = 1:nvec
      if (abs(evals(v)) > 0)
         weights(v) = 1./sqrt(abs(evals(v)));
      end
   end
   % sort by weight
   [junk inds] = sort(weights);
   weights = weights(inds(end:-1:1));
   evecs   = evecs(:,inds(end:-1:1));
   evals   = evals(inds(end:-1:1));
   % compute edges (exclude first evec)
   evecs2 = evecs(:,1:end);
   evecs2 = evecs_normalize(evecs2);
   evecs2 = reshape(evecs2,[sx sy 1 (nvec)]);
   [er2 ero2] = evecs_to_edges(real(evecs2),weights(1:end));
   [ei2 eio2] = evecs_to_edges(imag(evecs2),weights(1:end));
   e2  = sqrt(er2.*er2 + ei2.*ei2);
   eo2 = sqrt(ero2.*ero2 + eio2.*eio2);
   % normalize edges
   e2  = e2./(max(e2(:)) + eps);
   eo2 = eo2./(max(eo2(:)) + eps);
   % compute ucm
   ucm  = double(contours2ucm(eo2,'imageSize'));
   ucm2 = double(contours2ucm(eo2,'doubleSize'));
   % average figure/ground over ucm
   Sa = segment_ucm(ucm2 > th_a);
   Sb = segment_ucm(ucm2 > th_b);
   fg_avg_a = zeros(size(ae.fg_norm));
   fg_avg_b = zeros(size(ae.fg_norm));
   for s = 1:(Sa.n_regions)
      fg_avg_a(Sa.seg_members{s}) = mean(ae.fg_norm(Sa.seg_members{s}));
   end
   for s = 1:(Sb.n_regions)
      fg_avg_b(Sb.seg_members{s}) = mean(ae.fg_norm(Sb.seg_members{s}));
   end
   % visualization - fg
   fg_norm_vis  = ind2rgb(round(ae.fg_norm.*255)+1,jet(256));
   fg_avg_a_vis = ind2rgb(round(fg_avg_a.*255)+1,jet(256));
   fg_avg_b_vis = ind2rgb(round(fg_avg_b.*255)+1,jet(256));
   % visualization - contours
   spb_vis = 1 - e2;
   ucm_vis = 1 - ucm;
   % visualization - combined
   fg_ucm_a_vis = fg_avg_a_vis.*repmat(1 - ucm.*(ucm>th_a),[1 1 3]);
   fg_ucm_b_vis = fg_avg_b_vis.*repmat(1 - ucm.*(ucm>th_b),[1 1 3]);
   % assemble result
   aev = struct( ...
      'fg',           ae.fg_norm, ...
      'spb',          e2, ...
      'ucm',          ucm, ...
      'ucm2',         ucm2, ...
      'vis_fg',       fg_norm_vis, ...
      'vis_fg_avg_a', fg_avg_a_vis, ...
      'vis_fg_avg_b', fg_avg_b_vis, ...
      'vis_fg_ucm_a', fg_ucm_a_vis, ...
      'vis_fg_ucm_b', fg_ucm_b_vis, ...
      'vis_spb',      spb_vis, ...
      'vis_ucm',      ucm_vis ...
   );
end
