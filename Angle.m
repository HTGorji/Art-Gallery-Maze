classdef Angle < double
	methods
		function A = Angle (val)
			val = mod(val, 360);
			j = val > 180;
			val(j) = val(j) - 360;
			A = A@double(val);
		end
		
		function B = uplus (A)
			B = Navigation.Angle(uplus@double(A));
		end
		
		function B = uminus (A)
			B = Navigation.Angle(uminus@double(A));
		end
		
		function C = plus (A, B)
			C = Navigation.Angle(plus@double(A, B));
		end
		
		function C = minus (A, B)
			C = Navigation.Angle(minus@double(A, B));
		end
		
		function C = times (A, B)
			C = Navigation.Angle(times@double(A, B));
		end
		
		function C = mtimes (A, B)
			C = Navigation.Angle(mtimes@double(A, B));
		end
		
		function C = ldivide (A, B)
			C = Navigation.Angle(ldivide@double(A, B));
		end
		
		function C = rdivide (A, B)
			C = Navigation.Angle(rdivide@double(A, B));
		end
		
		function C = mldivide (A, B)
			C = Navigation.Angle(mldivide@double(A, B));
		end
		
		function C = mrdivide (A, B)
			C = Navigation.Angle(mrdivide@double(A, B));
		end
		
		function C = power (A, B)
			C = Navigation.Angle(power@double(A, B));
		end
		
		function C = mpower (A, B)
			C = Navigation.Angle(mpower@double(A, B));
		end
		
		function B = sin (A)
			B = sind(A);
		end
		
		function B = cos (A)
			B = cosd(A);
		end
		
		function B = tan (A)
			B = tand(A);
		end
		
		function B = radians (A)
			B = double(A) ./ 180 .* pi;
		end
	end
end
