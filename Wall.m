classdef Wall < Navigation.internal.MazeElement
	properties (Access = public)
		coord(1,4)	double {mustBeFinite} = [-5 0 5 0]
	end
	
	methods
		function W = Wall (varargin)
			W = W@Navigation.internal.MazeElement(varargin{:});
			if nargin > 1
				W.coord = varargin{2};
			end
		end
	end
	
	methods (Access = ?Navigation.Maze)
		function show (W, color)
			if ~isempty(W)
				xyz = cat(1, W.coord);
				line(xyz(:, [1 3])', xyz(:, [2 4])', 'Color', color);
			end
		end
	end
end
