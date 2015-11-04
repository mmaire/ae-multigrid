X = load('../data/res_bsds_testfg/contour/100080.mat');
F = load('../data/res_bsds_testfg/figure-ground/100080.mat');
S = load('../data/stencil.mat');

ae = ae_cnn(double(X.affinity)./255, double(F.affinity)./255, double(S.di));
