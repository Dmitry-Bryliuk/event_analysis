% ������� calc_nn_window
% ��������� ������ ��������� ���� � ���� �� ����� ����� �������
% �������� ��������� �������� ����� ����� ���� �������� ������� ��
% � ��������� � ��������� ��������, ������� ������� �� ��������� ������

function [nn_window_result, nn_event_window_position_start, window_event_matrix, out_of_range] = calc_nn_window(event_date_original, show_fig)

% �� �����:
% - event_date_original - ������������������ ����
% - show_fig - true/false - ���������� �� �������
%   ���� �������� �� �����, ������� �� ����������
% �� ������:
% - nn_window_result - ��������� ������ �� � ���� (������� �� �������)
% - nn_event_window_position_start - ������������������ ������� ������ ����
% - window_event_matrix - ������� ������� � ���� �� ��������
% - out_of_range - ����������� �� ���� �� �����
%   (�������������� �� ������ ��������� �� �����)

global factor_time_line time_line_zoom time_line_size_scaled nn_event_window_size nn;

% ��������� ������� ���� �� ������������������ �����
nn_event_window_position_start = 1 + (event_date_original - 1) * time_line_zoom;
% �������� ������� ����
nn_event_window_position_end = nn_event_window_position_start + nn_event_window_size - 1;
% �������� �� ���� ���� �� �������� �� �����
if nn_event_window_position_start > time_line_size_scaled
    nn_window_result = [];
    window_event_matrix = [];
    out_of_range = true;
    return;
end

out_of_range = false;

% ��������� ������� ����� ������� �� ��������
% ���������� �� ���������� ���� �� �������� �����
if nn_event_window_position_end <= time_line_size_scaled
    % ���� ���� ������� �� �����
    window_event_matrix = factor_time_line(:, nn_event_window_position_start:nn_event_window_position_end);
else
    % �� ����� ������ ������� ����
    window_event_matrix = zeros(size(factor_time_line, 1), nn_event_window_size);
    window_event_matrix(:, 1:time_line_size_scaled-nn_event_window_position_start+1) = factor_time_line(:, nn_event_window_position_start:time_line_size_scaled);
end
% ������ ������� ��������
window_event_matrix_linear = window_event_matrix';
window_event_matrix_linear = window_event_matrix_linear(:);
nn_window_result = nn(window_event_matrix_linear);

if nargin < 2
    show_fig = false;
end

if show_fig
    figure('Name', sprintf('���� ������� � ���� %d', event_date_original));
    subplot(2, 1, 1);
    plot(window_event_matrix');
    subplot(2, 1, 2);
    bar(nn_window_result);
end

end % function calc_nn_window
