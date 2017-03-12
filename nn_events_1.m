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
% - похоже в матлабе нет значений по ссылке, если мы берём переменную
%   из массива и меняем, то надо её перезаписать обратно в ячейку массива
%   иначе будет только локальная изменённая копия
%   аналогично надо зачитывать свежие выборки из массивов после изменения
%   в массиве
% - где матрицы, а где ячейки в матлабе - это полная магия, выясняется
%   методом тыка в консоли, отладке и окне переменных

% очистим консоль от предыдущего запуска
clc;

% закроем видимые графики от предыдущего запуска
% можно использовать close all hidden чтобы закрыть вообще все графики
close all;

% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значения
% raw - всё подряд (ориентируемся на него, в остальных могут съезжать ячейки)
% первая строка в excel-файле - заголовки, игнорируем
excel_file_path = 'D:\Download\event_analysis\sample_1_1.xlsx';
fprintf('читаю excel-файл "%s"\n\n', excel_file_path);
[num,txt,raw] = xlsread(excel_file_path, '', '', 'basic');

% убираем первую строку с заголовками
% (теперь строки с данными начинаются с единицы)
raw(1,:) = [];

% каждая строка в excel-е - это дата события, и список классов и факторов
% этого события
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
event_dates_original = cell2mat(raw(:,date_column_number));
% минимальное/максимальное время на шкале
% большие пустые промежутки для простоты не выкидываем
min_time_original = min(event_dates_original);
max_time_original = max(event_dates_original);
% размер временной шкалы (немасштабированный)
time_line_size_original = max_time_original - min_time_original + 1;
% сдвинем даты в начало временной шкалы чтобы удобнее считать
event_dates_original = event_dates_original - min_time_original + 1;

fprintf('начало временной шкалы: %.2f, конец: %.2f, размер:  %.2f\n\n', min_time_original, max_time_original, time_line_size_original);

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
time_line_sigma_scaled = time_line_zoom * time_line_sigma_original;

% функция всплеска (можно поэкспериментировать какая лучше)
% distrib = @(vec) normpdf(vec, 0, time_line_sigma);
distrib = @(vec) pdf('Stable', vec, 0.5, 0, time_line_sigma_scaled, 0);

% нормируем пик всплеска к единице
event_wave_norm_coeff = 1/distrib(0);

% ширина окна волны для наложения на временную шкалу
% в исходных единицах (годы)
event_wave_window_size_original = 100;
% ширина окна волны отмасштабированная
event_wave_window_size_scaled = event_wave_window_size_original * time_line_zoom;
% размеры окна и его половины округлены до целых чисел
event_wave_window_size_scaled_half = fix(event_wave_window_size_scaled / 2);
event_wave_window_size_scaled = event_wave_window_size_scaled_half * 2;
% фактически окно будет на единицу больше, т.к. добавляется центральная
% позиция, а слева и справа от неё по пол-окна

% (event_wave_x, event_wave_y) - всплеск с центром события
% он добавляется на временную шкалу фактора
% всплески накладываются друг на друга на общей шкале
event_wave_x = -event_wave_window_size_scaled_half : 1 : event_wave_window_size_scaled_half;
event_wave_y = event_wave_norm_coeff * distrib(event_wave_x);

% покажем график всплеска
figure('Name', 'форма всплеска');
plot(event_wave_x, event_wave_y);

% функция пересчёта исходной даты в позицию на шкале
% (масштабируем и сдвигаем на пол-окна)
calculate_event_dates_scaled = @(event_dates_original) event_dates_original * time_line_zoom + event_wave_window_size_scaled_half + 1;

% функция вычисления диапазона окна события по центру события
% (список значений оси X)
calculate_event_window = @(event_center_position_scaled) event_center_position_scaled - event_wave_window_size_scaled_half : event_center_position_scaled + event_wave_window_size_scaled_half;

% функция вычисления размера отмасштабированной временной шкалы
% (добавлены по пол-окна всплеска в начале и конце)
calculate_time_line_size_scaled = @(time_line_size_original) time_line_size_original * time_line_zoom + event_wave_window_size_scaled + 1;

% размер отмасштабированной временной шкалы
time_line_size_scaled = calculate_time_line_size_scaled(time_line_size_original);
% диапазон по оси X для рисования всяких графиков
time_line_range_scaled = 1:time_line_size_scaled;

