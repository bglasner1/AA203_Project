% AA203 Project
% 6/4/2017
% Function to generate and plot initial and final positions for a number 
% of agents NumAgents evenly spaced in a circle of radius Radius. The final
% positions (destinations) are straight across the circle (through the
% center point) from the initial points if OffsetFlag is false. If the
% OffsetFlag is true, each final position is offset from that point by a
% randomized (angular) amount

% Inputs: NumAgents: number of agents spaced evenly around a circle
%                    initially and headed across the circle
%         Radius: radius of the circle of initial and final positions.
%                 Centered at the origin.
%         OffsetFlag: Boolean: False => final positions are 180 degrees
%                                     from corresponding initials positions
%                              True  => final positions are 180 degrees
%                                       plus some random angle from 
%                                       corresponding initial positions.
%                                       Final positions are guaranteed not
%                                       to coincide.

% Outputs: x0: 2 x NumAgents array of initial positions
%              Ex: [x0_1 x0_2 x0_3 ... x0_N;
%                   y0_1 y0_2 y0_3 ... y0_N]
%          xf: 2 x NumAgents array of initial positions
%              Ex: [xf_1 xf_2 xf_3 ... xf_N;
%                   yf_1 yf_2 yf_3 ... yf_N]

function [x0,xf] = GetInitialAndFinalPositions(NumAgents,Radius,OffsetFlag)

% seed random number generator
rng shuffle

% Define output arrays
x0 = zeros(2,NumAgents);
xf = zeros(2,NumAgents);

% Fill arrays for each agent
for p = 1:NumAgents
    angularPosition = 2*pi*(p-1)/NumAgents; % angular position for ith agent (on circle centered at origin)
    x0(1,p) = Radius*cos(angularPosition); % initial x position for ith agent
    x0(2,p) = Radius*sin(angularPosition); % initial y position for ith agent
    
    if OffsetFlag == false
        xf_offset = 0; % no offset
    else
        % angular offset from final position straight across
        % non-zero offset improves cases with even number of agents
        xf_offset = pi/2/NumAgents*(rand(1)-0.5);
    end
                                                  
    xf(1,p) = Radius*cos(angularPosition + pi + xf_offset); % final x position for ith agent
    xf(2,p) = Radius*sin(angularPosition + pi + xf_offset); % final y position for ith agent
end

% Plot straight line trajectories
figure
% Plot circle
t = linspace(0,2*pi,100);
plot(Radius*cos(t),Radius*sin(t),'k')
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