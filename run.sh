#!/bin/bash

# Script para ejecutar Flutter Tweeter
# Uso: ./run.sh [opción]
# Opciones:
#   web      - Ejecutar en navegador web
#   android  - Compilar APK para Android
#   help     - Mostrar esta ayuda

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar encabezado
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Función para mostrar éxito
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Función para mostrar error
print_error() {
    echo -e "${YELLOW}✗ $1${NC}"
}

# Función para obtener dependencias
get_dependencies() {
    print_header "Obteniendo dependencias..."
    flutter pub get
    print_success "Dependencias obtenidas"
}

# Función para analizar código
analyze_code() {
    print_header "Analizando código..."
    flutter analyze
    print_success "Análisis completado"
}

# Ejecutar en web
run_web() {
    print_header "Ejecutando en navegador web..."
    get_dependencies
    flutter run -d chrome
}

# Compilar APK para Android
build_android() {
    print_header "Compilando APK para Android..."
    get_dependencies
    flutter build apk --release
    print_success "APK compilado en: build/app/outputs/apk/release/app-release.apk"
}

# Mostrar ayuda
show_help() {
    cat << EOF
${GREEN}Flutter Tweeter - Script de ejecución${NC}

${BLUE}Uso:${NC}
    ./run.sh [opción]

${BLUE}Opciones:${NC}
    web       Ejecutar en navegador web
    android   Compilar APK para Android
    analyze   Analizar código Dart
    deps      Obtener dependencias
    help      Mostrar esta ayuda

${BLUE}Ejemplos:${NC}
    ./run.sh web
    ./run.sh android
    ./run.sh analyze

EOF
}

# Parsear argumentos
case "${1:-help}" in
    web)
        run_web
        ;;
    android)
        build_android
        ;;
    analyze)
        analyze_code
        ;;
    deps)
        get_dependencies
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
