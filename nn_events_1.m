% ����� ���������� ������ �������:
% - ������ � ������ excel-���� � ���������
%   - ������� �������������� � �������������� ������ � ���������
%   - ������ ������� ���� ����� �����������, ���� ��� ��������
% - ���������� ��������� ����� �� ��������
%   - ������� �������� � ����� � ������ ������� ��� ������� ����������
%     ��������� �����
% - ��������� ������� ��������� ������� � ���������� �������������
%   ������������� ������� ��� �������� ��
%   (�� �������������� ������������� ������ ��������� ��������
%    � ��������������� ������� ���� ������)
% - ������ ���������� ����� �� ��������� ����� �������� � �����
%   ������� �������
% - [todo] ������� ������� � ���������������� ��������, ���� ��� �� ������
%   ��� ��� ����������
% - [todo] ���������/���������� ���� ����� � ��������� ��������, �����
%   ��������� ��������� �� ����� ��������?
%
% ������ ������������� ����������� todo-���:
% - [todo] ���������� ������������� ����������� ��������, �����
%   ������� ��������������� � ����������� �������� �������
%
% ��� ���� "�� ������", �� �����������:
% - ������������ �������������� ��������� ����� (�����, ��������, ...)
% - ������ ������������ ��������� (PCA-�������������)
% - ������������� ������� (�������� �� ������ ������ ���������)
%
% ����������:
% - ��� ����� ���� �� �������� ������� �����, ��� ����������� ������,
%   �� ��� ������ �������
%   ��� �������� ����� ������ ��� �����,
%   ���� A(length(A)+1) = ��������� ��������
% - �� ��������� ������������ ��������� ��������, ��� ������� �������,
%   ���� � �������� ������� ������
% - ������ � ������� ��� �������� �� ������, ���� �� ���� ����������
%   �� ������� � ������, �� ���� � ������������ ������� � ������ �������
%   ����� ����� ������ ��������� ��������� �����
%   ���������� ���� ���������� ������ ������� �� �������� ����� ���������
%   � �������
% - ��� �������, � ��� ������ � ������� - ��� ������ �����, ����������
%   ������� ���� � �������, ������� � ���� ����������
% - ������ ������ � �������� ��������� ����������, ���������� ���������
%   ����� ��� ������ �������, ������ ������ ������������� ��������
%   � �������� �� ���������� ��������
%   ������������� � ������ ����� ����, ������� ������ �����������
% - ��������� ��������� ������� ����� ������ ����� ���������: A = A'

% ������� ������� �� ����������� �������
clc;

% ������� ������� ������� �� ����������� �������
% ����� ������������ close all hidden ����� ������� ������ ��� �������
close all;

% ������� ��� ����������, ����� ������ ���������
clearvars;

% ����� �� ����������� ���� � ������ �������� ��� ���������� ������
% ������� nn_trained = true
nn_trained = false;

% ������ excel-����
% �� Excel, �� ���� ����� ������ excel-����� ������� �� �����
% num - ������� ������ �����
% txt - ������� ������ ��������� ��������
% raw - �� ������ (������������� �� ����, � ��������� ����� �������� ������)
% ������ ������ � excel-����� - ���������, ����������
excel_file_path = 'D:\Download\event_analysis\sample_1_1.xlsx';
fprintf('����� excel-���� "%s"\n\n', excel_file_path);
[num,txt,raw] = xlsread(excel_file_path, '', '', 'basic');

% ������� ������ ������ � �����������
% (������ ������ � ������� ���������� � �������)
raw(1,:) = [];

% ������ ������ � excel-� - ��� ���� �������, � ������ ������� � ��������
% ����� �������
% ������ ����� � excel-�����
% ������� � ������ ������� ������ (������� ���� ��� ��� ������ ���)
date_column_number = 1;
% ������� � ���������� ������
description_column_number = 2;
% ������� � ��������� ������
factors_column_number = 3;
% ������� � �������� ��������
classes_column_number = 4;

% ������� ������� � ������ ��������
event_dates_original = cell2mat(raw(:,date_column_number));
% �����������/������������ ����� �� �����
% ������� ������ ���������� ��� �������� �� ����������
min_time_original = min(event_dates_original);
max_time_original = max(event_dates_original);
% ������ ��������� ����� (������������������)
time_line_size_original = max_time_original - min_time_original + 1;
% ������� ���� � ������ ��������� ����� ����� ������� �������
event_dates_original = event_dates_original - min_time_original + 1;

