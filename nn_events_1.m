% самый интересный скрипт проекта:
% - читает и парсит excel-файл с событиями
%   - события предполагаются с проставленными датами и факторами
%   - классы событий тоже можно проставлять, если они известны
% - генерирует временные шкалы по факторам
%   - гладкие всплески с пиком в центре события для лучшего восприятия
%     нейронной сетью
% - [todo] извлекает примеры известных классов и генерирует искусственные
%   отрицательные примеры для обучения нс
%   (на дополнительное генерирование слегка искажённых исходных
%    и сгенерированных классов пока забьём)
% - [todo] проход скользящим окном по временной шкале факторов и поиск
%   похожих событий
%
% всякие промежуточные технические todo-шки:
% - [todo] сохранение промежуточных результатов парсинга, чтобы
%   быстрее перезапускалось с одинаковыми входными данными
% - [todo] графики событий по факторам
%
% что пока "за бортом", но планируется:
% - спектральное преобразование временной шкалы (Фурье, вейвлеты, ...)
% - сжатие пространства признаков (PCA-реконструкция)
% - кластеризация событий (думается на основе сжатых признаков)
%
% примечания:
% - код можно было бы написать намного проще, без преалокаций матриц,
%   но это лишние тормоза
%   для простоты пожно писать без этого,
%   типа A(length(A)+1) = следующее значение
% - по максимуму используются матричные операции, это намного быстрее,
%   хоть и выглядит немного магией

% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значения
% raw - всё подряд (ориентируемся на него, в остальных могут съезжать ячейки)
% первая строка в excel-файле - заголовки, игнорируем
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');
% убираем первую строку с заголовками
raw(1,:) = [];

% формат ячеек в excel-файле
% столбец с датами событий первый (считаем пока что это только год)
date_column_number = 1;
% столбец с описаниями второй
description_column_number = 2;
% столбец с факторами третий
factors_column_number = 3;
% столбец с классами четвёртый
classes_column_number = 4;

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
time_line_sigma_original = 3;
% ширина всплеска события отмасштабированная
time_line_sigma = time_line_zoom * time_line_sigma_original;

% функция всплеска (можно поэкспериментировать какая лучше)
% distrib = @(vec) normpdf(vec, 0, time_line_sigma);
distrib = @(vec) pdf('Stable', vec, 0.5, 0, time_line_sigma, 0);

% нормируем пик всплеска к единице
event_wave_scale = 1/distrib(0);

% ширина окна волны для наложения на временную шкалу
% в исходных единицах (годы)
event_wave_window_original = 100;
% ширина окна волны отмасштабированная
event_wave_window = event_wave_window_original * time_line_zoom;
% размеры окна и его половины округлены до целых чисел
event_wave_window_half = fix(event_wave_window / 2);
event_wave_window = event_wave_window_half * 2;

% (event_wave_x, event_wave_y) - всплеск с центром события
% он добавляется на временную шкалу фактора
% всплески накладываются друг на друга
event_wave_x = -event_wave_window_half : 1 : event_wave_window_half;
event_wave_y = event_wave_scale * distrib(event_wave_x);

% покажем график всплеска
% figure('Name', 'форма всплеска');
% plot(event_wave_x, event_wave_y);

% return

% парсим excel-файл

% парсим факторы из столбца factors_column_number
[factors, factors_map] = parse_factors(raw, factors_column_number);

% парсим классы из столбца classes_column_number
[classes, classes_map] = parse_factors(raw, classes_column_number);

% вытащим группы событий, для которых проставлены классы, в обучающую
% выборку

% вытащим отдельно список классов
classes_map_keys = keys(classes_map);

% сюда складываем найденные и сгенерированные группы событий по классам
% classes_events_map(класс) = список событий класса: строки, даты, факторы
% запоминаем все значения, потому что в сгенерированных классах не будет
% исходной строки из excel-я
% пока что один класс содержит только одну группу событий
classes_events_map = containers.Map('KeyType','char','ValueType','any');

