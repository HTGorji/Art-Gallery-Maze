classdef Log
	properties (Access = public)
		logFileName(1,1) string
	end
	
	properties (GetAccess = public, SetAccess = private)
		mazeFileName(1,1) string = ''
		navigationPath(1,1) Navigation.Path
	end
	
	methods (Static)
		function L = load (fileName)
			fileName = string(fileName);
			for i=1:numel(fileName)
				fname = char(fileName{i});
				[~,f,e] = fileparts(fname);
				fprintf('Reading %s... ', [f,e]);
				L(i) = MazeSuite.Log(fileName(i)); %#ok<AGROW>
				fprintf('done\n');
			end
			
			% Read associated mazes if available
			[mazeFileName,~,idx] = unique([L.mazeFileName]);
			L = reshape([L.navigationPath], size(fileName));
			for i=1:length(mazeFileName)
				fileName = char(mazeFileName(i));
				fileName(ismember(fileName, '/\')) = filesep;
				[pathName, fileName] = fileparts(fileName);
				fileName = fullfile(pathName, fileName);
				if exist([fileName, '.mat'], 'file') == 2
					M = load(fileName);
					[L(idx==i).maze] = deal(M.M);
				elseif exist([fileName, '.maz'], 'file') == 2
					[L(idx==i).maze] = deal(MazeSuite.Maze.load([fileName, '.maz']));
				end
			end
		end
	end
	
	methods
		function L = Log (fileName)
			L.logFileName = fileName;
			if exist(L.logFileName, 'file') ~= 2
				error('File not found.');
			end
			L = read(L);
		end
		
		function L = read (L)
			%% Read text file
			fid = fopen(L.logFileName, 'rt');
			fileContents = fread(fid, '*char')';
			fclose(fid);
			fileContents = regexp(fileContents, '.*', 'match', 'dotexceptnewline')';
			if ~ispc
				fileContents = cellfun(@(x)x(1:end-1), fileContents, 'UniformOutput', false);
			end
			rowIndex = 1;
			
			%% Parse header
			[L.navigationPath.subject, rowIndex] = parseHeader(fileContents, rowIndex, 'Walker');
			[L.mazeFileName, rowIndex] = parseHeader(fileContents, rowIndex, 'Maze');
			[t, rowIndex] = parseHeader(fileContents, rowIndex, 'Time');
			L.navigationPath.time = datetime(t, 'InputFormat', 'eee MMM dd HH:mm:ss yyyy');
			
			%% Skip until first data row
			while isempty(regexp(fileContents{rowIndex}, '^Time(ms', 'once'))
				rowIndex = rowIndex + 1;
			end
			rowIndex = rowIndex + 1;
			txt = fileContents(rowIndex:end);
			
			%% Parse main table
			val = regexp(txt, '^(\d+)\t(\d+)\t([-\.\d]+)\t([-\.\d]+)\t([-\.\d]+)\t([-\.\d]+)\t([-\.\d]+)\t([-\.\d]+)$', 'once', 'tokens');
			evt = cellfun(@isempty, val); % Rows which have not been parsed correctly are event descriptors
			val = cellfun(@str2double, cat(1, val{:}));
			evt = regexp(txt(evt), '^(\d+)\t(\d+)\tEvent\t(\d+)\t(\d+)\t(\d+)\t(\d+)$', 'once', 'tokens');
			if ~isempty(evt)
				evt = cellfun(@str2double, cat(1, evt{:}));
			end
			
			%% Extract position and orientation information
			Time        = seconds(val(:,2) / 1000);
			position    = [val(:,3), -val(:,4), val(:,5)];
			[az,el]     = cart2sph(val(:,6)-val(:,3), val(:,4)-val(:,7), val(:,8)-val(:,5));
			orientation = [az,el] .* 180 ./ pi;
			L.navigationPath.data = timetable(Time, position(:,1), position(:,2), orientation(:,1), 'VariableNames', {'PosX','PosY','Orientation'});
			
			%% Extract event information
			if ~isempty(evt)
				evt = evt(evt(:,3) == 1 & evt(:,5) == 1,:);
				L.navigationPath.event = timetable(seconds(evt(:,2)/1000), evt(:,6), 'VariableNames', {'Object'});
			end
			
			[~,L.navigationPath.name] = fileparts(char(L.logFileName));
		end
	end
end

function [val, rowIndex] = parseHeader (fileContents, rowIndex, header)
	while true
		val = regexp(fileContents{rowIndex}, ['^', header, '\t:\t(.*)'], 'once', 'tokens');
		rowIndex = rowIndex + 1;
		if ~isempty(val)
			val = val{1};
			break;
		end
	end
end

