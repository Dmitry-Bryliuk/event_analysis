% самый интересный скрипт проекта:
% - читает и парсит excel-файл с событиями
%   - события предполагаются с проставленными датами и факторами
%   - классы событий тоже можно проставлять, если они известны
% - генерирует временные шкалы по факторам
%   - гладкие всплески с пиком в центре события для лучшего восприятия
%     нейронной сетью
% - [todo] извлекает примеры известных классов и генерирует искусственные
%   отрицательные примеры для обучения нс
% - [todo] проход скользящим окном по временной шкале факторов и поиск
%   похожих событий
% - [todo] сохранение промежуточных результатов парсинга, чтобы
%   быстрее перезапускалось с одинаковыми входными данными
% что пока "за бортом", но планируется:
% - спектральное преобразование временной шкалы (Фурье, вейвлеты, ...)
% - сжатие пространства признаков (PCA-реконструкция)
% - кластеризация событий

% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значения
% raw - всё подряд (ориентируемся на него, в остальных могут съезжать ячейки)
% первая строка в excel-файле - заголовки, игнорируем
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');
% убираем первую строку с заголовками
raw(1,:) = [];

% даты событий в первом столбце (считаем пока что это только год)

% столбец с датами первый
date_column_number = 1;
% вытащим столбец с датами отдельно
event_dates = cell2mat(raw(:,date_column_number));
% минимальное/максимальное время на шкале
% большие пустые промежутки для простоты не выкидываем
min_time = min(event_dates);
max_time = max(event_dates);
% размер временной шкалы
time_line_size = max_time - min_time;
% сдвинем даты в начало временной шкалы чтобы удобнее считать
event_dates = event_dates - min_time;

fprintf('начало временной шкалы: %.2f, конец: %.2f, размер:  %.2f\n', min_time, max_time, time_line_size);

% масштабирование временной шкалы. мы делаем событие гладкой волной с пиком
% в дате события, и чтобы дать пространство для этой волны делаем шкалу
% более детальной

% если будут более точные даты, можно разнести отдельно годовые и
% внутригодовые/внутримесячные шкалы событий, чем пересчитывать шкалу в дни

% увеличиваем масштаб временной шкалы в 10 раз
time_line_zoom = 10;

% ширина всплеска события в исходных единицах (годы)
time_line_sigma_original = 10;
% ширина всплеска события отмасштабированная
time_line_sigma = time_line_zoom * time_line_sigma_original;

% нормируем пик всплеска к единице
event_wave_scale = 1/normpdf(0, 0, time_line_sigma);

% ширина окна волны для наложения на временную шкалу
% в исходных единицах (годы)
event_wave_window_original = 100;
% ширина окна волны отмасштабированная
event_wave_window = event_wave_window_original * time_line_zoom;

% (event_wave_x, event_wave_y) - всплеск с центром события
% он добавляется на временную шкалу фактора
% всплески накладываются друг на друга
event_wave_x = -event_wave_window/2 : 1 : event_wave_window/2;
event_wave_y = event_wave_scale * normpdf(event_wave_x, 0, time_line_sigma);
% покажем график всплеска
% plot(event_wave_x, event_wave_y);

% return

% парсим excel-файл

% парсим факторы из столбца 3
[factors, factors_map] = parse_factors(raw, 3);

% парсим классы из столбца 4
[classes, classes_map] = parse_factors(raw, 4);

% factor_time_line[фактор]
% это плавная шкала событий по отдельному фактору
% с максимумом в дате события
% в начале и в конце к ней прицеплено по половине окна всплеска
% чтобы крайние события не вылетали за пределы матрицы
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom + event_wave_window + 1);

% проходим по всем событиям на шкале и добавляем его факторы на шкалы
% факторов
fprintf('заполняю временные шкалы по факторам...\n');
for i = 1:length(event_dates)
    % список факторов
    factors_map_keys = keys(factors_map);
    % проходим по всем факторам и накладываем всплеск на временную шкалу
    for current_factor_key = factors_map_keys
        % найдём порядковый номер фактора в списке всех факторов
        current_factor_index = find(strcmp(factors_map_keys, current_factor_key));
        if isfinite(event_dates(i)) % это число?
            % центр события на шкале (сдвинут на пол окна всплеска)
            event_center_position = event_dates(i) * time_line_zoom + event_wave_window / 2;
            % окно внутри временной шкалы с центром в событии
            event_window = event_center_position - event_wave_window / 2 : event_center_position + event_wave_window / 2;
            % добавим окно всплеска на временную шкалу
            factor_time_line(current_factor_index, event_window) = factor_time_line(current_factor_index, event_window) + event_wave_y;
            %for j=1:time_line_zoom
            %    factor_time_line(current_factor_index, current_time_line_position) = j/10;
            %    % factor_time_line(current_factor_index, current_time_line_position) = factor_time_line(current_factor_index, current_time_line_position) + normpdf(j-timeline_zoom/2,0,100);
            %end
        end
    end
end
fprintf('заполняю временные шкалы по факторам - сделано\n');

function [factors, factors_map] = parse_factors(raw, factor_column_number)

% парсим факторы/классы
% на входе:
% - raw - таблица из excel
% - факторы в столбце factor_column_number, фразы через запятую
% на выходе:
% - в factors будут распарсенные массивы фраз
% - в factors_map будет весь список факторов по всем событиям

% берём в factors только колонку с текстом/номерами факторов
factors = raw(:,factor_column_number);
% сюда складываем все встретившиеся факторы
factors_map = containers.Map;

% проходим по всем строкам-событиям
for i = 1:length(factors)
    % парсим строку на фразы разделяя по запятым,
    % без пробелов в начале и конце
    
    % найденные факторы в текущей строке
    single_event_factors = {};
    
    if ischar(factors{i}) % это текст?
        single_event_factors = strsplit(strtrim(factors{i}),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors{i}) % это число?
        single_event_factors = {num2str(factors{i})};
    end
    
    % добавляем все факторы текущего события к множеству всех факторов
    for curren_event_factor = single_event_factors
        factors_map(curren_event_factor{1}) = 1;
    end
    
    % запоминаем распарсенный массив факторов для события
    factors{i} = single_event_factors;
end

end
