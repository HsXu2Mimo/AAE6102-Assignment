# AAE6102-Assignment (2021-10-31)


## Intorduction

The aim of the assessment is to using the least-squares (LS) approach to solve the receiver location. 
The raw measuremnt is an 8x7 matrix containing raw ranging information as rcvr.dat
The ephemeris data is an 8 x 24 matrix as eph.dat

## Instructions
1. Download 'lib' and 'code' folders
   - download the zip file and extract to desired folder
   - add the 'lib' into the matlab path 
2. Open file '[Main_code](Main_code.m)' in MATLAB
3. Press 'Run'

## Code Explanation
The code can be divided into two main part. 
1. The first part is to solve the satellites’ ECEF position.
2. The second partis using LS method to solve the receiver position and clock offset
3. The flowchart is as follows, 
<p align="center">
<img src="img/Fig.1 Mian flowchart of code.png ">
</p>
