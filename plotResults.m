function plotResults(continuity_map, coherency_scores, places, ...
  nodes_all_frames, inter_matches_all_frames, match_ratios, summary_graphs)

global FIRST_FRAME DATASET_NO draw_cf_node_radius FILE_HEADER

fig = figure('units','normalized','outerposition',[0 0 1 1]);
subplot(3,1,1);

%mahmut: experimental
% h = size(continuity_map,1);
% 
% for i=1:h
%   ind = findLongSeq(continuity_map(i,:));
%   continuity_map(i,:) = 0;
%   continuity_map(i,ind) = 1;
% end

%mahmut: experimental ends

%draw black-white continuity map
imagesc(continuity_map);
colormap([1 1 1; 0 0 0]);
hold on;

plot_height = size(continuity_map,1);

%plot coherency scores
coherency_scores_normalized = normalize_var(coherency_scores,0,plot_height);
plot(coherency_scores,'color','g','LineWidth',2);
hold on;

%plot detected places
stairs(places(2:end),'color','r','LineWidth',2);
hold on;

%plot consecutive frames match ratios
match_ratios = normalize_var(match_ratios,0,plot_height);
%plot(match_ratios,'color','b','LineWidth',2);
axis xy;

dcm_obj = datacursormode(fig);
datacursormode on;


while(1)
    %pause
    waitforbuttonpress
    c_info = getCursorInfo(dcm_obj);
    
    selected_frame_id = floor(c_info.Position(1));
    selected_unique_node_id = floor(c_info.Position(2));
    
    [X1,map1]=imread(strcat('Datasets/',num2str(DATASET_NO),...
                            '/',FILE_HEADER,zeroPad(FIRST_FRAME+selected_frame_id),...
                            num2str(FIRST_FRAME+selected_frame_id),...
                            '.jpg'));
                          
    subplot(3,1,2);

    imshow(X1,map1);
    hold on;
                  
    if(continuity_map(selected_unique_node_id,selected_frame_id) == 1)
      inter_matches = inter_matches_all_frames{selected_frame_id};
      node_id = find(inter_matches == selected_unique_node_id);
      selected_node = nodes_all_frames{selected_frame_id}(node_id,:);


      nodeRadius = selected_node{1,2}(4)*draw_cf_node_radius;
      colorR = selected_node{1,2}(1)/255;
      colorG = selected_node{1,2}(2)/255;
      colorB = selected_node{1,2}(3)/255;
        
      
      rectangle('Position', [selected_node{1,1}-[nodeRadius/2.0, nodeRadius/2.0],nodeRadius,nodeRadius],...
                'Curvature', [1,1],...
                'FaceColor', [0,1,0]);
      hold on;
    end
    
    %plot corresponding summary graph
    subplot(3,1,3);
    axis equal;
    set(gcf,'Visible','off');
    set(gca,'Ydir','reverse')
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    set(gca,'XColor',[1,1,1]);
    set(gca,'YColor',[1,1,1]);
        
    place_id = places(selected_frame_id);
    if(place_id > 0)
      for i = 1:size(vertcat(summary_graphs{:,place_id}),1)
        avg_node = summary_graphs{i,place_id};
        
        if(avg_node{1,1} > 5)
          node_radius = avg_node{1,1};
          colorR = avg_node{1,3}(1)/255;
          colorG = avg_node{1,3}(2)/255;
          colorB = avg_node{1,3}(3)/255;

          rectangle('Position', [avg_node{1,2}-[node_radius/2.0, node_radius/2.0],node_radius,node_radius],...
                    'Curvature', [1,1],...
                    'FaceColor', [colorR,colorG,colorB]);
          hold on;
        end
      end
    end

end

end

