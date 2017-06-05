% AA203 Project
% 6/3/2017
% Implementation of method from Richards, How 2002 in CVX
% State is (x,y) position and control is (ux,uy) = (vx,vy) velocity
%
% Inputs: NumAgents: number of agents spaced evenly around a circle
%                    initially and headed across the circle
%         TimeStep:  The time change at each step
%         NumTimeSteps: Number of steps until the max time
%                       Each agent is required to reach its final
%                       destination before the max time or the problem will
%                       be infeasible

function [X,U,cpu_time] = MinTime_NoRHC_FullComm_2D_CVX(NumAgents,TimeStep,NumTimeSteps)

%% Parameter definition

% Dimension of the problem (2 -> 2D, 3 -> 3D)
dim = 2;

% Determine initial positions of agents
Radius = 10; % radius of circle of initial positions
OffsetFlag = false; % Set final positions to be offset from 180 deg across
x0 = zeros(dim,1,NumAgents);
xf = zeros(dim,1,NumAgents);

[x0(:,1,:),xf(:,1,:)] = ...
                 GetInitialAndFinalPositions(NumAgents,Radius,OffsetFlag);

% Define parameters
R = 10000; % big number parameter. 10000-100000 best for speed
d = 1;     % exclusion zone center to edge distance
M = 10;    % number of edges in circle approximation polygon
           % for linear velocity limits
           % odd values of M seem to run faster (9 and 11 are faster than
           % 10)
umax = 0.5;  % max velocity magnitude
epsilon = 0.0001; % small number to scale control in objective function
                  % not much impact on speed. May need to increase to
                  % ensure final point for low precision calculations
% Create matrix of real times
times = [0:NumTimeSteps]'.*TimeStep;
 
%% CVX representation

% Suppress CVX output
% cvx_quiet true

% Perform optimization for trajectories
cvx_begin
    cvx_solver gurobi_2
%     cvx_solver mosek % Do not use. Test for 3 agents ran ~30x slower

    % control precision
    cvx_precision default
%     cvx_precision best % slower than default. Sometimes more accurate
%     cvx_precision high % slowest. Most accurate
%     cvx_precision medium % faster than default. Less accurate. No obvious
                           % issues with solutions during tests
%     cvx_precision low    % fastest. Least accurate. Solution during test
                           % seemed ok, but required increased epsilon to 
                           % hold final positions

    % variables
    variable x(dim,NumTimeSteps+1,NumAgents);
    variable u(dim,NumTimeSteps,NumAgents);
    variable c_pq(NumAgents-1,NumAgents-1,dim,NumTimeSteps+1) binary upper_triangular;
    variable c_qp(NumAgents-1,NumAgents-1,dim,NumTimeSteps+1) binary upper_triangular;
    variable b(NumTimeSteps+1,NumAgents) binary;
    
    % minimize sum of arrival times
    % add in sum of absolute values of all u values (u(:) is vector of all
    % u values) to smooth trajectories (reduce redundancy) and hold
    % trajectories at destination points. Scale by small epsilon value to
    % keep time as the priority
    % Adding in L1 norm of also results in 25% speed-up
    minimize(sum(times'*b) + epsilon*norm(u(:),1)); 
    subject to
        x(:,1,:) == x0; % initial position constraints
        
        % Velocity constraints (approximate circle with linear
        % constraints)
        for i = 1:NumTimeSteps % velocity constraint at each time step
            for p = 1:NumAgents    % velocity constraint for each agent
                for m = 1:M        % approximate circle with M sided polygon
                    m_angle = 2*pi*m/M; % mth position on circle for constraint
                    
                    % Constrain x (u(1)) and y (u(2)) velocity inside
                    % of mth side of polygon
                    u(1,i,p)*sin(m_angle) + u(2,i,p)*cos(m_angle) <= umax;
                end
            end
        end

        
        % System dynamics (position updated by control input (velocity))
        x(:,2:(NumTimeSteps+1),:) == ...
                             x(:,1:NumTimeSteps,:) + u(:,1:NumTimeSteps,:);

        % Collision Avoidance constraints       
        for i = 1:(NumTimeSteps+1)
            for p = 1:(NumAgents-1)
                for q = (p+1):NumAgents                    
                    for k = 1:dim
                        % x and y difference for p-q
                        x(k,i,p) - x(k,i,q) >= d - R*c_pq(p,q-1,k,i);
                        % x and y difference for q-p
                        x(k,i,q) - x(k,i,p) >= d - R*c_qp(p,q-1,k,i);
                    end
                        
                    % only allow 3 (of 4) constraints to be relaxed (c = 1)
                    % at a time (as long as one is active and satisfied,
                    % there will not be a collision)
                    sum(c_pq(p,q-1,:,i)) + sum(c_qp(p,q-1,:,i)) <= 3;
                end
            end
        end
        
        % Arrival constraints
        for p = 1:NumAgents
            for i = 1:(NumTimeSteps+1)            
                % When b(i,p) is 1, agent arrives (x = xf)
                % When b(i,p) is 0, unrestricted (R very large)
                x(:,i,p) - xf(:,1,p) <=  R*(1-b(i,p));
                x(:,i,p) - xf(:,1,p) >= -R*(1-b(i,p));
            end
            
            % Require that each agent arrives (once) at its destination
            % by the last time step 
            % (arrives at the step i when b(i,p) = 1)
            sum(b(:,p)) == 1;
        end
cvx_end

% Store results
X = x;
U = u;

%% Display results

% output
cpu_time = cvx_cputime;

display(cvx_cputime)
display(cvx_optval)

% Plot results
PlotTrajectory(X);
           
           
