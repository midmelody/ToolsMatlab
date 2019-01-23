clear all
close all

for i = 0:203
    % individual image
    folder = sprintf('RawData/PEx%04d_00000000',i);
    pathCase = correct_path(folder);
    if exist(pathCase, 'dir')
        % Get reference image size
        dicomPath = [pathCase,'dicoms/t2'];
        dicomPath = correct_path(dicomPath);
        img = dicomread([dicomPath,'000000.dcm']);
        sizeX = size(img,1);
        sizeY = size(img,2);
        % VOI folder
        pathVOI = strcat(pathCase,'voi');
        pathVOI = correct_path(pathVOI);
        voiNames = dir(strcat(pathVOI,'*.voi'));
        % iterate each VOI file
        for j = 1:numel(voiNames)
            fileName = voiNames(j).name;
            % read raw file
            content = fileread(strcat(pathVOI,fileName));
            % split each line
            content = regexp(content, '\n', 'split');
            % find total slices
            indexTotal = find(contains(content, '# number of slices for the VOI'));
            sliceTotal = content(indexTotal);
            sliceTotal = regexp(sliceTotal, '#', 'split');   
            sliceTotal = sliceTotal{1,1}{1,1};
            sliceTotal = str2double(sliceTotal); 
            % find the split index for each slice
            indexEnd = find(contains(content, '# unique ID of the VOI'));
            indexSplit = [find(contains(content, 'slice number')), indexEnd];
            % process each slice and write out
            outFilePath = strcat(pathCase,strrep(fileName,'voi','txt'));
            fileSegIndex = fopen(outFilePath,'w');
            for k = 1:sliceTotal
                % get slice number (z index)
                sliceNum = content(indexSplit(k));
                sliceNum = regexp(sliceNum, '#', 'split');
                sliceNum = sliceNum{1,1}{1,1};
                sliceNum = str2double(sliceNum); 
                % get contour points and write to temp file
                if(indexSplit(k+1)-indexSplit(k)>6)
                    contour = content((indexSplit(k)+3):(indexSplit(k+1)-1));
                    tmpFile = fopen('temp.txt', 'w');
                    for pt = 1:numel(contour)
                        fprintf(tmpFile, '%s\n', contour{pt});
                    end
                    fclose(tmpFile);
                    % load back as array
                    coord = table2array(readtable('temp.txt'));
                    % convert polygon to mask
                    mask = poly2mask(coord(:,1),coord(:,2),sizeX,sizeY);
                    for p = 1:sizeX
                        for q = 1:sizeY
                            if mask(p,q)==1
                                % to be used by ITK, so keep (0,0,0) index
                                fprintf(fileSegIndex, '%d %d %d\n', p-1, q-1, sliceNum-1);
                            end
                        end
                    end
                end
            end
            fclose(fileSegIndex);
        end
    end
end