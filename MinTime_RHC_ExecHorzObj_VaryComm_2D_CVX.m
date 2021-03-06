% AA203 Project
% 6/4/2017
% Implementation of distributed MPC method in CVX for multi-agent path
% path planning with collision avoidance constraints using a combination of
% methods from:
% Richards, How 2002 (Aircraft Trajectories)
% Bellingham, Richards, How 2002 (RHC)
% Richards, How 2004 (Decentralized MPC)
%
% State is (x,y) position and control is (ux,uy) = (vx,vy) velocity
%
% Inputs: NumAgents: number of agents spaced evenly around a circle
%                    initially and headed across the circle
%         CommRange: Radius of communication (max distance between two
%                    agents in full communication with one another)
%         ExecHorz: Execution Horizon, or number of steps that each agent
%                   takes in current planned trajectory before re-planning
%         PlanHorz: Planning Horizon, or number of steps ahead of the
%                   present time are in each planned trajectory
%                   (PlanHorz >= ExecHorz)
%
% Outputs: X: 2 x NumTimeSteps+1 x NumAgents 
%             (actual state trajectories for all agents)
%          U: 2 x NumTimeSteps x NumAgents
%             (control histories for all agents)
%          X_plans: NumTimeSteps x 1 cell array
%                   each entry is a 2 x PlanHorz+1 x NumAgents array with
%                   all of the planned trajectories at that time step
%          opt_time: The sum of the arrival times of all agents
%                    Infinity if any agent does not arrive
%          cpu_time: run time


function [X,U,X_plans,opt_time,cpu_time,NumCollisions] = MinTime_RHC_ExecHorzObj_VaryComm_2D_CVX(NumAgents,CommRange,ExecHorz,PlanHorz)

%% Parameter definition

% Dimension of the problem (2 -> 2D, 3 -> 3D)
dim = 2;

% Determine initial positions of agents
Radius = 10; % radius of circle of initial positions
OffsetFlag = false; % Set final positions to be offset from 180 deg across
x0 = zeros(dim,1,NumAgents);
xf = zeros(dim,1,NumAgents);

[x0(:,1,:),xf(:,1,:)] = ...
                 GetInitialAndFinalPositions(NumAgents,Radius,OffsetFlag);

% Define parameters
R = 10000; % big number parameter. 10000-100000 best for speed
d = 1;     % exclusion zone center to edge distance
margin = 1.05; % error margin to prevent unnecessary collisions
M = 10;    % number of edges in circle approximation polygon
           % for linear velocity limits
           % odd values of M seem to run faster (9 and 11 are faster than
           % 10)
umax = 0.5;  % max velocity magnitude
epsilon = 0.0001; % small number to scale control in objective function
                  % not much impact on speed. May need to increase to
                  % ensure final point for low precision calculations
arrival_tol = 0.0001; % tolerance for agent to arrive at destination
                  
% Define time parameters
TimeStep = 1; % Length of a time step
CurrentStep = 1; % Start at step 0 (initial point)
MaxNumTimeSteps = 100; % Restrict total number of time steps

% Pre allocate output arrays
X = NaN(dim,MaxNumTimeSteps+1,NumAgents);
U = NaN(dim,MaxNumTimeSteps,NumAgents);
X_plans = cell(MaxNumTimeSteps,1);
all_opt_times = inf(1,NumAgents);

% Define initial positions
X(:,1,:) = x0;

%initialize collision states
CollisionTable = zeros(NumAgents,NumAgents);
%keep track of collisions
NumCollisions = 0;

%% Calculate planned trajectories for each agent at each time step

% Keep track of cpu time
tic

% Suppress CVX output
cvx_quiet true

