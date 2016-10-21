dset = 'res_bsds_testfg';
imname = '100080';

% load CNN affinity predictions
X = load(['data/' dset '/contour/' imname '.mat']);
F = load(['data/' dset '/figure-ground/' imname '.mat']);
S = load('data/stencil.mat');

% angular embedding
ae = ae_cnn(double(X.affinity)./255, double(F.affinity)./255, double(S.di));

% display results
im = double(imread(['data/' imname '.png']))./255;
figure(1); imagesc(im); axis image; axis off; title('Image');
figure(2); subplot(1,2,1);
imagesc(ae.fg_norm); axis image; axis off; title('Figure/Ground');
figure(2); subplot(1,2,2);
imagesc(ae.spb); axis image; axis off; title('Spectral Boundaries');
