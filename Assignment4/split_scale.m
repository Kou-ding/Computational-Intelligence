%% Split - Preprocess Data

function [trnData,chkData,tstData] = split_scale(data,preproc)
    
    idx=randperm(length(data));

    % 60% for training
    trnIdx=idx(1:round(length(idx)*0.6));
    % 20% for checking/validation
    chkIdx=idx(round(length(idx)*0.6)+1:round(length(idx)*0.8));
    % 20% for testing
    tstIdx=idx(round(length(idx)*0.8)+1:end);

    trnX=data(trnIdx,1:end-1);
    chkX=data(chkIdx,1:end-1);
    tstX=data(tstIdx,1:end-1);

    switch preproc
        % Normalization to unit hypercube
        case 1                     
            xmin=min(trnX,[],1);
            xmax=max(trnX,[],1);
            trnX=(trnX-repmat(xmin,[length(trnX) 1]))./(repmat(xmax,[length(trnX) 1])-repmat(xmin,[length(trnX) 1]));
            chkX=(chkX-repmat(xmin,[length(chkX) 1]))./(repmat(xmax,[length(chkX) 1])-repmat(xmin,[length(chkX) 1]));
            tstX=(tstX-repmat(xmin,[length(tstX) 1]))./(repmat(xmax,[length(tstX) 1])-repmat(xmin,[length(tstX) 1]));
        % Standardization to zero mean - unit variance
        case 2
            mu=mean(data,1);
            sig=std(data,1);
            trnX=(trnX-repmat(mu,[length(trnX) 1]))./repmat(sig,[length(trnX) 1]);
            chkX=(trnX-repmat(mu,[length(chkX) 1]))./repmat(sig,[length(chkX) 1]);
            tstX=(trnX-repmat(mu,[length(tstX) 1]))./repmat(sig,[length(tstX) 1]);
        otherwise
            disp('Not appropriate choice.')
    end
    trnData=[trnX data(trnIdx,end)];
    chkData=[chkX data(chkIdx,end)];
    tstData=[tstX data(tstIdx,end)];

end