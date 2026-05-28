.PHONY: help get-deps analyze run-web build-android build-web clean

# Variables
PROJECT_NAME = flutter-tweeter
FLUTTER = flutter
DART = dart

# Colores
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

help:
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(GREEN)$(PROJECT_NAME) - Makefile$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Comandos disponibles:"
	@echo ""
	@echo "  make get-deps        Obtener dependencias"
	@echo "  make analyze         Analizar código Dart"
	@echo "  make run-web         Ejecutar en navegador web"
	@echo "  make build-android   Compilar APK para Android"
	@echo "  make build-web       Compilar para web"
	@echo "  make clean           Limpiar build"
	@echo "  make help            Mostrar esta ayuda"
	@echo ""

get-deps:
	@echo "$(BLUE)Obteniendo dependencias...$(NC)"
	@$(FLUTTER) pub get
	@echo "$(GREEN)✓ Dependencias obtenidas$(NC)"

analyze:
	@echo "$(BLUE)Analizando código...$(NC)"
	@$(FLUTTER) analyze
	@echo "$(GREEN)✓ Análisis completado$(NC)"

format:
	@echo "$(BLUE)Formateando código...$(NC)"
	@$(DART) format lib test
	@echo "$(GREEN)✓ Código formateado$(NC)"

run-web: get-deps
	@echo "$(BLUE)Ejecutando en navegador web...$(NC)"
	@$(FLUTTER) run -d chrome

build-android: get-deps
	@echo "$(BLUE)Compilando APK para Android...$(NC)"
	@$(FLUTTER) build apk --release
	@echo "$(GREEN)✓ APK compilado en: build/app/outputs/apk/release/app-release.apk$(NC)"

build-web: get-deps
	@echo "$(BLUE)Compilando para web...$(NC)"
	@$(FLUTTER) build web
	@echo "$(GREEN)✓ Compilación web completada$(NC)"

build-debug:
	@echo "$(BLUE)Compilando APK debug para Android...$(NC)"
	@$(FLUTTER) build apk
	@echo "$(GREEN)✓ APK debug compilado en: build/app/outputs/apk/debug/app-debug.apk$(NC)"

clean:
	@echo "$(BLUE)Limpiando build...$(NC)"
	@$(FLUTTER) clean
	@echo "$(GREEN)✓ Build limpiado$(NC)"

doctor:
	@echo "$(BLUE)Verificando entorno Flutter...$(NC)"
	@$(FLUTTER) doctor -v

upgrade:
	@echo "$(BLUE)Actualizando Flutter...$(NC)"
	@$(FLUTTER) upgrade

test:
	@echo "$(BLUE)Ejecutando tests...$(NC)"
	@$(FLUTTER) test

.DEFAULT_GOAL := help
