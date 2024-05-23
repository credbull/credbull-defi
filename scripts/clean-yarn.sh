cd ..

cd ~/proj/credbull/credbull-defi

# Remove all node_modules directories
find . -name "node_modules" -type d -prune -exec rm -rf '{}' +

# Remove all yarn.lock files
find . -name "yarn.lock" -type f -delete

# Remove all .pnp.js files (if not using PnP)
find . -name ".pnp.js" -type f -delete

# Run a clean yarn install
yarn install