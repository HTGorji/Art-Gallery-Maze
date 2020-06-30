classdef Landmark < Navigation.internal.MazeElement
	properties (Access = public)
		position(1,2)	double {mustBeFinite} = [0 0]
		size(1,2)		double {mustBeFinite, mustBePositive} = [0.1 0.1]
	end
	
	methods
		function L = Landmark (varargin)
			L = L@Navigation.internal.MazeElement(varargin{:});
			if nargin > 1
				L.position = varargin{2};
			end
			if nargin > 2
				L.size = varargin{3};
			end
		end
	end
	
	methods (Access = ?Navigation.Maze)
		function show (L, color)
			if ~isempty(L)
				xyz = cat(1, L.position);
				plot(xyz(:,1), xyz(:,2), [color, 'o']);
			end
		end
	end
end