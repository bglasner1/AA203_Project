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

function [X,U] = MinTime_NoRHC_FullComm_2D_CVX(NumAgents,TimeStep,NumTimeSteps)

% seed random number generator
rng shuffle

% Determine initial positions of agents
radius = 100; % radius of circle of initial positions
x0 = zeros(2,NumAgents);
xf = zeros(2,NumAgents);
for i = 1:NumAgents
    angularPosition = 2*pi*(i-1)/NumAgents; % angular position for ith agent (on circle centered at origin)
    x0(1,i) = radius*cos(angularPosition); % initial x position for ith agent
    x0(2,i) = radius*sin(angularPosition); % initial y position for ith agent
    
    xf_offset = 0; %pi/2/NumAgents*(rand(1)-0.5); % angular offset from final position straight across
    xf(1,i) = radius*cos(angularPosition + pi + xf_offset); % final x position for ith agent
    xf(2,i) = radius*sin(angularPosition + pi + xf_offset); % final y position for ith agent
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
axis square

% Define parameters
R = 10000; % big number parameter
d = 1;     % exclusion zone center to edge distance
M = 10;    % number of edges in circle approximation polygon
           % for linear velocity limits
           