fprintf('������ ��������� �����: %d, �����: %d, ������: %d\n\n', min_time_original, max_time_original, time_line_size_original);

% ��������������� ��������� �����. �� ������ ������� ������� ������ � �����
% � ���� �������, � ����� ���� ������������ ��� ���� ����� ������ �����
% ����� ���������

% ���� ����� ����� ������ ����, ����� �������� �������� ������� �
% �������������/�������������� ����� �������, ��� ������������� ����� � ���

% ����������� ������� ��������� ����� � 10 ���
global time_line_zoom;
time_line_zoom = 10;

% ������ �������� ������� � �������� �������� (����)
time_line_sigma_original = 3;
% ������ �������� ������� ������������������
time_line_sigma_scaled = time_line_zoom * time_line_sigma_original;

% ������� �������� (����� �������������������� ����� �����)
% distrib = @(vec) normpdf(vec, 0, time_line_sigma);
distrib = @(vec) pdf('Stable', vec, 0.5, 0, time_line_sigma_scaled, 0);

% ��������� ��� �������� � �������
event_wave_norm_coeff = 1/distrib(0);

% ������ ���� ����� ��� ��������� �� ��������� �����
% � �������� �������� (����)
event_wave_window_size_original = 100;
% ������ ���� ����� ������������������
event_wave_window_size_scaled = event_wave_window_size_original * time_line_zoom;
% ������� ���� � ��� �������� ��������� �� ����� �����
event_wave_window_size_scaled_half = fix(event_wave_window_size_scaled / 2);
event_wave_window_size_scaled = event_wave_window_size_scaled_half * 2;
% ���������� ���� ����� �� ������� ������, �.�. ����������� �����������
% �������, � ����� � ������ �� �� �� ���-����

% (event_wave_x, event_wave_y) - ������� � ������� �������
% �� ����������� �� ��������� ����� �������
% �������� ������������� ���� �� ����� �� ����� �����
event_wave_x = -event_wave_window_size_scaled_half : 1 : event_wave_window_size_scaled_half;
event_wave_y = event_wave_norm_coeff * distrib(event_wave_x);

% ������� ������ ��������
figure('Name', '����� ��������');
plot(event_wave_x, event_wave_y);

% ������� ��������� �������� ���� � ������� �� �����
% (������������ � �������� �� ���-����)
calculate_event_dates_scaled = @(event_dates_original) event_dates_original * time_line_zoom + event_wave_window_size_scaled_half + 1;

% ������� ���������� ��������� ���� ������� �� ������ �������
% (������ �������� ��� X)
calculate_event_window = @(event_center_position_scaled) event_center_position_scaled - event_wave_window_size_scaled_half : event_center_position_scaled + event_wave_window_size_scaled_half;

% ������� ���������� ������� ������������������ ��������� �����
% (��������� �� ���-���� �������� � ������ � �����)
calculate_time_line_size_scaled = @(time_line_size_original) time_line_size_original * time_line_zoom + event_wave_window_size_scaled + 1;

% ������ ������������������ ��������� �����
global time_line_size_scaled;
time_line_size_scaled = calculate_time_line_size_scaled(time_line_size_original);
% �������� �� ��� X ��� ��������� ������ ��������
time_line_range_scaled = 1:time_line_size_scaled;

% ������� ��� ��������� ������ ��������� � ���������
print_start_progress = @(title) fprintf('%s...\n', title);
print_end_progress = @(title) fprintf('%s - �������\n\n', title);

% ������ excel-����

% ������ ������� �� ������� factors_column_number
% � factors_by_row{row_index} ������ �������� ��� ������� � ������ i
% � factors_map{F} ������� ��� ���������� ������ F �� ���� ��������
[factors_by_row, factors_map] = parse_factors(raw, factors_column_number);

% ������� �������� ������ ��������
factors_map_keys = keys(factors_map);

% ������ ������ �� ������� classes_column_number
% � classes_by_row{i} ������ ������� ��� ������� � ������ i
% � classes_map{C} ������� ��� ���������� ����� C �� ���� ��������
[classes_by_row, classes_map] = parse_factors(raw, classes_column_number);

