% функция calc_nn_window
% вычисляет отклик нейронной сети в окне из общей шкалы событий
% вынесена отдельным скриптом чтобы можно было смотреть отклики нс
% с графиками в отдельных позициях, вызывая функцию из командной строки

function [nn_window_result, nn_event_window_position, window_event_matrix, out_of_range] = calc_nn_window(event_date_original, show_fig)

% на входе:
% - event_date_original - немасштабированная дата
% - show_fig - true/false - показывать ли графики
%   если параметр не задан, графики не показываем
% на выходе:
% - nn_window_result - результат работы нс в окне (отклики по классам)
% - nn_event_window_position - отмасштабированная позиция начала окна
% - window_event_matrix - выборка событий в окне по факторам
% - out_of_range - поместилось ли окно на шкалу
%   (соответственно ли дальше двигаться по шкале)

global factor_time_line time_line_zoom time_line_size_scaled nn_event_window_size nn;

% начальная позиция окна на отмасштабированной шкале
nn_event_window_position = 1 + (event_date_original - 1) * time_line_zoom;
% конечная позиция окна
nn_event_window_position_end = nn_event_window_position + nn_event_window_size - 1;
% умещается ли окно до конца шкалы
if nn_event_window_position_end > time_line_size_scaled
    nn_window_result = [];
    window_event_matrix = [];
    out_of_range = true;
    return;
end

out_of_range = false;

% двумерная матрица шкалы событий по факторам
% подвыборка из смещённого окна на основной шкале
window_event_matrix = factor_time_line(:, nn_event_window_position:nn_event_window_position_end);
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
