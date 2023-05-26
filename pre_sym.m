% Simulating the gyroscope measurements takes some time. To avoid this, the
% measurements were generated and saved to a MAT-file. By default, this
% example using the MAT-file. To generate the measurements instead, change
% this logical variable to true.
clc; clear all; close all;

IMU = imuSensor('accel-gyro')