% функция для упрощения вывода сообщений о прогрессе
print_start_progress = @(title) fprintf('%s...\n', title);
print_end_progress = @(title) fprintf('%s - сделано\n\n', title);

% парсим excel-файл

% парсим факторы из столбца factors_column_number
% в factors_by_row{i} список факторов для события в строке i
% в factors_map{F} сколько раз встретился фактор F во всех событиях
[factors_by_row, factors_map] = parse_factors(raw, factors_column_number);

% вытащим отдельно список факторов
factors_map_keys = keys(factors_map);

% парсим классы из столбца classes_column_number
% в classes_by_row{i} список классов для события в строке i
% в classes_map{C} сколько раз встретился класс C во всех событиях
[classes_by_row, classes_map] = parse_factors(raw, classes_column_number);

% вытащим группы событий, для которых проставлены классы, в обучающую
% выборку

% вытащим отдельно список классов
classes_map_keys = cell2mat(keys(classes_map));

% сюда складываем найденные и сгенерированные группы событий по классам
% classes_events_map(класс) = список событий класса: строки, даты, факторы
% запоминаем все значения, потому что в сгенерированных классах не будет
% исходной строки из excel-я
% пока что один класс содержит только одну группу событий
classes_info_map = containers.Map('KeyType','char','ValueType','any');

% функция для создания пустой структуры класса
create_class_info = @(class_name, class_event_count) struct('class_name', class_name, 'event_count', class_event_count, 'rows', zeros(class_event_count, 1), 'dates', zeros(class_event_count, 1), 'factors', {{}});

title = 'заполняю исходные классы';
print_start_progress(title);

% пройдём по всем классам
for class_key = classes_map_keys
    fprintf('- класс %s\n', class_key);
    % события и прочие данные класса,
    % инициализируем количеством событий в классе
    class_info = create_class_info(class_key, classes_map(class_key));
    % пройдём по всем ячейкам событий и вытащим в класс только те,
    % которые принадлежат этому классу
    class_event_counter = 1;
    for i = 1:length(classes_by_row)
        if ismember(classes_by_row{i}, class_key)
            fprintf('  - событие #%d/строка:%d/дата:%d/: %s, %s\n', class_event_counter, i, raw{i,date_column_number}, raw{i,description_column_number}, strjoin(factors_by_row{i}));
            % номер строки из excel-я
            class_info.rows(class_event_counter) = i;
            % дата события
            class_info.dates(class_event_counter) = event_dates_original(i);
            % факторы события
            class_info.factors{class_event_counter} = factors_by_row{i};
            class_event_counter = class_event_counter + 1;
        end
    end
    % сдвинем даты в начало окна
    class_info.dates = class_info.dates - min(class_info.dates) + 1;
    % запомним диапазон дат событий
    class_info.time_line_size_original = max(class_info.dates);
    % запомним данные по названию класса
    classes_info_map(class_key) = class_info;
end

print_end_progress(title);

% сгенерируем случайно несколько групп событий других классов
% (отрицательные примеры)

% количество отрицательных примеров
generated_negative_classes_count = 10;

% список исходных классов
% из них будем брать некоторые параметры для генерации выборки
classes_info_values = cell2mat(values(classes_info_map));

title = 'генерирую случайные классы';
print_start_progress(title);