% функция для создания пустой структуры класса
create_class_events = @(class_event_count) struct('rows', zeros(class_event_count, 1), 'dates', zeros(class_event_count, 1), 'factors', {{}});

fprintf('заполняю обучающие примеры по заданным классам...\n');

% пройдём по всем классам
for class_key = classes_map_keys
    fprintf('- класс %s\n', class_key{1});
    % массив событий класса, инициализируем посчитанной длинной
    class_event_count = classes_map(class_key{1});
    class_events = create_class_events(class_event_count);
    class_event_counter = 1;
    for i = 1:length(classes)
        if ismember(classes{i}, class_key)
            fprintf('  - событие #%d/%d [%d]: %s, %s\n', class_event_counter, i, raw{i,date_column_number}, raw{i,description_column_number}, strjoin(factors{i}));
            % номер строки из excel-я
            class_events.rows(class_event_counter) = i;
            % дата события
            class_events.dates(class_event_counter) = event_dates(i);
            % факторы события
            class_events.factors{class_event_counter} = factors{i};
            class_event_counter = class_event_counter + 1;
        end
    end
    % сдвинем даты в начало окна
    class_events.dates = class_events.dates - min(class_events.dates);
    % запомним данные по названию класса
    classes_events_map(class_key{1}) = class_events;
end

fprintf('заполняю обучающие примеры по заданным классам - сделано\n');

% сгенерируем случайно несколько групп событий других классов
% (отрицательные примеры)
% todo ...

% количество отрицательных примеров
generated_negative_classes_count = 10;

% список исходных классов
% из них будем брать некоторые параметры для генерации выборки
classes_events_values = values(classes_events_map);

fprintf('генерирую случайные обучающие классы...\n');

% todo: сгенерировать факторы, графики по классам

for generated_class_counter = 1:generated_negative_classes_count
    % сгенерируем имя класса
    generated_class_name = sprintf('random_class_%02d', generated_class_counter);
    fprintf('- класс %s\n', generated_class_name);
    % выберем случайно исходный класс
    refer_class_index = randi(length(classes_events_values));
    original_event_count = length(classes_events_values{refer_class_index}.dates);
    random_date_range = classes_events_values{refer_class_index}.dates(original_event_count);
    % сгенерируем случайно диапазон дат для событий, +/- 50% от исходного
    random_date_range = fix(random_date_range/2) + randi(random_date_range);
    % сгенерируем случайно количество событий, +/- 50% от исходного
    random_event_count = fix(original_event_count/2) + randi(original_event_count);
    % создадим пустой класс
    class_events = create_class_events(class_event_count);
    % заполним класс сгенерированными событиями
    for class_event_counter = 1:random_event_count
        % сгенерируем случайно дату события
        generated_event_date = randi(random_date_range);
        % сгенерируем случайно количество факторов, +/- 50% от исходного
        original_factor_count = length(classes_events_values{refer_class_index}.factors);
        random_factor_count = fix(original_factor_count/2) + randi(original_factor_count);
        fprintf('  - событие #%d [%d]: %s, %s\n', class_event_counter, generated_event_date, generated_class_name, 'strjoin(factors{i})');
        % дата события
        class_events.dates(class_event_counter) = generated_event_date;
        % факторы события
        % class_events.factors{class_event_counter} = factors{i};
    end
    % сдвинем даты в начало окна
    class_events.dates = class_events.dates - min(class_events.dates);
    % запомним данные по названию класса
    classes_events_map(generated_class_name) = class_events;
end

fprintf('генерирую случайные обучающие классы - сделано\n');

% заполним временные шкалы обучающих примеров
% todo ...

% return;

% заполним временную шкалу всеми факторами

