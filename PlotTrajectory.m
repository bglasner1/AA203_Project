% AA203 Project
% 6/4/2017
% Function to plot the trajectories defined in input matrix X
%
% Input X: 2 x NumTimeSteps+1 x NumAgents

function PlotTrajectory(X)

% Extract constants
NumTimeSteps = size(X,2) - 1;
NumAgents = size(X,3);
Radius = X(1,1,1); % radius is x position of first agent

figure
% Plot circle
t = linspace(0,2*pi,100);
plot(Radius*cos(t),Radius*sin(t),'k')
hold on
% Plot trajectories for each agent
for p = 1:NumAgents
    plot(X(1,1,p),X(2,1,p),'g.','MarkerSize',15)
    plot(X(1,NumTimeSteps+1,p),X(2,NumTimeSteps+1,p),'r*','MarkerSize',15)
    plot(X(1,:,p),X(2,:,p),'.-')
end
hold off
xlabel('x')
ylabel('y','Rotation',0)
title(['Minimum Time Trajectories for ',num2str(NumAgents),' Agents'])
axis equal