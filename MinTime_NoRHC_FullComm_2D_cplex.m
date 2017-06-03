%   AA203 Project
%   No RHC first approach using CPLEX as the solver

%NumAgents: The number of agents to be moved from starting positions to
%final positions

%TimeStep, the delta_t of each iteration 

%NumTimeSteps, the number of iterations

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
    xf_offset = (pi/2/NumAgents*rand(1)-0.5);
    xf(1,i) = radius*cos(theta + pi + xf_offset);
    xf(2,i) = radius*sin(theta + pi + xf_offset);
    
end

disp(x0);
disp(xf);


end