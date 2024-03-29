function [] = profile_experimnent(LINK)

    %% Собираем в файл
    clear
    Nx = 201;
    Ny = 201;

    tic

    for iy = 1:Ny

        for ix = 1:Nx
            ck = clock;
            file_name = [LINK, ...
                       num2str(ix - 1, '#03d') 'Y' num2str(iy - 1, '%03d') '.txt'];
            a = caseread(file_name);
            x = str2num(a(82:size(a, 1), :));

            %сигнал
            for ii = 1:length(x(:, 1))
                wave_frame(ii, ix, iy) = x(ii, 2);
            end

            rt = etime(clock, ck) * (1 - (iy - 1 + ix / Nx) / Ny) * Nx * Ny;
            fprintf(['files loading process' num2str((iy - 1 + ix / Nx) / Ny * 100, '%04.2f'), ...
                         '%% done ', 'Remaining time =', num2str(rt / 60, '%04.1f'), ' mins\n'])
        end

    end

    toc

    %время
    for ii = 1:length(x(:, 1))
        tt(ii) = x(ii, 1);
    end

    save loaded_wfms_inphase.mat -v7.3
    Table = permute(wave_frame, [3, 2, 1]);

    %% Обработка
    global Nt dt Zh k lymda
    lymda = 1.480/1.072; k = 2 * pi / lymda; Zh = -60;
    Nt = 5000;
    dt = 20e-9;
    dT = Nt * dt; df = 1 / dT;
    f = (-Nt / 2 + 1) * df:df:Nt / 2 * df;
    fi = find(f >= 1.072 * 1e6, 1);

    for iy = 1:Ny

        for ix = 1:Nx
            S(ix, iy, :) = fftshift(fft(Table(ix, iy, :)));
            Res(ix, iy) = S(ix, iy, fi) * 2;
        end

    end

    %% Обратная задача
    clear x delT
    global dx dy dk_x dk_y
    %Для проверки температурной зависимости:
    ind = 1;

    for delT = 0:0.005:10
        %для проверки температурной зависимости
        dc = 0.00267 * delT / 201/201;

        for ix = 1:Nx

            for iy = 1:Ny
                kk(ix, iy) = 2 * pi * 1.072 / (1.480 + dc * (ix + iy - 2));
            end

        end

        %Сетка [x,y]:
        dx = 0.5; dy = dx;
        X_max = Nx * dx; Y_max = Ny * dy;
        x = [- (X_max - dx) / 2:dx:(X_max - dx) / 2]; y = x;
        [X, Y] = meshgrid(x, y);

        % Сетка [kx,ky]:
        dk_x = 2 * pi / X_max; dk_y = dk_x;
        Kx_m = 2 * pi / dx; Ky_m = Kx_m;
        kx = [- (Kx_m - dk_x) / 2:dk_x:(Kx_m - dk_x) / 2]; ky = kx;
        [Kx, Ky] = meshgrid(kx, ky);

        IST = zeros(Nx, Ny);
        IST(Kx .^ 2 + Ky .^ 2 <= kk .^ 2) = 1;

        %Метод У.С.:
        %Прямое пр:
        S_new = fftshift(fft2(conj(Res)));
        prom = (kk .^ 2 - Kx .^ 2 - Ky .^ 2);

        for ix = 1:Nx

            for iy = 1:Ny

                if (prom(ix, iy) < 0)
                    kz(ix, iy) = kk(ix, iy);
                else
                    kz(ix, iy) = sqrt(prom(ix, iy));
                end

            end

        end

        %Пропагатор
        prop = exp(1i * Zh * kz);
        S_back = S_new .* prop;

        %Обратное БПФ:
        Res_back_test = (ifft2(S_back));
        nexttitle
        pcolor(abs(Res_back));
        title('Результат')

        %Отклонение :
        count = 0;

        for ix = 1:Nx

            for iy = 1:Ny
                count = count + (abs(Res_back_test(ix, iy)) - abs(Res_back(ix, iy))) ^ 2;
            end

        end

        pla(ind) = (count / Nx / (Nx - 1));
        ind = ind + 1;
    end

    nexttitle
    plot(pla);
    title('Стандартное отклонение в условтях линейного увеличения температуры')
    xlabel('Разница температур в начале и конце измерений ')
    ylabel('Среднее квадратическое отклоение')

end
