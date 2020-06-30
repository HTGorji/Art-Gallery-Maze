classdef Path
	properties (Access = public)
		name(1,1)		string = ''
	end
	
	properties (Access = public, Dependent)
		maze(1,1)		Navigation.Maze
	end
	
	properties (Access = public)
		subject(1,1)	string = ''
		time(1,1)		datetime
	end
	
	properties (Access = public, Dependent)
		data			timetable
	end
	
	properties (Access = public)
		event			timetable
	end
	
	properties (GetAccess = public, SetAccess = private)
		timeRange						timerange	= timerange(seconds(0), seconds(Inf), 'closed')
		duration(1,1)					duration	= seconds(0)
		cumulativeDistance(1,1)			double		= 0
		cumulativeDirectionChange(1,1)	double		= 0
	end

	properties (Access = protected)
		mazeObject		Navigation.Maze = Navigation.Maze('Empty maze')
		path			timetable
	end
	
	methods
		function p = get.data (P)
			p = P.path;
		end
		
		function P = set.data (P, p)
			assert(all(ismember({'PosX','PosY','Orientation'}, p.Properties.VariableNames)));
			assert(isnumeric(p.PosX) && all(isfinite(p.PosX(:))) && size(p.PosX,2) == 1);
			assert(isnumeric(p.PosY) && all(isfinite(p.PosY(:))) && size(p.PosY,2) == 1);
			if isa(p.Orientation, 'Navigation.Angle')
				assert(size(p.Orientation,2) == 1);
			else
				assert(isnumeric(p.Orientation) && size(p.Orientation,2) == 1 && all(p.Orientation > -180) && all(p.Orientation <= 180));
				p.Orientation = Navigation.Angle(p.Orientation);
			end
			assert(~isempty(p));
			P.path = timetable(p.Time, p.PosX, p.PosY, p.Orientation, 'VariableNames', {'PosX', 'PosY', 'Orientation'});
			P = computeParameters(P);
		end

		function P = set.event (P, e)
			if isempty(e)
				P.event = timetable.empty;
			else
				assert(all(ismember({'Object'}, e.Properties.VariableNames)));
				assert(isnumeric(e.Object) && all(isfinite(e.Object(:))) && size(e.Object,2) == 1);
				P.event = e;
			end
		end
		
		function M = get.maze (P)
			M = P.mazeObject;
		end
		
		function P = set.maze (P, M)
			P.mazeObject = M;
			if ~isempty(P.path)
				P.path.Region = contains(M.region, [P.path.PosX, P.path.PosY]);
			end
		end
	end
	
	methods (Access = public, Sealed)	
		function show (P)
			cla
			color = colorcube(numel(P));
			show(P(1).mazeObject);
			for i=1:numel(P)
				plot(P(i).path.PosX(1), P(i).path.PosY(1), 'o', 'MarkerEdgeColor', color(i,:));
				hold on
				plot(P(i).path.PosX(end), P(i).path.PosY(end), 'o', 'MarkerEdgeColor', color(i,:), 'MarkerFaceColor', color(i,:));
				hold on
				line(P(i).path.PosX, P(i).path.PosY, 'Color', color(i,:), 'LineWidth', 2);
			end
		end
		
		function movie (P, speed)
			if nargin < 2, speed = 1; end
			cla
			color = colorcube(numel(P));
			show(P(1).mazeObject);
			xlim = get(gca, 'XLim');
			ylim = get(gca, 'YLim');
			textLabel = text(xlim(1)+5, ylim(2)-5, 't = 0.000 s', 'FontName', 'Default', 'FontSize', 12, 'Interpreter', 'none');
			
			H = hgtransform;
			line([4 0; 0 0; 0 4], [0 -1; -1 1; 1 0], 'Parent', H);
			
			for i=1:numel(P)
				
				startTime = datetime;
				goOn = true;
				lastTimePoint = 1;
				t = P(i).path.Time - P(i).path.Time(1);
				while goOn
					nextTimePoint = find(t >= (datetime - startTime)*speed, 1, 'first');
					if isempty(nextTimePoint)
						nextTimePoint = height(P(i).path);
						goOn = false;
					end
					H.Matrix = makehgtform('translate', [P(i).path.PosX(nextTimePoint), P(i).path.PosY(nextTimePoint), 0], ...
						'zrotate', radians(P(i).path.Orientation(nextTimePoint)));
					line(P(i).path.PosX(lastTimePoint:nextTimePoint), P(i).path.PosY(lastTimePoint:nextTimePoint), 'Color', color(i,:), 'LineWidth', 2);
					textLabel.String = sprintf('%s, t = %.3f s', P(i).name, seconds(P(i).path.Time(nextTimePoint)));
					lastTimePoint = nextTimePoint;
					drawnow;
				end
			end
		end
		
		function S = extract (P, from, to)
			%EXTRACT    Extract subset(s) of a navigation path
			%
			% S = extract(P, fromT, toT) extracts the portion of the
			% Navigation.Path object P from time fromT to timeT into a new
			% Navigation.Path object S. If fromT and toT are vectors of the
			% same length, multiple portions will be extracted and stored
			% in an array of Navigation.Path objects S.
			S = repmat(P(:)', numel(from), 1);
			if isnumeric(from)
				from = seconds(from);
			end
			if isnumeric(to)
				to = seconds(to);
			end
			for i=1:numel(from)
				tr = timerange(from(i), to(i), 'closed');
				for j=1:numel(P)
					if ~isempty(S(i).path)
						S(i,j).path = S(i).path(tr,:);
						S(i,j) = computeSummary(S(i,j));
					end
					if ~isempty(S(i).event)
						S(i,j).event = S(i).event(tr,:);
					end
				end
			end
		end
		
		function plot (P, varargin)
			if isempty(varargin)
				varName = {'PosX','PosY'};
			else
				varName = varargin;
			end
			value = cell(1, length(varName));
			for i=1:length(varName)
				value{i} = P.path.(varName{i});
			end
			
			hold off
			plot(P.path.Time, value{:});
			legend(varName{:});
		end
		
		function P = recompute (P)
			for i=1:numel(P)
				P(i).path = timetable(P(i).path.Time, P(i).path.PosX, P(i).path.PosY, P(i).path.Orientation, 'VariableNames', {'PosX', 'PosY', 'Orientation'});
				P(i) = computeParameters(P(i));
			end
		end
	end
	
	methods (Access = private)	
		function P = computeParameters (P)
			movement                    = [diff(P.path.PosX), diff(P.path.PosY)];
			distance					= [0; sqrt(sum(movement.^2, 2))];
			%rotation					= [Navigation.Angle(0); diff(P.path.Orientation)];
			direction					= [Navigation.Angle(0); atan2d(movement(:,2), movement(:,1))];
			direction(distance==0)		= P.path.Orientation(distance==0);
			directionChange				= [Navigation.Angle(0); diff(direction)];
			region						= contains(P.mazeObject.region, [P.path.PosX, P.path.PosY]);
			P.path = [P.path, timetable(P.path.Time, direction, distance, directionChange, region, ...
				'VariableNames', {'Direction',	'Distance', 'DirectionChange', 'Region'})];
			P = computeSummary(P);
		end
		
		function P = computeSummary (P)
			P.timeRange					= timerange(P.path.Time(1), P.path.Time(end));
			P.duration					= P.path.Time(end) - P.path.Time(1);
			P.cumulativeDistance		= sum(P.path.Distance);
			P.cumulativeDirectionChange = sum(abs(P.path.DirectionChange));
		end
	end
	
	methods (Access = public, Sealed)
		function P = smooth (P, variables, windowSize)
			P.path = smoothdata(P.path, 'gaussian', seconds(windowSize), 'DataVariables', variables);
		end
		
		function T = summarize (S)
			%SUMMARIZE    Print table of summary path data
			
			R = arrayfun(@(x)x.path.Region(1), S);
			T = table([S.duration]', [S.cumulativeDistance]', [S.cumulativeDistance]' ./ seconds([S.duration])', [S.cumulativeDirectionChange]', R(:), 'VariableNames', {'Duration','Distance','MeanSpeed','CumulativeDirectionChange','Region'});
		end
		
		function S = split (P, varargin)
			%PATH/SPLIT     Split paths using different criteria
			%
			%  S = split(P, CRITERION) takes an array of Navigation.Path
			%  objects P and splits each of them into separate temporally
			%  contiguous segments according to the criterion specified in
			%  CRITERION, returning an array of Navigation.Path objects S,
			%  each containing one segment.
			%
			%  S = split(P, CRITERION1, CRITERION2, ...) splits each path
			%  using each of the specified criteria in the specified order.
			%
			%  Possible values of CRITERIA are:
			%
			%     'region'  Use the region definition associated with the
			%               maze to split the path each time the subject
			%               traverses a region boundary
			%
			%     'start'   Split the data each time the subject starts
			%               moving
			%
			%     'stop'    Split the data each time the subject stops
			%               moving
			%
			%     T         Split the data at all time points specified in
			%               the array T
			
			isCriteria = cellfun(@(x)ischar(x) || isstring(x), varargin);
			for i=find(~isCriteria)
				if ~isa(varargin{i}, 'duration')
					varargin{i} = seconds(varargin{i});
				end
			end
			
			S = Navigation.Path.empty;
			for i=1:numel(P)
				splitAt = 1;
				for j=1:length(varargin)
					if isCriteria(i)
						switch varargin{j}
							case 'region'
								splitAt = [splitAt; find(diff(P(i).path.Region)) + 1]; %#ok<AGROW>
							case 'start'
								splitAt = [splitAt; find(P(i).path.Distance(2:end) ~= 0 & P(i).path.Distance(1:end-1) == 0) + 1]; %#ok<AGROW>
							case 'stop'
								splitAt = [splitAt; find(P(i).path.Distance(2:end) == 0 & P(i).path.Distance(1:end-1) ~= 0) + 1]; %#ok<AGROW>
						end
					else
						for k=1:numel(varargin{i})
							splitAt = [splitAt; find(P(i).path.Time >= varargin{i}(k), 1, 'first')]; %#ok<AGROW>
						end
					end
				end
				splitAt = [unique(splitAt); height(P(i).path)+1];
				tstart  = P(i).path.Time(splitAt(1:end-1));
				tend    = P(i).path.Time(splitAt(2:end)-1);
				S       = [S; extract(P(i), tstart, tend)]; %#ok<AGROW>
			end
		end
		
		function P = join (S, varargin)
			%PATH/JOIN     Join path segments into a path
			S = S(:)';
			for i=1:length(varargin)
				S = [S, varargin{i}(:)']; %#ok<AGROW>
			end
			P = S(1);
			for i=2:numel(S)
				P.path = [P.path; S(i).path];
				P.event = [P.event; S(i).event];
			end
			P.path = sortrows(P.path);
			P.event = sortrows(P.event);
			P = computeSummary(P);
		end
	end
end
