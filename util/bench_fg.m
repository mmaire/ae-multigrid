% Benchmark figure/ground predictions against ground-truth.
%
% [stats vis] = bench_fg(fg, gt, S, method)
%
% Input:
%    fg          - f/g predictions
%    gt          - f/g ground-truth (averaged over ground-truth regions)
%    S           - target segmentation (optional; default: use ground-truth)
%    method      - target transfer method {'mean','median'} (default: 'median')
%
% Output:
%    stats.      - performance metrics
%       rank_l1     - L1 pixel rank difference
%       rank_l2     - L2 pixel rank difference
%       rank_mx     - rank mapping matrix
%       reg_acc     - region pair (shared edges) classification accuracy
%       reg_cnt     - region pair (shared edges) count
%       epx_acc     - edge pixel classification accuracy (all edges)
%       epx_cnt     - edge pixel count                   (all edges)
%       epx_acc_50  - edge pixel classification accuracy (50% most figural)
%       epx_cnt_50  - edge pixel count                   (50% most figural)
%       epx_acc_25  - edge pixel classification accuracy (25% most figural)
%       epx_cnt_25  - edge pixel count                   (25% most figural)
%       
%    vis.        - visualization
%       fg          - f/g predictions  (input)
%       gt          - f/g ground-truth (input)
%       fg_proj     - f/g predictions  (projected onto target segmentation)
%       gt_proj     - f/g ground-truth (projected onto target segmentation)
%       emap        - boundary ownership error visualization
function [stats vis] = bench_fg(fg, gt, S, method)
   % default arguments
   if ((nargin < 3) || (isempty(S)))
      % target ground-truth segmentation
      S = segment_gt_glob(gt);
   end
   if ((nargin < 4) || (isempty(method)))
      % default transfer method
      method = 'median';
   end
   % normalize f/g to [0,1] range
   fg = sig_normalize(fg);
   gt = sig_normalize(gt);
   % extract region f/g on target segmentation
   r_fg = reg_extract(fg, S, method);
   r_gt = reg_extract(gt, S, method);
   % project f/g onto target segmentation
   fg_proj = reg_project(r_fg, S);
   gt_proj = reg_project(r_gt, S);
   % get region ranks
   [junk r_rank_fg] = sort(r_fg);
   [junk r_rank_gt] = sort(r_gt);
   clear junk;
   % normalize ranks
   r_rank_fg = sig_normalize(r_rank_fg);
   r_rank_gt = sig_normalize(r_rank_gt);
   % project rank onto target segmentation
   fg_rank = reg_project(r_rank_fg, S);
   gt_rank = reg_project(r_rank_gt, S);
   % compute pixel rank difference
   r_diff = fg_rank - gt_rank;
   rank_l1 = sum(sum(abs(r_diff))) ./ numel(r_diff);
   rank_l2 = sum(sum(r_diff.*r_diff)) ./ numel(r_diff);
   % rank mapping histogram
   nbins = 10;
   b_fg = floor([fg_rank(:)].*(1 - eps).*nbins) + 1;
   b_gt = floor([gt_rank(:)].*(1 - eps).*nbins) + 1;
   rank_mx = full(sparse(b_fg, b_gt, ones([numel(b_fg) 1]), nbins, nbins));
   % compute edge classification accuracy
   emap = zeros(size(gt));
   reg_ok    = 0; reg_cnt    = 0;
   epx_ok    = 0; epx_cnt    = 0;
   epx_ok_50 = 0; epx_cnt_50 = 0;
   epx_ok_25 = 0; epx_cnt_25 = 0;
   for r1 = 1:(S.n_regions)
      regs = S.graph{r1};
      ctrs = S.graph_contours{r1};
      for n = 1:numel(regs)
         r2 = regs(n);
         % get f/g predictions across edge
         e_fg = sign(r_fg(r1) - r_fg(r2));
         e_gt = sign(r_gt(r1) - r_gt(r2));
         % if ground-truth doesn't change across edge, then skip it
         if (e_gt == 0)
            continue;
         end
         % check if edge involves highly figural region in ground-truth
         is_50 = ...
            (r_rank_gt(r1) >= 0.50) | ...
            (r_rank_gt(r2) >= 0.50);
         is_25 = ...
            (r_rank_gt(r1) >= 0.75) | ...
            (r_rank_gt(r2) >= 0.75);
         % compute score increments
         inc    = double((e_fg == e_gt));
         inc_50 = inc.*double(is_50);
         inc_25 = inc.*double(is_25);
         % update edge map
         e = ctrs{n};
         if (e_fg == e_gt)
            emap(e) = 1;
         else
            emap(e) = -1;
         end
         % update region score
         reg_ok  = reg_ok + inc;
         reg_cnt = reg_cnt + 1;
         % update edge scores
         epx_ok     = epx_ok     + inc.*numel(e);
         epx_ok_50  = epx_ok_50  + inc_50.*numel(e);
         epx_ok_25  = epx_ok_25  + inc_25.*numel(e);
         epx_cnt    = epx_cnt    + numel(e);
         epx_cnt_50 = epx_cnt_50 + double(is_50).*numel(e);
         epx_cnt_25 = epx_cnt_25 + double(is_25).*numel(e);
      end
   end
   % handle edge double-counting
   reg_ok     = reg_ok     / 2;
   reg_cnt    = reg_cnt    / 2;
   epx_ok     = epx_ok     / 2;
   epx_ok_50  = epx_ok_50  / 2;
   epx_ok_25  = epx_ok_25  / 2;
   epx_cnt    = epx_cnt    / 2;
   epx_cnt_50 = epx_cnt_50 / 2;
   epx_cnt_25 = epx_cnt_25 / 2;
   % compute accruacy
   reg_acc    = reg_ok    ./ reg_cnt;
   epx_acc    = epx_ok    ./ epx_cnt;
   epx_acc_50 = epx_ok_50 ./ epx_cnt_50;
   epx_acc_25 = epx_ok_25 ./ epx_cnt_25;
   % assemble stats
   stats = struct( ...
      'rank_l1',    {rank_l1}, ...
      'rank_l2',    {rank_l2}, ...
      'rank_mx',    {rank_mx}, ...
      'reg_acc',    {reg_acc}, ...
      'reg_cnt',    {reg_cnt}, ...
      'epx_acc',    {epx_acc}, ...
      'epx_cnt',    {epx_cnt}, ...
      'epx_acc_50', {epx_acc_50}, ...
      'epx_cnt_50', {epx_cnt_50}, ...
      'epx_acc_25', {epx_acc_25}, ...
      'epx_cnt_25', {epx_cnt_25} ...
   );
   % assemble visualization
   vis = struct( ...
      'fg',      {fg}, ...
      'gt',      {gt}, ...
      'fg_proj', {fg_proj}, ...
      'gt_proj', {gt_proj}, ...
      'emap',    {emap} ...
   );
end

% Normalize a signal to [0,1] range.
function xn = sig_normalize(x);
   xn = ...
      (x - min(x(:))) ./ ...
      (max(x(:)) - min(x(:)) + eps);
end

% Extract a region properties by averaging over segmentation.
function r = reg_extract(x, S, method)
   r = zeros([S.n_regions 1]);
   if (strcmp(method,'mean'))
      for n = 1:(S.n_regions)
         r(n) = mean(x(S.seg_members{n}));
      end
   elseif (strcmp(method,'median'))
      for n = 1:(S.n_regions)
         r(n) = median(x(S.seg_members{n}));
      end
   else
      error('invalid transfer method specified');
   end
end

% Project region properties onto a segmentation.
function x = reg_project(r, S)
   x = zeros(size(S.seg));
   for n = 1:(S.n_regions)
      x(S.seg_members{n}) = r(n);
   end
end