% Loop until all agents arrive at their destination
while any(all_opt_times == inf)...
      && (CurrentStep < (MaxNumTimeSteps+1))...
    
    % Initilize X_plans for this timestep
    X_plans{CurrentStep} = zeros(2,PlanHorz+1,NumAgents);
    
    % Update to execution horizon (until MaxNumTimeSteps + 1)
    UpdateEnd = min([(CurrentStep + ExecHorz),(MaxNumTimeSteps + 1)]);
    
    % Loop through number of agents
    for p = 1:NumAgents
        
        % Determine which agents this agent is in communication with at the
        % current step
        OtherAgents = [1:(p-1),(p+1):NumAgents];
        dist_btwn_agents = ... % L2 norm to calc distance between agents
            norms((X(:,CurrentStep,p) - X(:,CurrentStep,OtherAgents)),2,1);
        dist_btwn_agents = dist_btwn_agents(:); % convert to vector
        
        % Perform optimization in CVX for trajectories
        cvx_begin
            cvx_solver gurobi_2
        %     cvx_solver mosek % Do not use. Test for 3 agents ran ~30x slower

            % control precision
            cvx_precision default
        %     cvx_precision best % slower than default. Sometimes more accurate
        %     cvx_precision high % slowest. Most accurate
        %     cvx_precision medium % faster than default. Less accurate. No obvious
                                   % issues with solutions during tests
        %     cvx_precision low    % fastest. Least accurate. Solution during test
                                   % seemed ok, but required increased epsilon to 
                                   % hold final positions

            % variables
            variable x(dim,PlanHorz+1);
            variable u(dim,PlanHorz);
            variable c_pq(NumAgents-1,dim,PlanHorz) binary;
            variable c_qp(NumAgents-1,dim,PlanHorz) binary;
            % no collision constraints at initial time step

            % minimize distance from the end of the planned trajectory to
            % the destination (xf/goal). Use L1 norm for linearity.
            % add in distance from next step to the destination scaled down
            % by very small epsilon value to ensure that the agent
            % progresses toward the destination after the destination comes
            % into the horizon. Again use L1 norm
            plan_dist_to_goal = norm((xf(:,1,p) - x(:,PlanHorz+1)),1);
            next_dist_to_goal = 0;
            for planStep = 2:ExecHorz+1
                next_dist_to_goal = next_dist_to_goal + norm((xf(:,1,p) - x(:,planStep)),1);
            end
            minimize(plan_dist_to_goal + epsilon*next_dist_to_goal); 
            subject to
                % initial position constraint
                x(:,1) == X(:,CurrentStep,p); 

                % Velocity constraints (approximate circle with linear
                % constraints)
                for i = 1:PlanHorz % velocity constraint at each time step
                    for m = 1:M        % approximate circle with M sided polygon
                        m_angle = 2*pi*m/M; % mth position on circle for constraint

                        % Constrain x (u(1)) and y (u(2)) velocity inside
                        % of mth side of polygon
                        u(1,i)*sin(m_angle) + u(2,i)*cos(m_angle) <= umax;
                    end
                end


                % System dynamics (position updated by control input (velocity))
                x(:,2:(PlanHorz+1)) == x(:,1:PlanHorz) + u(:,1:PlanHorz);

                % Collision Avoidance constraints       
                % Avoid collisions with all other agents q
                for q = OtherAgents  
                    % Develop planning hierarchy. Agent 1 plans first
                    % and predicts plans for later agents. Later agents
                    % use actual plans for earlier agents and predict
                    % plans for later agents. If two agents are not in
                    % communication, they can only predict the
                    % (straight line) trajectory of the other.
                    
                    % If q has already planned at this time step
                    if q < p
                        % Convert agent number q to valid index
                        q_ind = q;

                        % Check if p and q are in communication
                        if dist_btwn_agents(q_ind) <= CommRange
                            % In comm. Use q's current planned trajectory
                            xq = X_plans{CurrentStep}(:,:,q);
                        else
                            % Check if current step is initial step                       
                            if CurrentStep > 1
                            
                                % Not in comm. Use predicted straight
                                % trajectory with q's current state and 
                                % last control
                                xq = GetStraightTrajectory(...
                                    X(:,CurrentStep,q),...
                                    U(:,CurrentStep-1,q),PlanHorz);
                                
                            % Current step is 1. Generate static trajectory at
                            % current position
                            else
                                xq = GetStraightTrajectory(...
                                       X(:,CurrentStep,q),[0 0]',PlanHorz);
                            end
                        end
                        
                    % Else q has not planned at this time step
                    else
                        % Convert agent number q to valid index
                        q_ind = q-1;                        
                        
                        % Check if current step is initial step                       
                        if CurrentStep > 1
                            % Check if p and q are in communication 
                            if dist_btwn_agents(q_ind) <= CommRange
                                % In comm. Use q's last planned trajectory
                                xq = X_plans{CurrentStep-1}(:,:,q);
                            else
                                % Not in comm. Use predicted straight
                                % trajectory with q's current state and last
                                % control
                                xq = GetStraightTrajectory(...
                                    X(:,CurrentStep,q),...
                                    U(:,CurrentStep-1,q),PlanHorz);
                            end
                        % Current step is 1. Generate static trajectory at
                        % current position
                        else
                            xq = GetStraightTrajectory(...
                                    X(:,CurrentStep,q),[0 0]',PlanHorz);
                        end
                    end
                    
                    
                    if (CollisionTable(p,q) == 0)
                        % Define collision avoidance constraints for all time
                        % steps in horizon. No collision constraints at initial
                        % time step
                        for i = 2:(PlanHorz+1)
                            for k = 1:dim
                               % x and y difference for p-q
                               x(k,i) - xq(k,i) >= margin*d - R*c_pq(q_ind,k,i-1);
                               % x and y difference for q-p
                               xq(k,i) - x(k,i) >= margin*d - R*c_qp(q_ind,k,i-1);
                            end

                            % only allow 3 (of 4) constraints to be relaxed (c = 1)
                            % at a time (as long as one is active and satisfied,
                            % there will not be a collision)
                            sum(c_pq(q_ind,:,i-1))+sum(c_qp(q_ind,:,i-1)) <= 3;
                        end
                    end
                end
        cvx_end
        
        % Update X and U for execution horizon
        % Check for infeasible result
        LengthToStore = UpdateEnd - CurrentStep;
        if strcmp(cvx_status,'Infeasible')
          fprintf('\nAgent %i Infeasible at time step %i\n',p,CurrentStep);
          U(:,CurrentStep:(UpdateEnd-1),p) = zeros(2,LengthToStore);
          X(:,(CurrentStep+1):UpdateEnd,p) = X(:,CurrentStep,p).*ones(2,LengthToStore);
        else
            U(:,CurrentStep:(UpdateEnd-1),p) = u(:,1:LengthToStore);
            X(:,(CurrentStep+1):UpdateEnd,p) = x(:,2:(LengthToStore+1));
        end
        
        % Check to see if any of the updated points cause a collision with
        % any of the other agents
        for q = 1:(p-1)
            for FutureTimes = (CurrentStep+1):UpdateEnd
                %if we are in the exclusion zone of the other agent there
                %is a collision
                
                if((abs(X(1,FutureTimes,p) - X(1,FutureTimes,q)) < d) &&...
                        (abs(X(2,FutureTimes,p) - X(2,FutureTimes,q)) < d))
                    %if the collision bool is not set, we have to handle it
                    if(CollisionTable(p,q) == 0)
                        %update the number of collisions
                        NumCollisions = NumCollisions + 1;
                        %update the collision bools for p and q
                        CollisionTable(p,q) = 1;
                        CollisionTable(q,p) = 1;
                    end
                else %we are not in a collision
                    %check to see if our last step was a collision
                    if(CollisionTable(p,q) == 1)
                        %if it is set to 1, clear the bools
                        CollisionTable(p,q) = 0;
                        CollisionTable(q,p) = 0;
                    end
                end
            end
        end
        

        % Store current trajectory in X_plans for all time steps in execution
        % horizon
        for i = 1:LengthToStore
           X_plans{CurrentStep + (i-1)}(:,:,p) = x;
           
           % Ensure accurate current position even for infeasible plan
           X_plans{CurrentStep + (i-1)}(:,1,p) = X(:,CurrentStep,p);

           % Check for arrival if you haven't already arrived
           if (all_opt_times(p) == inf) && ...
                (norm((xf(:,1,p) - X(:,CurrentStep+i,p)),2) <= arrival_tol)  

              % If you have arrived, store arrival time (index 1 is time 0)
              all_opt_times(p) = (CurrentStep + i - 1)*TimeStep;      
           end
        end           
    end
    

    % Update counter by execution horizon (until MaxNumTimeSteps + 1)
    CurrentStep = UpdateEnd;

end

%% Display results

% Output
cpu_time = toc;
opt_time = sum(all_opt_times);

if(NumCollisions > 0)
    opt_time = inf;
end

% display(cpu_time)
% display(opt_time)
% display(NumCollisions)

% Limit output arrays to stop at the last arrival step
X = X(:,1:CurrentStep,:);
U = U(:,1:(CurrentStep-1),:);
%     X_plans = X_plans{1:(CurrentStep-1)};

% Store only plans that were used
temp = cell((CurrentStep-1),1);
for i = 1:length(temp)
    temp{i} = X_plans{i};
end
X_plans = temp;


% Plot results
% PlotTrajectory(X);
           
           
