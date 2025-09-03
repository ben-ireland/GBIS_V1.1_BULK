function [TS_Files, Loop_nums] = Get_Loop_Nums(TS_Files, Options)

    for k = 1:length(TS_Files)
        VolcNames{k} = TS_Files(k).name(1:end-21);

        MultipleFrames = arrayfun(@(x) contains(x.name,VolcNames{k}),TS_Files);
        indicies = find(MultipleFrames);
        NumFrames(k) = numel(indicies);
    end

    if Options.SingleFrameOnly ==1
        Loop_nums = num2cell(1:length(TS_Files));
    elseif Options.AscDscOnly ==1
        [C, ia, ic] = unique(VolcNames);
        NumFrames = NumFrames(ia);
        NumFrames(NumFrames<2) = [];
        C(NumFrames<2) = [];
        ia(NumFrames<2) = [];
        TS_Files(NumFrames<2) = [];

        for k = 1:length(C)
            if NumFrames(k) >1
                Loop_nums{k} = ia(k):ia(k)+(NumFrames(k)-1);
            else
                Loop_nums{k} = ia(k);
            end
        end
    else
        [C, ia, ic] = unique(VolcNames);
        NumFrames = NumFrames(ia);

        for k = 1:length(C)
            if NumFrames(k) >1
                Loop_nums{k} = ia(k):ia(k)+(NumFrames(k)-1);
            else
                Loop_nums{k} = ia(k);
            end
        end
    end
end