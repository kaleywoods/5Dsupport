function deform_images_psuedo_originalscans_toolbox(patient)
    
    
    %| Deform the reference image to the phases at which the origincal scans were acquired
    %|  using the model parameters;
    %|
    %| The 5d motion model generates DVFs going from an arbitrary phase,
    %| to the reference phase, so these need to be inverted.
    
    %| This code uses backwards2forwards.m (mex code compiled from C) from
    %| "Mulitmodality non-rigid demon algorith image resgistration toolbox"
    %| written by Dirk-Jan Kroon
    %|(http://www.mathworks.com/matlabcentral/fileexchange/21451-multimodality-non-rigid-demon-algorithm-image-registration).
    
    
    %|  However, as the target bellows voltage and flow is now not known
    %|  exactly (only the reference volume and flow , not where the voxel is
    %|  deformed to), the voltage and flow is found iteratively (small
    %|  difference).
    
    %|  DVFs are then generated at the 'target' volume and flows.
    
    %|  Images are deformed using mirt3D_mexinterp.m, a faster version of Matlab's built-in
    %|interp3/interpn.  This can be replaced with the built in versions, but please be carefull iwith the image/DVF orientation
    %|i.e. meshgrid vs ndgrid (http://www.mathworks.com/help/matlab/math/interpolating-gridded-data.html#bs2o5wb-1); 
    
    %|  A comparison of the original and the 'psuedo' model derived scans
    %|  are saved to a pdf file; ), one scan per page.
    %|  This shows original scan versus reference scan and a difference image (top row),
    %|  and then the target scan versus the model derived scan (bottom row).
    
    %|          *Please make sure Matlab can find your install of Elastix
    %|                  patient.elastix_root_folder needs to be set in
    %|                  choose_patient_toolbox.m
    %|                      default = "C:/Program Files/elastix/" -
    %|                                                          (windows).
    
    
    %------------------------------------------------------------------------
    %|      Dependancies;
    %|                  invert_motion_field
    %|                  deform_using_transformix_toolbox
    %|
    %------------------------------------------------------------------------
    %   This file is part of the
    %   5D-Novel4DCT Toolbox  ("Novel4DCT-Toolbox")
    %   DH Thomas, Ph.D
    %   University of California, Los Angeles
    %   Contact: mailto:dhthomas@mednet.ucla.edu
    %------------------------------------------------------------------------
    % $Author: DHThomas $	$Date: 2014/04/01 10:23:59 $	$Revision: 0.1 $
    
    lung_window=[-1024 276];
    
    load([patient.folder '/hu_fit'])
    hu_fit_p1=squeeze(hu_fit(1,:,:,:));
    hu_fit_p2=squeeze(hu_fit(2,:,:,:));
    clear hu_fit
    
    step=1;
    
    ii=1:patient.dim(1);
    jj=1:step:patient.dim(2);
    kk=1:step:patient.dim(3);
    
    
    %     bv_smooth=sort((pt.bellows_volt_drifted),'descend');
    
    [~,~,grid_z]=ndgrid(ii,jj,kk);
    volt_ref_img=single(reshape(patient.bellows_volt_drifted(grid_z,1),size(ii,2),size(jj,2),size(kk,2)));
    clear grid_z
    
    
    %     load([ patient.model_folder '\simple_coefs'])
    
    
    %     clear volt flow time
    
    
    %     param_folder = patient.model_params_folder;%([patient.model_folder '\model_params\'])
    % param_folder = ([model_folder '\model_params\'])
    
    %     cd(param_folder)
    
    clear static hu_fit_p1 constant alpha beta constant_inverse alpha_inverse beta_inverse movie_breath movie_breath_drifted movie_flow
    hu_fit_p2 = single(hu_fit_p2);
    folder_output = [patient.model_folder '/Psuedo_scans']
    mkdir(folder_output)
    
    %%%%%%
    
    for scan=2:patient.scans;
        
    %%%%%
        
        
        phase_tic = tic;
        volt = patient.bellows_volt(:,scan);%movie_breath(phase*100/fps*fps_upsample);
        flow = patient.flow(:,scan);   %movie_flow(phase*100/fps*fps_upsample);
        
        %         volt = patient.bellows_volt_drifted(:,scan);%movie_breath(phase*100/fps*fps_upsample);
        %         flow = patient.flow_drifted(:,scan);   %movie_flow(phase*100/fps*fps_upsample);
        volt_3d = permute(repmat(volt, [1,patient.dim(1), patient.dim(2)]),[2,3,1]);
        
        hu_correction = single(nanmean(hu_fit_p2(patient.static_mask>0))*(volt_3d-volt_ref_img));%ones(size(hu_fit_p2)).*
        
%         dvf_pseudo_tmp = create_psuedo_dvf_vec_volt3d_sliding_IterateVoltage(patient, volt, flow, scan, ii,jj,kk)  ;
        dvf_pseudo_tmp = create_psuedo_dvf_vec_volt3d_IterateVoltage_vectorized(patient, volt, flow, scan, ii,jj,kk);
        vX = double(squeeze(dvf_pseudo_tmp(:,:,1,:)));%reshape(model_u*E', size(ii,2), size(jj,2), size(kk,2)));
        vY = double(squeeze(dvf_pseudo_tmp(:,:,2,:)));%double(reshape(model_v*E', size(ii,2), size(jj,2), size(kk,2)));
        vZ = double(squeeze(dvf_pseudo_tmp(:,:,3,:)));%double(reshape(model_w*E', size(ii,2), size(jj,2), size(kk,2)));
        
        %         deformed_image_tmp = deform_image_DT_inverse(patient.static,vX, vY, vZ);
        %         deformed_mask_tmp= deform_image_DT(patient.static_mask,vX, vY, vZ);
        %         image_scan_pseudo = deformed_image_tmp.image;
        %         x0 = single(1:patient.dim(2));
        %         y0 = single(1:patient.dim(1));
        %         z0 = single(1:patient.dim(3));
        %
        %         [xx,yy,zz] = meshgrid(x0,y0,z0);	% xx, yy and zz are the original coordinates of image pixels
        %         vx = xx-vX;
        %         vy = yy-vY;
        %         vz = zz-vZ;
        %         [ivx,ivy,ivz]=spm_invdef(vx,vx,vz,mysize(vy),eye(4),eye(4));
        
        scan_folder = [folder_output sprintf('/scan%d',scan)];
        mkdir(scan_folder);
        
        %         dvf_pseudo_1(:,:,1,:) = vX;
        %         dvf_pseudo_1(:,:,2,:) = vY;
        %         dvf_pseudo_1(:,:,3,:) = vZ;
        %         metaImageWrite(double(dvf_pseudo_1),[scan_folder '/' sprintf('deformationField_2')],'ElementSpacing', [1 1 1]);
        display(sprintf('Scan %d of %d; Inverting DVF (may take ~10mins)', scan,patient.scans))
       % [ivy,ivx,ivz]=backwards2forwards(vY,vX,vZ);
         [ivy,ivx,ivz]=invertDVF(vY,vX,vZ);

                tic
        ivy(ivy == 0) = NaN;
        ivx(ivx == 0) = NaN;
        ivz(ivz == 0) = NaN;

        display(sprintf('Deforming Scan %d of %d', scan,patient.scans));
        image_ref = patient.static;%
%         image_ref(patient.body_mask<1)= min(patient.static(:));
        image_scan_pseudo_tmp = deform_image_mirt3d(image_ref, ivy, ivx, ivz);
        image_scan_pseudo_tmp(isnan(image_scan_pseudo_tmp)) = min(image_scan_pseudo_tmp(:));
        mask_scan_pseudo = deform_image_mirt3d(patient.static_mask, ivy, ivx, ivz);
        mask_scan_pseudo(isnan(mask_scan_pseudo)) = 0;
%         mask_scan_pseudo(isnan(mask_scan_pseudo)) = min(mask_scan_pseudo(:));
        mask_scan_pseudo = logical(mask_scan_pseudo);
        %         deformed_image_tmp = deform_image_DT(img_average,vX, vY, vZ);
        %         deformed_mask_tmp= deform_image_DT(static_mask,vX, vY, vZ);
        %         deformed_mask=deformed_mask_tmp.image;
        %         deformed_mask(deformed_mask>0)=1;
        %         hu_correction(deformed_mask==0)=0;
        hu_correction(mask_scan_pseudo==0)=0;
        image_scan_pseudo=image_scan_pseudo_tmp+hu_correction;
        metaImageWrite(image_scan_pseudo,[scan_folder '/' sprintf('pseudo_scan%d', scan)],'ElementSpacing', [1 1 1]);
        metaImageWrite(double(mask_scan_pseudo),[scan_folder '/' sprintf('pseudo_mask%d', scan)],'ElementSpacing', [1 1 1]);
        %metaImageWrite(image_scan_pseudo,[scan_folder '\' sprintf('pseudo_scan%d', scan)],'ElementSpacing', [1 1 1]);
        %metaImageWrite(double(mask_scan_pseudo),[scan_folder '\' sprintf('pseudo_mask%d', scan)],'ElementSpacing', [1 1 1]);
%         [image_scan_pseudo, mask_scan_pseudo]  = deform_using_transformix_toolbox(patient, scan_folder);
        
        image_scan = metaImageRead([patient.folder_static sprintf('/scan_%d_cut',scan)]);
        
        register_pseudoscans_toolbox(patient, scan)
        
        figure(100);
        set(gcf,'units','normalized','position',patient.default_figure_position);
        
        cor_slice = floor(patient.dim(1)/2);
        sag_slice = patient.sagittal_right_middle;        
        % Choose this to display the left lung;
        %         sag_slice = patient.sagittal_left_middle;

%         ax_slice = floor(patient.dim(1)/3);
%         sag_slice =191;%160;%172;%pt10=209;%pt7=   225;% pt2 = 191;
        
        
        cut_cor = 1;%1;%pt2 = 80;
        cut_ax = 10
        %         subplot(2,4,1)
        %         imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_ref(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))));
        %         title(sprintf('[Scan %d] vs [Reference]',scan))
        %         subplot(2,4,2)
        %         imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_ref(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),'diff');
        %         subplot(2,4,3)
        %         imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_ref(:,sag_slice,:))));
        %         title(sprintf('[Scan %d] vs [Reference]',scan))
        %         subplot(2,4,4)
        %         imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_ref(:,sag_slice,:))),'diff');
        %
        %         subplot(2,4,5)
        %         imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_scan_pseudo(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))))
        %         title(sprintf('[Scan %d] vs [Reference deformed to Scan %d]',scan, scan))
        %         subplot(2,4,6)
        %         imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_scan_pseudo(cor_slice,cut_cor+20:patient.dim(2)-cut_cor,:))),'diff')
        %         subplot(2,4,7)
        %         imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_scan_pseudo(:,sag_slice,:))))
        %         title(sprintf('[Scan %d] vs [Reference deformed to Scan %d]',scan, scan))
        %         subplot(2,4,8)
        %         imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_scan_pseudo(:,sag_slice,:))),'diff')
        
        subplot(2,3,1)
        imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_ref(cor_slice,cut_cor:patient.dim(2)-cut_cor,:))));
        title(sprintf('[Scan %d] vs [Reference]',scan))
        subplot(2,3,2)
        imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_ref(:,sag_slice,:))));
        subplot(2,3,3)
        plot_dvf_original_cdf_toolbox(patient, scan)
