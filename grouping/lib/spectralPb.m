function [sPb] = spectralPb(mPb, orig_sz, outFile, nvec)
% function [sPb] = spectralPb(mPb, orig_sz, outFile, nvec)
%
% description:
%   global contour cue from local mPb.
%
% computes Intervening Contour with BSE code by Charless Fowlkes:
%
%http://www.cs.berkeley.edu/~fowlkes/BSE/
%
% Pablo Arbelaez <arbelaez@eecs.berkeley.edu>
% April 2008

if nargin<4, nvec = 17; end
if nargin<3, outFile = '';end
if nargin<2, orig_sz = size(mPb); end


%% similarity matrix
[tx, ty] = size(mPb);
img = zeros(tx, ty, 3, 'uint8');
imgFile = strcat(outFile, '_img.jpg');
imwrite(img, imgFile);

l{1} = zeros(size(mPb, 1) + 1, size(mPb, 2));
l{1}(2:end, :) = mPb;
l{2} = zeros(size(mPb, 1), size(mPb, 2) + 1);
l{2}(:, 2:end) = mPb;

latFile = strcat(outFile, '_lat.tmp');
write_array(latFile, l);
clear l img;

simFile = strcat(outFile, '_sim.tmp');
system(sprintf('/home/mmaire/papers/pami2009/software/grouping/lib/segment -image %s -smatrixfile %s -readlattice true -latticefile %s -dthresh 5', imgFile, simFile, latFile));
delete(latFile);
delete(imgFile);

%% generalized eigenvectors
W = read_smatrix(simFile);
delete(simFile);

[wx, wy] = size(W);
x = 1 : wx;
S = full(sum(W, 1));
D = sparse(x, x, S, wx, wy);
clear S x;

opts.issym=1;
opts.isreal = 1;
opts.disp=2;
[EigVect, EVal] = eigs(D - W, D, nvec, 'sm',opts);
clear D W opts;

EigVal = diag(EVal);
clear Eval;

EigVal(1:end) = EigVal(end:-1:1);
EigVect(:, 1:end) = EigVect(:, end:-1:1);

txo=orig_sz(1); tyo=orig_sz(2); 
vect = zeros(txo, tyo, nvec);
for v = 2 : nvec,
    vect(:, :, v) = imresize(reshape(EigVect(:, v), [ty tx])',[txo,tyo]);
end
clear EigVect;

%% spectral Pb

for v=2:nvec,
    vect(:,:,v)=(vect(:,:,v)-min(min(vect(:,:,v))))/(max(max(vect(:,:,v)))-min(min(vect(:,:,v))));
end

% OE parameters
hil = 0;
deriv = 1;
support = 3;
sigma = 1;
norient = 8;
dtheta = pi/norient;
ch_per = [4 3 2 1 8 7 6 5];

sPb = zeros(txo, tyo, norient);
for v = 1 : nvec
    if EigVal(v) > 0,
        vec = vect(:,:,v)/sqrt(EigVal(v));
        for o = 1 : norient,
            theta = dtheta*o;
            f = oeFilter(sigma, support, theta, deriv, hil);
            sPb(:,:,ch_per(o)) = sPb(:,:,ch_per(o)) + abs(applyFilter(f, vec));
        end
    end
end

if ~strcmp(outFile,''), save (outFile,'sPb'); end
