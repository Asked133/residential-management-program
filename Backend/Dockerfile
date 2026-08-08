# ─────────────────────────────────────────────────────────────
# Stage 1: Build
# ─────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copiar solo el .csproj primero (aprovecha el cache de capas de Docker)
COPY HavenApi.csproj ./
RUN dotnet restore

# Copiar el resto del código y publicar en modo Release
COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# ─────────────────────────────────────────────────────────────
# Stage 2: Runtime (imagen más ligera, sin SDK)
# ─────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Copiar el artefacto publicado del stage anterior
COPY --from=build /app/publish ./

# Render inyecta la variable PORT dinámicamente
# ASP.NET Core la lee con ASPNETCORE_URLS
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}

EXPOSE 8080

ENTRYPOINT ["dotnet", "HavenApi.dll"]
