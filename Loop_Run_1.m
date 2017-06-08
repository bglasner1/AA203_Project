% Script to run multiple simulations in a row
% See comments in MinTime_RHC_VaryComm_2D_CVX for additional detail
fprintf('Starting Run 1\r\n');
N_agents = [2,3,5,7]; % Range of number of agents to simulate
TimeStep = 1;
NumTimeSteps = 50;

for N = N_agents
                % Do calculation
                
                [X,U,cpu_time,opt_cost] = ...
                    MinTime_NoRHC_FullComm_2D_CVX(N,TimeStep,NumTimeSteps);
                
      % Save results to file
                
      filename = strcat('Central_', ...
      num2str(N),'Agents_', ...
      num2str(TimeStep),'TimeStep_', ...
      num2str(NumTimeSteps),'NumTimeSteps.mat');
                
      save(filename,'X','U','cpu_time','opt_cost');
                
      clear X U cpu_time opt_cost

end