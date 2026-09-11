# Atelier DevOps - Git avancé

Projet réalisé dans le cadre de la séance 1 DevOps.

## Stratégie de branches

Nous utilisons la stratégie **Trunk-Based Development**.

- `main` est la branche principale.
- Les développements sont réalisés sur des branches courtes.
- Convention de nommage : `feature/nom`, `fix/nom`, `chore/nom`.
- Aucun développement important ne doit être réalisé directement sur `main`.
- Les modifications sont intégrées à `main` via une Pull Request après revue.
- Une fois la Pull Request fusionnée, la branche de travail est supprimée (pas fait pour preuves)