% factor_time_line[фактор]
% это плавная временная шкала событий по каждому фактору
% с максимумом в дате события
% в начале и в конце к ней прицеплено по половине окна всплеска
% чтобы крайние события не вылетали за пределы матрицы
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom + event_wave_window + 1);

% даты, пересчитанные в позиции на временной шкале (сдвинуты на пол окна всплеска)
event_dates_time_line = event_dates * time_line_zoom + event_wave_window_half + 1;

% вытащим отдельно список факторов
factors_map_keys = keys(factors_map);

% сюда складываем позиции событий на шкале по каждому фактору
% (нужны чтобы отмечать позиции на графике)
% event_dates_time_line_by_factor = cell(length(factors_map_keys), 1);
% выделим заранее место под список дат каждого фактора
event_dates_time_line_by_factor = cellfun(@(fk) zeros(factors_map(fk), 1), factors_map_keys, 'UniformOutput', false);

fprintf('заполняю временные шкалы по факторам...\n');

% проходим по всем событиям, по всем его факторам
% и добавляем каждый фактор на соответствующую временную шкалу
for i = 1:length(event_dates)
    if ~isfinite(event_dates(i))
        % пропускаем не-числа
        continue;
    end
    fprintf('- событие [%d]: %s\n', raw{i,date_column_number}, raw{i,description_column_number});
    % проходим по всем факторам события и накладываем всплеск на временную шкалу
    for factor_key = factors{i}
        % найдём порядковый номер фактора в списке всех факторов
        factor_index = find(strcmp(factors_map_keys, factor_key));
        fprintf('  - фактор [%d]: %s\n', factor_index, factor_key{1});
        % центр события на шкале (сдвинут на пол окна всплеска)
        event_center_position = event_dates_time_line(i);
        % запомним его позицию для графика (добавляем в конец)
        event_dates_time_line_by_factor{factor_index}(find(event_dates_time_line_by_factor{factor_index}==0,1)) = event_center_position;
        % окно внутри временной шкалы с центром в событии
        event_window = event_center_position - event_wave_window_half : event_center_position + event_wave_window_half;
        % добавим окно всплеска на временную шкалу
        factor_time_line(factor_index, event_window) = factor_time_line(factor_index, event_window) + event_wave_y;
    end
end
fprintf('заполняю временные шкалы по факторам - сделано\n');

% покажем графики событий по факторам
figure('Name', 'события по факторам');
% рисуем все факторы в первый подграфик
subplot(length(factors_map_keys) + 1, 1, 1);
plot(rot90(factor_time_line));
for i = 1:length(factors_map_keys)
    % рисуем фактор i в i+1 подграфик
    subplot(length(factors_map_keys) + 1, 1, i+1);
    plot(factor_time_line(i,:), '-o', 'MarkerIndices', event_dates_time_line_by_factor{i});
end

function [factors, factors_map] = parse_factors(raw, factor_column_number)

% парсим факторы/классы
% на входе:
% - raw - таблица из excel
% - факторы в столбце factor_column_number, фразы через запятую
% на выходе:
% - в factors{i} будут распарсенные массивы фраз для события в строке i
% - в factors_map будет весь список факторов по всем событиям
%   в виде ассоциативного множества:
%   factors_map(фактор) = сколько раз встретился этот фактор в событиях
%   todo: наверно стоит сюда писать сразу список дат

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
        single_event_factors = strsplit(lower(strtrim(factors{i})),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors{i}) % это число?
        single_event_factors = {num2str(factors{i})};
    end
    
    % добавляем все факторы текущего события к множеству всех факторов
    % заодно считаем количество каждого фактора в отдельности, пригодится
    for curren_event_factor = single_event_factors
        factor_count = 0;
        if factors_map.isKey(curren_event_factor{1})
            factor_count = factors_map(curren_event_factor{1});
        end
        factors_map(curren_event_factor{1}) = factor_count + 1;
    end
    
    % запоминаем распарсенный массив факторов для события
    factors{i} = single_event_factors;
end

end
