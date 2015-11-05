% Run AE-CNN on a dataset.
function ae_cnn_batch(dset)
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
         'Running (' num2str(n) ' of ' num2str(numel(fnames)) '): ' ...
         imname ...
      ]);
      X = load([din '/contour/' imname '.mat']);
      F = load([din '/figure-ground/' imname '.mat']);
      ae = ae_cnn( ...
         double(X.affinity)./255, ...
         double(F.affinity)./255, ...
         double(S.di) ...
      );
      save([dout '/mat/' imname '.mat'],'ae');
      imwrite(ae.spb,     [dout '/vis/' imname '_spb.png']);
      imwrite(ae.fg_norm, [dout '/vis/' imname '_fg.png']);
   end
end
