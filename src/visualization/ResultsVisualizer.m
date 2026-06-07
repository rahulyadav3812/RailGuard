classdef ResultsVisualizer
    properties
        outputDir;
    end
    methods
        function obj = ResultsVisualizer(outputDir)
            if nargin<1, outputDir='results/figures'; end
            obj.outputDir = outputDir;
            if ~exist(outputDir,'dir'), mkdir(outputDir); end
        end
        
        function saveFig(obj, f, name)
            try
                drawnow('nocallbacks');
                saveas(f, fullfile(obj.outputDir, [name '.png']));
                fprintf('    Saved: %s\n', name);
            catch ME
                fprintf('    SKIP %s: %s\n', name, ME.message);
            end
            try close(f); catch; end
        end
        
        function plotConfusionMatrix(obj, YTest, predictions, titleStr)
            f = figure('Visible','off','Renderer','painters','CreateFcn','');
            cm = confusionmat(YTest, predictions);
            imagesc(cm); colormap(parula); colorbar;
            set(gca,'XTick',[1 2],'XTickLabel',{'Normal','Attack'},...
                'YTick',[1 2],'YTickLabel',{'Normal','Attack'});
            xlabel('Predicted'); ylabel('Actual'); title(titleStr);
            for r=1:2, for c=1:2
                text(c,r,num2str(cm(r,c)),'HorizontalAlignment','center','Color','w','FontSize',14,'FontWeight','bold');
            end; end
            obj.saveFig(f, 'confusion_matrix');
        end
        
        function plotROC(obj, YTest, scores, label)
            f = figure('Visible','off','Renderer','painters','CreateFcn','');
            [X,Y,~,AUC] = perfcurve(YTest, scores, 1);
            plot(X,Y,'b-','LineWidth',2); hold on;
            plot([0 1],[0 1],'k--');
            xlabel('FPR'); ylabel('TPR');
            title(sprintf('ROC - %s (AUC=%.3f)', label, AUC));
            grid on; hold off;
            obj.saveFig(f, ['roc_' lower(label)]);
        end
        
        function plotBarComparison(obj, values, labels, metricName)
            f = figure('Visible','off','Renderer','painters','CreateFcn','');
            bar(values, 0.6); set(gca,'XTickLabel',labels);
            ylabel(metricName); title([metricName ' Comparison']);
            grid on;
            obj.saveFig(f, ['compare_' lower(metricName)]);
        end
    end
end