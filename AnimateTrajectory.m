function output = AnimateTrajectory(X)

% Extract constants
NumTimeSteps = size(X,2) - 1;
NumAgents = size(X,3);

% Size of exclusion zone
d = 1;

% radius of circle of initial positions
radius = 10; 

% Time step
TimeStep = 1;
TimeVector = (0:NumTimeSteps)'*TimeStep;

% plot trajectory
figure
xlabel('x')
ylabel('y')
title('Trajectory Animation')


for iter = 1:10
    for i = 1:(NumTimeSteps+1)
        for  p = 1:NumAgents            
            % Plot circle
            t = linspace(0,2*pi,100);
            plot(radius*cos(t),radius*sin(t),'k')
            hold on
            
            % Start and end positions
            plot(X(1,1,p),X(2,1,p),'g.','MarkerSize',10)
%             plot(X(1,end,p),X(2,end,p),'r*','MarkerSize',10)
            
            % Current position
            x = X(1,i,p);
            y = X(2,i,p);            
            plot(x,y,'k.')
            rectangle('Position',[x-d/2,y-d/2,d,d],...
                      'EdgeColor','b','LineStyle','--')
        end
        
        hold off
        axis equal
        drawnow
        pause(0.1)%TimeStep)
    end
end