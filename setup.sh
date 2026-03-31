#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_REPO="https://github.com/penpot/penpot-mcp.git"
SOURCE_DIR="penpot-mcp-source"
IMAGE_NAME="penpot-mcp"
CONTAINER_NAME="penpot-mcp-server"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi

    # Check if docker-compose exists (v1 or v2)
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    print_success "All prerequisites are met!"
}

# Clone or update local source repository
ensure_source_directory() {
    print_status "Preparing Penpot MCP source..."

    if [ ! -d "$SOURCE_DIR" ]; then
        git clone "$SOURCE_REPO" "$SOURCE_DIR"
    elif [ -d "$SOURCE_DIR/.git" ]; then
        print_status "Updating existing source checkout..."
        git -C "$SOURCE_DIR" pull --ff-only
    else
        print_warning "'$SOURCE_DIR' already exists and is not a git checkout."
        print_warning "Using the existing directory as-is."
    fi

    print_status "Checking local Penpot MCP source..."

    if [ ! -d "$SOURCE_DIR" ]; then
        print_error "Missing '$SOURCE_DIR' directory."
        print_error "Place the Penpot MCP source in '$SOURCE_DIR' and try again."
        exit 1
    fi

    if [ ! -f "$SOURCE_DIR/package.json" ]; then
        print_error "Missing '$SOURCE_DIR/package.json'."
        print_error "The local source directory does not look like the Penpot MCP monorepo."
        exit 1
    fi

    print_success "Source directory is ready."
}

# Setup environment file
setup_environment() {
    print_status "Setting up environment file..."

    if [ ! -f ".env" ]; then
        cp .env.example .env
        print_warning "Created .env file from template. Please edit it with your Penpot credentials:"
        print_warning "  PENPOT_USERNAME=your_username"
        print_warning "  PENPOT_PASSWORD=your_password"
        echo
        read -p "Press Enter to continue after editing the .env file..."
    else
        print_success "Environment file already exists."
    fi
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."

    docker build -t "$IMAGE_NAME:latest" .

    print_success "Docker image built successfully!"
}

# Start services with Docker Compose
start_services() {
    print_status "Starting services with Docker Compose..."

    # Determine docker-compose command
    if command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi

    $COMPOSE_CMD up -d

    print_success "Services started successfully!"

    print_status "Waiting for services to be healthy..."
    sleep 10

    # Check if the MCP HTTP endpoint is responding
    if curl -f http://localhost:4401/mcp >/dev/null 2>&1; then
        print_success "PenPot MCP Server is running and healthy!"
        echo
        print_status "You can now:"
        echo "  • View logs: $COMPOSE_CMD logs -f penpot-mcp"
        echo "  • Check status: $COMPOSE_CMD ps"
        echo "  • MCP endpoint: http://localhost:4401/mcp"
        echo "  • Plugin manifest: http://localhost:4400/manifest.json"
        echo "  • Stop services: $COMPOSE_CMD down"
    else
        print_warning "Service might still be starting up. Check logs with: $COMPOSE_CMD logs penpot-mcp"
    fi
}

# Main function
main() {
    echo
    print_status "🐳 PenPot MCP Server Docker Setup Script"
    echo "==========================================="
    echo

    # Parse command line arguments
    case "${1:-setup}" in
        "setup")
            check_prerequisites
            ensure_source_directory
            setup_environment
            build_image
            start_services
            ;;
        "build")
            check_prerequisites
            ensure_source_directory
            build_image
            ;;
        "start")
            check_prerequisites
            ensure_source_directory
            start_services
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  setup    Clone/update source, build, and start [default]"
            echo "  build    Only build the Docker image"
            echo "  start    Start the services"
            echo "  help     Show this help message"
            echo
            exit 0
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac

    echo
    print_success "🎉 Done! Your PenPot MCP Server is ready!"
}

# Run main function
main "$@"
