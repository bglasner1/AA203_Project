%   AA203 Project
%   No RHC first approach using CPLEX as the solver
% Inputs: NumAgents: number of agents spaced evenly around a circle
%                    initially and headed across the circle
%         TimeStep:  The time change at each step
%         NumTimeSteps: Number of steps until the max time (not including
%                       the 0th time step, so everything is +1)
%                       Each agent is required to reach its final
%                       destination before the max time or the problem will
%                       be infeasible

function [X,U] = MinTime_NoRHC_FullComm_2D_cplex(NumAgents,TimeStep,NumTimeSteps)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


rng('shuffle'); %seed the random generator based on time

%generate initial positions for agents
%and generate final positions for agents

x0 = zeros(2,NumAgents);
xf = zeros(2,NumAgents);

radius = 50;

for i = 1:NumAgents
    %find theta, position around the circle
    theta = ((2*pi)/NumAgents)*(i-1);
    
    %starting positions evenly spaced around the circle
    x0(1,i) = radius*cos(theta);
    x0(2,i) = radius*sin(theta);
    
    %ending positions are on opposite side of circle
    xf_offset = 0; %(pi/2/NumAgents*rand(1)-0.5);
    xf(1,i) = radius*cos(theta + pi + xf_offset);
    xf(2,i) = radius*sin(theta + pi + xf_offset);
    
end

% Plot straight line trajectories
figure
% Plot circle
t = linspace(0,2*pi,100);
plot(radius*cos(t),radius*sin(t),'k')
hold on
% Plot initial and final points with straight line trajectory
for i = 1:NumAgents    plot(x0(1,i),x0(2,i),'b.','MarkerSize',15) % initial point
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
           
           
%begin cplex shenanigans

%start with equality constraints
NumStateVars = (NumTimeSteps + 1)*(NumAgents)*2; %T+1 * N * 2(x,y)
NumControlVars = (NumTimeSteps)*(NumAgents)*2; %T * N * 2(ux,uy)
NumCollisionVars = (NumTimeSteps + 1)*(NumAgents)*(NumAgents - 1)*2;  %T+1 *(N)(N-1)/2 * 4
NumEndpointVars = (NumTimeSteps)*(NumAgents); %T * N

%Calculate the total number of variables to know the column dimensions of
%Aeq and Aineq
NumVars = NumStateVars + NumControlVars + NumCollisionVars + NumEndpointVars;

%build the string of variable identifiers
ctype = '';

%make every state variable continuous
for i = 1:NumStateVars
    ctype = horzcat(ctype,'C');
end

%make all control variables continuous
for i = 1:NumControlVars
    ctype = horzcat(ctype, 'C');
end

%make all collision variables binary
for i = 1:NumCollisionVars
    ctype = horzcat(ctype, 'B');
end

%make all endpoint variables binary
for i = 1:NumEndpointVars
    ctype = horzcat(ctype, 'B');
end

%build the upper bounds and lower bounds for each variable
lb = zeros(NumVars,1);
ub = zeros(NumVars,1);

%set upper and lower bounds on state variables as +/- infinity
for i = 1:NumStateVars
    lb(i,1) = -1*inf;
    ub(i,1) = inf;
end

offset = NumStateVars; %start at the position right after the state variables end
%set upper and lower bounds on control variables as +/- infinity
for i = 1:NumControlVars
    lb(offset + i, 1) = -1*inf;
    ub(offset + i, 1) = inf;
end

offset = NumStateVars + NumControlVars; %start at the position right after the control vars end
%set upper and lower bounds on collision vars as 1,0
for i = 1:NumCollisionVars
    lb(offset + i, 1) = 0;
    ub(offset + i, 1) = 1;
end

offset = NumStateVars + NumControlVars + NumCollisionVars; %start at position after collision vars end
%set upper and lower bounds on endpoint vars as 1,0
for i = 1:NumEndpointVars
    lb(offset + i, 1) = 0;
    ub(offset + i, 1) = 1;
end

%begin building the Aeq matrix;
NumEqConstraints = (NumTimeSteps + 1)*(NumAgents)*2;
Aeq = zeros(NumEqConstraints, NumVars);
beq = zeros(NumVars, 1);

%start with adding initial condition constraints
for i = 1:NumAgents
   %x initial condition
   Aeq(2*i-1,1+(i-1)*(NumTimeSteps+1)*2) = 1;
   %y initial condition
   Aeq(2*i,2+(i-1)*(NumTimeSteps+1)*2) = 1;
end

%add the beq values for the initial condition constraints
for i = 1:NumAgents
    %x initial condition
    beq(1+(i-1)*(NumTimeSteps+1)*2,1) = x0(1,i);
    %y initial condition
    beq(2+(i-1)*(NumTimeSteps+1)*2,1) = x0(2,i);
end

offset = (NumAgents*2);
%add system dynamics constraints
for i = 1:NumAgents
    for j = 1:NumTimeSteps
        %x constraint
        %x_k
        %NEED TO FIX THIS OFFSET VALUE
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j-1, 1+(i-1)*(NumTimeSteps+1)*2+2*(j-1)) = 1;
        %x_k+1
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j-1, 1+(i-1)*(NumTimeSteps+1)*2+2*j) = -1;
        %ux_k
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j-1, NumStateVars+(i-1)*(NumTimeSteps)*2+2*j-1) = 1;
        
        %y constraint
        %y_k
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j, 2+(i-1)*(NumTimeSteps+1)*2+2*(j-1)) = 1;
        %y_k+1
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j, 2+(i-1)*(NumTimeSteps+1)*2+2*j) = -1;
        %uy_k
        Aeq(offset+(i-1)*(NumTimeSteps)*2+2*j, NumStateVars+(i-1)*(NumTimeSteps)*2+2*j) = 1;
    end
end

%ADD THE REST OF THE CONSTRAINTS TO THE beq matrix (but you prob dont need
%to since the RHS is zero
% disp(ctype);
% disp(lb');
% disp(ub');
disp(Aeq);
%disp(beq');

end


