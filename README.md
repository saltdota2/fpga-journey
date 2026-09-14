# fpga-journey

Учебный репозиторий:  FPGA/RTL design.
Target: AMD Artix-7 (xc7a35ticsg324-1L), Vivado 2022.1, non-project flow.

## Быстрый старт

    make help     # список целей
    make synth    # синтез + отчёты
    make bit      # полный флоу до bitstream

## Структура

| Путь | Содержимое |
|---|---|
| `rtl/` | синтезируемый SystemVerilog |
| `tb/` | тестбенчи |
| `constr/` | XDC-констрейнты |
| `scripts/` | Tcl для non-project flow |
| `docs/` | конспекты, roadmap |

## Модули

| Модуль | Описание | LUT | FF | Fmax |
|---|---|---|---|---|
| `led_blink` | параметризуемый мигатель | 35 | 27 | ~250 МГц |
| `fifo_sync` | параметризуемый sync FIFO, standard/FWFT | 63 LUT | 34 FF | 1 BRAM |
#