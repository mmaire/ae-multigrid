% Segmentation from UCM.
% Given a UCM, return a data structure for the corresponding segmentation.
function S = segment_ucm(ucm, is_quad_size)
   % default arguments
   if (nargin < 2), is_quad_size = false; end
   % compute segmentation from ucm
   seg = bwlabel(ucm==0);
   % shrink seg to double size (if needed)
   if (is_quad_size)
      seg = seg(2:2:end,2:2:end);
   end
   % shrink seg to normal size and relabel
   seg = seg(2:2:end,2:2:end);
   [vals i j] = unique(seg(1:end));
   relabel = 1:length(vals);
   seg(1:end) = relabel(j);
   % compute pixel membership of each segment
   seg_members = segment_members(seg);
   % compute segment centroids/centers
   [seg_centroids seg_centers] = segment_centers(seg, seg_members);
   % compute distances from boundary
   boundary = segment_boundary(seg);
   boundary_dist = bwdist(boundary);
   % compute graph of neighboring segments
   [graph graph_contours] = segment_graph(seg);
   % assemble segmentation data structure
   S.n_regions      = max(seg(:));     % number of regions 
   S.seg            = seg;             % region id of each pixel
   S.seg_members    = seg_members;     % list of pixels in each region
   S.seg_centroids  = seg_centroids;   % centroid of each region
   S.seg_centers    = seg_centers;     % center (not centroid) of each region
   S.boundary       = boundary;        % boundary flag for each pixel
   S.boundary_dist  = boundary_dist;   % distance from each pixel to nearest boundary
   S.graph          = graph;           % for each region, list of adjacent regions
   S.graph_contours = graph_contours;  % pixels on contours between adjacent regions in graph
end

%% compute pixels belonging to each segment
function seg_members = segment_members(seg)
   % initialize member lists
   n_regions = max(seg(:));
   seg_members = cell([n_regions 1]);
   % sort segment ids
   seg_labels = reshape(seg, [1 prod(size(seg))]);
   [seg_sorted inds] = sort(seg(:));
   seg_labels = seg_labels(inds);
   seg_starts = find(seg_labels ~= [-1 seg_labels(1:end-1)]);
   seg_ends   = find(seg_labels ~= [seg_labels(2:end) (n_regions+1)]);
   % store pixel membership of each segment
   for n = 1:n_regions
      ps = seg_starts(n);
      pe = seg_ends(n);
      seg_members{n} = inds(ps:pe);
   end
end

%% compute centroid and center of each segment
function [seg_centroids seg_centers] = segment_centers(seg, seg_members)
   % get image size, number of segments
   [sx sy] = size(seg);
   n_regions = length(seg_members);
   % initialize centroids/centers
   seg_centroids.xs = zeros([n_regions 1]);
   seg_centroids.ys = zeros([n_regions 1]);
   seg_centers.inds = zeros([n_regions 1]);
   seg_centers.xs   = zeros([n_regions 1]);
   seg_centers.ys   = zeros([n_regions 1]);
   % compute centroids/centers
   for n = 1:n_regions
      % get indices and coordinates of segment members
      members = seg_members{n};
      [xs ys] = ind2sub([sx sy], members);
      % compute centroid
      mx = mean(xs);
      my = mean(ys);
      seg_centroids.xs(n) = mx;
      seg_centroids.ys(n) = my;
      % compute center (point in segment closest to centroid)
      dist_sq = ((xs - mx).^2 + (ys - my).^2);
      [d_min i] = min(dist_sq);
      seg_centers.inds(n) = members(i);
      seg_centers.xs(n)   = xs(i);
      seg_centers.ys(n)   = ys(i);
   end
end

%% compute (thick) boundary from segmentation 
function [boundary dx dy dxy dyx] = segment_boundary(seg)
   [sx sy] = size(seg);
   % compute vertical, horizontal, diagonal differences
   dx  = (seg(1:end-1,:) ~= seg(2:end,:));
   dy  = (seg(:,1:end-1) ~= seg(:,2:end));
   dxy = (seg(1:end-1,1:end-1) ~= seg(2:end,2:end));
   dyx = (seg(2:end,1:end-1) ~= seg(1:end-1,2:end));
   % mark thick boundaries along each direction
   bx  = ([dx; zeros([1 sy])] | [zeros([1 sy]); dx]);
   by  = ([dy  zeros([sx 1])] | [zeros([sx 1])  dy]);
   bxy = zeros(size(seg));
   bxy(1:end-1,1:end-1) = bxy(1:end-1,1:end-1) | dxy;
   bxy(2:end,2:end)     = bxy(2:end,2:end)     | dxy;
   byx = zeros(size(seg));
   byx(2:end,1:end-1) = byx(2:end,1:end-1) | dyx;
   byx(1:end-1,2:end) = byx(1:end-1,2:end) | dyx;
   % combine boundaries
   boundary = bx | by | bxy | byx;
end