% ������� ������ �������, ��� ������� ����������� ������, � ���������
% �������

% ������� �������� ������ �������
classes_map_keys = cell2mat(keys(classes_map));

% ���� ���������� ��������� � ��������������� ������ ������� �� �������
% classes_events_map(�����) = ������ ������� ������: ������, ����, �������
% ���������� ��� ��������, ������ ��� � ��������������� ������� �� �����
% �������� ������ �� excel-�
% ���� ��� ���� ����� �������� ������ ���� ������ �������
classes_info_map = containers.Map('KeyType','char','ValueType','any');

% ������� ��� �������� ������ ��������� ������
create_class_info = @(class_name, class_event_count) struct('class_name', class_name, 'event_count', class_event_count, 'rows', zeros(class_event_count, 1), 'dates', zeros(class_event_count, 1), 'factors', {{}});

title = '�������� �������� ������';
print_start_progress(title);

% ������ �� ���� �������
for class_key = classes_map_keys
    fprintf('- ����� %s\n', class_key);
    % ������� � ������ ������ ������,
    % �������������� ����������� ������� � ������
    class_info = create_class_info(class_key, classes_map(class_key));
    % ������ �� ���� ������� ������� � ������� � ����� ������ ��,
    % ������� ����������� ����� ������
    class_event_counter = 1;
    for row_index = 1:length(classes_by_row)
        if ismember(classes_by_row{row_index}, class_key)
            fprintf('  - ������� #%d/������:%d/����:%d/: %s, %s\n', class_event_counter, row_index, raw{row_index,date_column_number}, raw{row_index,description_column_number}, strjoin(factors_by_row{row_index}));
            % ����� ������ �� excel-�
            class_info.rows(class_event_counter) = row_index;
            % ���� �������
            class_info.dates(class_event_counter) = event_dates_original(row_index);
            % ������� �������
            class_info.factors{class_event_counter} = factors_by_row{row_index};
            class_event_counter = class_event_counter + 1;
        end
    end
    % ������� ���� � ������ ����
    class_info.dates = class_info.dates - min(class_info.dates) + 1;
    % �������� �������� ��� �������
    class_info.time_line_size_original = max(class_info.dates);
    % �������� ������ �� �������� ������
    classes_info_map(class_key) = class_info;
end

print_end_progress(title);

% ����������� �������� ��������� ����� ������� ������ �������
% (������������� �������)

% ���������� ������������� ��������
generated_negative_classes_count = 10;

% ������ �������� �������
% �� ��� ����� ����� ��������� ��������� ��� ��������� �������
classes_info_values = cell2mat(values(classes_info_map));

title = '��������� ��������� ������';
print_start_progress(title);

% ����������� ��������� ������ � �������� ����������
for generated_class_counter = 1:generated_negative_classes_count
    % ������� �������� �������� �����
    class_events_refered = classes_info_values(randi(length(classes_info_values)));
    % ����������� �������� ���������� �������, +/- 50% �� ���������
    random_event_count = fix(class_events_refered.event_count/2) + randi(class_events_refered.event_count);
    % �������� ������ ����� � ������ ����������� �������
    % � ��������������� ������
    class_info = create_class_info(sprintf('generated_class_%02d', generated_class_counter), random_event_count);
    fprintf('- ����� %s\n', class_info.class_name);
    % ����������� �������� �������� ��� ��� �������, +/- 50% �� ���������
    random_date_range = fix(class_events_refered.time_line_size_original/2) + randi(class_events_refered.time_line_size_original);
    % �������� ����� ���������������� ���������
    for class_event_counter = 1:random_event_count
        % ����������� �������� ���� �������
        generated_event_date = randi(random_date_range);
        % ���� �������
        class_info.dates(class_event_counter) = generated_event_date;
        % ����������� �������� ���������� ��������, +/- 50% �� ���������
        original_factor_count = length(class_events_refered.factors);
        % ����� �������� �� ���� ������ ��� ���� ���� ������� ��
        % ���������� � ������ ����������
        random_factor_count = min([fix(original_factor_count/2) + randi(original_factor_count) length(factors_map_keys)]);
        % c���������� ������� �������
        % ���������� ����� ����������, ����� ������� �� �������������
        % (��� ����� ���������������� ���� ������ ������� � ����� �� �������� ������ � �� �� �����, ��� ���������)
        class_info.factors{class_event_counter} = factors_map_keys(randperm(length(factors_map_keys), random_factor_count));
        fprintf('  - ������� #%d/����:%d/: %s\n', class_event_counter, generated_event_date, strjoin(class_info.factors{class_event_counter}));
    end
    % ������� ���� � ������ ����
    class_info.dates = class_info.dates - min(class_info.dates) + 1;
    % �������� �������� ��� �������
    class_info.time_line_size_original = max(class_info.dates);
    % �������� ������ �� �������� ������
    classes_info_map(class_info.class_name) = class_info;
