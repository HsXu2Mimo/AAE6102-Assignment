clc
clear all
close all

% % Data input%
% read ephemeris data
eph_data=load('Assignment\Data\eph.dat');

% % the detail info of eph_data
% Column1:rcvr_tow;   --receiver time of week(s)
% Column 2: svid;   -- satellite PRN number (1 – 32)
% Column 3: toc;  -- reference time of clock parameters (s)
% Column 4: toe;   -- reference time of ephemeris parameters (s)
% Column 5: af0;  -- clock correction coefficient – group delay (s)
% Column 6: af1;   -- clock correction coefficient (s/s)
% Column 7: af2;    -- clock correction coefficient (s/s/s)
% Column 8: ura;   -- user range accuracy (m)
% Column 9: e;   -- eccentricity (-)
% Column 10: sqrta;   -- square root of semi-major axis a (m**1/2)
% Column 11: dn;   -- mean motion correction (r/s)
% Column 12: m0;   -- mean anomaly at reference time (r)
% Column 13: w;    -- argument of perigee (r)
% Column 14: omg0;    -- right ascension (r)
% Column 15: i0;   -- inclination angle at reference time (r)
% Column 16: odot;   -- rate of right ascension (r/s)
% Column 17: idot;    -- rate of inclination angle (r/s)
% Column 18: cus;   -- argument of latitude correction, sine (r)
% Column 19: cuc;   -- argument of latitude correction, cosine (r)
% Column 20: cis;  -- inclination correction, sine (r)
% Column 21: cic;   -- inclination correction, cosine (r)
% Column 22: crs;  -- radius correction, sine (m)
% Column 23: crc;   -- radius correction, cosine (m)
% Column 24: iod;  -- issue of data number

% read measurements data
rcvr_data=load('Assignment\Data\rcvr.dat');
% Column 1: rcvr_tow;   -- receiver time of week (s)
% Column 2: svid;   -- satellite PRN number (1 – 32)
% Column 3: pr;   -- pseudorange (m)
% Column 4: cycles;   -- number of accumulated cycles
% Column 5: phase;   -- to convert to (0 – 359.99) mult. by 360/2048
% Column 6: slp_dtct;   -- 0 = no cycle slip detected; non 0 = cycle slip
% Column 7: snr_dbhz;    -- signal to noise ratio (dB-Hz)


% % % sort the rcvr_data and eph_data into PRN order
eph_data=sortrows(eph_data,2);
rcvr_data=sortrows(rcvr_data,2);

%speed of light.
c = 2.99792458e8;
% % transmission_time of each sat
time_tx_all=440992-rcvr_data(:,3)./c;rcvr_data(:,1)

%%%
%%% For each satellites
%%% calculate Sat Position in ECEF

for idex_sat=1:size(eph_data,1)
    eph_data_one=eph_data(idex_sat,:); % ephemeris 
    time_tx=time_tx_all(idex_sat,:);   % transmission_time 
    time_rec=rcvr_data(idex_sat,1);    % local_time of Receiver
    [sat_pos_Eci(idex_sat,:),sat_pos_ECEF(idex_sat,:),sat_clock_error_correction(idex_sat,:)]......
    =satellite_positioning_aae6102(eph_data_one,time_tx,time_rec);%


end

% % Data output%
sat_clk=sat_clock_error_correction;
Sat_rcvr_data=rcvr_data;
% pos_est is the User location in ECEF coordinates
[pos_est]=LS_POS_aae6102(sat_pos_ECEF,sat_clk,Sat_rcvr_data);



