function [pos_est]=LS_POS_aae6102(sat_pos_ECEF,sat_clk,sat_rcvr_data)

%   [dtR, var_dtR] =  LS_POS_aae6102(sat_pos_ECEF,Sat_rcvr_data)%
% INPUT:
% sat_pos_ECEF - ECEF coordinates satellite position (X,Y,Z)
% sat_clk      - satellite clock_error_correction
% sat_rcvr_data- satellite measurement
% OUTPUT:
% pos_est      - User_location
%%%%%
% %Setting

% initial position
pos_ini=[-2694685.473,-4293642.366,3857878.924];
XR=pos_ini;
XR=reshape(XR,1,3);

% satellite position (X,Y,Z)
XS=sat_pos_ECEF;

%satellite topocentric coordinates (azimuth, elevation, distance)
[az, el, dist_] = topocent_gogps(XR, XS);

%cartesian to geodetic conversion of ROVER coordinates
[phiR, lamR, hR] = cart2geod(XR(1), XR(2), XR(3));

%radians to degrees
phiR = phiR * 180 / pi;
lamR = lamR * 180 / pi;

%computation of tropospheric errors
err_tropo = tropo_error_correction(el, hR);

% % Least square setting
dt = [0];
delta_pos = [1e9; 1e9; 1e9; 0];% 
% delta_pos=[-5710;1080;-2610;519450];%
pos_ini=XR;

%Error Free- Pr
pr=sat_rcvr_data(:,3)+sat_clk*2.99792458e8-err_tropo;

%Estimated Position for each step
step_pos=[xyz2llh_deg(pos_ini),pos_ini,0,0];

while ((norm(delta_pos(1:3,1))>1E-4 ))%1e-3
    
    for idx_sv = 1 : size(sat_pos_ECEF,1)
        pos1_pr0(idx_sv) = norm(sat_pos_ECEF(idx_sv,:)-pos_ini);
        y(idx_sv,1) = pr(idx_sv) - pos1_pr0(idx_sv) - delta_pos(4,1);
        H(idx_sv,1:4) = [(pos_ini - sat_pos_ECEF(idx_sv,:))./pos1_pr0(idx_sv),1];     
    end
    
    delta_pos = inv(H'*H)*H'*y;
    pos_ini = pos_ini + delta_pos(1:3,1)';
    dt(1) = dt(1) + delta_pos(4,1);
    step_pos=[step_pos;[ xyz2llh_deg(pos_ini),pos_ini,norm(delta_pos(1:3,1)),dt]];
    
   
end
pos_est = pos_ini;
pr_resi = y - H*delta_pos;


end
%
% %computation of tropospheric errors
function err_tropo = tropo_error_correction(el, h)
h(h < 0) = 0;
%conversion to radians
el = abs(el) * pi/180;
%pressure [mbar]
Pr = 1013.25;
%temperature [K]
Tr = 291.15;
%numerical constants for the algorithm [-] [m] [mbar]
Hr = 50.0;

P = Pr * (1-0.0000226*h).^5.225;
T = Tr - 0.0065*h;
H = Hr * exp(-0.0006396*h);
%linear interpolation
h_a = [0; 500; 1000; 1500; 2000; 2500; 3000; 4000; 5000];
B_a = [1.156; 1.079; 1.006; 0.938; 0.874; 0.813; 0.757; 0.654; 0.563];

t = zeros(length(T),1);
B = zeros(length(T),1);

for i = 1 : length(T)
    
    d = h_a - h;%(i)
    [dmin, j] = min(abs(d));
    if (d(j) > 0)
        index = [j-1; j];
    else
        index = [j; j+1];
    end
    %     (i)
    t(i) = (h- h_a(index(1))) ./ (h_a(index(2)) - h_a(index(1)));
    B(i) = (1-t(i))*B_a(index(1)) + t(i)*B_a(index(2));
end

e = 0.01 * H .* exp(-37.2465 + 0.213166*T - 0.000256908*T.^2);

%tropospheric error
err_tropo = ((0.002277 ./ sin(el)) .* (P - (B ./ (tan(el)).^2)) + (0.002277 ./ sin(el)) .* (1255./T + 0.05) .* e);

end
function [Az, El, D] = topocent_gogps(Xr, Xs)

% SYNTAX:
%   [Az, El, D] = topocent(Xr, Xs);
%
% INPUT:
%   Xr = receiver coordinates (X,Y,Z)
%   Xs = satellite coordinates (X,Y,Z)
%
% OUTPUT:
%   D = rover-satellite distance
%   Az = satellite azimuth
%   El = satellite elevation
%
% DESCRIPTION:
%   Computation of satellite distance, azimuth and elevation with respect to
%   the receiver.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.4.3
%
% Copyright (C) Kai Borre
% Kai Borre 09-26-97
%
% Adapted by Mirko Reguzzoni, Eugenio Realini, 2009
%----------------------------------------------------------------------------------------------
% numel(Xs)
%conversion from geocentric cartesian to geodetic coordinates
[phi, lam, h] = cart2geod(Xr(1), Xr(2), Xr(3)); %#ok<NASGU>

%new origin of the reference system
X0(:,1) = Xr(1) * ones(size(Xs,1),1);
X0(:,2) = Xr(2) * ones(size(Xs,1),1);
X0(:,3) = Xr(3) * ones(size(Xs,1),1);

%computation of topocentric coordinates
cl = cos(lam); sl = sin(lam);
cb = cos(phi); sb = sin(phi);
F = [-sl -sb*cl cb*cl;
      cl -sb*sl cb*sl;
       0    cb   sb];
local_vector = F' * (Xs-X0)';
E = local_vector(1,:)';
N = local_vector(2,:)';
U = local_vector(3,:)';
hor_dis = sqrt(E.^2 + N.^2);

if hor_dis < 1.e-20
   %azimuth computation
   Az = 0;
   %elevation computation
   El = 90;
else
   %azimuth computation
   Az = atan2(E,N)/pi*180;
   %elevation computation
   El = atan2(U,hor_dis)/pi*180;
end

i = find(Az < 0);
Az(i) = Az(i)+360;

%receiver-satellite distance
D = sqrt(sum((Xs-X0).^2 ,2));
end

