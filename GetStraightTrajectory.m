% AA203 Project
% 6/5/2017
%
% Function to generate straight line trajectory given a current 2D state 
% and 2D input velocity u

function x_straight = GetStraightTrajectory(x0,u,horizon)

% initialize array
x_straight = zeros(2,horizon+1);

% define initial state
x_straight(:,1) = x0;

% fill in trajectory
for i = 2:(horizon+1)
    x_straight(:,i) = x_straight(:,i-1) + u;
end