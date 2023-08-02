# PsGitHubOrgMap

For a given GitHub org, dump the membership & repository configuration to the filesystem. Also deploys to the GH org changes registered to the filesystem record.

This whole repo is a thin wrapper over the functionality provided by the official [PowerShellForGitHub](https://github.com/microsoft/PowerShellForGitHub) repo. This module is just for standardizing filesytem formats, providing config support for multiple orgs, and providing re-deploy wrappers. 

The PAT you will need to use this module requires the following permissions
- admin:org
- repo

Optionally you can include the delete_repo permission if you are comfortable auto-deleting repos.
