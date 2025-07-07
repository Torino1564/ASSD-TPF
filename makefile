SRC_DIR := src
BUILD_DIR := build

.PHONY: all prepare build upload verify clean

all: build

prepare:
	@echo Cleaning build directory...
	@if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
	@mkdir $(BUILD_DIR)

	@echo Copying Verilog files...
	@powershell -Command "Get-ChildItem -Recurse -Filter *.v -Path '$(SRC_DIR)' | ForEach-Object { $$relativePath = $_.FullName.Substring((Resolve-Path '$(SRC_DIR)').Path.Length + 1); $$dest = Join-Path '$(BUILD_DIR)' $$relativePath; New-Item -ItemType Directory -Path (Split-Path $$dest) -Force | Out-Null; Copy-Item -Path $_.FullName -Destination $$dest -Force }"

	@echo Copying apio.ini...
	@if exist apio.ini copy /Y apio.ini $(BUILD_DIR) >nul

build: prepare
	@echo Running APIO build...
	@cd $(BUILD_DIR) && apio build

upload: prepare
	@echo Running APIO upload...
	@cd $(BUILD_DIR) && apio upload

verify: prepare
	@echo Running APIO verify...
	@cd $(BUILD_DIR) && apio verify

clean:
	@if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
