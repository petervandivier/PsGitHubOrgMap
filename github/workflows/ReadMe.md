# GitHub action

Copy this GH action to the repository from which you are managing org configuration. 

Provision a Personal Access Token and add it as a secret named `ORG_MAP_PAT` scoped to the either the org or the management repo. If the PAT is scoped to a user, update the username in the credential line of the action.yaml.

If the target branch of the management repo is not `main`, update in the action.yaml as well. 
