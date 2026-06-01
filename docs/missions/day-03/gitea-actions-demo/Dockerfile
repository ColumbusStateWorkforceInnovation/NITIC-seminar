# Minimal demo Dockerfile — what the .gitea/workflows/ci.yaml above builds.
# Static page served by nginx. The CI loop edits one string in index.html,
# pushes, and watches the new tag land in Harbor and roll out via ArgoCD.
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