end

print_end_progress(title);

% �������� ��������� ����� �� �������� ��� �������
% ������ ���� ����� - ���� ������
% ���� ��� ���������� ���������/���������� ��������

% ���� ���������� ������ �������
classes_info_values = cell2mat(values(classes_info_map));

title = '�������� ��������� ����� �� ���� �������';
print_start_progress(title);

% �������� �� ���� �������
for class_info = classes_info_values
    fprintf('- ����� %s\n', class_info.class_name);
    % ����, ������������� � ������� �� ��������� ����� (�������� �� ��� ���� ��������)
    class_info.dates_scaled = calculate_event_dates_scaled(class_info.dates);
    % ��������� ����� ��� ����� ������, �� ��������, � ����������� ���������� �������
    class_info.time_line_size_scaled = calculate_time_line_size_scaled(class_info.time_line_size_original);
    class_info.factor_time_line = zeros(length(factors_map), class_info.time_line_size_scaled);
    % ������ ������������������ ��� �� ��������
    class_info.dates_by_factor_scaled = cell(length(factors_map_keys), 1);
    % �������� �� ���� �������� ������
    for class_event_counter = 1:class_info.event_count
        fprintf('  - ������� #%d [%d]\n', class_event_counter, class_info.dates(class_event_counter));
        % �������� �� ���� �������� ������� � ����������� ������� �� ��������� �����
        for factor_key = class_info.factors{class_event_counter}
            % ����� ���������� ����� ������� � ������ ���� ��������
            factor_index = find(strcmp(factors_map_keys, factor_key));
            fprintf('    - ������ [%d]: %s\n', factor_index, factor_key{1});
            % ����� ������� �� ����� (������� �� ��� ���� ��������)
            event_center_position = class_info.dates_scaled(class_event_counter);
            % �������� ��� ������� ��� �������
            class_info.dates_by_factor_scaled{factor_index}(length(class_info.dates_by_factor_scaled{factor_index}) + 1) = event_center_position;
            % ���� ������ ��������� ����� � ������� � �������
            event_window = calculate_event_window(event_center_position);
            % ������� ���� �������� �� ��������� �����
            class_info.factor_time_line(factor_index, event_window) = class_info.factor_time_line(factor_index, event_window) + event_wave_y;
        end
    end
    % �������� ������ �� �������� ������
    classes_info_map(class_info.class_name) = class_info;
end

print_end_progress(title);

