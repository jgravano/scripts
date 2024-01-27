#!/bin/bash

OLD_USERNAME="{{ old_username }}"
NEW_USERNAME="{{ new_username }"
OLD_ACCESS_TOKEN="{{ old_access_token }}"
NEW_ACCESS_TOKEN="{{ new_access_token }}"

# Obtener todos los repositorios de la cuenta antigua
repos=$(curl -s -H "Authorization: token $OLD_ACCESS_TOKEN" "https://api.github.com/users/$OLD_USERNAME/repos?per_page=100" | jq -r '.[] | .ssh_url')

# Clonar y transferir repositorios a la nueva cuenta
for repo in $repos; do
  echo "Cloning $repo..."
  git clone --bare "$repo"

  repo_name=$(basename "$repo" .git)
  cd "$repo_name.git" || exit

  echo "Creating new repository in $NEW_USERNAME account..."
  curl -s -X POST -H "Authorization: token $NEW_ACCESS_TOKEN" -d "{\"name\":\"$repo_name\"}" "https://api.github.com/user/repos" > /dev/null

  echo "Pushing to the new repository..."
  git push --mirror "git@github.com:$NEW_USERNAME/$repo_name.git"

  cd ..
  rm -rf "$repo_name.git"
  echo "Finished transferring $repo_name"
done

echo "All repositories have been transferred successfully!"
