function ea_get_Eproj(tractset,stim_ID,space)
% Comptute E-field metrics directly on fibers (optionally in native space).
% The results are stored as
% patient_folder/connectomes/connnectomeName/stim_ID/E_metrics.mat (values for all fibers in the connectome!)
% By Butenko and Roediger, konstantinmgtu@gmail.com

arguments
    tractset       % fiber filtering object
    stim_ID        % when using PseudoM, provide stimulation folder full(!) name
    space          % space where to compute E-proj, 'MNI' or 'native'
end

if isempty(tractset.analysispath)
    pth = fileparts(tractset.leadgroup);
    tractset.analysispath=[pth,filesep,'fiberfiltering',filesep,tractset.ID,'.fibfilt'];
end

% use connectome with all pathways combined
if tractset.multi_pathways == 1
    % check if merged_pathways is in fibfiltering folder
    [filepath,~,~] = fileparts(tractset.analysispath);
    merged_connectome = [filepath,filesep,tractset.connectome,filesep,'merged_pathways.mat'];
    if ~isfile(merged_connectome)
        % else check if it is in the original lead-group folder
        [filepath,~,~] = fileparts(tractset.leadgroup);
        merged_connectome = [filepath,filesep,tractset.connectome,filesep,'merged_pathways.mat'];
        if ~isfile(merged_connectome)
            % or if it is in another lead-group folder (where fibfiltering file is)
            [filepath,~,~] = fileparts(tractset.analysispath);
            [filepath,~,~] = fileparts(filepath);
            merged_connectome = [filepath,filesep,tractset.connectome,filesep,'merged_pathways.mat'];
        end
    end
else
    merged_connectome = [ea_getconnectomebase('dMRI'), tractset.connectome, filesep, 'data.mat'];
end


% find where VATs are
if ~isfield(tractset.M,'pseudoM')
    if strcmp(space,'MNI')
        stim_space = ['/MNI152NLin2009bAsym/gs_',tractset.M.guid]; 
    else
        stim_space = ['/native/gs_',tractset.M.guid]; 
    end
else
    % custom case
    if strcmp(space,'MNI')
        stim_space = ['/MNI152NLin2009bAsym/',stim_ID]; 
    else
        stim_space = ['/native/',stim_ID];
    end
end

ea_dispercent(1/size(tractset.M.patient.list,1),'Computing E-field metrics on fibers')
for pt_i = 1:size(tractset.M.patient.list,1)
    fprintf('\nProcessing: %s\n',tractset.M.patient.list{pt_i});
    stim_folder = strcat(tractset.M.patient.list{pt_i},filesep,'stimulations',stim_space);

    for side = 1:2
    
        switch side
            case 1
                side_suffix = '_rh';
                sideLabel = 'R'; 
            case 2
                side_suffix = '_lh';
                sideLabel = 'L'; 
        end

        % OSS-DBS format (for Simbio, the function is not available)
        Field4D = [stim_folder, filesep, '4D_efield_model-ossdbs_hemi-', sideLabel, '.nii'];
        if isfile(Field4D)
            % compute projection of the E-field onto the fibers
            ea_get_E_field_along_fibers(tractset.M.patient.list{pt_i}, stim_space, Field4D, merged_connectome, side_suffix, tractset.calcthreshold)
        else
            [~,pt_label,~] = fileparts(tractset.M.patient.list{pt_i});
            fprintf("Missing stimulation for %s, %s side \n",pt_label,side_suffix)
        end
    end

end
ea_dispercent(1/size(tractset.M.patient.list,1),'end')