%{
% ������� ������� ������� �� �������
% � ������� ������� ���� ��������, ������� ������� �� ���������
figure('Name', '������� �� �������');

% ���� ���������� ������ �������
classes_info_values = cell2mat(values(classes_info_map));

class_index = 1;
for class_info = classes_info_values
    subplot(length(classes_info_map), 1, class_index);
    plot(class_info.factor_time_line');
    class_index = class_index + 1;
end
%}

% �������� ��������� ������� ��� ��������� ����
% ���� �� �� - �������
% [������ ���� ������� * ���������� ���� ��������]
% ����� ��� ������� �������� �������� (����������� ������� �� �� ��������)
% ������ ��� �������� ������ �� �����, �.�. ��� ������ ������� �����
% ������� ��� ���� �� ������������ ����� ���� �������

% ���� ���������� ������ �������
classes_info_values = cell2mat(values(classes_info_map));

% ������ ���� ������� ��� ������������ �������� ��� � �������
global nn_event_window_size;
nn_event_window_size = max([classes_info_values.time_line_size_scaled]);

title = '�������� ��������� ������� �� �������';
print_start_progress(title);

% �������� �� ���� �������
for class_info = classes_info_values
    fprintf('- ����� %s\n', class_info.class_name);
    % ��������� ������� ����� ������� �� ��������
    class_info.event_matrix = zeros(length(factors_map_keys), nn_event_window_size);
    % �������� �� ���� �������� ������
    for class_event_counter = 1:class_info.event_count
        fprintf('  - ������� #%d [%d]\n', class_event_counter, class_info.dates(class_event_counter));
        % �������� �� ���� �������� ������� � ����������� ������� �� ��������� �����
        for factor_key = class_info.factors{class_event_counter}
            % ����� ���������� ����� ������� � ������ ���� ��������
            factor_index = find(strcmp(factors_map_keys, factor_key));
            fprintf('    - ������ [%d]: %s\n', factor_index, factor_key{1});
            % �������� ������� �� ���
            class_event_window_x = 1:class_info.time_line_size_scaled;
            % ������� ����� ������� �� ������� �� ������� �������
            class_info.event_matrix(factor_index, class_event_window_x) = class_info.factor_time_line(factor_index, class_event_window_x);
        end
    end
    % ������ ������� ��������
    class_info.event_matrix_linear = class_info.event_matrix';
    class_info.event_matrix_linear = class_info.event_matrix_linear(:);
    % �������� ������ �� �������� ������
    classes_info_map(class_info.class_name) = class_info;
end

print_end_progress(title);

% ������� ������� ������� �� �������
figure('Name', '������� ������� �� �������');

% ���� ���������� ������ �������
classes_info_values = cell2mat(values(classes_info_map));

class_index = 1;
for class_info = classes_info_values
    subplot(length(classes_info_map), 1, class_index);
    plot(class_info.event_matrix');
    class_index = class_index + 1;
end

% ������� �������� ������� ������� �� �������
figure('Name', '�������� ������� ������� �� �������');

% ���� ���������� ������ �������
classes_info_values = cell2mat(values(classes_info_map));

class_index = 1;
for class_info = classes_info_values
    subplot(length(classes_info_map), 1, class_index);
    plot(class_info.event_matrix_linear);
    class_index = class_index + 1;
end

% �������� ������� ��� �������� ��������� ����
% ������ ������� ��� ���� �����/������
nn_input = [classes_info_values.event_matrix_linear];

% �������� ������� ��������� ����
% ���������� �������� ����� �� ��� �� ������� �������
% (��� ���������� ��������, ��� ������ ����� �� ��� ���������� �������)
% ���������� ����� - ��� ��������� �������
% ������ � ������� ���������� ��������� ����������� ������ � ������
% � ��� ���� ������ ����������� ������ ������, ������� � ������� ��� ����,
% �� ����������� ������ � ������ �������
nn_output = zeros(length(classes_info_values), size(nn_input, 2));

for class_index = 1:length(classes_info_values)
    % ���� ���� ������ �� �����, �� ���� ����� ������, ����� ����� ���� �� sample_index
    sample_index = class_index;
    nn_output(class_index, sample_index) = 1;
end

global nn;

if nn_trained
    title = '�������� ��������� ��������� ����';
    print_start_progress(title);
    
    load nn;
    
    print_end_progress(title);
else
    title = '������ ��������� ����';
    print_start_progress(title);
    
    % ��������� ���� � ����� ������, � ������ ���������� �������� � ������ ����
    % ���������������� ���������� �������� ����� ����� ������ �������
    % ���������� ������� � ������
    % ������ ���� ������� ���� ������ ������ ������� ���� �� �����
    nn = patternnet([10 10]);
    % �� ���������� ���� � �� ����� ��������
    nn.trainParam.showWindow = 0;
    % ������� ��������� ���� �� ��������
    nn = train(nn, nn_input, nn_output);
    
    save nn;
    
    print_end_progress(title);
end

% �������� ��������� ����� ����� ���������

% factor_time_line[������]
% ��� ������� ��������� ����� ������� �� ������� �������
% � ���������� � ���� �������
% � ������ � � ����� � ��� ���������� �� �������� ���� ��������
% ����� ������� ������� �� �������� �� ������� �������
global factor_time_line;
factor_time_line = zeros(length(factors_map), time_line_size_scaled);

% ����, ������������� � ������� �� ��������� ����� (�������� �� ��� ���� ��������)
event_dates_scaled = calculate_event_dates_scaled(event_dates_original);

% ���� ���������� ������� ������� �� ����� �� ������� �������
% (����� ����� �������� ������� �� �������)
% /������ ������� ��� �����������������/ event_dates_time_line_by_factor = cell(length(factors_map_keys), 1);
% ������� ������� ����� ��� ������ ��� ������� �������
event_dates_by_factor_scaled = cellfun(@(fk) zeros(factors_map(fk), 1), factors_map_keys, 'UniformOutput', false);

title = '�������� ��������� ����� �� ��������';
print_start_progress(title);

% �������� �� ���� ��������, �� ���� ��� ��������
% � ��������� ������ ������ �� ��������������� ��������� �����
for row_index = 1:length(event_dates_original)
    if ~isfinite(event_dates_original(row_index))
        % ���������� ��-�����
        continue;
    end
    fprintf('- ������� [%d]: %s\n', raw{row_index,date_column_number}, raw{row_index,description_column_number});
    % �������� �� ���� �������� ������� � ����������� ������� �� ��������� �����
    for factor_key = factors_by_row{row_index}
        % ����� ���������� ����� ������� � ������ ���� ��������
        factor_index = find(strcmp(factors_map_keys, factor_key));
        fprintf('  - ������ [%d]: %s\n', factor_index, factor_key{1});
        % ����� ������� �� ����� (������� �� ��� ���� ��������)
        event_center_position = event_dates_scaled(row_index);
        % �������� ��� ������� ��� ������� (��������� � �����, ������������� ������� - �������)
        event_dates_by_factor_scaled{factor_index}(find(event_dates_by_factor_scaled{factor_index}==0,1)) = event_center_position;
        % ���� ������ ��������� ����� � ������� � �������
        event_window = calculate_event_window(event_center_position);
        % ������� ���� �������� �� ��������� �����
        factor_time_line(factor_index, event_window) = factor_time_line(factor_index, event_window) + event_wave_y;
    end
end

print_end_progress(title);

% ������� ������� ������� �� ��������
figure('Name', '��� ����� ������� �� ��������');
% ������ ����� �� ���� �������� � ������ ���������
subplot(length(factors_map_keys) + 1, 1, 1);
plot(factor_time_line');
for factor_index = 1:length(factors_map_keys)
    % ������ ������ i � i+1 ���������
    subplot(length(factors_map_keys) + 1, 1, factor_index+1);
    plot(factor_time_line(factor_index,:), '-o', 'MarkerIndices', event_dates_by_factor_scaled{factor_index});
end

%{
% ������������ ��� ����� ������� ���������� ����� �� ���� ��������� ����
% ������ �������

% ��� ���� (1/20 �� ������� ����)
% ����� ��������� � �������, ���� ����� �� ��������
nn_event_window_step = time_line_zoom;%fix(nn_event_window_size / 20);

% ��������� ���� �����
nn_all_step_positions = 1:nn_event_window_step:time_line_size_scaled-nn_event_window_size;

% ���������� �����
nn_event_window_step_count = length(nn_all_step_positions);

% ������� ����������� �� ���� ����� ��� �������
nn_all_step_result = zeros(nn_event_window_step_count, length(classes_info_values));

title = '�������� ��� ����� ������� ��������� �����';
print_start_progress(title);

fprintf('������ ������������������ �����: %d\n', time_line_size_scaled);
fprintf('������ ���� �������: %d\n', nn_event_window_size);
fprintf('��� ���� �������: %d\n', nn_event_window_step);
fprintf('���������� �����: %d\n', nn_event_window_step_count);

% ������ ��� ����� ������� � �������� �����
for nn_event_window_step_counter = 1:nn_event_window_step_count
    nn_event_window_position = nn_all_step_positions(nn_event_window_step_counter);
    fprintf('- ������� %d\n', nn_event_window_position);
    % ��������� ������� ����� ������� �� ��������
    % ���������� �� ���������� ���� �� �������� �����
    step_event_matrix = factor_time_line(:, nn_event_window_position:nn_event_window_position+nn_event_window_size-1);
    % ������ ������� ��������
    step_event_matrix_linear = step_event_matrix';
    step_event_matrix_linear = step_event_matrix_linear(:);
    nn_step_result = nn(step_event_matrix_linear);
    nn_all_step_result(nn_event_window_step_counter, :) = nn_step_result;
end

print_end_progress(title);

% ������� ���������� ������������ ��������� �����
figure('Name', '���������� ������������ ��������� ����� - 1');
% ������ ����� �� ���� �������� � ������ ���������
subplot(length(classes_info_values) + 1, 1, 1);
plot(factor_time_line');
for class_index = 1:length(classes_info_values)
    % ������ ���������� i � i+1 ���������
    subplot(length(classes_info_values) + 1, 1, class_index+1);
    plot(nn_all_step_positions, nn_all_step_result(:,class_index));
end
%}

% ������������ ��� ����� ������� ���������� ����� �� ���� ��������� ����
% ������ �������, ��� �� �������� �����

% ��������� ���� ����� � �������� ���������
nn_all_step_positions_original = 1:time_line_size_original;
% ��������� ���� ����� � �������� ������������������
nn_all_step_positions_scaled = nn_all_step_positions_original * time_line_zoom;

% ������� ����������� �� ���� ����� ��� �������
nn_all_window_result = zeros(time_line_size_scaled, length(classes_info_values));

title = '�������� ��� ����� ������� ��������� �����';
print_start_progress(title);

% ������ ��� ����� ������� � ����� � �������� ���
nn_event_window_step_counter = 1;
for event_date_original = nn_all_step_positions_original
    fprintf('- ������� %d/%d\n', event_date_original, time_line_size_original);
    [nn_window_result, nn_event_window_position, window_event_matrix, out_of_range] = calc_nn_window(event_date_original);
    if out_of_range
        fprintf('- ��������� ������ ������������\n');
        break;
    end
    nn_all_window_result(nn_event_window_position-time_line_zoom+1:nn_event_window_position, :) = repmat(nn_window_result, 1, time_line_zoom)';
    nn_event_window_step_counter = nn_event_window_step_counter + 1;
end

print_end_progress(title);

% ������� ���������� ������������ ��������� �����
figure('Name', '���������� ������������ ��������� ����� - 2');
% ������ ����� �� ���� �������� � ������ ���������
subplot(length(classes_info_values) + 1, 1, 1);
plot(factor_time_line');
xlim([1 time_line_size_scaled]);
for class_index = 1:length(classes_info_values)
    % ������ ���������� i � i+1 ���������
    subplot(length(classes_info_values) + 1, 1, class_index+1);
    plot(1:time_line_size_scaled, nn_all_window_result(:,class_index));
    xlim([1 time_line_size_scaled]);
end

% ������� parse_factors - ������ �������/������ �� excel-�

function [factors_by_row, factors_map] = parse_factors(raw, factor_column_number)

% �� �����:
% - raw - ������� �� excel
% - ������� � ������� factor_column_number, ����� ����� �������
% �� ������:
% - � factors{i} ����� ������������ ������� ���� ��� ������� � ������ i
% - � factors_map ����� ���� ������ �������� �� ���� ��������
%   � ���� �������������� ���������:
%   factors_map(������) = ������� ��� ���������� ���� ������ � ��������

% ���� � factors ������ ������� � �������/�������� ��������
factors_by_row = raw(:,factor_column_number);
% ���� ���������� ��� ������������� �������
factors_map = containers.Map;

% �������� �� ���� �������-��������
for row_index = 1:length(factors_by_row)
    % ������ ������ �� ����� �������� �� �������,
    % ��� �������� � ������ � �����
    
    % ��������� ������� � ������� ������
    single_event_factors = {};
    
    if ischar(factors_by_row{row_index}) % ��� �����?
        single_event_factors = strsplit(lower(strtrim(factors_by_row{row_index})),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors_by_row{row_index}) % ��� �����?
        single_event_factors = {num2str(factors_by_row{row_index})};
    end
    
    % ��������� ��� ������� �������� ������� � ��������� ���� ��������
    % ������ ������� ���������� ������� ������� � �����������, ����������
    for curren_event_factor = single_event_factors
        factor_count = 0;
        if factors_map.isKey(curren_event_factor{1})
            factor_count = factors_map(curren_event_factor{1});
        end
        factors_map(curren_event_factor{1}) = factor_count + 1;
    end
    
    % ���������� ������������ ������ �������� ��� �������
    factors_by_row{row_index} = single_event_factors;
end

end % function parse_factors
