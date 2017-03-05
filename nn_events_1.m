% ������ excel-����
% �� Excel, �� ���� ����� ������ excel-����� ������� �� �����
% num - ������� ������ �����
% txt - ������� ������ ��������� ��������
% raw - �� ������
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% ������ ������ � excel-����� - ���������, ����������

% ������ �������

% ������� � ������� 3, ����� ����� �������
% �� ������ � factors ����� ������������ ������� ����
factors = raw(:,3);

% ����� ����� ���� ������ �������� �� ���� ��������
factors_map = containers.Map;

for i = 2:length(factors)
    % ������ ������ �� ����� �������� �� �������,
    % ��� �������� � ������ � �����
    if ischar(factors{i})
        single_event_factors = strsplit(strtrim(factors{i}),'\s*,\s*','DelimiterType','RegularExpression');
        for curren_event_factor = single_event_factors
            factors_map(curren_event_factor{1}) = 1;
        end
        factors{i} = single_event_factors;
    end
end
