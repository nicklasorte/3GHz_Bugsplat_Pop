clear;
clc;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\3.1GHz_Army';
cd(folder1)
addpath(folder1)
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Basic_Functions')
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\General_Movelist')  %%%%%%%%This is another Github repo
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\General_Terrestrial_Pathloss')  %%%%%%%%This is another Github repo
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Generic_Bugsplat')
addpath('C:\Local Matlab Data') %%%%%%%One Drive Error with mat files
pause(0.1)


%%%%%%%%%%%%%%%%%Base Station Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%1) Azimuth -180~~180
%%%2) Rural
%%%3) Suburban
%%%4) Urban
aas_zero_elevation_data=zeros(361,4);
aas_zero_elevation_data(:,1)=-180:1:180;
%%%%AAS Reduction in Gain to Max Gain (0dB is 0dB reduction)
bs_down_tilt_reduction=abs(max(aas_zero_elevation_data(:,[2:4]))) %%%%%%%%Downtilt dB Value for Rural/Suburban/Urban
norm_aas_zero_elevation_data=horzcat(aas_zero_elevation_data(:,1),aas_zero_elevation_data(:,[2:4])+bs_down_tilt_reduction);
bs_down_tilt_reduction=min(bs_down_tilt_reduction)
max(norm_aas_zero_elevation_data(:,[2:4])) %%%%%This should be [0 0 0]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%From the CBRS Portal Data: Pax River
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cell_data_header=cell(1,21);
cell_data_header{1}='data_label1';
cell_data_header{2}='latitude';
cell_data_header{3}='longitude';
cell_data_header{4}='rx_bw_mhz';
cell_data_header{5}='rx_height';
cell_data_header{6}='ant_hor_beamwidth';
cell_data_header{7}='min_azimuth';
cell_data_header{8}='max_azimuth';
cell_data_header{9}='rx_ant_gain_mb';
cell_data_header{10}='rx_nf';
cell_data_header{11}='in_ratio';
cell_data_header{12}='min_ant_loss';
cell_data_header{13}='fdr_dB';
cell_data_header{14}='dpa_threshold';
cell_data_header{15}='required_pathloss';
cell_data_header{16}='base_protection_pts';
cell_data_header{17}='base_polygon';
cell_data_header{18}='gmf_num';
cell_data_header{19}='rx_lat';
cell_data_header{20}='rx_lon';
cell_data_header{21}='base_polyshape';

cell_sim_data=cell(1,21);
cell_sim_data{1,1}='PaxRiverAdams';
cell_sim_data{1,2}=38.2975;
cell_sim_data{1,3}=-76.375833;
cell_sim_data{1,5}=10;
cell_sim_data{1,6}=3; 
cell_sim_data{1,7}=37;
cell_sim_data{1,8}=214;
cell_sim_data{1,12}=40;
cell_sim_data{1,14}=-144;
cell_sim_data{1,16}=horzcat(cell_sim_data{1,2},cell_sim_data{1,3},cell_sim_data{1,5});
cell_sim_data{1,17}=horzcat(cell_sim_data{1,2},cell_sim_data{1,3});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Test
rev=999; %%%%%%ADAMS Pax River
grid_spacing=1;  %%%%km:
sample_spacing_km=5;
bs_eirp=45%%%% %%%%%EIRP [dBm/10MHz] for Rural, Suburan, Urban: 62dBm/1MHz --> 36.25dBm/MHz at 50th (0,0), then - 1.25 for 80% TDD, 35dBm/Mhz --> 45dBm/10MHz
bs_bw_mhz=10; %%%%%%10 MHz channels for base station
network_loading_reduction=0% %%%%%%Already in the mask
sim_scale_factor=3; %%%%%%%%%%The scaling Factor for the simulation area. 1.1 is a 10% increase in distance post ITM
max_itm_dist_km=400; %%%%%It just makes it easy if we have a max number
mitigation_dB=0:10:60;  %%%%%%%%% in dB%%%%% Beam Muting or PRB Blanking (or any other mitigation mechanism):  30 dB reduction %%%%%%%%%%%%Consider have this be an array, 3dB step size, to get a more granular insight into how each 3dB mitigation reduces the coordination zone.
reliability=50%
Tpol=1; %%%polarization for ITM
FreqMHz=3300;
confidence=50;
tx_height_m=25
tf_clutter=0;%1;  %%%%%%This if for P2108.
sim_folder1='C:\Local Matlab Data\3.1GHz_Army' %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bs_eirp_reductions=(bs_eirp-bs_down_tilt_reduction-network_loading_reduction);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%Create a Rev Folder
cd(sim_folder1);
pause(0.1)
tempfolder=strcat('Rev',num2str(rev));
[status,msg,msgID]=mkdir(tempfolder);
rev_folder=fullfile(sim_folder1,tempfolder);
cd(rev_folder)
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Saving the simulation files in a folder for the option to run from a server
'First save . . .' %%%%%24 seconds on Z drive
tic;
save('grid_spacing.mat','grid_spacing')
save('reliability.mat','reliability')
save('confidence.mat','confidence')
save('FreqMHz.mat','FreqMHz')
save('Tpol.mat','Tpol')
save('norm_aas_zero_elevation_data.mat','norm_aas_zero_elevation_data')
save('tf_clutter.mat','tf_clutter')
save('mitigation_dB.mat','mitigation_dB')
save('tx_height_m.mat','tx_height_m')
save('bs_eirp_reductions.mat','bs_eirp_reductions')
save('sim_scale_factor.mat','sim_scale_factor')
toc;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Should probably pull this out of the loop so we don't have to do it 4,000 times
%%%%%%%%%%Find the ITM Area Pathloss for the distance array
tic;
max_rx_height=50
[array_dist_pl]=itm_area_dist_array_sea_rev2(app,reliability,tx_height_m,max_rx_height,max_itm_dist_km,FreqMHz);
toc;
tic;
save(strcat('Rev',num2str(rev),'_array_dist_pl.mat'),'array_dist_pl')
toc;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%First loop does all the calculation for the 15 columns, then just saves the cell_sim_data for the server to make the folders
%%%%%%%%%For Loop the Locations
cell_sim_data=vertcat(cell_data_header,cell_sim_data)
col_dpa_threshold_idx=find(matches(cell_data_header,'dpa_threshold'));
col_req_path_idx=find(matches(cell_data_header,'required_pathloss'));

[num_locations,~]=size(cell_sim_data);
table([1:num_locations]',cell_sim_data(:,1))
tic;
for base_idx=2:1:num_locations
    temp_single_cell_sim_data=cell_sim_data(base_idx,:);
    dpa_threshold=temp_single_cell_sim_data{col_dpa_threshold_idx};

    required_pathloss=ceil(bs_eirp_reductions-dpa_threshold); %%%%%%%%%%%%%%%%%Round up
    cell_sim_data{base_idx,col_req_path_idx}=required_pathloss;

    strcat(num2str(base_idx/num_locations*100),'%')
end
toc;  %%%%%%%%%%%

cd(rev_folder)
pause(0.1)
cell_sim_data(1:2,:)'
'Last save . . .'
tic;
save('cell_sim_data.mat','cell_sim_data')
toc;
cell_sim_data



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Now running the simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tf_server_status=0;
parallel_flag=0%1%0;
[workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag)
workers=2
tf_recalculate=0
tf_rescrap_rev_data=1
wrapper_bugsplat_merge_folders_geoplot_pea_rev14(app,rev_folder,parallel_flag,workers,tf_server_status,tf_recalculate,tf_rescrap_rev_data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end
cd(folder1)
'Done'

rev_folder


