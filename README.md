# event_analysis
многофакторный анализ событий, выявление закономерностей, дубликатов и скрытых факторов

цель проекта - анализ событий, в первую очередь нейронными сетями (потому что я в них слегка разбираюсь), на предмет выявления различных закономерностей, поиск дублирующихся событий на временной шкале, автоматическая группировка сходных событий из разных участков временной шкалы, выявления всяческих скрытых факторов.

нейронные сети - это магический бульбулятор, которому можно скормить всё что угодно и оно всё поймёт. если нс скормить на вход ерунду, на выходе будет такая же ерунда. нс это конкретный математический аппарат, которому нужны правильно подготовленные исходные данные, а это 99.9% работы.

кроме временной отметки, у события должны быть отмечены сопутствующие факторы. в идеале, если известны группы событий, принадлежащих известному классу (если это точно известно, или хотя-бы гипотеза), то отметить и эти классы.

в контексте анализа событий что нейронные сети умеют делать:
- ужимать пространство признаков до небольшой размерности (это анализ главных компонент, PCA). предварительная классификация не обязательна, но может использоваться дополнительно.
- по известной обучающей выборке (группа событий/класс) классифицировать неизвестные события. обучающая выборка должна быть проклассифицирована.
- кластеризация - группировка похожих событий в кластеры, предварительная классификация необязательна. что за события сгруппировались в конкретный кластер трактовать будет уже человек.

каждое событие - это временная отметка на шкале и список сопутствующих факторов и классов.

группа событий - это несколько событий на шкале, отмеченных одним классом. событие может относиться к нескольким классам.

примеры в процессе

#### факторы и классы

факторы и классы - это набор слов через запятую, как тэги, главное чтобы один фактор/класс обозначался одним и тем-же словом

для более общего анализа можно использовать суперфакторы и суперклассы. несколько похожих факторов можно дополнительно обозначить одним более общим, например, если у события месяц инюнь/июль/август, то такие события можно дополнительно пометить фактором "время года лето". нс такое любят. плюс это уменьшает ошибки, если датировка события "плавает".

аналоги. похожие факторы можно явно объеденить, например, "аномальное похолодание", "замёрзли моря", "год без лета" можно объявить аналогами и трактовать как один класс.

идея состоит в том, чтобы можно было настраивать такие списки отдельно, не редактируя сам список событий.

#### в каком виде это скармливается в нейронные сети

временная шкала развёртывается в дискретный линейный график. например, если весь диапазон событий от 1 до 2000 лет и точность развёртки 1 год, то в шкале будет 2000 ячеек, каждая из который соответствует своему году.

каждый фактор развёртывается в отдельную временную шкалу, в которой число от 0 (фактор отсутствует) до 1 (фактор присутствует). факторы желательно разгладить, т.е. не только единичные пики на фоне нулей, но и промежуточные значения "холмики" в окрестностях события. нс такое любят.

исходный пример:

| год  | факторы       |
| ---- |---------------|
| 3    | A             |
| 5    | A,B           |
| 7    | C             |

развернётся приблизительно так:

ф\г | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
----|---|---|---|---|---|---|---|---|---|----|
A   |   |0.5| 1 |0.5| 1 |0.5|   |   |   |    |
B   |   |   |   |0.5| 1 |0.5|   |   |   |    |
C   |   |   |   |   |   |0.5| 1 |0.5|   |    |

(как нормировать всплески при наложении ещё предстоит выяснить)

классы разворачиваются в свою выходную шкалу, понятную нс, например у нас 3 класса, тогда длина шкалы будет 3:

группы\классы    | класс 1 | класс 2 | класс 3 | примечание   |
-----------------|---------|---------|---------|--------------|
группа событий 1 |    1    |    0    |    1    | классы 1 и 3 |
группа событий 2 |    0    |    1    |    0    | класс 2      |
группа событий 3 |    0    |    0    |    1    | класс 3      |

далее временные шкалы факторов можно пересчитать в частотный спектр (например ряды Фурье или вейвлеты), для уменьшения проблем из-за временных искажений и лучшего выявления связей. возможно есть что-то, позволяющее пересчитать дискретные шкалы напрямую в спектр без предварительного сглаживания.

далее выбирается временное окно и шаг, с которым это окно двигается по основной шкале. куски шкал по всем факторам внутри окна и подаются на вход нс, это входной образ.

если есть классификация событий, то выход нс - это классы всех событий, попавших в окно. для обучающей выборки можно подгонять окно так, чтобы все события класса попали внутрь окна, а на вход можно подавать только события, относящиеся к одному классу, последовательно по всем классам (например, если они накладываются внутри окна), и/или выкидывать события без классов. но это уже надо проверять что и в каких сочетаниях лучше работает.
