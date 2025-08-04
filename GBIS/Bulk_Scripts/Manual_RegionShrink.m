function DefImg = Manual_RegionShrink(DefImg,VolcName,MANUAL_Options)
    DefImg = Manual_IFG_Region_Shrink(DefImg,MANUAL_Options.RegionShrinkMinPts,MANUAL_Options.RS_DiskSize,VolcName,1);
end