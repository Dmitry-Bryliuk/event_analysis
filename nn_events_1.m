% ������ excel-����
% �� Excel, �� ���� ����� ������ excel-����� ������� �� �����
% num - ������� ������ �����
% txt - ������� ������ ��������� ��������
% raw - �� ������
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% ������ ������ � excel-����� - ���������, ����������

% ������ ������� �� ������� 3
[factors, factors_map] = parse_factors(raw, 3);

% ������ ������ �� ������� 4
[classes, classes_map] = parse_factors(raw, 4);

function [factors, factors_map] = parse_factors(raw, factor_row_number)

% ������ �������/������
% raw - ������� �� excel
% ������� � ������� factor_row_number, ����� ����� �������
% �� ������ � factors ����� ������������ ������� ����
% � factors_map ����� ���� ������ �������� �� ���� ��������

factors = raw(:,factor_row_number);
factors_map = containers.Map;

for i = 2:length(factors)
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
