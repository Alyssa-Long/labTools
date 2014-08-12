classdef adaptationData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        data %Contains adaptation parameters
    end
    
    properties (Dependent)
        
    end
    
    methods
        %Constructor
        function this=adaptationData(meta,sub,data)
            
            if nargin>0 && isa(meta,'experimentMetaData')
                this.metaData=meta;
            else
                ME=MException('adaptationData:Constructor','metaData is not an experimentMetaData type object.');
                throw(ME);
            end
            
            if nargin>1 && isa(sub,'subjectData')
                this.subData=sub;
            else
                ME=MException('adaptationData:Constructor','Subject data is not a subjectData type object.');
                throw(ME);
            end
            
            if nargin>2 && isa(data,'paramData')
                this.data=data;
            else
                ME=MException('adaptationData:Constructor','Data is not a paramData type object.');
                throw(ME);
            end
        end
        
        function newThis=removeBias(this,conditions)
            % removeBias('condition') or removeBias({'Condition1','Condition2',...}) 
            % removes the median value of every parameter from each trial of the
            % same type as the condition entered. If no condition is
            % specified, then the condition name that contains both the
            % type string and the string 'base' is used as the baseline
            % condition.
            
            if nargin>1
                newThis=removeBiasV2(this,conditions);
            else
                newThis=removeBiasV2(this);
            end
            
            %             if nargin>1
            %                 %convert input to standardized format
            %                 if isa(conditions,'char')
            %                     conditions={conditions};
            %                 elseif isa(conditions,'double')
            %                     conditions=conds(conditions);
            %                 end
            %                 % validate condition(s)
            %                 cInput=conditions(this.isaCondition(conditions));
            %             end
            %
            %             trialsInCond=this.metaData.trialsInCondition;
            %             conds=this.metaData.conditionName;
            %             trialTypes=this.data.trialTypes;
            %             types=unique(trialTypes(~cellfun(@isempty,trialTypes)));
            %             labels=this.data.labels;
            %
            %             for itype=1:length(types)
            %                 allTrials=[];
            %                 baseTrials=[];
            %                 for c=1:length(conds)
            %                     trials=trialsInCond{c};
            %                     if all(strcmpi(trialTypes(trials),types{itype}))
            %                         allTrials=[allTrials trials];
            %                         if nargin<2 || isempty(conditions)
            %                             %if no conditions were entered, this just searches all
            %                             %condition names for the string 'base' and
            %                             %the Type string
            %                             if ~isempty(strfind(lower(conds{c}),'base')) && ~isempty(strfind(lower(conds{c}),lower(types{itype})))
            %                                 baseTrials=[baseTrials trials];
            %                             end
            %                         else
            %                             if any(ismember(cInput,conds{c}))
            %                                 baseTrials=[baseTrials trials];
            %                             end
            %                         end
            %                     end
            %                 end
            %                 inds=cell2mat(this.data.indsInTrial(allTrials));
            %                 if ~isempty(baseTrials)
            %                     base=nanmedian(this.getParamInTrial(labels,baseTrials));
            %                     newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
            %                 else
            %                     warning(['No ' types{itype} ' baseline trials detected. Bias not removed from ' types{itype} ' trials.'])
            %                     newData(inds,:)=this.data.Data(inds,:);
            %                 end
            %             end
            %
            %             newParamData=paramData(newData,labels,this.data.indsInTrial,this.data.trialTypes);
            %             newThis=adaptationData(this.metaData,this.subData,newParamData);
        end
        
        %Other I/O functions:
        function labelList=getParameters(this)
            labelList=this.data.labels;
        end
        
        function [data,inds,auxLabel]=getParamInTrial(this,label,trial)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);
            
            % validate trial(s)
            trialNum = [];
            for t=trial
                if isempty(this.data.indsInTrial(t))
                    warning(['Trial number ' num2str(t) ' is not a trial in this experiment.'])
                else
                    trialNum(end+1)=t;
                end
            end
            %get data
            inds=cell2mat(this.data.indsInTrial(trialNum));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function [data,inds,auxLabel]=getParamInCond(this,label,condition)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);
            
            % validate condition(s)
            condNum = [];
            if isa(condition,'char')
                condition={condition};
            end
            if isa(condition,'cell')
                for i=1:length(condition)
                    boolFlags=strcmpi(this.metaData.conditionName,condition{i});
                    if any(boolFlags)
                        condNum(end+1)=find(boolFlags);
                    else
                        warning([this.subData.ID ' did not perform condition ''' condition{i} ''''])
                    end
                end
            else %a numerical vector
                for i=1:length(condition)
                    if length(this.metaData.trialsInCondition)<i || isempty(this.metaData.trialsInCondition(condition(i)))
                        warning([this.subData.ID ' did not perform condition number ' num2str(condition(i))])
                    else
                        condNum(end+1)=condition(i);
                    end
                end
            end
            
            %get data
            trials=cell2mat(this.metaData.trialsInCondition(condNum));
            inds=cell2mat(this.data.indsInTrial(trials));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function plotParamTimeCourse(this,label)
            
            if isa(label,'char')
                label={label};
            end
            
            ah=optimizedSubPlot(length(label),4,1); %this changes default color order of axes
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            nPoints=size(this.data.Data,1);
            for l=1:length(label)
                dataPoints=NaN(nPoints,nConds);
                for i=1:nConds
                    trials=this.metaData.trialsInCondition{conds(i)};
                    if ~isempty(trials)
                        for t=trials
                            inds=this.data.indsInTrial{t};
                            dataPoints(inds,i)=this.getParamInTrial(label(l),t);
                        end
                    end
                end
                plot(ah(l),dataPoints,'.','MarkerSize',15)
                title(ah(l),[label{l},' (',this.subData.ID ')'])
            end
            condDes = this.metaData.conditionName;
            legend(condDes(conds)); %this is for the case when a condition number was skipped
            linkaxes(ah,'x')
            axis tight
        end
        
        function plotParamTrialTimeCourse(this,label)
            
            ah=optimizedSubPlot(length(label),4,1);            
            
            nTrials=length(cell2mat(this.metaData.trialsInCondition));
            trials=find(~cellfun(@isempty,this.data.trialTypes));
            nPoints=size(this.data.Data,1);
            
            for l=1:length(label)
                dataPoints=NaN(nPoints,nTrials);
                for i=1:nTrials
                    inds=this.data.indsInTrial{trials(i)};
                    dataPoints(inds,i)=this.getParamInTrial(label(l),trials(i));
                end
                plot(ah(l),dataPoints,'.','MarkerSize',15)
                title(ah(l),[label{l},' (',this.subData.ID ')'])
            end
            
            trialNums = cell2mat(this.metaData.trialsInCondition);
            legendEntry={};
            for i=1:length(trialNums)
                legendEntry{end+1}=num2str(trialNums(i));
            end
            legend(legendEntry);
            linkaxes(ah,'x')
            axis tight
        end
        
        function plotParamByConditions(this,label)
            
            N1=3; %very early number of points
            N2=5; %early number of points
            N3=20; %late number of points
            
            ah=optimizedSubPlot(length(label),4,1);           
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            for l=1:length(label)
                earlyPoints=[];
                veryEarlyPoints=[];
                latePoints=[];
                for i=1:nConds
                    aux=this.getParamInCond(label(l),conds(i));
                    try %Try to get the first strides, if there are enough
                        veryEarlyPoints(i,:)=aux(1:N1);
                        earlyPoints(i,:)=aux(1:N2);
                    catch %In case there aren't enough strides, assign NaNs to all
                        veryEarlyPoints(i,:)=NaN;
                        earlyPoints(i,:)=NaN;
                    end
                    %Last 20 steps, excepting the very last 5
                    try
                        latePoints(i,:)=aux(end-N3-4:end-5);
                    catch
                        latePoints(i,:)=NaN;
                    end
                end
                axes(ah(l))
                hold on
                
                bar((1:3:3*nConds)-.25,nanmean(veryEarlyPoints,2),.15,'FaceColor',[.8,.8,.8])
                bar((1:3:3*nConds)+.25,nanmean(earlyPoints,2),.15,'FaceColor',[.6,.6,.6])
                bar(2:3:3*nConds,nanmean(latePoints,2),.3,'FaceColor',[0,.3,.6])
                errorbar((1:3:3*nConds)-.25,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                errorbar((1:3:3*nConds)+.25,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                errorbar(2:3:3*nConds,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                %plot([1:3:3*nConds]-.25,veryEarlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot([1:3:3*nConds]+.25,earlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot(2:3:3*nConds,latePoints,'x','LineWidth',2,'Color',[0,.6,.2])
                xTickPos=(1:3:3*nConds)+.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([label{l},' (',this.subData.ID ')'])
                hold off
            end
            legend('Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'); %this is for the case when a condition number was skipped
        end
        
        function [boolFlag,labelIdx]=isaCondition(this,cond)
            if isa(cond,'char')
                auxCond{1}=cond;
            elseif isa(cond,'cell')
                auxCond=cond;
            elseif isa(cond,'double')
                auxCond=this.metaData.conditionName(cond);
            end
            N=length(auxCond);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                for i=1:length(this.metaData.conditionName)
                    if strcmpi(auxCond{j},this.metaData.conditionName{i})
                        boolFlag(j)=true;
                        labelIdx(j)=i;
                        break;
                    end
                end
            end
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning([this.subData.ID 'did not perform condition ''' cond{i} ''' or the condition is misspelled.'])
                end
            end
        end
    end
    
    
    
    methods(Static)
        function plotGroupedSubjects(adaptDataList,label,removeBiasFlag,plotIndividualsFlag)
            
            if nargin<4 || isempty(plotIndividualsFlag)
                plotIndividualsFlag=true;
            end
            
            %First: see if adaptDataList is a single subject (char), a cell
            %array of subject names (one group of subjects), or a cell array of cell arrays of
            %subjects names (several groups of subjects), and put all the
            %cases into the same format
            if isa(adaptDataList,'cell')
                if isa(adaptDataList{1},'cell')
                    auxList=adaptDataList;
                else
                    auxList{1}=adaptDataList;
                end
            elseif isa(adaptDataList,'char')
                auxList{1}={adaptDataList};
            end
            Ngroups=length(auxList);
            
            %UPDATE LEGEND IF THESE LINES ARE CHANGED
            N1=3; %very early number of points
            N2=5; %early number of points
            N3=20; %late number of points
            
            ah=optimizedSubPlot(length(label),4,1);
            
            load(auxList{1}{1});
            this=adaptData;
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            for l=1:length(label)
                axes(ah(l))
                hold on
                
                for group=1:Ngroups
                    earlyPoints=[];
                    veryEarlyPoints=[];
                    latePoints=[];
                    for subject=1:length(auxList{group}) %Getting data for each subject in the list
                        load(auxList{group}{subject});
                        if nargin<3 || isempty(removeBiasFlag) || removeBiasFlag==1
                            this=adaptData.removeBias; %Default behaviour
                        else
                            this=adaptData;
                        end
                        for i=1:nConds
                            trials=this.metaData.trialsInCondition{conds(i)};
                            if ~isempty(trials)
                                aux=this.getParamInCond(label(l),conds(i));
                                try %Try to get the first strides, if there are enough
                                    veryEarlyPoints(i,subject)=mean(aux(1:N1));
                                    earlyPoints(i,subject)=mean(aux(1:N2));
                                catch %In case there aren't enough strides, assign NaNs to all
                                    veryEarlyPoints(i,subject)=NaN;
                                    earlyPoints(i,subject)=NaN;
                                end
                                
                                %Last 20 steps, excepting the very last 5
                                try                                    
                                    latePoints(i,subject)=mean(aux(end-N3-4:end-5));
                                catch
                                    latePoints(i,subject)=NaN;
                                end
                            else
                                veryEarlyPoints(i,subject)=NaN;
                                earlyPoints(i,subject)=NaN;
                                latePoints(i,subject)=NaN;
                            end
                        end
                    end
                    %plot bars
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        bar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2),.15/Ngroups,'FaceColor',[.85,.85,.85].^group)
                        bar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2),.15/Ngroups,'FaceColor',[.7,.7,.7].^group)
                    else
                        h(2*(group-1)+1)=bar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2),.3/Ngroups,'FaceColor',[.6,.6,.6].^group);
                    end
                    h(2*group)=bar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2),.3/Ngroups,'FaceColor',[0,.4,.7].^group);
                    %plot individual data points
                    if Ngroups==1 || plotIndividualsFlag %Only plotting individual subject performance if there is only one group, or flag is set
                        if Ngroups==1
                            plot((1:3:3*nConds)-.25+(group-1)/Ngroups,veryEarlyPoints,'x','LineWidth',2)
                            plot((1:3:3*nConds)+.25+(group-1)/Ngroups,earlyPoints,'x','LineWidth',2)
                        else
                            plot((1:3:3*nConds)+(group-1)/Ngroups,earlyPoints,'x','LineWidth',2)
                        end
                        plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'x','LineWidth',2)
                    end
                    %plot error bars (using standard error)
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        errorbar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                        errorbar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    else
                        errorbar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    end
                    errorbar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                end
                xTickPos=(1:3:3*nConds)+.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                title([label{l}])
                hold off
            end
            linkaxes(ah,'x')
            axis tight
            condDes = this.metaData.conditionName;
            if Ngroups==1
                legend([{'Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'}, auxList{1} ]);
            else
                legStr={};
                for group=1:Ngroups
                    legStr=[legStr, {['Early (first 5), Group ' num2str(group)],['Late (last 20 (-5)), Group ' num2str(group)]}];
                end
                legend(h,legStr)
            end
        end
        
        %function [avg, indiv]=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,indivFlag,indivSubs)
        function plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,indivFlag,indivSubs)
            
            %First: see if adaptDataList is a single subject (char), a cell
            %array of subject names (one group of subjects), or a cell array of cell arrays of
            %subjects names (several groups of subjects), and put all the
            %cases into the same format
            if isa(adaptDataList,'cell')
                if isa(adaptDataList{1},'cell')
                    auxList=adaptDataList;
                else
                    auxList{1}=adaptDataList;
                end
            elseif isa(adaptDataList,'char')
                auxList{1}={adaptDataList};
            end
            Ngroups=length(auxList);
            
            %make sure params is a cell array
            if isa(params,'char')
                params={params};
            end
            
            %TO DO: check condition input
            for c=1:length(conditions)        
                cond{c}=conditions{c}(ismember(conditions{c},['A':'Z' 'a':'z' '0':'9'])); %remove non alphanumeric characters                
            end
            
            if nargin<4
                binwidth=1;
            end
            
            %Initialize plot
            ah=optimizedSubPlot(length(params),4,1);
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            LineOrder={'-','--',':','-.'};
            
            %Load data and determine length of conditions
            
            nConds= length(conditions);
            
            s=1;
            for group=1:Ngroups
                for subject=1:length(auxList{group})
                    %Load subject
                    load(auxList{group}{subject});
                    adaptData = adaptData.removeBias;
                    for c=1:nConds                        
                        dataPts=adaptData.getParamInCond(params,conditions{c});
                        nPoints=size(dataPts,1);
                        if nPoints == 0
                            numPts.(cond{c})(s)=NaN;
                        else                             
                            numPts.(cond{c})(s)=nPoints;
                        end                        
                        for p=1:length(params)
                            %itialize so ther are no inconsistant dimensions or out of bounds errors
                            values(group).(params{p}).(cond{c})(subject,:)=NaN(1,1000); %this assumes that the max number of data points that could exist in a single condition is 1000                                         
                            values(group).(params{p}).(cond{c})(subject,1:nPoints)=dataPts(:,p);                            
                        end
                    end
                    s=s+1;
                end
            end           
            
            %plot the average value of parameter(s) entered over time, across all subjects entered.
            for group=1:Ngroups
                Xstart=1;
                lineX=[];
                subjects=auxList{group};
                for c=1:length(conditions)

                    % 1) find the length of each condition

                    %to plot the min number of pts in each condition:

%                       [maxPts,loc]=nanmin(numPts.(cond{c}));
%                       while maxPts<0.75*nanmin(numPts.(cond{c})([1:loc-1 loc+1:end]))
%                           numPts.(cond{c})(loc)=nanmean(numPts.(cond{c})([1:loc-1 loc+1:end])); %do not include min in mean
%                           [maxPts,loc]=nanmin(numPts.(cond{c}));
%                       end

                    %to plot the max:
                    
                    [maxPts,loc]=nanmax(numPts.(cond{c}));
                    while maxPts>1.25*nanmax(numPts.(cond{c})([1:loc-1 loc+1:end]))
                        numPts.(cond{c})(loc)=nanmean(numPts.(cond{c})([1:loc-1 loc+1:end])); %do not include min in mean
                        [maxPts,loc]=nanmax(numPts.(cond{c}));
                    end

                    for p=1:length(params)

                        allValues=values(group).(params{p}).(cond{c})(:,1:maxPts);

                        % 2) average across subjuects within bins

                        %Find (running) averages and standard deviations for bin data
                        start=1:size(allValues,2)-(binwidth-1);
                        stop=start+binwidth-1;
                        %             %Find (simple) averages and standard deviations for bin data
                        %             start = 1:binwidth:(size(allValues,2)-binwidth+1);
                        %             stop = start+(binwidth-1);

                        for i = 1:length(start)
                            t1 = start(i);
                            t2 = stop(i);                                    
                            bin = allValues(:,t1:t2);

                            %errors calculated as SE of averaged subject points
                            subBin=nanmean(bin,2);
                            avg(group).(params{p}).(cond{c})(i)=nanmean(subBin);
                            se(group).(params{p}).(cond{c})(i)=nanstd(subBin)/sqrt(length(subBin));
                            indiv(group).(params{p}).(cond{c})(:,i)=subBin;

%                           %errors calculated as SE of all data
%                           %points (before indiv subjects are averaged)
%                           avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
%                           se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
%                           indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                        end

                        % 3) plot data
                        axes(ah(p))
                        hold on                       
                        y=avg(group).(params{p}).(cond{c});
                        E=se(group).(params{p}).(cond{c});                        
                        condLength=length(y);
                        x=Xstart:Xstart+condLength-1;
                        if nargin>4 && ~isempty(indivFlag) && indivFlag~=0
                            if nargin>5 && ~isempty(indivSubs)
                                subsToPlot=indivSubs{group};                                
                            else
                                subsToPlot=subjects;
                            end
                            for s=1:length(subsToPlot)
                                subInd=find(ismember(subjects,subsToPlot{s}));
                                % %to plot as dots
                                % plot(x,indiv.(['cond' num2str(cond)])(subInd,:),'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                                %to plot as lines
                                Li{group}(s)=plot(x,indiv(group).(params{p}).(cond{c})(subInd,:),LineOrder{group},'color',ColorOrder(subInd,:));
                                legendStr{group}=subsToPlot;
                            end
                            plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group)                            
                        else
                            if Ngroups==1
                                [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);                                
                                set(Li{c},'Clipping','off')
                                H=get(Li{c},'Parent');                                
                                legendStr={conditions};
                            else
                                [Pa, Li{group}]=nanJackKnife(x,y,E,ColorOrder(group,:),ColorOrder(group,:)+0.5.*abs(ColorOrder(group,:)-1),0.7);                                
                                set(Li{group},'Clipping','off')
                                H=get(Li{group},'Parent');                                
                                legendStr{group}={['group ' num2str(group)]};
                            end
                            set(Pa,'Clipping','off')
                            set(H,'Layer','top')
                        end                        
                        h=refline(0,0);
                        set(h,'color','k')                        
                        
                        if c==length(conditions) && group==Ngroups
                            %on last iteration of conditions loop, add title and
                            %vertical lines to seperate conditions
                            title(params{p},'fontsize',12)
                            line([lineX; lineX],ylim,'color','k')
                            xticks=[0 lineX]+diff([0 lineX Xstart+condLength])./2;                    
                            set(gca,'fontsize',8,'Xlim',[0 Xstart+condLength],'Xtick', xticks, 'Xticklabel', conditions)
                        end
                        hold off
                    end
                    Xstart=Xstart+condLength;
                    lineX(end+1)=Xstart-0.5;
                end
            end           
            linkaxes(ah,'x')
            legend([Li{:}],[legendStr{:}])
        end
        
    end %static methods
    
end
