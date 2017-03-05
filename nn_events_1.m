% ������ excel-����
% �� Excel, �� ���� ����� ������ excel-����� ������� �� �����
% num - ������� ������ �����
% txt - ������� ������ ��������� ��������
% raw - �� ������ (������������� �� ����, � ��������� ����� �������� ������)
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% ������� ������ ������ � �����������
raw(1,:) = [];

% ������ ������ � excel-����� - ���������, ����������

% ������ ������� �� ������� 3
[factors, factors_map] = parse_factors(raw, 3);

% ������ ������ �� ������� 4
[classes, classes_map] = parse_factors(raw, 4);

% ���� ������� � ������ ������� (������� ���� ��� ��� ������ ���)

% �����������/������������ ����� �� �����
% ������� ������ ���������� ��� �������� �� ����������
% ������� � ������ ������
date_column_number = 1;
event_dates = cell2mat(raw(:,date_column_number));
min_time = min(event_dates);
max_time = max(event_dates);
time_line_size = max_time - min_time;

fprintf('������ ��������� �����: %.2f, �����: %.2f, ������:  %.2f\n', min_time, max_time, time_line_size);

% ��������������� ��������� �����. �� ������ ������� ������� ������ � �����
% � ���� �������, � ����� ���� ������������ ��� ���� ����� ������ �����
% ����� ���������

% ���� ����� ����� ������ ����, ����� �������� �������� ������� �
% �������������/�������������� ����� �������, ��� ������������� ����� � ���

time_line_zoom = 10; % ����������� ������� ��������� ����� � 10 ���

% factor_time_line[������]
% - ��� ������� ����� ������� �� ���������� �������
%   � ���������� � ���� �������
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom);

% ������ �������� �������
time_line_sigma = 100;

% ��������� ��� �������� � �������
time_line_sigma_scale = 1/normpdf(0,0,100);

% �������� �� ���� �������� �� ����� � ��������� ��� ������� �� �����
% ��������
for i = 1:length(event_dates)
    factors_map_keys = keys(factors_map);
    % event_dates(i)
    for current_factor_key = factors_map_keys
        current_factor_index = find(strcmp(factors_map_keys, current_factor_key));
        if isfinite(event_dates(i))
            for j=1:time_line_zoom
                current_time_line_position = event_dates(i)*time_line_zoom+j-1;
                factor_time_line(current_factor_index, current_time_line_position) = j/10;
                % factor_time_line(current_factor_index, current_time_line_position) = factor_time_line(current_factor_index, current_time_line_position) + normpdf(j-timeline_zoom/2,0,100);
            end
        end
    end
end

function [factors, factors_map] = parse_factors(raw, factor_column_number)

% ������ �������/������
% raw - ������� �� excel
% ������� � ������� factor_column_number, ����� ����� �������
% �� ������ � factors ����� ������������ ������� ����
% � factors_map ����� ���� ������ �������� �� ���� ��������

factors = raw(:,factor_column_number);
factors_map = containers.Map;

for i = 1:length(factors)
    % ������ ������ �� ����� �������� �� �������,
    % ��� �������� � ������ � �����
    
    single_event_factors = {};
    
    if ischar(factors{i})
        single_event_factors = strsplit(strtrim(factors{i}),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors{i})
        single_event_factors = {num2str(factors{i})};
    end
    
    for curren_event_factor = single_event_factors
        factors_map(curren_event_factor{1}) = 1;
    end
    
    factors{i} = single_event_factors;
end

end
