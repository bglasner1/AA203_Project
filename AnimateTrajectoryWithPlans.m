% AA203 Project
% 6/3/2017
% Function to animate the trajectories defined and display the plans at 
% each step in input cell array X_plans
%
% Input X: 2 x NumTimeSteps+1 x NumAgents

function AnimateTrajectoryWithPlans(X_plans)

% Extract constants
NumTimeSteps = length(X_plans) - 1;
NumAgents = size(X_plans{1},3);

% Size of exclusion zone
d = 1;

% radius of circle of initial positions
radius = 10; 

% Time step
TimeStep = 1;
TimeVector = (0:NumTimeSteps)'*TimeStep;

% plot trajectory
figure
for iter = 1:10
    for i = 1:(NumTimeSteps+1)
        for  p = 1:NumAgents            
            % Plot circle
            t = linspace(0,2*pi,100);
            plot(radius*cos(t),radius*sin(t),'k')
            hold on
            
            % Start and end positions
            plot(X_plans{1}(1,1,p),X_plans{1}(2,1,p),'g.','MarkerSize',15)
            plot(X_plans{end}(1,1,p),X_plans{end}(2,1,p),'r*','MarkerSize',15)
            
            % Check for collisions
            AgentColor = 'b';
            OtherAgents = [1:(p-1),(p+1):NumAgents];
            
            for q = OtherAgents
                if((abs(X_plans{i}(1,1,p) - X_plans{i}(1,1,q)) < d) &&...
                        (abs(X_plans{i}(2,1,p) - X_plans{i}(2,1,q)) < d))
                    
                    AgentColor = 'r';
                    break;                    
                end
            end
            
            
            % Plot current plan
            x = X_plans{i}(1,:,p);
            y = X_plans{i}(2,:,p);            
            plot(x,y,'.-')
            rectangle('Position',[x(1)-d/2,y(1)-d/2,d,d],...
                      'EdgeColor',AgentColor,'LineStyle','--')
        end
        
        hold off
        xlabel('x')
        ylabel('y','Rotation',0)
        title('Trajectory Animation With Plans')
        axis equal
        drawnow
        pause(0.1)%TimeStep)
    end
end