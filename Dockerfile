# Creating multi-stage build for production
FROM node:jod-alpine AS build
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev > /dev/null 2>&1
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /srv/
COPY package.json package-lock.json ./
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --only=production
ENV PATH=/srv/node_modules/.bin:$PATH
WORKDIR /srv/app
COPY . .
RUN npm run build

# Creating final production image
FROM node:jod-alpine
RUN apk add --no-cache vips-dev
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /srv/
COPY --from=build /srv/node_modules ./node_modules
WORKDIR /srv/app
COPY --from=build /srv/app ./
ENV PATH=/srv/node_modules/.bin:$PATH

RUN chown -R node:node /srv/app
USER node
EXPOSE 1337

CMD ["npm", "run", "start"]