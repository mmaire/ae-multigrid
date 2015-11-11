% Benchmark
%function bench_batch
   % data directory
   dbench = 'bench';
   % get file list 
   fnames = dir([dbench '/fg/*.png']);
   fnames = {fnames.name};
   n_files = numel(fnames);
   % benchmark results
   stats_fg      = cell([n_files 1]);
   stats_fg_eccv = cell([n_files 1]);
   vis_fg      = cell([n_files 1]);
   vis_fg_eccv = cell([n_files 1]);
   % process batch
   for n = 1:n_files
      % get image name
      f = fnames{n};
      imname = f(1:end-4);
      disp([ ...
         'Benching (' num2str(n) ' of ' num2str(n_files) '): ' ...
         imname ...
      ]);
      % load
      fg = double(imread([dbench '/fg/' imname '.png']))./255;
      fg_eccv = rgb2ind(imread([dbench '/fg_eccv/' imname '.png']),jet(256));
      fg_eccv = double(fg_eccv)./255;
      gt = load([dbench '/gt_glob/' imname '.mat']);
      gt = gt.fg_ae_avg;
      % benchmark
      [s v]   = bench_fg(fg, gt);
      [se ve] = bench_fg(fg_eccv, gt);
      % store
      stats_fg{n} = s;
      vis_fg{n}   = v;
      stats_fg_eccv{n} = se;
      vis_fg_eccv{n}   = ve;
      % display
      figure(1); 
      subplot(1,3,1); imagesc(gt); title('gt'); axis image;
      subplot(1,3,2); imagesc(fg); title('fg'); axis image;
      subplot(1,3,3); imagesc(fg_eccv); title('fg eccv'); axis image;
      figure(2); 
      subplot(1,2,1); imagesc(v.emap); title('fg'); axis image; caxis([-1 1]);
      subplot(1,2,2); imagesc(ve.emap); title('fg eccv'); axis image; caxis([-1 1]);
      drawnow;
      pause(0.5);
   end
   % assemble stats
   s  = [stats_fg{:}];
   se = [stats_fg_eccv{:}];
   acc = [s.epx_acc];
   cnt = [s.epx_cnt];
   rl1 = [s.rank_l1];
   rl2 = [s.rank_l2];
   acc_e = [se.epx_acc];
   cnt_e = [se.epx_cnt];
   rl1_e = [se.rank_l1];
   rl2_e = [se.rank_l2];


%end
