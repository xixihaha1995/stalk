% This is first version of find the stalk profile after impact 
% using bwcoundaries function in MATLAB
% Subtract the background by using a reference image
% The logic is modified;

clear all; close all; clc;

format shortg
c = clock;
disp(c);

directory = 'C:\Users\lab-admin\Desktop\Lichen_Wu\movies_processed';
cd(directory);
movie_dir = dir(directory);

ext = '.bmp';
ext_out = '_test.txt';
extlevel_out = '.txt';

levelDir = 'C:\Users\lab-admin\Desktop\Lichen_Wu\movies_leveled\';
level_out = strcat(levelDir,'level',extlevel_out);

outDir = 'C:\Users\lab-admin\Desktop\Lichen_Wu\movies_circled\';
filename_out = strcat(outDir,'circled',ext_out);

for movie_itr = 6: 8
    movie_folder_name = movie_dir(movie_itr).name;
    cd(strcat(movie_folder_name,'\'));
    img_dir=dir(strcat(movie_dir(movie_itr).folder,'\',movie_dir(movie_itr).name));
    [ref_index,ref_indexUseless] = size(img_dir);
    ref_index = ref_index -1;
    FirstIm = ref_index - 40;
    
    ref_file = strcat(img_dir(ref_index).name);
%     if a bmp file
%     contains(ref_file,'.bmp')

    ref_a = imread(ref_file);
    
    Impact_location = 1225; 
    
    y2 = Impact_location+500;
    y1 = Impact_location-500;

    figure(1);
    set(gcf,'WindowState','maximized')

    plot(smooth(double((ref_a(:, Impact_location-500)))),'r');
    hold on
    plot(smooth(double((ref_a(:, Impact_location+500)))), 'g');
    hold off
    disp('Stretch figure 1 horizontally for a better resolution..... ')
    disp('Click on the middle pick in red line once: ?')
    [x1,y1g] = ginput(1);
    disp(' ... ')
    disp('Click on the middle pick in green line once: ?')
    [x2,y2g] = ginput(1);
    
    level = (x1 + x2)/2; 
    numCircledFailuer = 0;
    totalNumber = 0;
    skipped = 0;
   
    
    fid = fopen(level_out,'a');
%     fprintf(fid,'\n');
    
    fprintf(fid,'%s',[movie_folder_name]);
    fprintf(fid,'\t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d\n',[c(1);c(2);c(3);c(4);c(5);c(6);x1;x2]);
    fclose(fid);
    
    % figure(2); imshow(ref_a);
    % hold on
    % plot([y1 y2], [x1 x2], 'r')
    % hold off
    % 
    alpha = atan((x2-x1)/(y2-y1)); % the angle of falt surface in the image
    




    
    for ii = size(img_dir):-1:3
        filename = strcat(img_dir(ii).name);

%         skip  non-.bmp file, skip txt file(including .bmp ext)
        if ref_index == ii || contains(filename,'.bmp') == 0 ||...
                contains(filename,'.txt')
            skipped = skipped +1;
            continue
        end
    
% ref should be 1 img ahead of first
%         ii = ii - 1;
%         filename = strcat(img_dir(ii).name);
%         
%         %         skip  non-.bmp file, skip txt file(including .bmp ext)
%         if contains(filename,'.bmp') == 0 || contains(filename,'.txt')
%             continue
%         end
        

            
        a = imread(filename);
        
% subtract the background
        a0 =ref_a-a; 

        
        a0_max = double(max(max(a0)))/256.0;
        a1 = imadjust(a0, [0.01 a0_max], [0 1]); %for a better contrast
        BW = a0>max(max(a0))/5; %another way to convert into BW 
        [B, L]=bwboundaries(BW,'noholes');

        kk=0;
        boundary_size = zeros(1, length(B));
        for k=1:length(B)       
            boundary_size(k)= length(B{k});
            if boundary_size(k) >200 %count boundaries with points greater than 200
                 kk = kk+1;
            end
        end
        [K_M, K_I]=sort(boundary_size, 'descend');
        
%         find circle
%         find circle

        boundary = B{K_I(1)};

        if  max(boundary(:,1))< level
            totalNumber = totalNumber + 1;
            
                boundary = B{K_I(1)};
                figure(2);
                imshow(a);
                hold on;

                plot(boundary(:,2), boundary(:,1),'r');
                hold off;


                cenXX = mean(boundary(:,2));
                cenYY = mean(boundary(:,1));

                if (cenXX >1750 || cenXX <900)
                msg='locations of droplet are wrong';
                error(msg)
                end
                
                [centers,radii] = imfindcircles(BW,[28 50],'ObjectPolarity','bright');
                siz=size(radii);
                
                
                if(siz(1) ~= 1)
                    numCircledFailuer = numCircledFailuer + 1;

                    stats = regionprops('table',BW,'Centroid',...
                    'MajorAxisLength','MinorAxisLength','Orientation');
                    stats = sortrows(stats,2,'descend');
                    centers = stats.Centroid;
                    %         centers = centers(1,:);
                    majorAxisLength = stats.MajorAxisLength(1);
                    minorAxisLength =stats.MinorAxisLength(1);
                    %         if majorAxisLength<30
                    %             majorAxisLength=strcat(num2str(majorAxisLength),'invalidEcllipse');
                    %         end
                    orientation = stats.Orientation(1);

                    fid = fopen(filename_out,'a');
                    
                    fprintf(fid,'%s',[img_dir(ii).name]);
                    fprintf(fid, '\t  %d \t  %d \t  %d \t  %d \t  %d \t  %d \t  %8.2f \t %8.2f \t %s\t %8.2f \t %d\n',...
                        [c(1);c(2);c(3);c(4);c(5);c(6); cenXX; cenYY; majorAxisLength;...
                        minorAxisLength; orientation]); 
                    fclose(fid);

                    continue
                end
                
                if (radii<30)
                    msg='radius of droplet are too small';
                    error(msg)
                elseif (radii>115)
                    msg='radius of droplet are too big';
                    error(msg)
                end

                fid = fopen(filename_out,'a');
                
                fprintf(fid,'%s',[img_dir(ii).name]);
                fprintf(fid, '\t %d \t  %d \t  %d \t  %d \t  %d \t  %d \t %8.2f \t %8.2f \t %8.2f\n',...
                    [c(1);c(2);c(3);c(4);c(5);c(6);cenXX; cenYY;radii]); %relative to flat surface
                fclose(fid); 
                continue
        end
        if max(boundary(:,1))> level && ii == ref_index - totalNumber -skipped + 1
            
            fprintf('Total %d images have been processed, %d have been circled, %d have been centroided.\n', ...
                totalNumber, totalNumber - numCircledFailuer, numCircledFailuer);
            disp('------');
            diary 'C:\Users\lab-admin\Desktop\Lichen_Wu\matlab\circle_droplet\circleDiaryFile'
        end
            
        
      
%         while  max(boundary(:,1))> level
%             fprintf('Droplet from image %d might have contacted the surface\n', ii);
% %             LastIm = ii -1;
% %             totalNumber = LastIm - FirstIm + 1 ;
% % distance between impact and jet growing
%             img_itr = ii - 50;
%         end
        
        
        if max(boundary(:,1))> level && ii < ref_index - totalNumber -skipped + 1 -40
            
            figure(3); imshow(a1);
            hold on
            for k1=1:kk
                boundary = B{K_I(k1)};
                plot(boundary(:,2), boundary(:,1),'r');
                text(boundary(int16(K_M(k1)/2), 2), boundary(int16(K_M(k1)/2),1), num2str(k1),'Color','green','FontSize',24);
            end 
            plt=plot([y1 y2], [x1 x2], 'm', 'LineWidth', 2);

            hold off


            profl = B{K_I(1)};
            [min_x, I_min]=min(profl(:,2)); %In the horizontal direction
            [max_x, I_max]=max(profl(:,2));
            x_temp = profl(I_min:I_max, 2)';
            y_temp = profl(I_min:I_max, 1)';

            figure(4); imshow(a);
            hold on
            plot(x_temp, y_temp, 'r');
            %hold off

            % alpha = 0; %The flat surface has aero angle in image 
            profile_x = (y_temp-x1).*sin(alpha)+(x_temp-y1).*cos(alpha);
            profile_y = (y_temp-x1).*cos(alpha)-(x_temp-y1).*sin(alpha);

            plot(profile_x+y1, profile_y+x1, 'y')
            hold off

            filename_out = strcat(filename,ext_out);
            fid = fopen(filename_out,'w');
            %relative to flat surface
            fprintf(fid, '%8.2f \t %8.2f\n',[profile_x; -profile_y]); 
            fclose(fid);
            clear profile_x profile_y  
        end
        
        continue
    end
    cd ..
    
end

        
    











