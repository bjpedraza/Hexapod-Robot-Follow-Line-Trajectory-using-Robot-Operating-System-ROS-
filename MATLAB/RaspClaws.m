
function RaspClaws(varargin)

    opt.niterations = 500;
    opt.movie = [];
    
    opt = tb_optparse(opt, varargin);
    
L1 = 0.067; L2 = 0.05;

fprintf('create leg model\n');

% create the leg links based on DH parameters
%                    theta   d     a  alpha  
links(1) = Link([    0       0    L1   pi/2 ], 'standard');
links(2) = Link([    0       0   -L2   0   ], 'standard');

% now create a robot to represent a single leg
leg = SerialLink(links, 'name', 'leg', 'offset', [pi/2 -pi/2]);
%leg.plot([0 0]);

% define the key parameters of the gait trajectory, walking in the
% x-direction
xf = 5; xb = -xf;   % forward and backward limits for foot on ground
y = 9;              % distance of foot from body along y-axis
zu = 5; zd = 10;     % height of foot when up and down
% define the rectangular path taken by the foot

segments = [xf y zd; xb y zd; xb 11 zu; xf 11 zu] * 0.01;

% build the gait. the points are:
%   1 start of walking stroke
%   2 end of walking stroke
%   3 end of foot raise
%   4 foot raised and forward
%
% The segments times are :
%   1->2  3s
%   2->3  0.5s
%   3->4  1s
%   4->1  0.5ss
%
% A total of 4s, of which 3s is walking and 1s is reset.  At 0.01s sample
% time this is exactly 400 steps long.
%
% We use a finite acceleration time to get a nice smooth path, which means
% that the foot never actually goes through any of these points.  This
% makes setting the initial robot pose and velocity difficult.
%
% Intead we create a longer cyclic path: 1, 2, 3, 4, 1, 2, 3, 4. The
% first 1->2 segment includes the initial ramp up, and the final 3->4
% has the slow down.  However the middle 2->3->4->1 is smooth cyclic
% motion so we "cut it out" and use it.
fprintf('create trajectory\n');

segments = [segments; segments];
tseg = [3 0.25 0.5 0.25]';
tseg = [tseg; tseg];
x = mstraj(segments, [], tseg, segments(1,:), 0.01, 0.1);

% pull out the cycle
fprintf('inverse kinematics (this will take a while)...');
xcycle = x(100:500,:);
qcycle = leg.ikine( SE3(xcycle), 'mask', [0 1 1 0 0 0] );

% dimensions of the robot's rectangular body, width and height, the legs
% are at each corner.
W = 0.1; L = 0.2;

% a bit of optimization.  We use a lot of plotting options to 
% make the animation fast: turn off annotations like wrist axes, ground
% shadow, joint axes, no smooth shading.  Rather than parse the switches 
% each cycle we pre-digest them here into a plotopt struct.
% plotopt = leg.plot({'noraise', 'nobase', 'noshadow', ...
%     'nowrist', 'nojaxes'});
% plotopt = leg.plot({'noraise', 'norender', 'nobase', 'noshadow', ...
%     'nowrist', 'nojaxes', 'ortho'});

fprintf('\nanimate\n');

plotopt = {'noraise', 'nobase', 'noshadow', 'nowrist', 'nojaxes', 'delay', 0};

% create 4 leg robots.  Each is a clone of the leg robot we built above,
% has a unique name, and a base transform to represent it's position
% on the body of the walking robot.
legs(1) = SerialLink(leg, 'name', 'leg1');
legs(2) = SerialLink(leg, 'name', 'leg2', 'base', transl(-L/2, 0, 0));
legs(3) = SerialLink(leg, 'name', 'leg3', 'base', transl(-L, 0, 0));
legs(4) = SerialLink(leg, 'name', 'leg4', 'base', transl(-L, -W, 0)*trotz(pi));
legs(5) = SerialLink(leg, 'name', 'leg5', 'base', transl(-L/2, -W, 0)*trotz(pi));
legs(6) = SerialLink(leg, 'name', 'leg6', 'base', transl(0, -W, 0)*trotz(pi));


figure;
clf; axis([-0.3 0.1 -0.25 0.15 -0.10 0.2]); set(gca,'Zdir', 'reverse')
hold on;
% draw the robot's body
patch([0 -L -L 0], [0 0 -W -W], [0 0 0 0], ...
    'FaceColor', 'r', 'FaceAlpha', 0.5)
legs(1).plot([0 0], plotopt{:});
legs(2).plot([0 0], plotopt{:});
legs(3).plot([0 0], plotopt{:});
legs(4).plot([0 0], plotopt{:});
legs(5).plot([0 0], plotopt{:});
legs(6).plot([0 0], plotopt{:});

%figure;
% create a fixed size axis for the robot, and set z positive downward
%clf; axis([-0.3 0.1 -0.2 0.2 -0.15 0.05]); set(gca,'Zdir', 'reverse')
%hold on

% instantiate each robot in the axes
%for i=1:6
%    legs(i).plot(qcycle(1,:), plotopt{:});
%end
%hold off

% walk!
k = 1;
A = Animate(opt.movie);

for i=1:opt.niterations
    legs(1).animate( gait(qcycle, k, 0,   0));
    legs(2).animate( gait(qcycle, k, 100, 0));
    legs(3).animate( gait(qcycle, k, 200, 0));
    legs(4).animate( gait(qcycle, k, 300, 1));
    legs(5).animate( gait(qcycle, k, 400, 1));
    legs(6).animate( gait(qcycle, k, 500, 1));
    drawnow
    k = k+1;
    A.add();
end

end
