% ����� ���������� ������ �������:
% - ������ � ������ excel-���� � ���������
%   - ������� �������������� � �������������� ������ � ���������
%   - ������ ������� ���� ����� �����������, ���� ��� ��������
% - ���������� ��������� ����� �� ��������
%   - ������� �������� � ����� � ������ ������� ��� ������� ����������
%     ��������� �����
% - [todo] ��������� ������� ��������� ������� � ���������� �������������
%   ������������� ������� ��� �������� ��
%   (�� �������������� ������������� ������ ��������� ��������
%    � ��������������� ������� ���� ������)
% - [todo] ������ ���������� ����� �� ��������� ����� �������� � �����
%   ������� �������
%
% ������ ������������� ����������� todo-���:
% - [todo] ���������� ������������� ����������� ��������, �����
%   ������� ��������������� � ����������� �������� �������
% - [todo] ������� ������� �� ��������
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

% ������ excel-����
% �� Excel, �� ���� ����� ������ excel-����� ������� �� �����
% num - ������� ������ �����
% txt - ������� ������ ��������� ��������
% raw - �� ������ (������������� �� ����, � ��������� ����� �������� ������)
% ������ ������ � excel-����� - ���������, ����������
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');
% ������� ������ ������ � �����������
raw(1,:) = [];

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
event_dates = cell2mat(raw(:,date_column_number));
% �����������/������������ ����� �� �����
% ������� ������ ���������� ��� �������� �� ����������
min_time = min(event_dates);
max_time = max(event_dates);
% ������ ��������� �����
time_line_size = max_time - min_time;
% ������� ���� � ������ ��������� ����� ����� ������� �������
event_dates = event_dates - min_time;

fprintf('������ ��������� �����: %.2f, �����: %.2f, ������:  %.2f\n', min_time, max_time, time_line_size);

% ��������������� ��������� �����. �� ������ ������� ������� ������ � �����
% � ���� �������, � ����� ���� ������������ ��� ���� ����� ������ �����
% ����� ���������

% ���� ����� ����� ������ ����, ����� �������� �������� ������� �
% �������������/�������������� ����� �������, ��� ������������� ����� � ���

% ����������� ������� ��������� ����� � 10 ���
time_line_zoom = 10;

% ������ �������� ������� � �������� �������� (����)
time_line_sigma_original = 3;
% ������ �������� ������� ������������������
time_line_sigma = time_line_zoom * time_line_sigma_original;

% ������� �������� (����� �������������������� ����� �����)
% distrib = @(vec) normpdf(vec, 0, time_line_sigma);
distrib = @(vec) pdf('Stable', vec, 0.5, 0, time_line_sigma, 0);

% ��������� ��� �������� � �������
event_wave_scale = 1/distrib(0);

% ������ ���� ����� ��� ��������� �� ��������� �����
% � �������� �������� (����)
event_wave_window_original = 100;
% ������ ���� ����� ������������������
event_wave_window = event_wave_window_original * time_line_zoom;
% ������� ���� � ��� �������� ��������� �� ����� �����
event_wave_window_half = fix(event_wave_window / 2);
event_wave_window = event_wave_window_half * 2;

% (event_wave_x, event_wave_y) - ������� � ������� �������
% �� ����������� �� ��������� ����� �������
% �������� ������������� ���� �� �����
event_wave_x = -event_wave_window_half : 1 : event_wave_window_half;
event_wave_y = event_wave_scale * distrib(event_wave_x);

% ������� ������ ��������
% figure('Name', '����� ��������');
% plot(event_wave_x, event_wave_y);

% return

% ������ excel-����

% ������ ������� �� ������� factors_column_number
[factors, factors_map] = parse_factors(raw, factors_column_number);

% ������ ������ �� ������� classes_column_number
[classes, classes_map] = parse_factors(raw, classes_column_number);

% ������� ������ �������, ��� ������� ����������� ������, � ���������
% �������

% ������� �������� ������ �������
classes_map_keys = keys(classes_map);

