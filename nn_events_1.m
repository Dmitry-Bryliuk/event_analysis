% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значени€
% raw - всЄ подр€д
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% перва€ строка в excel-файле - заголовки, игнорируем

% парсим факторы из столбца 3
[factors, factors_map] = parse_factors(raw, 3);

% парсим классы из столбца 4
[classes, classes_map] = parse_factors(raw, 4);

function [factors, factors_map] = parse_factors(raw, factor_row_number)

% парсим факторы/классы
% raw - таблица из excel
% факторы в столбце factor_row_number, фразы через зап€тую
% на выходе в factors будут распарсенные массивы фраз
% в factors_map будет весь список факторов по всем событи€м

factors = raw(:,factor_row_number);
factors_map = containers.Map;

for i = 2:length(factors)
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
