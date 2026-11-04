$project = "keycloak-extension"
New-Item -ItemType Directory -Force -Path "$project\icons" | Out-Null

# (Copia el mismo contenido de cada archivo que en el script bash)
# Para Windows, lo más fácil es usar el script bash con Git Bash o WSL.