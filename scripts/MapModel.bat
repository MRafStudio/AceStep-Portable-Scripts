REM scripts\MapModel.bat
@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM   MapModel.bat — маппинг моделей AceStep-1.5
REM   Вход:  %1 = CURRENT_MODEL (turbo, sft, xl-base, xl-sft, xl-turbo, base)
REM   Выход: REAL_MODEL, HF_REPO, MODEL_SIZE, MODEL_VRAM, MODEL_STEPS
REM ============================================================================

set "INPUT_MODEL=%~1"
set "INPUT_MODEL=%INPUT_MODEL: =%"

REM Дефолт
set "REAL_MODEL=acestep-v15-turbo"
set "HF_REPO=ACE-Step/acestep-v15-turbo"
set "MODEL_SIZE=~5GB"
set "MODEL_VRAM=6GB+"
set "MODEL_STEPS=8"
set "MODEL_DESC=Быстрая"

if /I "%INPUT_MODEL%"=="base" (
    set "REAL_MODEL=acestep-v15-base"
    set "HF_REPO=ACE-Step/acestep-v15-base"
    set "MODEL_SIZE=~5GB"
    set "MODEL_VRAM=6GB+"
    set "MODEL_STEPS=50"
    set "MODEL_DESC=Стандарт (устаревшая)"
)

if /I "%INPUT_MODEL%"=="sft" (
    set "REAL_MODEL=acestep-v15-sft"
    set "HF_REPO=ACE-Step/acestep-v15-sft"
    set "MODEL_SIZE=~5GB"
    set "MODEL_VRAM=6GB+"
    set "MODEL_STEPS=50"
    set "MODEL_DESC=Стандарт"
)

if /I "%INPUT_MODEL%"=="turbo" (
    set "REAL_MODEL=acestep-v15-turbo"
    set "HF_REPO=ACE-Step/acestep-v15-turbo"
    set "MODEL_SIZE=~5GB"
    set "MODEL_VRAM=6GB+"
    set "MODEL_STEPS=8"
    set "MODEL_DESC=Быстрая"
)

if /I "%INPUT_MODEL%"=="xl-base" (
    set "REAL_MODEL=acestep-v15-xl-base"
    set "HF_REPO=ACE-Step/acestep-v15-xl-base"
    set "MODEL_SIZE=~19GB"
    set "MODEL_VRAM=12GB+"
    set "MODEL_STEPS=50"
    set "MODEL_DESC=Все задачи"
)

if /I "%INPUT_MODEL%"=="xl-sft" (
    set "REAL_MODEL=acestep-v15-xl-sft"
    set "HF_REPO=ACE-Step/acestep-v15-xl-sft"
    set "MODEL_SIZE=~19GB"
    set "MODEL_VRAM=12GB+"
    set "MODEL_STEPS=50"
    set "MODEL_DESC=Стандарт"
)

if /I "%INPUT_MODEL%"=="xl-turbo" (
    set "REAL_MODEL=acestep-v15-xl-turbo"
    set "HF_REPO=ACE-Step/acestep-v15-xl-turbo"
    set "MODEL_SIZE=~19GB"
    set "MODEL_VRAM=12GB+"
    set "MODEL_STEPS=8"
    set "MODEL_DESC=Быстрая"
)

REM Возвращаем переменные через endlocal
endlocal & set "REAL_MODEL=%REAL_MODEL%" & set "HF_REPO=%HF_REPO%" & set "MODEL_SIZE=%MODEL_SIZE%" & set "MODEL_VRAM=%MODEL_VRAM%" & set "MODEL_STEPS=%MODEL_STEPS%" & set "MODEL_DESC=%MODEL_DESC%"

exit /b 0