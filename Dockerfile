FROM ghcr.io/hazmi35/node:20-dev-alpine as build-stage

# Prepare pnpm with corepack (experimental feature)
RUN corepack enable && corepack prepare pnpm@latest

# Copy package.json, lockfile and npm config files
COPY package.json pnpm-lock.yaml *.npmrc  ./

# Fetch dependencies to virtual store
RUN pnpm fetch

# Install dependencies
RUN pnpm install --offline --frozen-lockfile

# Copy Project files
COPY . .

# Build TypeScript Project
RUN pnpm run build

# Prune devDependencies
RUN pnpm prune --production

# Get ready for production
FROM ghcr.io/hazmi35/node:20-alpine

LABEL name "whatsapp-bot"
LABEL maintainer "Clytage <admin@clytage.org>"

# Install ffmpeg
RUN apk add --no-cache ffmpeg

# Copy needed files
COPY --from=build-stage /tmp/build/package.json .
COPY --from=build-stage /tmp/build/node_modules ./node_modules
COPY --from=build-stage /tmp/build/dist ./dist

# Additional Environment Variables
ENV NODE_ENV production

# Start the app with node
CMD ["node", "dist/index.js"]