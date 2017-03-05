% ������ ������������� � ������������� ������ � �������� ����������������
% ������

% ������ � ����� ����� � �������, ���� ����� ����� �� ��������� �������
% ������������� ������� ����� ������ �������

% ����� �������� ��� ���, ����� �� ����������� ���������� ������� �
% �������:
% echo off

% ������ �������� ������, ������ ������� ��� ���� �����/������
z = rot90([1 0 1; 0 1 0]);
% ������ �������, ������ ������� ���������� �������������� ������ � ������
% ��� ���������� �������
zc = rot90([1 0; 0 1]);

% ��������� ���� � ����� ������, � ������ ���������� �������� � ������ ����
net = patternnet([2 2]);
% ������� ��������� ���� �� ��������
net = train(net, z, zc);

% ���������� ����������� ����:
% view(net)

% ���������� ��������� ������ ���� �� ��������� �������
% (����� �������� ��� ��, ��� � ����� ��������)
perform(net, zc, net(z))

% ���������� � ����� ������� �� ������� ������� �����:
vec2ind(net(z))

% � ��� ����� �������� ������ (��������� � �����������) ������ � ��������
% ��� �� ���� ��������������:
net(rot90([1 0 1]))
net(rot90([0 0 1]))
net(rot90([0 0.5 0]))

% ��� ����� ������� ���� ��� �� ������ ������� (������� �� ���������
% ������������� ���� � � ��� ����� ���� ������):
net(rot90([-10 -10 1]))
% �� ����� ���������� � ������ ������ ��� ������:
vec2ind(net(rot90([-10 -10 1])))