%% build region adjacency graph from segmentation
function [graph graph_contours] = segment_graph(seg)
   % get image size, number of regions
   [sx sy] = size(seg);
   n_regions = max(seg(:));
   % find label discontinuities
   [boundary dx dy dxy dyx] = segment_boundary(seg);
   % extract label pairs across discontinuities
   [xs ys] = find(dx);
   i1_x = sub2ind([sx sy],xs,ys);
   i2_x = sub2ind([sx sy],xs+1,ys);
   L1_x = seg(i1_x);
   L2_x = seg(i2_x);
   [xs ys] = find(dy);
   i1_y = sub2ind([sx sy],xs,ys);
   i2_y = sub2ind([sx sy],xs,ys+1);
   L1_y = seg(i1_y);
   L2_y = seg(i2_y);
   [xs ys] = find(dxy);
   i1_xy = sub2ind([sx sy],xs,ys);
   i2_xy = sub2ind([sx sy],xs+1,ys+1);
   L1_xy = seg(i1_xy);
   L2_xy = seg(i2_xy);
   [xs ys] = find(dyx);
   i1_yx = sub2ind([sx sy],xs+1,ys);
   i2_yx = sub2ind([sx sy],xs,ys+1);
   L1_yx = seg(i1_yx);
   L2_yx = seg(i2_yx);
   % assemble labels
   i1 = [i1_x; i1_y; i1_xy; i1_yx];
   i2 = [i2_x; i2_y; i2_xy; i2_yx];
   L1 = [L1_x; L1_y; L1_xy; L1_yx];
   L2 = [L2_x; L2_y; L2_xy; L2_yx];
   % sort and group by first label 
   [L1 inds] = sort(L1);
   L2 = L2(inds);
   i1 = i1(inds);
   i2 = i2(inds);
   L_starts = find(L1 ~= [-1; L1(1:end-1)]);
   L_ends   = find(L1 ~= [L1(2:end); (-1)]);
   % build graph
   graph = cell([n_regions 1]);
   graph_contours = cell([n_regions 1]);
   for n = 1:length(L_starts)
      % graph connections
      src  = L1(L_starts(n));
      dsts = L2(L_starts(n):L_ends(n));
      graph{src} = unique(dsts);
      % contours on each connection
      i1_curr = i1(L_starts(n):L_ends(n));
      i2_curr = i2(L_starts(n):L_ends(n));
      [dsts inds] = sort(dsts);
      i1_curr = i1_curr(inds);
      i2_curr = i2_curr(inds);
      d_starts = find(dsts ~= [-1; dsts(1:end-1)]);
      d_ends   = find(dsts ~= [dsts(2:end); (-1)]);
      n_dsts = length(unique(dsts));
      contours = cell([n_dsts 1]);
      for d = 1:n_dsts
         d_inds = d_starts(d):d_ends(d);
         contours{d} = unique([i1_curr(d_inds); i2_curr(d_inds)]);
      end
      graph_contours{src} = contours;
   end
   % sort and group by second label
   [L2 inds] = sort(L2);
   L1 = L1(inds);
   i1 = i1(inds);
   i2 = i2(inds);
   L_starts = find(L2 ~= [-1; L2(1:end-1)]);
   L_ends   = find(L2 ~= [L2(2:end); (-1)]);
   % build reverse graph
   graph_rev = cell([n_regions 1]);
   graph_contours_rev = cell([n_regions 1]);
   for n = 1:length(L_starts)
      % graph connections
      src  = L2(L_starts(n));
      dsts = L1(L_starts(n):L_ends(n));
      graph_rev{src} = unique(dsts);
      % contours on each connection
      i1_curr = i1(L_starts(n):L_ends(n));
      i2_curr = i2(L_starts(n):L_ends(n));
      [dsts inds] = sort(dsts);
      i1_curr = i1_curr(inds);
      i2_curr = i2_curr(inds);
      d_starts = find(dsts ~= [-1; dsts(1:end-1)]);
      d_ends   = find(dsts ~= [dsts(2:end); (-1)]);
      n_dsts = length(unique(dsts));
      contours = cell([n_dsts 1]);
      for d = 1:n_dsts
         d_inds = d_starts(d):d_ends(d);
         contours{d} = unique([i1_curr(d_inds); i2_curr(d_inds)]);
      end
      graph_contours_rev{src} = contours;
   end
   % merge graphs
   for n = 1:n_regions
      % merge connections out of node
      connections = unique([graph{n}; graph_rev{n}]);
      n_dsts = length(connections);
      % merge contours
      [in_g  loc_g]  = ismember(connections, graph{n});
      [in_gr loc_gr] = ismember(connections, graph_rev{n});
      contours_g  = graph_contours{n};
      contours_gr = graph_contours_rev{n};
      contours = cell([n_dsts 1]);
      for d = 1:n_dsts
         if (in_g(d))
            contours{d} = [contours{d}; contours_g{loc_g(d)}];
         end
         if (in_gr(d))
            contours{d} = [contours{d}; contours_gr{loc_gr(d)}];
         end
         contours{d} = unique(contours{d});
      end
      % update graph
      graph{n} = connections;
      graph_contours{n} = contours;
   end
end
