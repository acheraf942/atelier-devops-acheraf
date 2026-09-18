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

Test verification declencheur PR
## Séance 3 — Docker : comparaison des tailles d'image

| Version | Taille | Description |
|---|---|---|
| naive | 1.15 GB | Image `python:3.12` complète, tout en un seul stage |
| multistage | *(à compléter)* | Build multi-stage sur `python:3.12-slim`, dépendances copiées uniquement, utilisateur non-root, gunicorn |

Gain : *(à compléter, en % ou en GB économisés)*

