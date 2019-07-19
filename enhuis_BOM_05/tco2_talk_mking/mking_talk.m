clear;
close all;
% this script is to correct dic from glodap in 2002 to glodap in 1958
% The difference from 2002 to 1958 is from Khatiwala_DIC_inversion.mat (ddic=dic(2002)-dic(1958))

file_in='/tigress/GEOCLIM/LRGROUP/datasets/cobalt_data/tco2_talk_mking/GLODAPv2.2016b.TAlk.nc';
file_out='/tigress/GEOCLIM/LRGROUP/datasets/cobalt_data/tco2_talk_mking/TAlk_v2.nc';

data=ncread(file_in,'TAlk');
data2=circshift(data,200,1);

ncwrite(file_out,'Alk',data2)
ncwriteatt(file_out,'/','history2','The 1 X 1 global mapped field of total alkalinity from the GLODAPv2 data product, and then rewrite into MOM6 format by Enhui Liao from Laure Group using Khatiwala_DIC_inversion.mat.')
ncwriteatt(file_out,'/','new_creation_date',datestr(now));










