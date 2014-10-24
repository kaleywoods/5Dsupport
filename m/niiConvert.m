function niiConvert(inputFile,outputFile)
    
    mhdImg = metaImageRead(inputFile);
    mhdInfo = metaImageInfo(inputFile);
    nii = make_nii(mhdImg,mhdInfo.ElementSpacing);
    save_nii(nii,outputFile);
end




