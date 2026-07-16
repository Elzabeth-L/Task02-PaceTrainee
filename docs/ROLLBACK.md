# Rollback

1. Find an earlier successful build's full SHA and confirm both public images remain available.
2. Dispatch `Infrastructure` with `apply`, the affected account, and that SHA.
3. The pipeline verifies both images, records both current parameters, temporarily updates both parameters to create task-definition changes, then restores them during the approval wait.
4. Review the readable plan and approve the protected environment.
5. After approval, the workflow writes the reviewed pair again and the exact plan deploys it; ECS health checks and circuit breakers supervise rollout.

If planning fails, the workflow restores previous SSM state. If apply fails, it reports possible partial infrastructure state and restores prior parameters where safe, but does not apply an unreviewed rollback. Re-run an approved apply. Never update only one parameter for a normal release.
