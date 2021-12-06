FROM node:slim

WORKDIR /app

# change ownership of the "/app" dir to be used by the node user
# install "dumb-init" to handle a container's child process problem
RUN set -eux; \
  chown node:node /app; \
 	apt-get update && apt-get install -y --no-install-recommends \
 	dumb-init; \
 	apt-get clean && rm -rf /var/lib/apt/lists/*

# rewrites npm global root directory
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

# Copy everything to the root of the API service docker volume, and expose port to the outside world
COPY --chown=node:node . .

# Install the good ol' NPM modules and get Adonis CLI in the game
RUN npm install --no-optional

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "ace", "serve"]

USER node
