# Docker Compose Lifecycle
dcb() { docker compose build; }
dco() { docker compose; }
dcstart() { docker compose start; }
dcstop() { docker compose stop; }
dcr() { docker compose run; }
dcu() { docker compose up; }
dcub() { docker compose up --build; }
dcud() { docker compose up -d; }
dcuddf() { docker compose -f $1 up -d; }
dcudf() { docker compose -f $1 up; }
dcup() { docker compose up; }
dcupb() { docker compose up --build; }
dcupd() { docker compose up -d; }

# Container Management
dcd() { docker compose down; }
dcdn() { docker compose down; }
dck() { docker compose kill; }
dcrm() { docker compose rm; }
dct() { docker compose top; }

# Logs & Status
dcl() { docker compose logs $1; }
dclf() { docker compose logs -f $1; }
dcp() { docker compose ps; }
dcps() { docker compose ps; }

# Pull & Restart
dcpull() { docker compose pull; }
dcrestart() { docker compose restart; }

# Docker Exec
dce() { docker compose exec; }
deib() { docker exec -it $1 bash; }

dcxxx() {
        local CONTAINER_NAME=$1
    
        # Pull latest image
        docker compose pull "$CONTAINER_NAME" && \
        # Stop and remove container
        docker compose down "$CONTAINER_NAME" && \
        # Start container in detached mode
        docker compose up -d "$CONTAINER_NAME" && \
        # Follow logs
        docker compose logs -f "$CONTAINER_NAME"
}