% ���� ���������� ��������� � ��������������� ������ ������� �� �������
% classes_events_map(�����) = ������ ������� ������: ������, ����, �������
% ���������� ��� ��������, ������ ��� � ��������������� ������� �� �����
% �������� ������ �� excel-�
% ���� ��� ���� ����� �������� ������ ���� ������ �������
classes_events_map = containers.Map('KeyType','char','ValueType','any');

% ������� ��� �������� ������ ��������� ������
create_class_events = @(class_event_count) struct('rows', zeros(class_event_count, 1), 'dates', zeros(class_event_count, 1), 'factors', {{}});

fprintf('�������� ��������� ������� �� �������� �������...\n');

% ������ �� ���� �������
for class_key = classes_map_keys
    fprintf('- ����� %s\n', class_key{1});
    % ������ ������� ������, �������������� ����������� �������
    class_event_count = classes_map(class_key{1});
    class_events = create_class_events(class_event_count);
    class_event_counter = 1;
    for i = 1:length(classes)
        if ismember(classes{i}, class_key)
            fprintf('  - ������� #%d/%d [%d]: %s, %s\n', class_event_counter, i, raw{i,date_column_number}, raw{i,description_column_number}, strjoin(factors{i}));
            % ����� ������ �� excel-�
            class_events.rows(class_event_counter) = i;
            % ���� �������
            class_events.dates(class_event_counter) = event_dates(i);
            % ������� �������
            class_events.factors{class_event_counter} = factors{i};
            class_event_counter = class_event_counter + 1;
        end
    end
    % ������� ���� � ������ ����
    class_events.dates = class_events.dates - min(class_events.dates);
    % �������� ������ �� �������� ������
    classes_events_map(class_key{1}) = class_events;
end

fprintf('�������� ��������� ������� �� �������� ������� - �������\n');

% ����������� �������� ��������� ����� ������� ������ �������
% (������������� �������)
% todo ...

% ���������� ������������� ��������
generated_negative_classes_count = 10;

% ������ �������� �������
% �� ��� ����� ����� ��������� ��������� ��� ��������� �������
classes_events_values = values(classes_events_map);

fprintf('��������� ��������� ��������� ������...\n');

% todo: ������������� �������, ������� �� �������

for generated_class_counter = 1:generated_negative_classes_count
    % ����������� ��� ������
    generated_class_name = sprintf('random_class_%02d', generated_class_counter);
    fprintf('- ����� %s\n', generated_class_name);
    % ������� �������� �������� �����
    refer_class_index = randi(length(classes_events_values));
    original_event_count = length(classes_events_values{refer_class_index}.dates);
    random_date_range = classes_events_values{refer_class_index}.dates(original_event_count);
    % ����������� �������� �������� ��� ��� �������, +/- 50% �� ���������
    random_date_range = fix(random_date_range/2) + randi(random_date_range);
    % ����������� �������� ���������� �������, +/- 50% �� ���������
    random_event_count = fix(original_event_count/2) + randi(original_event_count);
    % �������� ������ �����
    class_events = create_class_events(class_event_count);
    % �������� ����� ���������������� ���������
    for class_event_counter = 1:random_event_count
        % ����������� �������� ���� �������
        generated_event_date = randi(random_date_range);
        % ����������� �������� ���������� ��������, +/- 50% �� ���������
        original_factor_count = length(classes_events_values{refer_class_index}.factors);
        random_factor_count = fix(original_factor_count/2) + randi(original_factor_count);
        fprintf('  - ������� #%d [%d]: %s, %s\n', class_event_counter, generated_event_date, generated_class_name, 'strjoin(factors{i})');
        % ���� �������
        class_events.dates(class_event_counter) = generated_event_date;
        % ������� �������
        % class_events.factors{class_event_counter} = factors{i};
    end
    % ������� ���� � ������ ����
    class_events.dates = class_events.dates - min(class_events.dates);
    % �������� ������ �� �������� ������
    classes_events_map(generated_class_name) = class_events;
end

fprintf('��������� ��������� ��������� ������ - �������\n');

% �������� ��������� ����� ��������� ��������
% todo ...

% return;

% �������� ��������� ����� ����� ���������

