% ����� ���������� ������ �������:
% - ������ � ������ excel-���� � ���������
%   - ������� �������������� � �������������� ������ � ���������
%   - ������ ������� ���� ����� �����������, ���� ��� ��������
% - ���������� ��������� ����� �� ��������
%   - ������� �������� � ����� � ������ ������� ��� ������� ����������
%     ��������� �����
% - [todo] ��������� ������� ��������� ������� � ���������� �������������
%   ������������� ������� ��� �������� ��
% - [todo] ������ ���������� ����� �� ��������� ����� �������� � �����
%   ������� �������
% ������ ������������� ����������� todo-���:
% - [todo] ���������� ������������� ����������� ��������, �����
%   ������� ��������������� � ����������� �������� �������
% - [todo] ������� ������� �� ��������
% ��� ���� "�� ������", �� �����������:
% - ������������ �������������� ��������� ����� (�����, ��������, ...)
% - ������ ������������ ��������� (PCA-�������������)
% - ������������� �������

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
time_line_sigma_original = 10;
% ������ �������� ������� ������������������
time_line_sigma = time_line_zoom * time_line_sigma_original;

% ��������� ��� �������� � �������
event_wave_scale = 1/normpdf(0, 0, time_line_sigma);

% ������ ���� ����� ��� ��������� �� ��������� �����
% � �������� �������� (����)
event_wave_window_original = 100;
% ������ ���� ����� ������������������
event_wave_window = event_wave_window_original * time_line_zoom;

% (event_wave_x, event_wave_y) - ������� � ������� �������
% �� ����������� �� ��������� ����� �������
% �������� ������������� ���� �� �����
event_wave_x = -event_wave_window/2 : 1 : event_wave_window/2;
event_wave_y = event_wave_scale * normpdf(event_wave_x, 0, time_line_sigma);
% ������� ������ ��������
% plot(event_wave_x, event_wave_y);

% return

% ������ excel-����

% ������ ������� �� ������� factors_column_number
[factors, factors_map] = parse_factors(raw, factors_column_number);

% ������ ������ �� ������� classes_column_number
[classes, classes_map] = parse_factors(raw, classes_column_number);

% factor_time_line[������]
% ��� ������� ��������� ����� ������� �� ������� �������
% � ���������� � ���� �������
% � ������ � � ����� � ��� ���������� �� �������� ���� ��������
% ����� ������� ������� �� �������� �� ������� �������
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom + event_wave_window + 1);

% ������� �������� ������ ��������
factors_map_keys = keys(factors_map);

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
        event_center_position = event_dates(i) * time_line_zoom + event_wave_window / 2 + 1;
        % ���� ������ ��������� ����� � ������� � �������
        event_window = event_center_position - event_wave_window / 2 : event_center_position + event_wave_window / 2;
        % ������� ���� �������� �� ��������� �����
        factor_time_line(factor_index, event_window) = factor_time_line(factor_index, event_window) + event_wave_y;
        %for j=1:time_line_zoom
        %    factor_time_line(current_factor_index, current_time_line_position) = j/10;
        %    % factor_time_line(current_factor_index, current_time_line_position) = factor_time_line(current_factor_index, current_time_line_position) + normpdf(j-timeline_zoom/2,0,100);
        %end
    end
end
fprintf('�������� ��������� ����� �� �������� - �������\n');

function [factors, factors_map] = parse_factors(raw, factor_column_number)

% ������ �������/������
% �� �����:
% - raw - ������� �� excel
% - ������� � ������� factor_column_number, ����� ����� �������
% �� ������:
% - � factors ����� ������������ ������� ����
% - � factors_map ����� ���� ������ �������� �� ���� ��������
%   � ���� �������������� ���������

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
        single_event_factors = strsplit(strtrim(factors{i}),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors{i}) % ��� �����?
        single_event_factors = {num2str(factors{i})};
    end
    
    % ��������� ��� ������� �������� ������� � ��������� ���� ��������
    for curren_event_factor = single_event_factors
        factors_map(curren_event_factor{1}) = 1;
    end
    
    % ���������� ������������ ������ �������� ��� �������
    factors{i} = single_event_factors;
end

end
