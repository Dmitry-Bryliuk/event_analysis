% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значени€
% raw - всЄ подр€д (ориентируемс€ на него, в остальных могут съезжать €чейки)
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% убираем первую строку с заголовками
raw(1,:) = [];

% перва€ строка в excel-файле - заголовки, игнорируем

% парсим факторы из столбца 3
[factors, factors_map] = parse_factors(raw, 3);

% парсим классы из столбца 4
[classes, classes_map] = parse_factors(raw, 4);

% даты событий в первом столбце (считаем пока что это только год)

% минимальное/максимальное врем€ на шкале
% большие пустые промежутки дл€ простоты не выкидываем
% столбец с датами первый
date_column_number = 1;
event_dates = cell2mat(raw(:,date_column_number));
min_time = min(event_dates);
max_time = max(event_dates);
time_line_size = max_time - min_time;

fprintf('начало временной шкалы: %.2f, конец: %.2f, размер:  %.2f\n', min_time, max_time, time_line_size);

% масштабирование временной шкалы. мы делаем событие гладкой волной с пиком
% в дате событи€, и чтобы дать пространство дл€ этой волны делаем шкалу
% более детальной

% если будут более точные даты, можно разнести отдельно годовые и
% внутригодовые/внутримес€чные шкалы событий, чем пересчитывать шкалу в дни

time_line_zoom = 10; % увеличиваем масштаб временной шкалы в 10 раз

% factor_time_line[фактор]
% - это плавна€ шкала событий по отдельному фактору
%   с максимумом в дате событи€
factor_time_line = zeros(length(factors_map), time_line_size * time_line_zoom);

% ширина всплеска событи€
time_line_sigma = 100;

% нормируем пик всплеска к единице
time_line_sigma_scale = 1/normpdf(0,0,100);

% проходим по всем событи€м на шкале и добавл€ем его факторы на шкалы
% факторов
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

% парсим факторы/классы
% raw - таблица из excel
% факторы в столбце factor_column_number, фразы через зап€тую
% на выходе в factors будут распарсенные массивы фраз
% в factors_map будет весь список факторов по всем событи€м

factors = raw(:,factor_column_number);
factors_map = containers.Map;

for i = 1:length(factors)
    % парсим строку на фразы раздел€€ по зап€тым,
    % без пробелов в начале и конце
    
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
