classdef Bridge < handle
	properties (GetAccess = public, SetAccess = private, Dependent)
		connected = false
	end
	
	properties (Access = private)
		tcpConnection
	end
	
	properties (Access = private, Constant)
		mazeSuiteUnitScale  = 1 / 1.5;			% Scale factor (maze units / m)
	end
	
	methods
		function MB = Bridge
			MB.tcpConnection = tcpip('localhost', 6350);
			MB.tcpConnection.NetworkRole = 'server';
			MB.tcpConnection.Terminator = '';
			MB.tcpConnection.ByteOrder = 'littleEndian';
			MB.tcpConnection.ReadAsyncMode = 'continuous';
		end
		
		function c = get.connected (MB)
			c = strcmp(MB.tcpConnection.Status, 'open');
		end
		
		function connect (MB)
			if ~MB.connected
				fopen(MB.tcpConnection);
			end
		end
		
		function disconnect (MB)
			if MB.connected
				fclose(MB.tcpConnection);
			end
		end
		
		function sendCue (MB)
			writePacket(MB, 20);
		end
		
		function walk (MB, distance)
			if distance > 0
				writePacket(MB, 24,  distance * MB.mazeSuiteUnitScale * 100);
			elseif distance < 0
				writePacket(MB, 25, -distance * MB.mazeSuiteUnitScale * 100);
			end
		end
		
		function rotate (MB, angle)
			if angle > 0
				writePacket(MB, 29,  angle * 10);
			elseif angle < 0
				writePacket(MB, 28, -angle * 10);
			end
		end
		
		function strafe (MB, distance)
			if distance > 0
				writePacket(MB, 27,  distance * MB.mazeSuiteUnitScale * 100);
			elseif distance < 0
				writePacket(MB, 26, -distance * MB.mazeSuiteUnitScale * 100);
			end
		end
		
		function jump (MB)
			writePacket(MB, 13);
		end
		
		function setJoystick (MB, pos)
			writePacket(MB, 400, 1, [(pos(1)+1)/2*65536, 0, 0, 0]);
			writePacket(MB, 400, 2, [0, (-pos(2)+1)/2*65536, 0, 0]);
			if length(pos) > 2
				writePacket(MB, 400, 3, [0, 0, (-pos(3)+1)/2*65536, 0]);
			end
		end
		
		function showAlert (MB, message, duration)
			writePacket(MB, -101, duration, message);
		end
		
		function nextLevel (MB)
			writePacket(MB, -500, -500);
		end
		
		function blockInvalidMoves (MB, flag)
			if flag
				writePacket(MB, 98, 1);
			else
				writePacket(MB, 98, 0);
			end
		end
		
		function [pos, time] = getPosition (MB)
			writePacket(MB, 97, 97);
			[command, iArg, dArg] = readPacket(MB);
			while command ~= 97
				[command, iArg, dArg] = readPacket(MB);
			end
			pos = [dArg([1,3]), mod(dArg(4),360)];
			time = double(iArg);
		end
		
		function setPosition (MB, pos)
			writePacket(MB, -90, -90, [pos(1), -0.04, pos(2), -mod(pos(3),360)/180*pi]);
		end
	end
	
	methods (Access = private)
		function writePacket (MB, command, iArg, dArg)
			if ~MB.connected
				throwAsCaller(MException('mazebridge:connection', 'The connection with MazeSuite is not active: cannot send commands.'));
			end
			if nargin < 3
				iArg = 0;
			end
			if nargin < 4
				dArg = zeros(1, 32, 'uint8');
			elseif ischar(dArg)
				dArg = [uint8(dArg), zeros(1, 32-length(dArg), 'uint8')];
			else
				dArg = typecast(double(dArg), 'uint8');
			end
			packet        = zeros(1, 44, 'uint8');
			packet(1:3)   = [7 40 40];
			packet(4:7)   = typecast(int32(command),  'uint8');
			packet(8:11)  = typecast(int32(iArg),     'uint8');
			packet(12:43) = dArg;
			packet(44)    = mod(sum(packet(4:43)), 256);
			fwrite(MB.tcpConnection, packet);
		end
		
		function [command, iArg, dArg] = readPacket (MB)
			packet    = uint8(fread(MB.tcpConnection, [1 44], 'uint8'));
			command = typecast(packet(4:7),   'int32');
			iArg    = typecast(packet(8:11),  'int32');
			dArg    = typecast(packet(12:43), 'double');
			checksum  = mod(sum(packet(4:43)), 256);
			valid   = all(packet(1:3) == [7, 40, 40]) && checksum == packet(44);
			if ~valid
				fprintf('Warning: invalid packet received.\n');
				command = -1000;
				iArg    = 0;
				dArg(:) = 0;
			end
			if command == -101
				k = find(packet(12:43) == 0, 1);
				dArg = char(packet(11 + (1:k)));
			end
		end
	end
end
