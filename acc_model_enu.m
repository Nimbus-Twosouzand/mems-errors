clear all; close all; clc

% number of points
N = 2000; 

% memory allocation
C_rpy_ned = zeros(3,3);
ya_rpy = zeros(3,N);
RPY_new = zeros(N,3);
err_RPY = zeros(N,3);
M_rpy = zeros(3,N);
A_rpy = zeros(3,N);
ym_rpy = zeros(3,N);
Azimuth_magn = zeros(1,N);
err_Azimuth = zeros(1,N);
Azimuth = zeros(1,N);
ym_enu = zeros(3,N);

% true roll, pitch, yaw angles
% random limited angles 
R = (rand(N,1)*2*pi - pi)* 165/180;
P = (rand(N,1)*pi - pi/2)* 75/90; 
% Y = (rand(N,1)*2*pi - pi)* 165/180; 

% constant angles
% R = ones(N,1)*deg2rad(180);  
% P = ones(N,1)*deg2rad(90);
% Y = ones(N,1)*deg2rad(180);

% zero angles
% R = zeros(N,1);                    
% P = zeros(N,1);
Y = zeros(N,1);

% angles matrix
RPY = [R P Y];            

% true magnetic induction vector
M_enu = [0; 11; -8] * 1e-6 * 1;  % uT
A_enu = [0; 0; -1];  % g

%--------------------------------Choose IMU--------------------------------
[acc_parameters, magn_parameters, imu_name] = get_MPU9250A_parameters();
%[acc_parameters, magn_parameters, imu_name] = get_ADIS16488A_parameters();
%--------------------------------------------------------------------------

% calculations
for i = 1:N
   
  % quaternion to matrix convertion
  C_rpy_enu(1:3,1:3) = rpy2mat(RPY(i,1:3)');  
  
  % true acceleration vector
  A_rpy(1:3,i) = C_rpy_enu(1:3,1:3)' * A_enu; 
  
  % true magnetic field vector
  M_rpy(1:3,i) = C_rpy_enu(1:3,1:3)' * M_enu; 
  
  % true magnetic azimuth angle
  Azimuth(i) = Y(i);                                      
  
  % accelerometer error model application 
  ya_rpy(1:3,i)= acc_meas(A_rpy(1:3,i), acc_parameters); 
  % ya_rpy(1:3,i) = A_rpy(1:3,i); % using IDEAL accelerometers
  
  % magnetometer error model application 
  ym_rpy(1:3,i) = m_meas(M_rpy(1:3,i), magn_parameters); 

  % angles calculating by true accelaration vector 
  % RPY_new1 = angle_calc(A_rpy(1:3,i));  
  
  % angles calculating by accelerometer measurements
  RPY_new__ = angle_calc(ya_rpy(1:3,i));                    
  RPY_new(i,1:3)= RPY_new__; 
  
  % magn to horizontal plane
  C_rpy_enu_new(1:3,1:3) = rpy2mat([RPY_new(i,1:2)'; 0]); 
  
  % magnetometer measurements convertion from body frame coordinates to horizontal
  ym_enu(1:3,i) = C_rpy_enu_new(1:3,1:3) * ym_rpy(1:3,i); 
  
  % using IDEAL magnetometers
  % ym_enu(1:3,i) = C_rpy_enu_new(1:3,1:3) * M_rpy(1:3,i);
  
  % azimuth angle calculation
  Azimuth_magn(i) = atan2(ym_enu(1,i),ym_enu(2,i));       
 
  % angles errors calculation
  err_RPY(i,1:3) = RPY(i,1:3) - RPY_new(i,1:3);           
  err_Azimuth(i) = Azimuth_magn(i) -  Azimuth(i); 
  
  % angles correction 
  if err_RPY(i,1) > pi
    err_RPY(i,1) = 2*pi - err_RPY(i,1);
  elseif err_RPY(i,1) < -pi
    err_RPY(i,1) = 2*pi + err_RPY(i,1);
  end
  if err_Azimuth(i) > pi
    err_Azimuth(i) = 2*pi - err_Azimuth(i);
  elseif err_Azimuth(i) < -pi
    err_Azimuth(i) = 2*pi + err_Azimuth(i);
  end
end

% rad2deg
err_PPY_deg = err_RPY*180/pi;
err_Azimuth_deg = err_Azimuth*180/pi;

% plotting
% roll error vs roll & pitch

figure(1);
plot3(R*180/pi, P*180/pi, err_PPY_deg(:,1), '.r')
ax = gca;
set(ax,'xtick',(-180:90:180));
set(ax,'ytick',(-90:30:90));
set(ax,'ztick',(-30:10:30));
%legend(['roll error vs roll & pitch for ' imu_name])
title(['roll error vs roll & pitch for ' imu_name])
grid on
xlabel('roll, deg')
ylabel('pitch, deg')
zlabel('roll error, deg')
grid on
% cmnstr = 'r_err_vs_r_p_err.png';
% print(figure(1), cmnstr, '-dpng', '-r300');

% % pitch error vs roll & pitch
figure(2);
plot3(R*180/pi, P*180/pi, err_PPY_deg(:,2),'.r')
ax = gca;
set(ax,'xtick',(-180:90:180));
set(ax,'ytick',(-90:90:90));
set(ax,'ztick',(-10:2:10));
title(['pitch error vs roll & pitch for ' imu_name])
xlabel('roll, deg')
ylabel('pitch, deg')
zlabel('pitch error, deg')
grid on
% cmnstr = 'p_err_vs_r_p_err.png';
% print(figure(2), cmnstr, '-dpng', '-r300');
             
% to plot the following dependencies correctly you must set one of the angles by zeros 
% azimuth error vs roll & pitch
figure(3);
plot3(R*180/pi, P*180/pi, err_Azimuth_deg, '.b')
ax = gca;
set(ax,'xtick',(-180:90:180));
set(ax,'ytick',(-90:30:90));
set(ax,'ztick',(-50:10:50));
title(['azimuth error vs roll & pitch' imu_name])
xlabel('roll, deg')
ylabel('pitch, deg')
zlabel('azimuth error, deg')
grid on
% cmnstr = 'az_err_vs_r_p.png';
% print(figure(3), cmnstr, '-dpng', '-r300');

% % azimuth error vs roll & azimuth
% figure(4);
% plot3(R*180/pi, Y*180/pi, err_Azimuth_deg, '.r')
% ax = gca;
% set(ax,'xtick',(-180:90:180));
% set(ax,'ytick',(-180:90:180));
% set(ax,'ztick',(-20:5:20));
% title(['azimuth error vs roll & azimuth' imu_name])
% xlabel('roll, deg')
% ylabel('azimuth, deg')
% zlabel('azimuth error, deg')
% grid on
% cmnstr = 'az_err_vs_r_az.png';
% print(figure(4), cmnstr, '-dpng', '-r300');

% azimuth error vs pitch & azimuth
% figure(5);
% plot3(P*180/pi, Y*180/pi, err_Azimuth_deg, '.r')
% ax = gca;
% set(ax,'xtick',(-90:30:90));
% set(ax,'ytick',(-180:90:180));
% set(ax,'ztick',(-180:60:180));
% title(['azimuth error vs pitch & azimuth' imu_name])
% xlabel('pitch, deg')
% ylabel('azimuth, deg')
% zlabel('azimuth error')
% grid on
% cmnstr = 'az_err_vs_p_az.png';
% print(figure(5), cmnstr, '-dpng', '-r300');
