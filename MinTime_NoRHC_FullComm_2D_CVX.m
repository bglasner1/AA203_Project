% AA203 Project
% 6/3/2017
% Implementation of method from Richards, How 2002 in CVX
% State is (x,y) position and control is (ux,uy) = (vx,vy) velocity

% Inputs: NumAgents: number of agents spaced evenly around a circle
%                    initially and headed across the circle
%         TimeStep:  The time change at each step
%         NumTimeSteps: Number of steps until the max time
%                       Each agent is required to reach its final
%                       destination before the max time or the problem will
%                       be infeasible

function [X,U,cpu_time] = MinTime_NoRHC_FullComm_2D_CVX(NumAgents,TimeStep,NumTimeSteps)

%% Parameter definition

% seed random number generator
rng shuffle

% Determine initial positions of agents
radius = 10; % radius of circle of initial positions
x0 = zeros(2,1,NumAgents);
xf = zeros(2,1,NumAgents);
for p = 1:NumAgents
    angularPosition = 2*pi*(p-1)/NumAgents; % angular position for ith agent (on circle centered at origin)
    x0(1,1,p) = radius*cos(angularPosition); % initial x position for ith agent
    x0(2,1,p) = radius*sin(angularPosition); % initial y position for ith agent
    
    xf_offset = 0; %pi/2/NumAgents*(rand(1)-0.5); % angular offset from final position straight across
    xf(1,1,p) = radius*cos(angularPosition + pi + xf_offset); % final x position for ith agent
    xf(2,1,p) = radius*sin(angularPosition + pi + xf_offset); % final y position for ith agent
end

% Plot straight line trajectories
figure
% Plot circle
t = linspace(0,2*pi,100);
plot(radius*cos(t),radius*sin(t),'k')
hold on
% Plot initial and final points with straight line trajectory
for i = 1:NumAgents
    plot(x0(1,i),x0(2,i),'b.','MarkerSize',15) % initial point
    plot(xf(1,i),xf(2,i),'r*','MarkerSize',15) % final point
    plot([x0(1,i) xf(1,i)],[x0(2,i) xf(2,i)],'g','MarkerSize',15) % trajectory
end
hold off
xlabel('x')
ylabel('y')
title(['Initial Positions and Destinations for ',...
        num2str(NumAgents),' Agents'])
axis equal

% Define parameters
R = 10000; % big number parameter
d = 1;     % exclusion zone center to edge distance
M = 10;    % number of edges in circle approximation polygon
           % for linear velocity limits
umax = 0.5;  % max velocity magnitude

           
% Create matrix of real times
times = [0:NumTimeSteps]'.*TimeStep;
 
%% CVX representation

% Suppress CVX output
% cvx_quiet true

% Perform optimization for trajectories
cvx_begin
    cvx_solver gurobi_2

    variable x(2,NumTimeSteps+1,NumAgents);
    variable u(2,NumTimeSteps,NumAgents);
    variable c_pq(2,NumTimeSteps+1,NumAgents,NumAgents) binary;
    variable c_qp(2,NumTimeSteps+1,NumAgents,NumAgents) binary;
    variable b(NumTimeSteps+1,NumAgents) binary;
    minimize(sum(times'*b)); % minimize sum of arrival times
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
                    % x and y difference for p-q
                    x(:,i,p) - x(:,i,q) >= d - R*c_pq(:,i,p,q);
                    % x and y difference for q-p
                    x(:,i,q) - x(:,i,p) >= d - R*c_qp(:,i,p,q);
                    
                    % only allow 3 (of 4) constraints to be relaxed (c = 1)
                    % at a time (as long as one is active and satisfied,
                    % there will not be a collision)
                    sum(c_pq(:,i,p,q)) + sum(c_qp(:,i,p,q)) <= 3;
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

% Time step when destination is reached for each agent
destStep = [(1:NumAgents)' zeros(NumAgents,1)];
for p = 1:NumAgents
    destStep(p,2) = find(round(b(:,p)) == 1);
end

% Display agent number and time step at which destination is reached
display(destStep);

% Display positions at those times
for p = 1:NumAgents
    display(x(:,destStep(p,2),p))
end

% Plot results
figure
% Plot circle
t = linspace(0,2*pi,100);
plot(radius*cos(t),radius*sin(t),'k')
hold on
% Plot trajectories
for p = 1:NumAgents
    plot(x(1,1,p),x(2,1,p),'g.','MarkerSize',15)
    plot(x(1,destStep(p,2),p),x(2,destStep(p,2),p),'mo','MarkerSize',10)
    plot(x(1,NumTimeSteps+1,p),x(2,NumTimeSteps+1,p),'r*','MarkerSize',15)
%     plot(x(1,:,p),x(2,:,p),'b.-')
    plot(x(1,1:destStep(p,2),p),x(2,1:destStep(p,2),p),'.-')
end
hold off
xlabel('x')
ylabel('y')
title(['Minimum Time Trajectories for ',...
        num2str(NumAgents),' Agents with Full Communication'])
axis equal
           
           
