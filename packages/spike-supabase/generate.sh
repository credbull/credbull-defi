#!/bin/bash

if [ "$#" -lt 0 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <filename> [directory]"
  exit 1
fi

FILENAME=$1

# Default directory is 'components'
COMP_DIRECTORY=${2:-components}

# Prompt user for component or page
echo "Choose an option:"
select OPTION in "Component" "Page"; do
  case $OPTION in
  "Component")
    read -p "Enter component name: " COMPONENT_NAME
    DIRECTORY="./src/app/$COMP_DIRECTORY/$COMPONENT_NAME"
    FILENAME=$COMPONENT_NAME
    echo "Generating $FILENAME in $DIRECTORY..."
    mkdir -p $DIRECTORY

    # Prompt user for file extension
    PS3="Choose a file extension (use arrow keys): "
    select EXTENSION in "ts" "tsx"; do
      if [ "$EXTENSION" == "ts" ] || [ "$EXTENSION" == "tsx" ]; then
        break
      else
        echo "Invalid selection. Please choose 1 or 2."
      fi
    done

    cat <<EOL >$DIRECTORY/$FILENAME.$EXTENSION
import React from 'react';

const $COMPONENT_NAME: React.FC = () => {
  return (
    <div>
      <h1>$COMPONENT_NAME Component</h1>
      <p>This is a sample React component.</p>
    </div>
  );
};

export default $COMPONENT_NAME;

EOL
    echo "File generated successfully in $DIRECTORY!"
    break
    ;;

  "Page")
    read -p "Enter page name: " PAGE_NAME
    PAGE_DIR="./src/pages/$PAGE_NAME"
    echo "Generating page $PAGE_NAME in $PAGE_DIR..."
    mkdir -p $PAGE_DIR

    # Prompt user for file extension
    PS3="Choose a file extension (use arrow keys): "
    select EXTENSION in "ts" "tsx"; do
      if [ "$EXTENSION" == "ts" ] || [ "$EXTENSION" == "tsx" ]; then
        break
      else
        echo "Invalid selection. Please choose 1 or 2."
      fi
    done

    cat <<EOL >"$PAGE_DIR/$FILENAME/index.$EXTENSION"
import React from 'react';

const ${PAGE_NAME}_Page: React.FC = () => {
  return (  
    <div>
      <h1>$PAGE_NAME Page</h1>
      <p>This is a sample React page.</p>
    </div>
  );
};

export default ${PAGE_NAME}_Page;

EOL
    echo "Page generated successfully in $PAGE_DIR!"
    break
    ;;

  *)
    echo "Invalid option. Please select 1 or 2."
    ;;
  esac
done
