% This script creates various plots that will be useful for the report and
% presentation.  Based on data that has already been calculated

clc; clf; clear all; close all;

% Plot 1 - comparison between centralized planning and various horizons for
% N = 5 agents case.

load('Central_5Agents_1TimeStep_50NumTimeSteps.mat'); % Centralized planning

optcost_central = opt_cost; cputime_central = cpu_time; % Save for later

figure(1); hold on;
plot([5,20],[1,1],'k--');%[opt_cost,opt_cost],'k--');
figure(2); hold on;
plot([5,20],[cpu_time,cpu_time],'k--');

% MPC

horizons = [5,6,7,10,15,20]; % Planning horizons that were previously calculated
costs = zeros(size(horizons));

for i = horizons
    file2open = strcat('RHC_100CommRange_5Agents_1ExecHorz_', ...
        num2str(i),'PlanHorz.mat');
    load(file2open);
    costs(find(horizons==i)) = opt_time; % Extract optimal cost for this run
    comptimes(find(horizons==i)) = cpu_time; % Extract computation time
end

% Evaluate percent suboptimality

cost_suboptimality = (costs-optcost_central)/optcost_central;
comp_suboptimality = (comptimes-cputime_central)/cputime_central;

% Plot results

figure(1);
plot(horizons,costs/optcost_central,'b.-');
xlabel('Planning Horizon'); ylabel('Optimal Transfer Time, Normalized');
%title('Comparison of Transfer Time, N = 5')
axis([5,20,175/optcost_central,225/optcost_central]);
legend('Centralized Planning','Model-Predictive Control','Location','Best');

figure(2);
plot(horizons,comptimes,'b.-');
xlabel('Planning Horizon'); ylabel('CPU Time (s)')
%title('Comparison of CPU Time, N = 5')
legend('Centralized Planning','Model-Predictive Control','Location','Best');

% Plot 2 - Level curves of optimal cost and CPU time for horizon 10 and
% various numbers of agents

Nrange = [2,3,5,7,10,20] ; % Number of agents to attempt to plot
commrange = [0,1,2,3,5,10,15,100];
colors = 'k.-b.-r.-g.-m.-c.-'; % Range of colors to plot

for N = Nrange
    
    clear valid_comms num_colls comp_time optimal_cost
    valid_comms = []; num_colls = []; comp_time = []; optimal_cost = [];
    
    for comms = commrange
        
        % Open file if exists
        file2open = strcat('RHC_',num2str(comms),'CommRange_',num2str(N), ...
            'Agents_1ExecHorz_10PlanHorz.mat');
        if(exist(file2open,'file'))
            load(file2open);
            valid_comms = [valid_comms,comms]; % Extract current comms range
            num_colls = [num_colls,NumCollisions]; % Extract number collisions
            comp_time = [comp_time,cpu_time]; % Extract CPU Time
            optimal_cost = [optimal_cost,opt_time]; % Extract optimal cost
            
        end
    end
    
    % Plot level curves
    
    index = find(N == Nrange); % Index of vector to use
    
    if(N<20)
        figure(3);
        semilogx(valid_comms,num_colls,colors(index*3-2:index*3)); hold on;
    end
    
    figure(4);
    semilogx(valid_comms,optimal_cost/N,colors(index*3-2:index*3)); hold on;
    
    if(N<20)
        figure(5);
        semilogx(valid_comms,comp_time,colors(index*3-2:index*3)); hold on;
    end
    
end

% Format plots
figure(3);
xlabel('Communication Range'); ylabel('Number of Collisions');
%title('Number of Collisions at Various Communications Ranges')
legend('N=2','N=3','N=5','N=7','N=10','Location','Best');

figure(4);
xlabel('Communication Range'); ylabel('Travel Time per Agent (steps)');
%title('Travel Time at Various Communications Ranges, Normalized')
legend('N=2','N=3','N=5','N=7','N=10','Location','Best');

figure(5);
xlabel('Communication Range'); ylabel('Computation Time (s)');
%title('Computation Time at Various Communications Ranges')
legend('N=2','N=3','N=5','N=7','N=10','Location','Best');

% Plot 3 - consider 10-agent, 10-horizon problem with various execution
% horizons with resepect to communications range

commrange = [0,1,1.6,1.9,2,2.1,2.2,2.4,2.5,2.7,2.8,3,3.3,3.6,3.9,4.1, ...
    4.2,4.4,4.5,4.7,4.8,5,5.1,5.3,5.6,5.7,5.9,6,6.3,6.6,6.9,7.2,7.8]; % Comms ranges
colors = 'k.-b.-r.-'; % Range of colors to plot

for exechz = 1:3
    
    clear valid_comms num_colls
    valid_comms = []; num_colls = [];
    
    for range = commrange
        file2open = strcat('RHC_',num2str(range),'CommRange_10Agents_', ...
            num2str(exechz),'ExecHorz_','10PlanHorz.mat');
        if(exist(file2open,'file'))
            load(file2open);
            
            valid_comms = [valid_comms,range]; % Extract current comms range
            num_colls = [num_colls,NumCollisions]; % Extract number collisions
        end
    end
    
    figure(6); hold on;
    plot(valid_comms,num_colls,colors(3*exechz-2:3*exechz));

end

plot([2.4 2.4], [0 14], 'k:');
plot([3.4 3.4], [0 14], 'b:');
plot([4.4 4.4], [0 14], 'r:');

xlabel('Communications Range'); ylabel('Number of Collisions');
%title('Effect of Execution Horizon on Number of Collisions, N = 10');
legend('1 Step','2 Step','3 Step','Location','Best');
