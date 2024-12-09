# MAIA User Registration

The User Registration in MAIA includes a list of users and the projects they are associated with (i.e. Kubernetes namespace).
Upon receiving a request to register a new user, the following steps are taken:
1. Create the new Namespace, if not existing. See [Namespace Creation](MAIA_Workspace.md#namespace-creation)
2. Create the corresponding group in Keycloak, following the convention `MAIA:<namespace>`.
3. Associate the user with the group in Keycloak.