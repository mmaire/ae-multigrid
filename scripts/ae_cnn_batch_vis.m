% Run AE-CNN on a dataset.
function ae_cnn_batch_vis(dset)
   % data directory names
   din  = ['../data/res_' dset];
   dout = ['out_' dset];
   % get file list 
   fnames = dir([din '/contour/*.mat']);
   fnames = {fnames.name};
   % load stencil
   S = load('../data/stencil.mat');
   % display status
   disp(['Input:  ' din]);
   disp(['Output: ' dout]);
   % process batch
   for n = 1:numel(fnames)
      % get image name
      f = fnames{n};
      imname = f(1:end-4);
      disp([ ...
         'Visualizing (' num2str(n) ' of ' num2str(numel(fnames)) '): ' ...
         imname ...
      ]);
      % load results
      ae = load([dout '/mat/' imname '.mat']);
      ae = ae.ae;
      % generate visualization
      aev = ae_vis(ae);
      % write fg
      imwrite(aev.fg,  [dout '/fg/' imname '.png']);
      % write ucm
      imwrite(aev.ucm, [dout '/ucm/' imname '.png']);
      % write visualization
      imwrite(aev.vis_fg,       [dout '/vis_new/' imname '_fg.png']);
      imwrite(aev.vis_fg_avg_a, [dout '/vis_new/' imname '_fg_avg_a.png']);
      imwrite(aev.vis_fg_avg_b, [dout '/vis_new/' imname '_fg_avg_b.png']);
      imwrite(aev.vis_fg_ucm_a, [dout '/vis_new/' imname '_fg_ucm_a.png']);
      imwrite(aev.vis_fg_ucm_b, [dout '/vis_new/' imname '_fg_ucm_b.png']);
      imwrite(aev.vis_spb,      [dout '/vis_new/' imname '_spb.png']);
      imwrite(aev.vis_ucm,      [dout '/vis_new/' imname '_ucm.png']);
   end
end