% factor_time_line[������]
% ��� ������� ��������� ����� ������� �� ������� �������
% � ���������� � ���� �������
% � ������ � � ����� � ��� ���������� �� �������� ���� ��������
% ����� ������� ������� �� �������� �� ������� �������
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom + event_wave_window + 1);

% ����, ������������� � ������� �� ��������� ����� (�������� �� ��� ���� ��������)
event_dates_time_line = event_dates * time_line_zoom + event_wave_window_half + 1;

% ������� �������� ������ ��������
factors_map_keys = keys(factors_map);

% ���� ���������� ������� ������� �� ����� �� ������� �������
% (����� ����� �������� ������� �� �������)
% event_dates_time_line_by_factor = cell(length(factors_map_keys), 1);
% ������� ������� ����� ��� ������ ��� ������� �������
event_dates_time_line_by_factor = cellfun(@(fk) zeros(factors_map(fk), 1), factors_map_keys, 'UniformOutput', false);

fprintf('�������� ��������� ����� �� ��������...\n');

% �������� �� ���� ��������, �� ���� ��� ��������
% � ��������� ������ ������ �� ��������������� ��������� �����
for i = 1:length(event_dates)
    if ~isfinite(event_dates(i))
        % ���������� ��-�����
        continue;
    end
    fprintf('- ������� [%d]: %s\n', raw{i,date_column_number}, raw{i,description_column_number});
    % �������� �� ���� �������� ������� � ����������� ������� �� ��������� �����
    for factor_key = factors{i}
        % ����� ���������� ����� ������� � ������ ���� ��������
        factor_index = find(strcmp(factors_map_keys, factor_key));
        fprintf('  - ������ [%d]: %s\n', factor_index, factor_key{1});
        % ����� ������� �� ����� (������� �� ��� ���� ��������)
        event_center_position = event_dates_time_line(i);
        % �������� ��� ������� ��� ������� (��������� � �����)
        event_dates_time_line_by_factor{factor_index}(find(event_dates_time_line_by_factor{factor_index}==0,1)) = event_center_position;
        % ���� ������ ��������� ����� � ������� � �������
        event_window = event_center_position - event_wave_window_half : event_center_position + event_wave_window_half;
        % ������� ���� �������� �� ��������� �����
        factor_time_line(factor_index, event_window) = factor_time_line(factor_index, event_window) + event_wave_y;
    end
end
fprintf('�������� ��������� ����� �� �������� - �������\n');

% ������� ������� ������� �� ��������
figure('Name', '������� �� ��������');
% ������ ��� ������� � ������ ���������
subplot(length(factors_map_keys) + 1, 1, 1);
plot(rot90(factor_time_line));
for i = 1:length(factors_map_keys)
    % ������ ������ i � i+1 ���������
    subplot(length(factors_map_keys) + 1, 1, i+1);
    plot(factor_time_line(i,:), '-o', 'MarkerIndices', event_dates_time_line_by_factor{i});
end

function [factors, factors_map] = parse_factors(raw, factor_column_number)

% ������ �������/������
% �� �����:
% - raw - ������� �� excel
% - ������� � ������� factor_column_number, ����� ����� �������
% �� ������:
% - � factors{i} ����� ������������ ������� ���� ��� ������� � ������ i
% - � factors_map ����� ���� ������ �������� �� ���� ��������
%   � ���� �������������� ���������:
%   factors_map(������) = ������� ��� ���������� ���� ������ � ��������
%   todo: ������� ����� ���� ������ ����� ������ ���

% ���� � factors ������ ������� � �������/�������� ��������
factors = raw(:,factor_column_number);
% ���� ���������� ��� ������������� �������
factors_map = containers.Map;

% �������� �� ���� �������-��������
for i = 1:length(factors)
    % ������ ������ �� ����� �������� �� �������,
    % ��� �������� � ������ � �����
    
    % ��������� ������� � ������� ������
    single_event_factors = {};
    
    if ischar(factors{i}) % ��� �����?
        single_event_factors = strsplit(lower(strtrim(factors{i})),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors{i}) % ��� �����?
        single_event_factors = {num2str(factors{i})};
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
    factors{i} = single_event_factors;
end

end
