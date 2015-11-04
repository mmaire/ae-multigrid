dset = 'res_bsds_testfg';
%dset = 'res_bsds_train';

imname = '100080';
%imname = '41004';
%imname = '135069';


X = load(['../data/' dset '/contour/' imname '.mat']);
F = load(['../data/' dset '/figure-ground/' imname '.mat']);
S = load('../data/stencil.mat');

ae = ae_cnn(double(X.affinity)./255, double(F.affinity)./255, double(S.di));
