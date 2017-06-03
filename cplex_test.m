function cplex_test
% Use the function cplexmilp to solve a mixed-integer linear programming problem
%
% The MILP problem solved in this example is
%   Minimize  5.8x1 + 3x2 + 1.2x3
%   Subject to
%        x1 + 2.1 x2 + x3 = 6
%             3 x < (=) 4.2
%        x1 + 0.2 x2 < (=) 4.2
%              x3 < (=) 3
%   Bounds
%        0 <= x1 <= inf
%        0 <= x2 <= inf
%        0 <= x3 <= inf

%   Integers
%       x1,x3


   % Since cplexmilp solves minimization problems and the problem
   % is a maximization problem, negate the objective
   f     = [5.8 3 1.2]';
   Aineq = [0  3  0; 1 0.2  0; 0 0 1];
   bineq = [4.2 4.2 2]';
   
   Aeq   = [1 2.1 1];
   beq   =  6;
   
   lb    = [0;    0;   0];
   ub    = [inf; inf; inf];
   ctype = 'ICI';
   
   options = cplexoptimset;
   options.Display = 'on';
   
   [x, fval, exitflag, output] = cplexmilp (f, Aineq, bineq, Aeq, beq,...
      [ ], [ ], [ ], lb, ub, ctype, [ ], options);
   
   fprintf ('\nSolution status = %s \n', output.cplexstatusstring);
   fprintf ('Solution value = %f \n', fval);
   disp ('Values =');
   disp (x');


end