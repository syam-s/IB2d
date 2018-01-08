%-------------------------------------------------------------------------------------------------------------------%
%
% IB2d is an Immersed Boundary Code (IB) for solving fully coupled non-linear 
% 	fluid-structure interaction models. This version of the code is based off of
%	Peskin's Immersed Boundary Method Paper in Acta Numerica, 2002.
%
% Author: Nicholas A. Battista
% Email:  nickabattista@gmail.com
% Date Created: September 9th, 2016
% Institution: UNC-CH
%
% This code is capable of creating Lagrangian Structures using:
% 	1. Springs
% 	2. Beams (torsional springs, non-invariant beams)
% 	3. Target Points
%	4. Muscle-Model (combined Force-Length-Velocity model, "HIll+(Length-Tension)")
%
% One is able to update those Lagrangian Structure parameters, e.g., spring constants, resting lengths, etc
% 
% There are a number of built in Examples, mostly used for teaching purposes. 
% 
% If you would like us to add a specific muscle model, please let Nick (nickabattista@gmail.com) know.
%
%--------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the geometry and prints associated input files
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Make_Your_Geometry_and_Input_Files()

%
% Grid Parameters (MAKE SURE MATCHES IN input2d !!!)
%
Nx =  1024;      % # of Eulerian Grid Pts. in x-Direction (MUST BE EVEN!!!)
Lx = 1.0;        % Length of Eulerian Grid in x-Direction
dx = Lx/Nx;      % Grid spatial resolution

%
% Immersed Structure Geometric / Dynamic Parameters %
%
ds = 0.5*dx;                % Lagrangian Pt. Spacing (2x resolution of Eulerian grid)
struct_name = 'sea_spider'; % Name for .vertex, .spring, etc files. (must match what's in 'input2d')
legD = 0.1;                 % leg diameter
gutD = 0.5*0.1;             % gut diameter

% Call function to construct geometry
[xLag,yLag,Ninfo] = give_Me_Immsersed_Boundary_Geometry(ds,Nx,Lx,legD,gutD);

% Plot Geometry to test
plot(xLag,yLag,'r-'); hold on;
plot(xLag,yLag,'*'); hold on;
xlabel('x'); ylabel('y');
axis([0 Lx 0 Lx]);



% Prints .vertex file!
print_Lagrangian_Vertices(xLag,yLag,struct_name);


% Prints .spring file!
k_Spring_Adj = 2.5e4;                 % Spring stiffness (adjacent lag. pts)
k_Spring_Across = 1e2;                % Spring stiffness (across)
ds_Adj = ds;                          % Spring resting length (adjacent)
ds_Across = legD;                     % Spring resting length (across)
print_Lagrangian_Springs(xLag,yLag,k_Spring_Adj,k_Spring_Across,ds_Adj,ds_Across,struct_name,Ninfo)


% Prints .beam file!
k_Beam = 1e3;               % Beam Stiffness (does not need to be equal for all beams)
C = 0;                      % "Curvature" of initial configuration
print_Lagrangian_Beams(xLag,yLag,k_Beam,C,struct_name,Ninfo);


% Prints .target file!
k_Target = 2e5;
print_Lagrangian_Target_Pts(xLag,k_Target,struct_name,Ninfo);

% Prints .porous file!
alpha = 1e-4; 
print_Lagrangian_Porosity(xLag,alpha,struct_name,Ninfo)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints VERTEX points to a file called 'struct_name'.vertex
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Vertices(xLag,yLag,struct_name)

    N = length(xLag); % Total # of Lag. Pts

    vertex_fid = fopen([struct_name '.vertex'], 'w');

    fprintf(vertex_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = 1:N
        X_v = xLag(s);
        Y_v = yLag(s);
        fprintf(vertex_fid, '%1.16e %1.16e\n', X_v, Y_v);
    end

    fclose(vertex_fid);

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints TARGET points to a file called 'struct_name'.target
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Target_Pts(xLag,k_Target,struct_name,Ninfo)

    % Ninfo(2): # of lag. pts. before leg (outer tube) geometry

    N = length(xLag)-Ninfo(2);

    target_fid = fopen([struct_name '.target'], 'w');

    fprintf(target_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = Ninfo(2)+1:length(xLag)
        fprintf(target_fid, '%d %1.16e\n', s, k_Target);
    end

    fclose(target_fid);   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints POROSITY points to a file called 'struct_name'.porous
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Porosity(xLag,alpha,struct_name,Ninfo)

    % Ninfo(2): # of lag. pts. before leg (outer tube) geometry

    N = length(xLag)-Ninfo(2);
    
    porous_fid = fopen([struct_name '.porous'], 'w');

    fprintf(porous_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = Ninfo(2)+1:length(xLag)
        if s == Ninfo(2)+1
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,-2);      
        elseif s == Ninfo(2)+2
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,-1);
        elseif s== Ninfo(3)-1
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,1);
        elseif s==Ninfo(3)
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,2);
        elseif s == Ninfo(3)+1
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,-2);      
        elseif s == Ninfo(3)+2
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,-1);
        elseif s== length(xLag)-1
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,1);
        elseif s== length(xLag)
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,2);
        else
            fprintf(porous_fid, '%d %1.16e %1.16e\n', s, alpha,0);
        end
    end

    fclose(porous_fid); 
        
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints SPRING points to a file called 'struct_name'.spring
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Springs(xLag,yLag,k_Spring_Adj,k_Spring_Across,ds_Adj,ds_Across,struct_name,Ninfo)

    N = Ninfo(2)-2 + Ninfo(1); % adjacent and then across

    spring_fid = fopen([struct_name '.spring'], 'w');

    fprintf(spring_fid, '%d\n', N );    % Print # of springs 

    %SPRINGS ADJACENT VERTICES (top)
    for s = 1:Ninfo(1)-1
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring_Adj, ds_Adj);  
    end
    
    %SPRINGS ADJACENT VERTICES (bot)
    for s = Ninfo(1)+1:Ninfo(2)-1
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring_Adj, ds_Adj);  
    end
    
    %SPRINGS ACROSS GUT
    for s = 1:Ninfo(1)
        sTOP = s;
        sBOT = s+Ninfo(1);
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', sTOP, sBOT, k_Spring_Across, ds_Across);  
    end
    
    fclose(spring_fid);      

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints BEAM (Torsional Spring) points to a file called 'struct_name'.beam
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Beams(xLag,yLag,k_Beam,C,struct_name,Ninfo)

    % k_Beam: beam stiffness
    % C: beam curvature
    
    N = Ninfo(2)-4; % among adjacent lag points

    beam_fid = fopen([struct_name '.beam'], 'w');

    fprintf(beam_fid, '%d\n', N );

    %spring_force = kappa_spring*ds/(ds^2);

    %BEAMS BETWEEN VERTICES (TOP)
    for s = 2:Ninfo(1)-1
        fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C );  
    end
    
    %BEAMS BETWEEN VERTICES (BOT)
    for s = Ninfo(1)+2:Ninfo(2)-1
        fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C );  
    end
    
   
    fclose(beam_fid); 
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: computes "curvature" of starting configuration
% 
% NOTE: not curvature in the traditional geometric sense, in the 'discrete'
% sense through cross product.
%
% NOTE: assumes a CLOSED structure
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function C = compute_Curvatures(xLag,yLag)

