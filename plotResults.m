function plotResults(continuity_map, coherency_scores, places, ...
  nodes_all_frames, inter_matches_all_frames, match_ratios, summary_graphs, ...
  recognized_places)

global FIRST_FRAME LAST_FRAME DATASET_NO draw_cf_node_radius FILE_HEADER FILE_SUFFIX ...
  NODE_PERCENT_THRES DO_PERF_MEASUREMENT SCALE_DOWN_RATIO TEST_FOLDER ...
  GT_PLACES_FILE;

%clear results file
mkdir(strcat('Results/',num2str(DATASET_NO)));
delete(strcat('Results/',num2str(DATASET_NO),'/*.*'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE SSGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

min_place_nr = min(places(places ~= 0 & places ~= -1));
max_place_nr = max(places);


for place_nr = min_place_nr:max_place_nr
  fig_ssg = figure();
  set(fig_ssg, 'Visible', 'off');
  
  for i = 1:size(summary_graphs,1)
    avg_node = summary_graphs{i,place_nr};

    place_length = size(find(places == place_nr),2);
    
    if(~isempty(avg_node) && avg_node{1,1} > NODE_PERCENT_THRES*place_length)
      node_radius = avg_node{1,3}(4)*draw_cf_node_radius;
      colorR = avg_node{1,3}(3)/255;
      colorG = avg_node{1,3}(2)/255;
      colorB = avg_node{1,3}(1)/255;

      rectangle('Position', [avg_node{1,2}-[node_radius/2.0, node_radius/2.0],node_radius,node_radius],...
                'Curvature', [1,1],...
                'FaceColor', [colorR,colorG,colorB]);
      hold on;
    end
  end
  print(fig_ssg,strcat('Results/',num2str(DATASET_NO),'/ssg-',num2str(place_nr)),'-depsc');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT RECOGNIZED PLACES AND GROUND TRUTH PLACES %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(~isempty(GT_PLACES_FILE))
  fig_gt_places = figure;

  locs = readDatasetLocations(DATASET_NO);

  % first plot ground truth labels
  for i = 1:max(locs(3,:))
    base_points = locs(:,locs(3,:) == i);
    plot(base_points(1,:),base_points(2,:),'LineWidth',10,'Color',[0,i/max(locs(3,:)),0]);
    hold on;
  end

  %plot places
  for i = 1:max(places)
    place_points = locs(:,FIRST_FRAME - 1 + find(places == i));
    plot(place_points(1,:),place_points(2,:),'Color','r','LineWidth',10);
    hold on;
    if(i < max(places))
      trans_points = locs(:,FIRST_FRAME  + find(places == i,1,'last'):...
                            FIRST_FRAME - 2 + find(places == i+1,1,'first'));
      plot(trans_points(1,:),trans_points(2,:),'Color','b','LineWidth',10);
      hold on;
    end
  end
  title('Ground Truth Places and Detected Places');
  axis equal;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT CONFUSION MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(DO_PERF_MEASUREMENT && ~isempty(TEST_FOLDER) && ~isempty(recognized_places) )
  recognized_places = recognized_places(1,1:size(places,2));
  recognized_places_ids = find(recognized_places);
  filtered_places = places(recognized_places_ids);
  filtered_recognized = recognized_places(recognized_places_ids);
  
  conf_matrix = zeros(max(filtered_places),max(filtered_places));
  for i = 1:max(filtered_places)
    for j = 1:max(filtered_places)
      actual_places_ids = find(filtered_places == i);
      predicted_places_ids = find(filtered_recognized(actual_places_ids)==j);
      conf_matrix(i,j) = size(predicted_places_ids,2)/size(actual_places_ids,2);
    end
  end
  
  plotConfMatrix(conf_matrix);
  
  correctly_recognized = size(find(filtered_places == filtered_recognized),2) / ...
    size(find(filtered_places~=0),2);
 
  disp(['Recognition rate is: ', num2str(correctly_recognized)]); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT CONTINUITY MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig = figure('units','normalized','outerposition',[0 0 1 1]);

%draw black-white continuity map
fig_coh_map = subplot(4,1,1);


imagesc(continuity_map);
colormap([1 1 1; 0 0 0]);
title('Coherency Map');
ylabel('Node #');
xlabel('Frames');
axis xy;
hold on;

dcm_obj = datacursormode(fig);
datacursormode on;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT COHERENCY SCORES AND DETECTED PLACES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig_coherency = subplot(4,1,2);
ylabel('Incoherency');
xlabel('Frames');

plot_height = size(continuity_map,1);

for i = min(places(places>0)):max(places)
  place_i1_start = find(places == i,1,'first');
  place_i1_end   = find(places == i,1,'last');
  
  if(i < max(places))
    place_i2_start = find(places == i+1,1,'first');
    place_i2_end   = find(places == i+1,1,'last');

    %places
    p=patch([place_i1_start place_i1_end place_i1_end place_i1_start],[0 0 1 1],'r');
    hold on;

    %transitions
    p=patch([place_i1_end place_i2_start place_i2_start place_i1_end],[0 0 1 1],'b');
    hold on;
  else
    %places
    p=patch([place_i1_start place_i1_end place_i1_end place_i1_start],[0 0 1 1],'r');
    hold on;
  end
  
end

coherency_scores_normalized = normalize_var(coherency_scores,0,1);
plot(coherency_scores_normalized,'color','g','LineWidth',2);
hold on;

extractBestKeyframes(places, coherency_scores_normalized);

%plot detected places
%stairs(places(2:end),'color','r','LineWidth',1);
xlim([1,LAST_FRAME-FIRST_FRAME]);
hold on;

%plot performance results
if(DO_PERF_MEASUREMENT && ~isempty(TEST_FOLDER) && ~isempty(recognized_places))
  ids = find(recognized_places(1,:) ~= 0);
  
  for i = 1:size(ids,2)
    if(ids(i) < size(places,2))
    if(recognized_places(1,ids(i)) == places(1,ids(i)))
      plot(ids(i),recognized_places(1,ids(i)),'+','color','b','LineWidth',1);
      hold on;
    else
      plot(ids(i),recognized_places(1,ids(i)),'+','color','r','LineWidth',1);
      hold on;
    end
    end
  end
  hold on;
end

%plot consecutive frames match ratios
match_ratios = normalize_var(match_ratios,0,plot_height);
%plot(match_ratios,'color','b','LineWidth',2);
title('Incoherency scores and selected keyframes based on coherent regions');


print(fig,strcat('Results/',num2str(DATASET_NO),'/result'),'-depsc');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT ASSOCIATED PLACE AND SSG WHEN CLICKED %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while(1)
    %pause
    waitforbuttonpress
    c_info = getCursorInfo(dcm_obj);
    
    selected_frame_id = floor(c_info.Position(1));
    selected_unique_node_id = floor(c_info.Position(2));
             
    [X2,map2]= imread(strcat('Datasets/',num2str(DATASET_NO),...
                            '/',FILE_HEADER,zeroPad(FIRST_FRAME+selected_frame_id),...
                            num2str(FIRST_FRAME+selected_frame_id),...
                            FILE_SUFFIX));
    
    subplot(4,1,3);
    

    imshow(X2,map2);
    set(gca,'Ydir','reverse');
    title('Clicked frame');
    
    hold on;
                  
    if(continuity_map(selected_unique_node_id,selected_frame_id) == 1)
      inter_matches = inter_matches_all_frames{selected_frame_id};
      node_id = find(inter_matches == selected_unique_node_id);
      selected_node = nodes_all_frames{selected_frame_id}(node_id,:);


      nodeRadius = selected_node{1,2}(4)*draw_cf_node_radius*6;
      colorR = selected_node{1,2}(1)/255;
      colorG = selected_node{1,2}(2)/255;
      colorB = selected_node{1,2}(3)/255;
        
      
      rectangle('Position', [selected_node{1,1}/SCALE_DOWN_RATIO-[nodeRadius/2.0, nodeRadius/2.0],nodeRadius,nodeRadius],...
                'Curvature', [1,1],...
                'FaceColor', [1,0,0]);
      hold on;
    end
    
    %plot corresponding summary graph
    h3 = subplot(4,1,4);
            
    if(size(places,2) < selected_frame_id || places(selected_frame_id) <= 0)
      cla(h3);
    else
      cla(h3);
      place_id = places(selected_frame_id); 
      place_length = size(find(places == place_id),2);
      if(place_id > 0)
        for i = 1:size(summary_graphs,1)
          avg_node = summary_graphs{i,place_id};

          if(~isempty(avg_node) && avg_node{1,1} > NODE_PERCENT_THRES*place_length)
            node_radius = avg_node{1,3}(4)*draw_cf_node_radius;
            colorR = avg_node{1,3}(3)/255;
            colorG = avg_node{1,3}(2)/255;
            colorB = avg_node{1,3}(1)/255;

            rectangle('Position', [avg_node{1,2}-[node_radius/2.0, node_radius/2.0],node_radius,node_radius],...
                      'Curvature', [1,1],...
                      'FaceColor', [colorR,colorG,colorB]);
            hold on;
          end
        end
      end
    end
    
    title('SSG');
    axis equal;
    set(gcf,'Visible','off');
    set(gca,'Ydir','reverse');
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    set(gca,'XColor',[1,1,1]);
    set(gca,'YColor',[1,1,1]);

end

end

