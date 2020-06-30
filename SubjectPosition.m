classdef SubjectPosition < Navigation.internal.MazeElement
	properties (Access = public)
		position(1,2)		double {mustBeFinite} = [0 0]
		orientation(1,1)	double {mustBeFinite} = 0
	end
	
	methods
		function SP = SubjectPosition (varargin)
			SP = SP@Navigation.internal.MazeElement(varargin{:});
			if nargin > 1
				SP.position = varargin{2};
			end
			if nargin > 2
				SP.orientation = varargin{3};
			end
		end
		
		function SP = set.orientation (SP, val)
			val = mod(val, 360);
			if val > 180
				SP.orientation = val - 360;
			else
				SP.orientation = val;
			end
		end
	end
	
	methods (Access = ?Navigation.Maze)
		function show (SP, color)
			for i=1:numel(SP)
				H = hgtransform;
				line([4 0; 0 0; 0 4], [0 -1; -1 1; 1 0], 'Parent', H, 'Color', color);
				H.Matrix = makehgtform('translate', [SP(i).position(1), SP(i).position(2), 0], ...
					'zrotate', SP(i).orientation*pi/180);
			end
		end
	end
end