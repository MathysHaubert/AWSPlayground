
# Résumé — TP intro Terraform & MiniStack

**Point de départ :** confusion initiale LocalStack/MiniStack — MiniStack est le remplaçant open-source apparu après le passage de LocalStack en payant, mais reste "drop-in" (même port 4566, même compatibilité Terraform/boto3).

## Infra as Code

- `provider.tf` : déclaration du plugin `hashicorp/aws`, credentials factices, endpoint DynamoDB redirigé vers MiniStack
- `main.tf` : une table `aws_dynamodb_table` (`Transactions`), `PAY_PER_REQUEST`, clé de partition `transaction_id`
- Cycle complet exécuté : `init` (télécharge le provider) → `plan` (dry-run) → `apply` (création réelle)

## Concepts clarifiés en cours de route

- **Provider vs endpoint** : sur vrai AWS, pas besoin de bloc `endpoints` — MiniStack sert juste à rediriger artificiellement les appels
- **DynamoDB n'a pas d'étape de "provisioning du service"** (contrairement à Lambda qui a besoin de code packagé), car il est serverless et schemaless
- **Clé primaire** : une seule clé de tri possible par table ; pour des accès multiples, on passe par un GSI (proche d'un index secondaire SQL) plutôt que de changer la clé primaire, qui est irréversible sans recréer la table

## Visualisation

StackPort branché sur le même réseau Docker que MiniStack (via le nom de service `localstack`, pas `localhost`) — piège classique de la région (`us-west-3` vs `eu-west-3` du provider) qui faisait "disparaître" la table de la vue.

## Code Python (boto3)

- Écriture/lecture simple avec `put_item` / `get_item` — observation du typage `Decimal` pour les nombres (jamais de `float` en fintech)
- `put_item` seul écrase silencieusement (pas d'idempotence native)
- Ajout de `ConditionExpression="attribute_not_exists(transaction_id)"` → exception `ConditionalCheckFailedException` capturée via `ClientError`, pour rejeter explicitement les doublons plutôt que de les écraser

## Cycle bouclé

`init` → `plan` → `apply` → vérification → (`destroy` à faire pour clôturer proprement)
