function patient = Generate_4DCT_toolbox(patient,imageVoltages, imageFlows)
    
   use_average_image = 0; %default - don't used the averaged image to deform (use the reference instead).
        prompt = 'Would you like to deform the averaged image [1] or the referece image [0] ?';
        use_average_image = input(prompt);
        
    if use_average_image>0;
        load([patient.folder '/img_average'])
        deform_image = img_average;
    else
        deform_image = patient.static;
    end
    
    patient.folder_4DCT = [patient.model_folder '/Psuedo_4DCT'];
    mkdir(patient.folder_4DCT)
    cd(patient.folder_4DCT)
    dirinfo = dir('*phase*');
    dirinfo(~[dirinfo.isdir]) = [];      
    str = 'Y'; %default is to continue

    if size(dirinfo,1) ~= 0;
        prompt = 'Psuedo 4DCT exists. \n                Do you want to re-generate 4DCT? Y [Hit Return for N]: ';
        str = input(prompt,'s');
        if isempty(str)
            str = 'N';
        end
    end
    if strcmpi('Y', str)>0;str = 'Y';end
     if strcmpi('N', str)>0;str = 'N';end
   
    if str == 'N'
        
    else
        
        
        step = 1;
        ii = 1:step:patient.dim(1);
        jj = 1:step:patient.dim(2);
        kk = 1:step:patient.dim(3);
        
        
        
        display('               Loading model parameters...');
        load([patient.model_folder '/model_params/alpha']);
        load([patient.model_folder '/model_params/beta']);
        load([patient.model_folder '/model_params/constant']);
        model_u=single([ constant.u(:) alpha.u(:) beta.u(:)]);% gamma_vec_u];
        model_v=single([ constant.v(:) alpha.v(:) beta.v(:)]);% gamma_vec_u];
        model_w= single([ constant.w(:) alpha.w(:) beta.w(:)]);% gamma_vec_u];
        clear alpha beta constant
        
        load([patient.folder '/hu_fit'])
        hu_fit_p1=squeeze(hu_fit(1,:,:,:));
        hu_fit_p2=squeeze(hu_fit(2,:,:,:));
        clear hu_fit
        

        [~,~,grid_z]=ndgrid(ii,jj,kk);
        volt_ref_img=reshape(patient.bellows_volt_drifted(grid_z,patient.ref),size(ii,2),size(jj,2),size(kk,2));

volt = imageVoltages;
flow = imageFlows;
for phase = 1:length(volt)
            
	    hu_fit_p2_finite=hu_fit_p2(isfinite(hu_fit_p2));
            hu_correction= nanmean(hu_fit_p2(patient.static_mask>0))*(volt(phase)-volt_ref_img);
            
            
            E=[1 volt(phase) flow(phase)];
            
            vX = double(reshape(model_u*E', size(ii,2), size(jj,2), size(kk,2)));
            vY = double(reshape(model_v*E', size(ii,2), size(jj,2), size(kk,2)));
            vZ = double(reshape(model_w*E', size(ii,2), size(jj,2), size(kk,2)));
            
            tic
            
        display(sprintf('Scan %d of %d; Inverting DVF...', phase,length(volt)))
        [ivy,ivx,ivz]=invertDVF(vY,vX,vZ);
        ivy(ivy == 0) = NaN;
        ivx(ivx == 0) = NaN;
        ivz(ivz == 0) = NaN;
        
        display(sprintf('Deforming Scan %d of %d', phase,length(volt)));
        image_ref = deform_image;%
        image_scan_pseudo_tmp = deform_image_mirt3d(image_ref, ivy, ivx, ivz);
        image_scan_pseudo_tmp(isnan(image_scan_pseudo_tmp)) = min(image_scan_pseudo_tmp(:));
        mask_scan_pseudo = deform_image_mirt3d(patient.static_mask, ivy, ivx, ivz);
        mask_scan_pseudo(isnan(mask_scan_pseudo)) = 0;
        deformed_mask = logical(mask_scan_pseudo);
        hu_correction(mask_scan_pseudo==0)=0;
        deformed_image=image_scan_pseudo_tmp+hu_correction;
        
            clear deformed_mask_tmp;
            clear deformed_image_tmp;
            
            
            save([patient.folder_4DCT  sprintf('/Deformed_pseudo_Image_phase_%d',phase)],'deformed_image')
            save([patient.folder_4DCT sprintf('/Deformed_pseudo_Mask_phase_%d',phase)],'deformed_mask')
            
            metaImageWrite(deformed_image,[patient.folder_4DCT  sprintf('/Deformed_pseudo_Image_phase_%d',phase)],'ElementSpacing', [1 1 1]);
            metaImageWrite(double(deformed_mask),[patient.folder_4DCT sprintf('/Deformed_pseudo_Mask_phase_%d',phase)],'ElementSpacing', [1 1 1]);

            toc
            
        end
        
        
    end
