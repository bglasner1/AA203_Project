% Script to run multiple simulations in a row
% See comments in MinTime_RHC_VaryComm_2D_CVX for additional detail
fprintf('Starting Run 6\r\n');
N_agents = 20;%10,11:3;20,25,30]; % Range of number of agents to simulate
CommRange = [0,2,10,100,1,3,15,50,5]; % Communication range - 0 is no comunication, 20 is full
ExecHorz = 1; % Number of steps to take before replanning.
PlanHorz = 10; % Number of steps the algorithm plans per iteration

for N = N_agents
    for range = CommRange
        for exec = ExecHorz
            for plan = PlanHorz
                
                % Do calculation
                
                [X,U,X_plans,opt_time,cpu_time,NumCollisions] = ...
                    MinTime_RHC_VaryComm_2D_CVX(N,range,exec,plan);
                
                % Save results to file
                
                filename = strcat('RHC_',num2str(range),'CommRange_', ...
                    num2str(N),'Agents_', ...
                    num2str(exec),'ExecHorz_', ...
                    num2str(plan),'PlanHorz.mat');
                
                save(filename,'X','U','X_plans','opt_time','cpu_time','NumCollisions');
                
                clear X U X_plans opt_time cpu_time NumCollisions
                
            end
        end
    end
end