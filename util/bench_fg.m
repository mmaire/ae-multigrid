% Benchmark figure/ground predictions against ground-truth.
%
% Input:
%    fg            - f/g predictions
%    gt            - f/g ground-truth (averaged over ground-truth regions)
%
% Output:
%    stats.
%       rank_l1  - L1 pixel rank difference
%       rank_l2  - L2 pixel rank difference
%       reg_acc  - region pair (shared edges) classification accuracy
%       reg_cnt  - region pair (shared edges) count 
%       epx_acc  - edge pixel classification accuracy
%       epx_cnt  - edge pixel count
%       
%    vis.
%       fg      - prediction visualization
%       gt      - ground-truth visualization
%       fg_gt   - figure/ground projected onto groundtruth
%       fg_err  - figure/ground projected + edge error visualization
function [stats vis] = bench_fg(fg, gt)
   % extract ground-truth segmentation
   S = segment_gt_glob(gt);
   % initialize region predictions
   r_fg = zeros([S.n_regions 1]);
   r_gt = zeros([S.n_regions 1]);
   % project predictions and ground-truth
   for n = 1:(S.n_regions)
      r_fg(n) = mean(fg(S.seg_members{n}));
      r_gt(n) = mean(gt(S.seg_members{n}));
   end
   % create projection over image domain
   proj_fg = zeros(size(fg));
   proj_gt = zeros(size(gt));
   for n = 1:(S.n_regions)
      proj_fg(S.seg_members{n}) = r_fg(n);
      proj_gt(S.seg_members{n}) = r_gt(n);
   end
   % compute ground-truth region areas
   r_area = zeros([S.n_regions 1]);
   for n = 1:(S.n_regions)
      r_area(n) = numel(S.seg_members{n});
   end
   % get region ranks
   [junk r_rank_fg] = sort(r_fg);
   [junk r_rank_gt] = sort(r_gt);
   clear junk;
   r_rank_fg = (r_rank_fg - 0.5) ./ (max(r_rank_fg) + eps);
   r_rank_gt = (r_rank_gt - 0.5) ./ (max(r_rank_gt) + eps);
   % project ranks
   proj_fg_rank = zeros(size(fg));
   proj_gt_rank = zeros(size(gt));
   for n = 1:(S.n_regions)
      proj_fg_rank(S.seg_members{n}) = r_rank_fg(n);
      proj_gt_rank(S.seg_members{n}) = r_rank_gt(n);
   end
   % compute rank errors
   diff_rank = r_rank_fg - r_rank_gt;
   diff_abs = abs(diff_rank);
   diff_sq  = diff_rank.*diff_rank;
   rank_l1 = sum(diff_abs(:))./numel(diff_rank);
   rank_l2 = sqrt(sum(diff_sq))./numel(diff_rank);
   % compute edge classification accuracy
   emap = zeros(size(gt));
   reg_ok = 0; reg_cnt = 0;
   epx_ok = 0; epx_cnt = 0;
   for r1 = 1:(S.n_regions)
      regs = S.graph{r1};
      ctrs = S.graph_contours{r1};
      for n = 1:numel(regs)
         r2 = regs(n);
         % get f/g predictions across edge
         e_fg = sign(r_fg(r1) - r_fg(r2));
         e_gt = sign(r_gt(r1) - r_gt(r2));
         % get edge elements
         e = ctrs{n};
         % update scores
         if (e_fg == e_gt)
            emap(e) = 1;
            reg_ok = reg_ok + 1;
            epx_ok = epx_ok + numel(e);
         else
            emap(e) = -1;
         end
         reg_cnt = reg_cnt + 1;
         epx_cnt = epx_cnt + numel(e);
      end
   end
   % handle edge double-counting
   reg_ok = reg_ok / 2;
   epx_ok = epx_ok / 2;
   reg_cnt = reg_cnt / 2;
   epx_cnt = epx_cnt / 2;
   % compute accruacy
   reg_acc = reg_ok ./ reg_cnt;
   epx_acc = epx_ok ./ epx_cnt;
   % assemble stats
   stats = struct( ...
      'rank_l1', {rank_l1}, ...
      'rank_l2', {rank_l2}, ...
      'reg_acc', {reg_acc}, ...
      'reg_cnt', {reg_cnt}, ...
      'epx_acc', {epx_acc}, ...
      'epx_cnt', {epx_cnt} ...
   );
   % assemble visualization
   vis = struct( ...
      'emap',    {emap} ...
   );
end
