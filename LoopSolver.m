% Script to run multiple simulations in a row
% See comments in MinTime_RHC_VaryComm_2D_CVX for additional detail

N_agents = [10,5,7];%10,11:3;20,25,30]; % Range of number of agents to simulate
CommRange = [3,5,10,15,100]; % Communication range - 0 is no comunication, 20 is full
ExecHorz = 1; % Number of steps to take before replanning.
PlanHorz = [5,6,7,10,15,20]; % Number of steps the algorithm plans per iteration

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