% сгенерируем случайные классы в заданном количестве
for generated_class_counter = 1:generated_negative_classes_count
    % выберем случайно исходный класс
    class_events_refered = classes_info_values(randi(length(classes_info_values)));
    % сгенерируем случайно количество событий, +/- 50% от исходного
    random_event_count = fix(class_events_refered.event_count/2) + randi(class_events_refered.event_count);
    % создадим пустой класс с нужным количеством событий
    % и сгенерированным именем
    class_info = create_class_info(sprintf('generated_class_%02d', generated_class_counter), random_event_count);
    fprintf('- класс %s\n', class_info.class_name);
    % сгенерируем случайно диапазон дат для событий, +/- 50% от исходного
    random_date_range = fix(class_events_refered.time_line_size_original/2) + randi(class_events_refered.time_line_size_original);
    % заполним класс сгенерированными событиями
    for class_event_counter = 1:random_event_count
        % сгенерируем случайно дату события
        generated_event_date = randi(random_date_range);
        % дата события
        class_info.dates(class_event_counter) = generated_event_date;
        % сгенерируем случайно количество факторов, +/- 50% от исходного
        original_factor_count = length(class_events_refered.factors);
        % чтобы факторов не было больше чем есть берём минимум от
        % случайного и общего количества
        random_factor_count = min([fix(original_factor_count/2) + randi(original_factor_count) length(factors_map_keys)]);
        % cгенерируем факторы события
        % генерируем через пермутации, чтобы факторы не дублировалось
        % (они могут продублироваться если другое событие с таким же фактором попадёт в то же место, это нормально)
        class_info.factors{class_event_counter} = factors_map_keys(randperm(length(factors_map_keys), random_factor_count));
        fprintf('  - событие #%d/дата:%d/: %s, %s\n', class_event_counter, generated_event_date, generated_class_name, strjoin(class_info.factors{class_event_counter}));
    end
    % сдвинем даты в начало окна
    class_info.dates = class_info.dates - min(class_info.dates) + 1;
    % запомним диапазон дат событий
    class_info.time_line_size_original = max(class_info.dates);
    % запомним данные по названию класса
    classes_info_map(class_info.class_name) = class_info;
end

print_end_progress(title);

% заполним временные шкалы по факторам для классов
% сейчас один класс - один пример
% пока без добавления искажённых/зашумлённых примеров

% берём обновлённый список классов
classes_info_values = cell2mat(values(classes_info_map));

title = 'заполняю временные шкалы по всем классам';
print_start_progress(title);

% проходим во всем классам
for class_info = classes_info_values
    fprintf('- класс %s\n', class_info.class_name);
    % даты, пересчитанные в позиции на временной шкале (сдвинуты на пол окна всплеска)
    class_info.dates_scaled = calculate_event_dates_scaled(class_info.dates);
    % временная шкала для этого класса, по факторам, с наложенными всплесками событий
    class_info.factor_time_line = zeros(length(factors_map), calculate_time_line_size_scaled(class_info.time_line_size_original));
    % списки отмасштабированных дат по факторам
    class_info.dates_by_factor_scaled = cell(length(factors_map_keys), 1);
    % проходим по всем событиям класса
    for class_event_counter = 1:class_info.event_count
        fprintf('  - событие #%d [%d]\n', class_event_counter, class_info.dates(class_event_counter));
        % проходим по всем факторам события и накладываем всплеск на временную шкалу
        for factor_key = class_info.factors{class_event_counter}
            % найдём порядковый номер фактора в списке всех факторов
            factor_index = find(strcmp(factors_map_keys, factor_key));
            fprintf('    - фактор [%d]: %s\n', factor_index, factor_key{1});
            % центр события на шкале (сдвинут на пол окна всплеска)
            event_center_position = class_info.dates_scaled(class_event_counter);
            % запомним его позицию для графика
            class_info.dates_by_factor_scaled{factor_index}(length(class_info.dates_by_factor_scaled{factor_index}) + 1) = event_center_position;
            % окно внутри временной шкалы с центром в событии
            event_window = calculate_event_window(event_center_position);
            % добавим окно всплеска на временную шкалу
            class_info.factor_time_line(factor_index, event_window) = class_info.factor_time_line(factor_index, event_window) + event_wave_y;
        end
    end
    % запомним данные по названию класса
    classes_info_map(class_info.class_name) = class_info;
    %figure; plot(rot90(class_events.factor_time_line));
end

print_end_progress(title);

% покажем графики событий по классам
figure('Name', 'события по классам');

% берём обновлённый список классов
classes_info_values = cell2mat(values(classes_info_map));

class_events_index = 1;
for class_info = classes_info_values
    subplot(length(classes_info_map), 1, class_events_index);
    plot(rot90(class_info.factor_time_line));
    class_events_index = class_events_index + 1;
end

% заполним временную шкалу всеми факторами

% factor_time_line[фактор]
% это плавная временная шкала событий по каждому фактору
% с максимумом в дате события
% в начале и в конце к ней прицеплено по половине окна всплеска
% чтобы крайние события не вылетали за пределы матрицы
factor_time_line = zeros(length(factors_map), time_line_size_scaled);

% даты, пересчитанные в позиции на временной шкале (сдвинуты на пол окна всплеска)
event_dates_scaled = calculate_event_dates_scaled(event_dates_original);

