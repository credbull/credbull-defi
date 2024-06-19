cd ..

# Capture the current directory
current_dir=$(pwd)

echo "Cleaning yarn caches from root directory ($current_dir)"

# Enable command echoing
set -x

# Ensure command echoing is disabled upon script exit
trap 'set +x' EXIT

pwd

# Remove all node_modules directories, excluding those under any 'lib' directory
find . -name "lib" -prune -o -name "node_modules" -type d -exec rm -rf '{}' +

# Remove all node_modules directories, excluding those under any 'lib' directory
find . -name "lib" -prune -o -name "cache" -type d -exec rm -rf '{}' +


# Remove all .pnp.js files (if not using PnP), excluding those under any 'lib' directory
find . -name "lib" -prune -o -name ".pnp.js" -type f -exec rm -f '{}' +w
