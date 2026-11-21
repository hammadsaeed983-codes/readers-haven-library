# ---------- Stage 1: Build the static site ----------
# Pinned Node.js LTS Alpine image used only to run the build — never shipped to production.
FROM node:22-alpine AS builder

# Working directory inside the build stage.
WORKDIR /app

# Copy only the package manifests first. Docker caches this layer, so if you
# later change page content (but not dependencies), npm ci won't re-run.
COPY package*.json ./

# Install exact versions from package-lock.json for a reproducible build.
RUN npm ci

# Now copy the actual source files needed to build the site.
COPY src/ ./src/
COPY styles/ ./styles/

# Run the "build" script from package.json (Parcel). Outputs static files to /app/dist.
RUN npm run build

# ---------- Stage 2: Serve the built site with Nginx ----------
# Small, pinned Nginx image. No Node.js, npm, or node_modules exist in this stage.
FROM nginx:1.27-alpine

# Copy ONLY the compiled static files from the builder stage into Nginx's web root.
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that the container listens on port 80.
EXPOSE 80

# Run Nginx in the foreground so the container doesn't exit immediately.
CMD ["nginx", "-g", "daemon off;"]