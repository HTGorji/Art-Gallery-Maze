classdef Maze < Navigation.internal.MazeElement & handle
	properties (Access = public)
		wall(1,:)			Navigation.Wall
		landmark(1,:)		Navigation.Landmark
		region(1,:)			Navigation.Region
		startPoint(1,1)		Navigation.SubjectPosition
	end
	
	methods (Static)
		function M = load (fileName)
			fileName = string(fileName);
			if isempty(fileName)
				M = Navigation.Maze.empty;
			else
				for i=1:length(fileName)
					tmp = load(fileName(i));
					if isfield(tmp, 'M') && isscalar(tmp.M) && isa(tmp.M, 'Navigation.Maze')
						M(i) = tmp.M; %#ok<AGROW>
						[~,f] = fileparts(fileName{i});
						M(i).name = f;
					else
						error('Invalid file: %s.', char(fileName(i)));
					end
				end
			end
		end
	end
	
	methods
		function M = Maze (varargin)
			M = M@Navigation.internal.MazeElement(varargin{:});
		end

		function show (M)
			% Show the maze plan into a Matlab figure window
			ax = gca;
			clo(ax);
			hold(ax, 'on');
			show(M.region, [0.4 0.4 0.4]);
			show(M.wall, 'k');
			show(M.landmark, 'b');
			show(M.startPoint, 'g');

			ax.Units = 'normalized';
			ax.OuterPosition = [0 0 1 1];
			ax.Color = 'white';
			ax.YDir = 'normal';
			ax.XLimMode = 'auto';
			ax.YLimMode = 'auto';
			ax.DataAspectRatio = [1 1 1];
		end	
	end
end

