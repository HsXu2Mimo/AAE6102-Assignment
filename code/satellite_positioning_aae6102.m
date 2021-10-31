function [sat_pos_Eci,sat_pos_ECEF,sat_clock_error_correction]=satellite_positioning_aae6102(eph_data_one,time_tx,time_rec)%

% SYNTAX:
%   [sat_pos_Eci] = satellite_positioning_aae6102(eph_data_one, time_tx);

%%% Input:
%   eph_data_one = ephemeris matrix
%   time_tx=transmission_time
% OUTPUT:
%   sat_pos_Eci  =ECI coordinates satellite position (X,Y,Z)
%   sat_pos_ECEF =ECEF coordinates satellite position (X,Y,Z)



% Fixed data
%speed of light.
c = 2.99792458e8;
%   WGS 84 value of the earth's gravitational constant for GPS user
GM = 3.986005e14;
%   WGS 84 value of the earth's rotation rate
omge = 7.2921151467e-5; %wedot% Ωomge = 7.2921151467 x 10-5 rad/sec

%   CIRCLE_RAD;
cr = 2*pi;%6.283185307179600;


% time of receiver local time
% time_rec=440992.001734540;% 440992
% time_tx=time_tx_all(1);


%get ephemerides parameters

toc=eph_data_one(3);%reference time of clock parameters (s)

toe=eph_data_one(4);%reference time of ephemeris parameters (s)

af0=eph_data_one(5);%clock correction coefficient – group delay (s)

af1=eph_data_one(6);%clock correction coefficient (s/s)

af2=eph_data_one(7);%clock correction coefficient (s/s/s)

ura=eph_data_one(8);%user range accuracy (m)

ecc=eph_data_one(9);%eccentricity

sqrta=eph_data_one(10);% square root of semi-major axis a (m**1/2)

dn=eph_data_one(11);% mean motion correction (r/s)

M0=eph_data_one(12);% mean anomaly at reference time (r)

w=eph_data_one(13);% argument of perigee (r)

omg0=eph_data_one(14);% right ascension (r)

i0=eph_data_one(15);%  inclination angle at reference time (r)

odot=eph_data_one(16);%   rate of right ascension (r/s)

IDOT=eph_data_one(17);%   rate of inclination angle (r/s)

cus=eph_data_one(18);%  -- argument of latitude correction, sine (r)

cuc=eph_data_one(19);%  -- argument of latitude correction, cosine (r)

cis=eph_data_one(20);%inclination correction, sine (r)

cic=eph_data_one(21);%inclination correction, cosine (r)

crs=eph_data_one(22);% radius correction, sine (m)

crc=eph_data_one(23);%radius correction, cosine (m)

iod=eph_data_one(24);%issue of data number;
%% Step 1.	Calculate the XYZ positions for all valid satellites at time 440992
%semi-major axis
A  = sqrta*sqrta;
%time from the ephemerides reference epoch

time = time_tx - toe;
tk = time;
if time > 302400 %half_week% seconds
    tk = time - 2*302400;
elseif time < -302400
    tk = time + 2*302400;
end

%computed mean motion [rad/sec]
n0 = sqrt(GM/A^3);
%corrected mean motion [rad/sec]
n  = n0 + dn;
%mean anomaly
Mk = M0 + n*tk;
% % Kepler's Equation for Eccentric Anomaly
Mk = rem(Mk+cr,cr);
Ek = Mk;

for i = 1 : 14%10%max_iter
    Ek_old = Ek;
    Ek = Mk+ecc*sin(Ek);
    dEk = rem(Ek-Ek_old,cr);
    if abs(dEk) < 1.e-12
        break
    end
end

Ek = rem(Ek+cr,cr);
% %
%true anomaly
fk = atan2(sqrt(1-ecc^2)*sin(Ek), cos(Ek) - ecc);
%argument of latitude
phik = fk + w;
phik = rem(phik,cr);

%Corrected Argument of Latitude
delt_uk=cuc*cos(2*phik) + cus*sin(2*phik);

%Corrected Radius
delt_rk=crc*cos(2*phik) + crs*sin(2*phik);

%Corrected Inclination
delt_uik=cic*cos(2*phik) + cis*sin(2*phik);

%corrected argument of latitude
uk = phik  + delt_uk;

%corrected radial distance
rk = A*(1 - ecc*cos(Ek)) + delt_rk;

%corrected inclination of the orbital plane
ik = i0 + IDOT*tk + delt_uik;

%satellite positions in the orbital plane
x1k = cos(uk)*rk;
y1k = sin(uk)*rk;

%corrected longitude of the ascending node
Omegak = omg0 + (odot - omge)*tk - omge*toe;
Omegak = rem(Omegak + cr, cr);

%satellite Earth-fixed coordinates (X,Y,Z)
xk = x1k*cos(Omegak) - y1k*cos(ik)*sin(Omegak);
yk = x1k*sin(Omegak) + y1k*cos(ik)*cos(Omegak);
zk = y1k*sin(ik);

sat_pos_Eci=[xk,yk,zk];

%ECI 2 ECEF
% travel_time=time_tx-4.409920017345400e+05;%440992 time_rec
travel_time=time_rec-time_tx;% time_rec：440992
omegatau = omge * travel_time;

%build a rotation matrix
R3 = [ cos(omegatau)    sin(omegatau)   0;
    -sin(omegatau)    cos(omegatau)   0;
    0                0               1];

%apply the rotation
sat_pos_ECEF =sum( R3 .* sat_pos_Eci,2);

%% Step 2.	Determine the broadcast satellite clock error
% sat_clock_error_correction
% The Satclk relativistic correction term 
sat_clk_relativistic = -4.442807633e-10 * ecc * sqrta * sin(Ek);

% The SV PRN code phase offset
sat_clock_error_correction = (af2 * (time_tx-toc) + af1) * (time_tx-toc) + af0+sat_clk_relativistic;

end



