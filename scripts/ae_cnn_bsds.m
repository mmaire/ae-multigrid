dset = 'res_bsds_testfg';

fnames = dir(['../data/' dset '/contour/*.mat']);
fnames = {fnames.name};

S = load('../data/stencil.mat');
for n = 1:numel(fnames)
   f = fnames{n};
   imname = f(1:end-4);

   disp(imname);
   X = load(['../data/' dset '/contour/' imname '.mat']);
   F = load(['../data/' dset '/figure-ground/' imname '.mat']);

   ae = ae_cnn(double(X.affinity)./255, double(F.affinity)./255, double(S.di));

   save(['out_mat/' imname '.mat'],'ae');
   imwrite(ae.spb, ['out_vis/' imname '_spb.png']);
   imwrite(ae.fg_norm, ['out_vis/' imname '_fg.png']);
end
