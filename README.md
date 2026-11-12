# TP4 - Observabilidad: GameCloud en Kubernetes

## Descripción
Stack de observabilidad para la API de ranking de GameCloud desplegada en Kubernetes (minikube). Incluye Prometheus, Grafana, Loki y Grafana Alloy.

## Requisitos
- Docker Desktop
- minikube
- kubectl
- Helm 3

## Estructura del repositorio
```
tp4-observabilidad/
├── README.md
├── app/                                  # API de ranking (provisto)
├── charts/gamecloud-ranking/
│   └── templates/
│       └── servicemonitor.yaml           # ServiceMonitor para Prometheus
├── observabilidad/
│   ├── values-kube-prometheus-stack.yaml  # Valores para Prometheus + Grafana
│   ├── values-loki.yaml                  # Valores para Loki (SingleBinary)
│   └── values-alloy.yaml                 # Valores para Alloy (recolector de logs)
├── dashboards/
│   └── gamecloud-dashboard.json          # Dashboard exportado de Grafana
└── escenarios/                           # Scripts de falla (provisto)
```

## Instrucciones para reproducir

### 0. Preparación del entorno
```bash
# Iniciar minikube
minikube start --cpus 4 --memory 8192 --driver docker

# Verificar nodo
kubectl get nodes

# Agregar repositorios de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Crear namespaces
kubectl create namespace observabilidad
kubectl create namespace gamecloud
```

### 1. Despliegue de la API
```bash
# Construir imagen dentro de minikube
minikube image build -t gamecloud-ranking:1.0 app/

# Instalar chart
helm upgrade --install gamecloud-ranking charts/gamecloud-ranking \
  -n gamecloud --create-namespace --wait

# Verificar pods
kubectl get pods -n gamecloud
```

### 2. Prometheus y Grafana
```bash
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack --version 92.11.0 \
  -n observabilidad \
  -f observabilidad/values-kube-prometheus-stack.yaml \
  --wait --timeout 10m

# Acceder a Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n observabilidad 3000:80
# Usuario: admin / Contraseña: prom-operator

# Acceder a Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n observabilidad 9090:9090
```

### 3. ServiceMonitor
```bash
# Actualizar el chart de la API (ya incluye el servicemonitor.yaml)
helm upgrade gamecloud-ranking charts/gamecloud-ranking -n gamecloud

# Verificar targets en Prometheus → Status → Target health
```

### 4. Loki y Alloy
```bash
# Instalar Loki
helm upgrade --install loki grafana/loki --version 7.5.0 \
  -n observabilidad \
  -f observabilidad/values-loki.yaml \
  --wait --timeout 10m

# Instalar Alloy
helm upgrade --install alloy grafana/alloy --version 1.14.2 \
  -n observabilidad \
  -f observabilidad/values-alloy.yaml \
  --wait --timeout 5m
```

### 5. Dashboard
Importar el archivo `dashboards/gamecloud-dashboard.json` desde Grafana (Dashboards → Import).

### 6. Escenarios de falla
```bash
# Escenario 1: errores 500
bash escenarios/1_errores.sh

# Volver a normalidad
bash escenarios/normal.sh

# Escenario 2: latencia alta
bash escenarios/2_latencia.sh
bash escenarios/normal.sh

# Escenario 3: CrashLoopBackOff
bash escenarios/3_crashloop.sh
bash escenarios/normal.sh

# Escenario 4: puerto incorrecto en Service
bash escenarios/4_puerto_service.sh
bash escenarios/normal.sh
```

## Versiones de charts utilizados
| Chart | Versión |
|-------|---------|
| kube-prometheus-stack | 92.11.0 |
| loki | 7.5.0 |
| alloy | 1.14.2 |
