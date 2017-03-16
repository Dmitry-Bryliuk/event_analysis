% функция calc_nn_window
% вычисляет отклик нейронной сети в окне из общей шкалы событий
% вынесена отдельным скриптом чтобы можно было смотреть отклики нс
% с графиками в отдельных позициях, вызывая функцию из командной строки

function [nn_window_result, nn_event_window_position_start, window_event_matrix, out_of_range] = calc_nn_window(event_date_original, show_fig)

% на входе:
% - event_date_original - немасштабированная дата
% - show_fig - true/false - показывать ли графики
%   если параметр не задан, графики не показываем
% на выходе:
% - nn_window_result - результат работы нс в окне (отклики по классам)
% - nn_event_window_position_start - отмасштабированная позиция начала окна
% - window_event_matrix - выборка событий в окне по факторам
% - out_of_range - поместилось ли окно на шкалу
%   (соответственно ли дальше двигаться по шкале)

global factor_time_line time_line_zoom time_line_size_scaled nn_event_window_size nn;

% начальная позиция окна на отмасштабированной шкале
nn_event_window_position_start = 1 + (event_date_original - 1) * time_line_zoom;
% конечная позиция окна
nn_event_window_position_end = nn_event_window_position_start + nn_event_window_size - 1;
% попадает ли окно хотя бы частично на шкалу
if nn_event_window_position_start > time_line_size_scaled
    nn_window_result = [];
    window_event_matrix = [];
    out_of_range = true;
    return;
end

out_of_range = false;

% двумерная матрица шкалы событий по факторам
% подвыборка из смещённого окна на основной шкале
if nn_event_window_position_end <= time_line_size_scaled
    % окно есть целиком на шкале
    window_event_matrix = factor_time_line(:, nn_event_window_position_start:nn_event_window_position_end);
else
    % на шкале только кусочек окна
    window_event_matrix = zeros(size(factor_time_line, 1), nn_event_window_size);
    window_event_matrix(:, 1:time_line_size_scaled-nn_event_window_position_start+1) = factor_time_line(:, nn_event_window_position_start:time_line_size_scaled);
end
% делаем матрицу линейной
window_event_matrix_linear = window_event_matrix';
window_event_matrix_linear = window_event_matrix_linear(:);
nn_window_result = nn(window_event_matrix_linear);

if nargin < 2
    show_fig = false;
end

if show_fig
    figure('Name', sprintf('Окно события в дате %d', event_date_original));
    subplot(2, 1, 1);
    plot(window_event_matrix');
    subplot(2, 1, 2);
    bar(nn_window_result);
end

end % function calc_nn_window