%         imshowpair(rot90(squeeze(image_scan(:,:,ax_slice))),rot90(squeeze(image_ref(:,:,ax_slice))));
%         title(sprintf('[Scan %d] vs [Reference]',scan))
        
        subplot(2,3,4)
        imshowpair(rot90(squeeze(image_scan(cor_slice,cut_cor:patient.dim(2)-cut_cor,:))),rot90(squeeze(image_scan_pseudo(cor_slice,cut_cor:patient.dim(2)-cut_cor,:))))
        title(sprintf('[Scan %d] vs [Reference deformed to Scan %d]',scan, scan))
        subplot(2,3,5)
        imshowpair(rot90(squeeze(image_scan(:,sag_slice,:))),rot90(squeeze(image_scan_pseudo(:,sag_slice,:))))
        subplot(2,3,6)
%         imshowpair(rot90(squeeze(image_scan(:,:,ax_slice ))),rot90(squeeze(image_scan_pseudo(:,:,ax_slice))))
%         title(sprintf('[Scan %d] vs [Reference deformed to Scan %d]',scan, scan))
        plot_dvf_psuedo_cdf_toolbox(patient, scan)       
        
        export_fig([patient.model_folder sprintf('/pt%d_psuedo_scans_6.pdf',patient.pt)], '-append')
        
        phase_time = toc(phase_tic)
        clear deformed_image deformed_image_tmp %deformed_image_tmp_inverse
    end
    
    
