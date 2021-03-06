% AA203 Project
% 6/3/2017
% Function to animate the trajectories defined in input matrix X
%
% Input X: 2 x NumTimeSteps+1 x NumAgents

function AnimateTrajectory(X)

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

% Make video
v = VideoWriter('Videos/newvideo.avi');
v.FrameRate = 5; % set frame rate
open(v);


% plot trajectory
figure
for iter = 1%:10
    for i = 1:(NumTimeSteps+1)
        for  p = 1:NumAgents            
            % Plot circle
            t = linspace(0,2*pi,100);
            plot(radius*cos(t),radius*sin(t),'k')
            hold on
            
            % Start and end positions
            plot(X(1,1,p),X(2,1,p),'g.','MarkerSize',15)
            plot(X(1,end,p),X(2,end,p),'r*','MarkerSize',15)
            
            % Check for collisions
            AgentColor = 'b';
            OtherAgents = [1:(p-1),(p+1):NumAgents];
            
            for q = OtherAgents
                if((abs(X(1,i,p) - X(1,i,q)) < d) &&...
                        (abs(X(2,i,p) - X(2,i,q)) < d))
                    
                    AgentColor = 'r';
                    break;                    
                end
            end
            
            
            % Current position
            x = X(1,i,p);
            y = X(2,i,p);            
            plot(x,y,'k.')
            rectangle('Position',[x-d/2,y-d/2,d,d],...
                      'EdgeColor',AgentColor,'LineStyle','--')
        end
        
        hold off
        xlabel('x')
        ylabel('y','Rotation',0)
        title('R_{comm}=0')
        axis([-(radius+d) (radius+d) -(radius+d) (radius+d)])
        axis equal
%         drawnow
%         pause(0.1)%TimeStep)
        
        frame = getframe(gcf);
        writeVideo(v,frame);
    end
end