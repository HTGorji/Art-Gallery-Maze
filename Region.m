classdef Region < Navigation.internal.MazeElement
	properties (Access = public)
		vertices	double {mustBeFinite} = [-1 -1 1 1]
	end
	
	methods
		function R = Region (varargin)
			%REGION         Polygonal region within a maze
			%
			%  A Navigation.Region object represents a named region with a
			%  polygonal shape within a maze. To create a region, use:
			%
			%     R = Navigation.Region(NAME, VERT);
			%
			%  where NAME is the name of the region, and VERT is a N-by-2
			%  array specifying the X and Y coordinates of the N vertices
			%  of a polygon, in counter-clockwise order. For rectangular
			%  regions, you can define vertices more simply through a
			%  1-by-4 vector [X1 Y1 X2 Y2] specifying the coordinates of
			%  the bottom-left and of the top-right corners of the
			%  rectangle.
			
			R = R@Navigation.internal.MazeElement(varargin{:});
			if nargin > 1
				R.vertices = varargin{2};
			end
		end
		
		function R = set.vertices (R, coord)
			if isequal(size(coord), [1 4]) % Rectangle
				coord = [coord([1 3 3 1]); coord([2 2 4 4])]';
			else
				assert(ismatrix(coord) && size(coord,2) == 2);
			end
			R.vertices = coord;
		end
		
		function a = area (R)
			%REGION/AREA    Area of a region
			%
			% A = region(R), where R is a vector of Navigation.Region
			% objects, return the areas of the regions.
			
			a = zeros(numel(R),1);
			for i=1:numel(R)
				x    = R(i).vertices(:,1);
				y    = R(i).vertices(:,2);
				n    = length(x);
				x2   = [x(2:n);x(1)];
				y2   = [y(2:n);y(1)];
				a(i) = 1/2*sum (x.*y2-x2.*y);
			end
		end
		
		function c = centroid (R)
			%REGION/CENTROID    Centroid of a region
			%
			% A = centroid(R), where R is a vector of Navigation.Region
			% objects, return the centroid of each of the regions.
			
			c = zeros(numel(R),2);
			for i=1:numel(R)
				x  = R(i).vertices(:,1);
				y  = R(i).vertices(:,2);
				n  = length(x);
				x2 = [x(2:n);x(1)];
				y2 = [y(2:n);y(1)];
				a  = 1/2*sum (x.*y2-x2.*y);
				x0 = 1/6*sum((x.*y2-x2.*y).*(x+x2))/a;
				y0 = 1/6*sum((x.*y2-x2.*y).*(y+y2))/a;
				c(i,:) = [x0, y0];
			end
		end
		
		function index = contains (R, xy)
			%REGION/CONTAINS    Determine which region contains points
			%
			% IDX = contains(R, XY), where R is an array of Navigation.Region
			% objects and XY is a N-by-2 matrix specifying the X and Y
			% coordinates of N points, returns a N-by-1 array IDX of
			% region indices, where IDX(i) is the index in the R array of
			% the region within which point XY(i,:) falls, or 0 if the
			% point falls outside all regions.

			nPoints = size(xy,1);
			nRegions = numel(R);
			flag = false(nPoints, nRegions);
			for i=1:nRegions
				flag(:,i) = inpolygon(xy(:,1), xy(:,2), R(i).vertices(:,1), R(i).vertices(:,2));
			end
			index = zeros(nPoints, 1);
			[r,c] = find(flag);
			index(r) = c;
		end
	end
	
	methods (Access = ?Navigation.Maze)
		function show (R, color)
			cmap = colorcube(numel(R));
			c = centroid(R);
			for i=1:numel(R)
				fill(R(i).vertices([1:end,1],1), R(i).vertices([1:end,1],2), cmap(i,:), 'FaceAlpha', 0.4);
				text(c(i,1), c(i,2), char(R(i).name), 'FontName', 'Default', 'Color', color, 'HorizontalAlignment', 'center');
			end
		end
	end
end