% читаем excel-файл
% ни Excel, ни офис чтобы читать excel-файлы матлабу не нужен
% num - матрица только числа
% txt - матрица только текстовые значени€
% raw - всЄ подр€д
[num,txt,raw] = xlsread('D:\Download\event_analysis\sample_1_1.xlsx', '', '', 'basic');

% перва€ строка в excel-файле - заголовки, игнорируем

% парсим факторы

% факторы в столбце 3, фразы через зап€тую
% на выходе в factors будут распарсенные массивы фраз
factors = raw(:,3);

% здесь будет весь список факторов по всем событи€м
factors_map = containers.Map;

for i = 2:length(factors)
    % парсим строку на фразы раздел€€ по зап€тым,
    % без пробелов в начале и конце
    if ischar(factors{i})
        single_event_factors = strsplit(strtrim(factors{i}),'\s*,\s*','DelimiterType','RegularExpression');
        for curren_event_factor = single_event_factors
            factors_map(curren_event_factor{1}) = 1;
        end
        factors{i} = single_event_factors;
    end
end
