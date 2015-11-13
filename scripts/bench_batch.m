% Run benchmark.
function [stats stats_eccv] = bench_batch(baseseg, th)
   % default arguments
   if (nargin < 2), th = 0.1; end
   % data directory
   dbench = 'bench';
   % output directories
   dout     = 'bench_out';
   dbase_gt = [dout '/base_gt'];
   dbase_us = [dout '/base_us'];
   if strcmp(baseseg,'gt')
      dbase = dbase_gt;
   elseif strcmp(baseseg,'us');
      dbase = dbase_us;
   end
   % get file list 
   fnames = dir([dbench '/fg/*.png']);
   fnames = {fnames.name};
   n_files = numel(fnames);
   % benchmark results
   stats      = cell([n_files 1]);
   stats_eccv = cell([n_files 1]);
   % edge error colormap
   emap_cmap = [ ...
      1 0 0; ...
      1 1 1; ...
      0 1 0; ...
   ];
   % process files
   for n = 1:n_files
      % get image name
      f = fnames{n};
      imname = f(1:end-4);
      disp([ ...
         'Benching (' num2str(n) ' of ' num2str(n_files) '): ' ...
         imname ...
      ]);
      % load results
      fg      = double(imread([dbench '/fg/' imname '.png']))./255;
      fg_eccv = rgb2ind(imread([dbench '/fg_eccv/' imname '.png']),jet(256));
      fg_eccv = double(fg_eccv)./255;
      gt      = load([dbench '/gt_glob/' imname '.mat']);
      gt      = gt.fg_ae_avg;
      % load base segmentation (if ours)
      S = [];
      if strcmp(baseseg,'us')
         X = load(['out_bsds/mat/' imname '.mat']);
         aev = ae_vis(X.ae);
         S = segment_ucm(aev.ucm2.*(aev.ucm2 > th));
      end
      % benchmark
      [s  v]  = bench_fg(fg,      gt, S, 'median');
      [se ve] = bench_fg(fg_eccv, gt, S, 'median');
      % store
      stats{n}      = s;
      stats_eccv{n} = se;
      % create visualization
      vis_gt           = ind2rgb(round(v.gt.*255)+1,jet(256));
      vis_gt_proj      = ind2rgb(round(v.gt_proj.*255)+1,jet(256));
      vis_fg           = ind2rgb(round(v.fg.*255)+1,jet(256));
      vis_fg_proj      = ind2rgb(round(v.fg_proj.*255)+1,jet(256));
      vis_eccv_fg      = ind2rgb(round(ve.fg.*255)+1,jet(256));
      vis_eccv_fg_proj = ind2rgb(round(ve.fg_proj.*255)+1,jet(256));
      vis_emap         = ind2rgb(v.emap+2,emap_cmap);
      vis_eccv_emap    = ind2rgb(ve.emap+2,emap_cmap);
      % save visualization
      imwrite(vis_gt,           [dbase '/' imname '_gt.png']);
      imwrite(vis_gt_proj,      [dbase '/' imname '_gt_proj.png']);
      imwrite(vis_fg,           [dbase '/' imname '_fg.png']);
      imwrite(vis_fg_proj,      [dbase '/' imname '_fg_proj.png']);
      imwrite(vis_eccv_fg,      [dbase '/' imname '_eccv_fg.png']);
      imwrite(vis_eccv_fg_proj, [dbase '/' imname '_eccv_fg_proj.png']);
      imwrite(vis_emap,         [dbase '/' imname '_emap.png']);
      imwrite(vis_eccv_emap,    [dbase '/' imname '_eccv_emap.png']);
   end
   % display summary statistics
   disp('Our System:');
   disp(bench_summary(stats));
   disp('ECCV 2010:');
   disp(bench_summary(stats_eccv));
end