N = length(xLag);
C = zeros( N );

%Note: needs to be done same order as you print .beam file!
for i=1:N
   
   % Pts Xp -> Xq -> Xr (same as beam force calc.)
   
   if ( (i > 1) && (i < N) )
   
        Xp = xLag(i-1); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(i-1); Yq = yLag(i); Yr = yLag(i+1);
   
   elseif (i==1)
       
        Xp = xLag(N); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(N); Yq = yLag(i); Yr = yLag(i+1);
       
   elseif (i==N)
       
        Xp = xLag(N-1); Xq = xLag(N); Xr = xLag(1);
        Yp = yLag(N-1); Yq = yLag(N); Yr = yLag(1);
       
   end
       
   C(i) = (Xr-Xq)*(Yq-Yp) - (Yr-Yq)*(Xq-Xp); %Cross product btwn vectors
      
end
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the Lagrangian structure geometry
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [xLag,yLag,Ninfo] = give_Me_Immsersed_Boundary_Geometry(ds,Nx,Lx,legD,gutD)
 
% ds:   Lagrangian pt. spacing
% Nx:   Eulerian grid resolution
% legD: leg (tube) diameter
% gutD: gut diameter

% GUT/LEG Useful Points
xTubeHor = 0.2*Lx:ds:0.8*Lx;
yTubeHor = 0.5*(1/8)*Lx*ones(1,length(xTubeHor));

%
% GUT (innter tube) Vertices
%
yGutTop = yTubeHor+gutD/2;
yGutBot = yTubeHor-gutD/2;
xGut = [xTubeHor xTubeHor];
yGut = [yGutTop yGutBot];

%
% LEG (outer tube) Vertices
%
yLegTop = yTubeHor+legD/2;
yLegBot = yTubeHor-legD/2;

yTubeLeft = 0.5*(1/8)-legD/2+ds:ds:0.5*(1/8)+legD/2-ds;
xTubeLeft = 0.2*Lx*ones(1,length(yTubeLeft));

% INCLUDING FOOT (left side)
%xLeg = [xTubeHor xTubeHor xTubeLeft];
%yLeg = [yLegTop  yLegBot  yTubeLeft];

% NOT INCLUDING FOOT (left side)
xLeg = [xTubeHor xTubeHor];
yLeg = [yLegTop  yLegBot ];

%
% Combine Geometries
% 
xLag = [xGut xLeg];
yLag = [yGut yLeg];

%
% Number of points info
%
Ninfo(1) = length(xGut)/2; % # pts along top of gut
Ninfo(2) = length(xGut);   % # pts before start of leg
Ninfo(3) = length(xGut)+length(xLeg)/2; % # of points before bottom of leg
% TESTING (i.e., PLOT IT, yo!)
%plot(xGut,yGut,'r*'); hold on
%plot(xLeg,yLeg,'b*'); hold on;
%axis([0 Lx 0 0.125*Lx]);
%pause();

