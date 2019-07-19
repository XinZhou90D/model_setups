clear;
close all;
% this script is to correct dic from glodap in 2002 to glodap in 1958
% The difference from 2002 to 1958 is from Khatiwala_DIC_inversion.mat (ddic=dic(2002)-dic(1958))

load('Khatiwala_DIC_inversion.mat')
file_in='/tigress/GEOCLIM/LRGROUP/datasets/cobalt_data/tco2_talk_mking/GLODAPv2.2016b.TCO2.nc';
%file_out='/tigress/GEOCLIM/LRGROUP/datasets/cobalt_data/tco2_talk_mking/TCO2_v2_correct_to_1958.nc';
file_out='/tigress/GEOCLIM/LRGROUP/datasets/cobalt_data/tco2_talk_mking/TCO2_v2_correct_to_1777.nc';

%get value from Khatwala
%t238 is year 2002, t194 is year 1958
%dic_dif=squeeze(DIC(:,:,:,238)-DIC(:,:,:,194))*1000; %units*1000-->umol/kg
%t238 is year 2002, t13 is year 1777
dic_dif=squeeze(DIC(:,:,:,238)-DIC(:,:,:,13))*1000; %units*1000-->umol/kg
[im,jm,km]=size(dic_dif);
dic_dif=permute(dic_dif,[2,1,3]);
[klon,klat,kdep]=meshgrid(x,y,z);

%get value from GLodap
dic_2002=ncread(file_in,'TCO2');
dic_2002=circshift(dic_2002,20,1);
dic_2002=permute(dic_2002,[2,1,3]); %j,i,k, i=0--360;
lon=ncread(file_in,'lon'); %original lon is from 20E-->380E
lon_correct=circshift(lon,20);
lon_correct(lon_correct>360)=lon_correct(lon_correct>360)-360;
lat=ncread(file_in,'lat');
dep=ncread(file_in,'Depth');
[glon,glat,gdep]=meshgrid(lon_correct,lat,dep);

%interpolation using griddata
idxgood=~isnan(dic_dif);
F = scatteredInterpolant(klon(idxgood),klat(idxgood),kdep(idxgood),dic_dif(idxgood),'linear','linear');
dic_dif_glodap=F(glon,glat,gdep);
idxbad=isnan(dic_2002);
dic_dif_glodap(idxbad)=0;
%mask=ones(im,jm);
%for k=1:33
%    a=squeeze(DIC(:,:,1,1));    mask(isnan(a))=0;    mask=mask';
%    b=dic_dif_glodap(:,:,k);    b(mask==0)=nan;
%    dic_dif_glodap(:,:,k)=b;
%end

dic_dif_glodap(glat>=70 | glat<=-80)=0;
dic_1958=dic_2002-dic_dif_glodap; %j,i,k, i=0--360;

dic_1958=permute(dic_1958,[2,1,3]); %j,i,k-->i,j,k; i=0-360;
dic_1958=circshift(dic_1958,180,1);  %i,j,k; 0-360-->-180-180

ncwrite(file_out,'TCO2',dic_1958)
ncwriteatt(file_out,'/','history2','The GLODAPv2.2016b input data were normalized to the year 2002, then normalized again to 1958 by Enhui Liao from Laure Group using Khatiwala_DIC_inversion.mat.')
ncwriteatt(file_out,'/','new_creation_date',datestr(now));

%F=griddedInterpolant(klon(idxgood),klat(idxgood),kdep(idxgood),dic_dif(idxgood));
%dic_dif_glodap=griddata(klon(idxgood),klat(idxgood),kdep(idxgood),dic_dif(idxgood),glon,glat,gdep);
%dic_dif_glodap2=circshift(dic_dif_glodap,340,2); %back to original order that lon from 20E-380E
%dic_dif_glodap3=permute(dic_dif_glodap2,[2,1,3]); %i and j order is switched