% сюда складываем позиции событий на шкале по каждому фактору
% (нужны чтобы отмечать позиции на графике)
% /старый вариант без предраспределения/ event_dates_time_line_by_factor = cell(length(factors_map_keys), 1);
% выделим заранее место под список дат каждого фактора
event_dates_by_factor_scaled = cellfun(@(fk) zeros(factors_map(fk), 1), factors_map_keys, 'UniformOutput', false);

title = 'заполняю временные шкалы по факторам';
print_start_progress(title);

% проходим по всем событиям, по всем его факторам
% и добавляем каждый фактор на соответствующую временную шкалу
for i = 1:length(event_dates_original)
    if ~isfinite(event_dates_original(i))
        % пропускаем не-числа
        continue;
    end
    fprintf('- событие [%d]: %s\n', raw{i,date_column_number}, raw{i,description_column_number});
    % проходим по всем факторам события и накладываем всплеск на временную шкалу
    for factor_key = factors_by_row{i}
        % найдём порядковый номер фактора в списке всех факторов
        factor_index = find(strcmp(factors_map_keys, factor_key));
        fprintf('  - фактор [%d]: %s\n', factor_index, factor_key{1});
        % центр события на шкале (сдвинут на пол окна всплеска)
        event_center_position = event_dates_scaled(i);
        % запомним его позицию для графика (добавляем в конец, незаполненные позиции - нулевые)
        event_dates_by_factor_scaled{factor_index}(find(event_dates_by_factor_scaled{factor_index}==0,1)) = event_center_position;
        % окно внутри временной шкалы с центром в событии
        event_window = calculate_event_window(event_center_position);
        % добавим окно всплеска на временную шкалу
        factor_time_line(factor_index, event_window) = factor_time_line(factor_index, event_window) + event_wave_y;
    end
end

print_end_progress(title);

% покажем графики событий по факторам
figure('Name', 'события по факторам');
% рисуем все факторы в первый подграфик
subplot(length(factors_map_keys) + 1, 1, 1);
plot(rot90(factor_time_line));
for i = 1:length(factors_map_keys)
    % рисуем фактор i в i+1 подграфик
    subplot(length(factors_map_keys) + 1, 1, i+1);
    plot(factor_time_line(i,:), '-o', 'MarkerIndices', event_dates_by_factor_scaled{i});
end

% функция fill_time_line_by_event_factors
% - заполняем временные шкалы по факторам всплесками в центрах событий
% todo... /а может и не надо её отдельно выносить/

function [factor_time_line] = fill_time_line_by_event_factors(event_dates, event_factors, title)

% на входе:
% - event_dates - исходные даты событий
% - event_factors - факторы к каждой дате
% - message - сообщение для консоли и графика
% на выходе:
% - factor_time_line - заполненная временная шкала по факторам


end % function fill_time_line_by_event_factors

% функция parse_factors - парсим факторы/классы из excel-я

function [factors_by_row, factors_map] = parse_factors(raw, factor_column_number)

% на входе:
% - raw - таблица из excel
% - факторы в столбце factor_column_number, фразы через запятую
% на выходе:
% - в factors{i} будут распарсенные массивы фраз для события в строке i
% - в factors_map будет весь список факторов по всем событиям
%   в виде ассоциативного множества:
%   factors_map(фактор) = сколько раз встретился этот фактор в событиях
%   todo: наверно стоит сюда писать сразу список дат?

% берём в factors только колонку с текстом/номерами факторов
factors_by_row = raw(:,factor_column_number);
% сюда складываем все встретившиеся факторы
factors_map = containers.Map;

% проходим по всем строкам-событиям
for i = 1:length(factors_by_row)
    % парсим строку на фразы разделяя по запятым,
    % без пробелов в начале и конце
    
    % найденные факторы в текущей строке
    single_event_factors = {};
    
    if ischar(factors_by_row{i}) % это текст?
        single_event_factors = strsplit(lower(strtrim(factors_by_row{i})),'\s*,\s*','DelimiterType','RegularExpression');
    elseif isfinite(factors_by_row{i}) % это число?
        single_event_factors = {num2str(factors_by_row{i})};
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
    factors_by_row{i} = single_event_factors;
end

end % function parse_factors
